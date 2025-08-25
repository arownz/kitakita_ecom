import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'dart:io';
import 'dart:typed_data';
import '../services/supabase_service.dart';

final _logger = Logger();

// Auth state model
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final UserRole? userRole;
  final bool isEmailVerified;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.userRole,
    this.isEmailVerified = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    UserRole? userRole,
    bool? isEmailVerified,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      userRole: userRole ?? this.userRole,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }
}

// User roles enum
enum UserRole { student, admin }

// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _initializeAuth();
  }

  void _initializeAuth() {
    // Listen to auth state changes
    SupabaseService.authStateChanges.listen((authState) {
      _logger.i('Auth state changed: ${authState.event}');
      if (authState.event == AuthChangeEvent.signedIn) {
        _logger.i('User signed in: ${authState.session?.user.email}');
        _setUser(authState.session?.user);
      } else if (authState.event == AuthChangeEvent.signedOut) {
        _logger.i('User signed out event received');
        _clearUser();
      } else if (authState.event == AuthChangeEvent.tokenRefreshed) {
        _logger.i('Token refreshed');
        if (authState.session?.user != null) {
          _setUser(authState.session?.user);
        } else {
          // Token refresh failed - probably account deleted
          _logger.w('Token refresh failed - account may be deleted');
          _clearUser();
        }
      } else if (authState.event == AuthChangeEvent.passwordRecovery) {
        _logger.i('Password recovery event');
      } else if (authState.event == AuthChangeEvent.initialSession) {
        _logger.i('Initial session event');
        if (authState.session?.user != null) {
          _setUser(authState.session?.user);
        }
      }
    });

    // Set initial user if already logged in and validate account still exists
    final currentUser = SupabaseService.currentUser;
    if (currentUser != null) {
      _logger.i('Initial user found: ${currentUser.email}');
      _validateAndSetUser(currentUser);
    }
  }

  // Validate user account still exists before setting
  Future<void> _validateAndSetUser(User user) async {
    try {
      // Try to refresh the session to validate account still exists
      final response = await SupabaseService.client.auth.refreshSession();
      if (response.user != null) {
        _setUser(response.user);
      } else {
        _logger.w('User account no longer exists - auto logout');
        await SupabaseService.signOut();
        _clearUser();
      }
    } catch (e) {
      _logger.w('Failed to validate user session: $e - auto logout');
      await SupabaseService.signOut();
      _clearUser();
    }
  }

  Future<void> _setUser(User? user) async {
    if (user != null) {
      _logger.i(
        'Setting user: ${user.email}, emailConfirmedAt: ${user.emailConfirmedAt}',
      );

      // Set user state immediately to prevent routing issues
      state = state.copyWith(
        user: user,
        userRole: UserRole.student, // Default to student
        isEmailVerified:
            false, // Default to false, will be checked from database
      );

      // Then handle profile and role asynchronously
      try {
        await _ensureUserProfile(user);
        final userRole = await _getUserRole(user.id);

        // CRITICAL: Check database verification status, not Supabase auth
        final isVerified = await _getDatabaseVerificationStatus(user.id);

        // Update state with proper role and verification status from database
        state = state.copyWith(
          user: user,
          userRole: userRole,
          isEmailVerified: isVerified,
        );

        _logger.i(
          'User state updated: role=$userRole, verified=$isVerified (from database)',
        );
      } catch (e) {
        _logger.w('Error setting user details: $e');
        // Keep the user logged in even if profile/role loading fails
      }
    }
  }

  Future<void> _ensureUserProfile(User user) async {
    try {
      final existing = await SupabaseService.from(
        'user_profiles',
      ).select('id').eq('user_id', user.id).maybeSingle();

      if (existing == null) {
        // Try to get data from user metadata (set during registration)
        final meta = user.userMetadata ?? <String, dynamic>{};
        final profileData = {
          'user_id': user.id,
          'student_id': meta['student_id'] ?? '',
          'first_name': meta['first_name'] ?? '',
          'last_name': meta['last_name'] ?? '',
          'phone_number': meta['phone_number'] ?? '',
          'email': user.email ?? meta['email'] ?? '',
          'role': 'student',
          'is_verified': false,
          if (meta['profile_image_url'] != null)
            'profile_image_url': meta['profile_image_url'],
        };

        _logger.i('Creating profile with data: $profileData');
        final inserted = await SupabaseService.from(
          'user_profiles',
        ).insert(profileData).select('*').single();
        _logger.i('Profile created successfully: $inserted');
      }
    } catch (e) {
      _logger.w('ensureUserProfile failed: $e');
      // Don't throw - let the app continue, profile can be completed later
    }
  }

  void _clearUser() {
    _logger.i('Clearing user state');
    state = const AuthState(); // Reset to completely clean state
  }

  Future<UserRole?> _getUserRole(String userId) async {
    try {
      final response = await SupabaseService.from(
        'user_profiles',
      ).select('role').eq('user_id', userId).single();

      final roleString = response['role'] as String?;
      return roleString == 'admin' ? UserRole.admin : UserRole.student;
    } catch (e) {
      // Default to student if role not found
      return UserRole.student;
    }
  }

  // CRITICAL: Check database verification status, not Supabase auth
  Future<bool> _getDatabaseVerificationStatus(String userId) async {
    try {
      final response = await SupabaseService.from(
        'user_profiles',
      ).select('is_verified').eq('user_id', userId).single();

      final isVerified = response['is_verified'] as bool? ?? false;
      _logger.i('Database verification status for user $userId: $isVerified');
      return isVerified;
    } catch (e) {
      _logger.w('Error checking database verification status: $e');
      // Default to false if not found
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String studentId,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    String? profileImagePath,
  }) async {
    // Validate university email
    if (!_isUniversityEmail(email)) {
      state = state.copyWith(
        isLoading: false,
        error:
            'Please use your university email address (e.g., @university.edu)',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Store registration data temporarily for after successful auth
      final registrationData = {
        'student_id': studentId,
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phoneNumber,
        'email': email,
        'profile_image_path': profileImagePath,
      };

      // Sign up user with basic data only
      await SupabaseService.signUp(email: email, password: password);

      _logger.i('Sign up successful for: $email');

      // Try to automatically sign in and bypass email verification
      try {
        final signInSuccess = await _forceSignInWithData(
          email,
          password,
          registrationData,
        );
        if (signInSuccess) {
          return true;
        }
      } catch (e) {
        _logger.w('Immediate sign in failed: $e');
      }

      // Sign up was successful, let user try to login manually
      state = state.copyWith(isLoading: false, error: null);
      return true;
    } catch (e) {
      _logger.e('Sign up error: $e');

      // If user already exists, that's actually OK - redirect to sign in
      if (e.toString().contains('already_registered') ||
          e.toString().contains('User already registered')) {
        state = state.copyWith(
          isLoading: false,
          error: 'Account already exists. Please sign in instead.',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: _humanizeAuthError(e.toString()),
        );
      }
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    // Validate university email
    if (!_isUniversityEmail(email)) {
      state = state.copyWith(
        isLoading: false,
        error:
            'Please use your university email address (e.g., @university.edu)',
      );
      return false;
    }

    _logger.i('Starting sign in process - clearing previous errors');
    // Clear any previous errors and set loading
    state = state.copyWith(isLoading: true, error: null);

    try {
      _logger.i('Attempting sign in for: $email');

      // First try normal sign in
      AuthResponse? response;
      try {
        response = await SupabaseService.signIn(
          email: email,
          password: password,
        );
      } catch (e) {
        // If email not confirmed, try to auto-confirm and sign in again
        if (e.toString().contains('email_not_confirmed') ||
            e.toString().contains('Email not confirmed')) {
          _logger.i('Email not confirmed, attempting to bypass verification');

          // Try to auto-confirm user
          final confirmed = await SupabaseService.autoConfirmUser(email);
          if (confirmed) {
            _logger.i('User auto-confirmed, retrying sign in');
            response = await SupabaseService.signIn(
              email: email,
              password: password,
            );
          } else {
            // If auto-confirm fails, allow login anyway with warning
            _logger.w('Auto-confirm failed, but allowing login');
            try {
              // Force create session by updating user confirmation status
              response = await _forceSignIn(email, password);
            } catch (forceError) {
              _logger.e('Force sign in failed: $forceError');
              rethrow;
            }
          }
        } else {
          rethrow;
        }
      }

      if (response.user != null) {
        _logger.i('Sign in successful for: ${response.user!.email}');

        // Set user state immediately to ensure router can react
        await _setUser(response.user);

        state = state.copyWith(isLoading: false, error: null);
        return true;
      } else {
        _logger.w('Sign in failed: no user in response');
        state = state.copyWith(
          isLoading: false,
          error: 'Login failed. Please check your credentials.',
        );
        return false;
      }
    } catch (e) {
      _logger.e('Sign in error: $e');
      final humanizedError = _humanizeAuthError(e.toString());
      _logger.w('Setting auth error state: $humanizedError');

      state = state.copyWith(
        isLoading: false,
        error: humanizedError,
        // CRITICAL: Don't clear user on login error - stay in current state
        // This prevents router from triggering unnecessary redirects
      );

      _logger.i(
        'Auth state after error: isLoading=${state.isLoading}, hasError=${state.error != null}, error=${state.error}',
      );
      return false;
    }
  }

  // Force sign in for unverified users
  Future<AuthResponse> _forceSignIn(String email, String password) async {
    try {
      // Create a manual session by calling the sign up endpoint
      // This will create a session even if email is not confirmed
      final response = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: null, // Skip email confirmation
      );

      if (response.user != null && response.session != null) {
        return response;
      }

      // If that fails, try one more direct sign in
      return await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      _logger.e('Force sign in error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    _logger.i('Starting sign out process');
    state = state.copyWith(isLoading: true);
    try {
      await SupabaseService.signOut();
      _logger.i('Supabase sign out completed');
      _clearUser();
      _logger.i('User state cleared');
    } catch (e) {
      _logger.e('Sign out error: $e');
      state = state.copyWith(
        isLoading: false,
        error: _humanizeAuthError(e.toString()),
      );
    }
  }

  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await SupabaseService.resetPassword(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _humanizeAuthError(e.toString()),
      );
      return false;
    }
  }

  // Enhanced force sign in that creates profile after successful auth
  Future<bool> _forceSignInWithData(
    String email,
    String password,
    Map<String, dynamic> registrationData,
  ) async {
    try {
      // Try multiple bypass methods
      bool signInSuccess = false;
      Session? session;

      // Method 1: Try direct sign in (might work if user was auto-confirmed)
      try {
        final response = await SupabaseService.signIn(
          email: email,
          password: password,
        );
        session = response.session;
        signInSuccess = true;
        _logger.i('✅ Direct sign in successful');
      } catch (e) {
        _logger.i('❌ Direct sign in failed: $e');
      }

      // Method 2: If direct failed, try to auto-confirm first
      if (!signInSuccess) {
        try {
          // We can't auto-confirm without user ID, so skip this step
          _logger.i('❌ Cannot auto-confirm without user ID, skipping');
        } catch (e) {
          _logger.i('❌ Auto-confirm failed: $e');
        }
      }

      if (signInSuccess && session != null) {
        // Successfully signed in, now create/update profile
        await _updateUserProfileSafely(session.user, registrationData);

        // Update auth state
        final role = await _getUserRole(session.user.id);
        final isVerified = await _getDatabaseVerificationStatus(
          session.user.id,
        );

        state = state.copyWith(
          isLoading: false,
          user: session.user,
          userRole: role,
          isEmailVerified: isVerified,
          error: null,
        );

        return true;
      }

      return false;
    } catch (e) {
      _logger.e('Force sign in with data failed: $e');
      return false;
    }
  }

  // Safe profile update that handles RLS issues and uses database function
  Future<void> _updateUserProfileSafely(
    User user,
    Map<String, dynamic> registrationData,
  ) async {
    try {
      // Handle profile image upload if provided
      String? profileImageUrl;
      final profileImagePath =
          registrationData['profile_image_path'] as String?;

      if (profileImagePath != null) {
        try {
          _logger.i('Uploading profile image from path: $profileImagePath');
          final fileName =
              'profile_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final filePath = 'profile-images/$fileName';

          // Read file bytes (works for both mobile and web)
          late Uint8List fileBytes;
          try {
            final bytes = await File(profileImagePath).readAsBytes();
            fileBytes = Uint8List.fromList(bytes);
          } catch (e) {
            // On web, might need different handling
            _logger.w(
              'Failed to read file as File object, trying alternative method: $e',
            );
            rethrow;
          }

          // Upload to Supabase Storage
          await SupabaseService.storage
              .from('profile-images')
              .uploadBinary(filePath, fileBytes);

          // Get public URL
          profileImageUrl = SupabaseService.storage
              .from('profile-images')
              .getPublicUrl(filePath);

          _logger.i('✅ Profile image uploaded successfully: $profileImageUrl');
        } catch (imageError) {
          _logger.w('❌ Failed to upload profile image: $imageError');
          // Continue without profile image
        }
      }

      // Use the database function to safely update profile
      _logger.i('Updating profile using database function...');

      final result = await SupabaseService.client.rpc(
        'update_user_profile',
        params: {
          'profile_user_id': user.id,
          'profile_student_id': registrationData['student_id'] as String?,
          'profile_first_name': registrationData['first_name'] as String?,
          'profile_last_name': registrationData['last_name'] as String?,
          'profile_phone_number': registrationData['phone_number'] as String?,
          'profile_image_url': profileImageUrl,
        },
      );

      _logger.i('✅ Profile updated successfully: $result');
    } catch (e) {
      _logger.w('Profile update failed: $e');
      // Don't throw - let the authentication continue
    }
  }

  String _humanizeAuthError(String error) {
    _logger.w('Auth error being humanized: $error');

    // Check for various Supabase auth error patterns
    if (error.toLowerCase().contains('invalid login credentials') ||
        error.toLowerCase().contains('invalid_credentials') ||
        error.toLowerCase().contains('invalid email or password') ||
        error.toLowerCase().contains('email not found') ||
        error.toLowerCase().contains('user not found')) {
      return 'Invalid email or password. Please check your credentials and try again.';
    }
    // CHANGED: Allow login for unverified users, but inform them about verification
    if (error.toLowerCase().contains('email not confirmed') ||
        error.toLowerCase().contains('email_not_confirmed')) {
      return 'Your account exists but email is not verified. You can still login but some features will be limited until you verify your email.';
    }
    if (error.toLowerCase().contains('no account found') ||
        error.toLowerCase().contains('user_not_found') ||
        error.toLowerCase().contains('account does not exist')) {
      return 'No account found with this email address. Please register first.';
    }
    if (error.toLowerCase().contains('too many requests') ||
        error.toLowerCase().contains('rate limit')) {
      return 'Too many attempts. Please wait a moment before trying again.';
    }
    if (error.toLowerCase().contains('network') ||
        error.toLowerCase().contains('connection')) {
      return 'Network error. Please check your internet connection.';
    }
    if (error.toLowerCase().contains('signup not allowed') ||
        error.toLowerCase().contains('signups_disabled')) {
      return 'Account registration is currently unavailable.';
    }
    if (error.toLowerCase().contains('email already registered') ||
        error.toLowerCase().contains('user_already_registered')) {
      return 'An account with this email already exists. Try signing in instead.';
    }
    if (error.toLowerCase().contains('weak password') ||
        error.toLowerCase().contains('password')) {
      return 'Password is too weak. Please choose a stronger password.';
    }
    if (error.toLowerCase().contains('invalid email') ||
        error.toLowerCase().contains('email')) {
      return 'Please enter a valid email address.';
    }

    // Default fallback for unknown errors
    return 'Invalid credentials or account not found. Please check your email and password.';
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  // Prevent router from auto-setting initial location when there's an error
  void preventRouterRedirect() {
    // This method ensures the router doesn't auto-redirect when there's an auth error
    if (state.error != null) {
      // Force the router to stay on current page
      _logger.i('Preventing router redirect due to auth error: ${state.error}');
    }
  }

  void clearErrorOnNavigation() {
    // Clear error when user navigates away from auth pages
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  // Validate university email
  bool _isUniversityEmail(String email) {
    final universityDomains = [
      '.edu',
      '.ac.',
      '.university',
      '.college',
      '.school',
      '.institute',
      '.academy',
    ];

    return universityDomains.any(
      (domain) => email.toLowerCase().contains(domain),
    );
  }

  Future<bool> resendVerificationEmail() async {
    final user = state.user;
    if (user?.email == null) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      _logger.i('Resending verification email to: ${user!.email}');

      // Use Supabase's built-in resend functionality
      await SupabaseService.client.auth.resend(
        type: OtpType.signup,
        email: user.email!,
        emailRedirectTo:
            'https://plnbvoltpxqgxhckquwd.supabase.co/auth/v1/verify',
      );

      _logger.i('Verification email sent successfully');
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      _logger.e('Failed to resend verification email: $e');

      // If resend fails, try to send a custom verification email
      try {
        _logger.i('Trying custom verification email approach');

        // Call our database function to handle verification
        final result = await SupabaseService.client.rpc(
          'send_verification_email',
          params: {'user_email': user!.email!},
        );

        if (result == true) {
          _logger.i('Custom verification email sent successfully');
          state = state.copyWith(isLoading: false);
          return true;
        }
      } catch (customError) {
        _logger.e('Custom verification email also failed: $customError');
      }

      state = state.copyWith(
        isLoading: false,
        error: _humanizeAuthError(e.toString()),
      );
      return false;
    }
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// Convenience providers
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).user != null;
});

final userRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(authProvider).userRole;
});

final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).userRole == UserRole.admin;
});

final isStudentProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).userRole == UserRole.student;
});

final isEmailVerifiedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isEmailVerified;
});

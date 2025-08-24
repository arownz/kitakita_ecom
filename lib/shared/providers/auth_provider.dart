import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
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
      final isVerified = user.emailConfirmedAt != null;
      state = state.copyWith(
        user: user,
        userRole: UserRole.student, // Default to student
        isEmailVerified: isVerified,
      );

      // Then handle profile and role asynchronously
      try {
        await _ensureUserProfile(user);
        final userRole = await _getUserRole(user.id);

        // Update state with proper role
        state = state.copyWith(
          user: user,
          userRole: userRole,
          isEmailVerified: isVerified,
        );

        _logger.i('User state updated: role=$userRole, verified=$isVerified');
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

  Future<bool> signUp({
    required String email,
    required String password,
    required String studentId,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    String? profileImageUrl,
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
      // First, sign up the user
      final response = await SupabaseService.signUp(
        email: email,
        password: password,
        userData: {
          'student_id': studentId,
          'first_name': firstName,
          'last_name': lastName,
          'phone_number': phoneNumber,
          if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
          'email': email,
        },
      );

      if (response.user != null) {
        final hasSession =
            response.session != null || SupabaseService.currentUser != null;
        try {
          // If we have a session, create the profile now; otherwise it will be
          // auto-created on first sign-in by _ensureUserProfile.
          if (hasSession) {
            final profileData = {
              'user_id': response.user!.id,
              'student_id': studentId,
              'first_name': firstName,
              'last_name': lastName,
              'phone_number': phoneNumber,
              'email': email,
              'role': 'student',
              'is_verified': false,
              if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
            };

            final profileResult = await SupabaseService.from(
              'user_profiles',
            ).insert(profileData).select().single();
            _logger.i('Profile created successfully: $profileResult');
          }

          // Set the user and role
          await _setUser(response.user);

          state = state.copyWith(isLoading: false);
          return true;
        } catch (profileError) {
          _logger.e('Profile creation error: $profileError');

          // If profile creation fails, try to clean up the auth user
          try {
            await SupabaseService.signOut();
          } catch (cleanupError) {
            _logger.e('Cleanup error: $cleanupError');
          }

          state = state.copyWith(
            isLoading: false,
            error: _humanizeAuthError(
              'Failed to create user profile: ${profileError.toString()}',
            ),
          );
          return false;
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Registration failed. Please try again.',
        );
        return false;
      }
    } catch (e) {
      _logger.e('SignUp error: $e');
      state = state.copyWith(
        isLoading: false,
        error: _humanizeAuthError(e.toString()),
      );
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
      final response = await SupabaseService.signIn(
        email: email,
        password: password,
      );

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
        user: null, // Ensure user is null on error
        userRole: null,
        isEmailVerified: false,
      );

      _logger.i(
        'Auth state after error: isLoading=${state.isLoading}, hasError=${state.error != null}, error=${state.error}',
      );
      return false;
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

  String _humanizeAuthError(String error) {
    _logger.w('Auth error being humanized: $error');

    // Check for various Supabase auth error patterns
    if (error.toLowerCase().contains('invalid login credentials') ||
        error.toLowerCase().contains('invalid_credentials') ||
        error.toLowerCase().contains('invalid email or password')) {
      return 'Invalid email or password. Please check your credentials and try again.';
    }
    if (error.toLowerCase().contains('email not confirmed') ||
        error.toLowerCase().contains('email_not_confirmed')) {
      return 'Please verify your email address before signing in.';
    }
    if (error.toLowerCase().contains('user not found') ||
        error.toLowerCase().contains('user_not_found') ||
        error.toLowerCase().contains('no account found')) {
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
    return 'Something went wrong. Please try again later.';
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
      await SupabaseService.client.auth.resend(
        type: OtpType.signup,
        email: user.email!,
      );
      _logger.i('Verification email sent successfully');
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      _logger.e('Failed to resend verification email: $e');
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

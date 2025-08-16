import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

// Auth state model
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final UserRole? userRole;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.userRole,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    UserRole? userRole,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      userRole: userRole ?? this.userRole,
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
      if (authState.event == AuthChangeEvent.signedIn) {
        _setUser(authState.session?.user);
      } else if (authState.event == AuthChangeEvent.signedOut) {
        _clearUser();
      }
    });

    // Set initial user if already logged in
    final currentUser = SupabaseService.currentUser;
    if (currentUser != null) {
      _setUser(currentUser);
    }
  }

  Future<void> _setUser(User? user) async {
    if (user != null) {
      final userRole = await _getUserRole(user.id);
      state = state.copyWith(user: user, userRole: userRole);
    }
  }

  void _clearUser() {
    state = state.copyWith(user: null, userRole: null);
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
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await SupabaseService.signUp(
        email: email,
        password: password,
        userData: {
          'student_id': studentId,
          'first_name': firstName,
          'last_name': lastName,
          'phone_number': phoneNumber,
        },
      );

      if (response.user != null) {
        // Create user profile in database
        await SupabaseService.from('user_profiles').insert({
          'user_id': response.user!.id,
          'student_id': studentId,
          'first_name': firstName,
          'last_name': lastName,
          'phone_number': phoneNumber,
          'email': email,
          'role': 'student',
          'is_verified': false,
        });

        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Registration failed. Please try again.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await SupabaseService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Login failed. Please check your credentials.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await SupabaseService.signOut();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await SupabaseService.resetPassword(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
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

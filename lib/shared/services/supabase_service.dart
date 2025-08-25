import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://irfkajxfonujbjxzveka.supabase.co';
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_KEY');

  static SupabaseClient get client => Supabase.instance.client;

  // Note: Supabase is now initialized in main.dart using the template approach

  // Auth related methods
  static User? get currentUser => client.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  // Stream of auth state changes
  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;

  // Sign up with email and password (with email confirmation enabled)
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: userData,
      // Enable email confirmation - we want users to verify their emails
      emailRedirectTo:
          'https://irfkajxfonujbjxzveka.supabase.co/auth/v1/verify',
    );
  }

  // Sign in with email and password (allow unverified emails)
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Try normal sign in first
      return await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      // If email not confirmed, try alternative approaches
      if (e.toString().contains('email_not_confirmed') ||
          e.toString().contains('Email not confirmed')) {
        if (kDebugMode) {
          print('🔧 Email not confirmed, trying workarounds...');
        }

        // Approach 1: Try to update user confirmation status via RPC
        try {
          await client.rpc('confirm_user_email', params: {'user_email': email});
          // If RPC succeeds, try sign in again
          return await client.auth.signInWithPassword(
            email: email,
            password: password,
          );
        } catch (rpcError) {
          if (kDebugMode) {
            print('🔧 RPC confirm failed: $rpcError');
          }
        }

        // Approach 2: Try signing up again (which might auto-confirm)
        try {
          final signUpResponse = await client.auth.signUp(
            email: email,
            password: password,
            emailRedirectTo: null,
          );

          // If we get a session from sign up, use it
          if (signUpResponse.session != null) {
            return signUpResponse;
          }

          // Otherwise try sign in one more time
          return await client.auth.signInWithPassword(
            email: email,
            password: password,
          );
        } catch (signUpError) {
          if (kDebugMode) {
            print('🔧 Alternative sign up failed: $signUpError');
          }
        }
      }

      // If all workarounds fail, rethrow the original error
      rethrow;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Reset password
  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  // Auto-confirm user email (bypass Supabase email verification)
  static Future<bool> autoConfirmUser(String email) async {
    try {
      // Use Supabase's admin API to confirm user
      final response = await client.functions.invoke(
        'auto-confirm-user',
        body: {'email': email},
      );
      return response.status == 200;
    } catch (e) {
      if (kDebugMode) {
        print('Auto-confirm user failed: $e');
      }
      return false;
    }
  }

  // Check if user needs email confirmation bypass
  static Future<bool> needsEmailConfirmationBypass(String email) async {
    try {
      // Try to sign in to check if email confirmation is needed
      await client.auth.signInWithPassword(email: email, password: 'dummy');
      return false; // If it doesn't throw, user is confirmed
    } catch (e) {
      if (e.toString().contains('email_not_confirmed') ||
          e.toString().contains('Email not confirmed')) {
        return true; // User needs bypass
      }
      return false; // Different error
    }
  }

  // Database operations
  static SupabaseQueryBuilder from(String table) {
    return client.from(table);
  }

  // Storage operations
  static SupabaseStorageClient get storage => client.storage;

  // Real-time subscriptions
  static RealtimeChannel channel(String channelName) {
    return client.channel(channelName);
  }
}

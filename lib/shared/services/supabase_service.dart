import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://plnbvoltpxqgxhckquwd.supabase.co';
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_KEY');

  static SupabaseClient get client => Supabase.instance.client;

  // Note: Supabase is now initialized in main.dart using the template approach

  // Auth related methods
  static User? get currentUser => client.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  // Stream of auth state changes
  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;

  // Sign up with email and password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: userData,
    );
  }

  // Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign out
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Reset password
  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
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

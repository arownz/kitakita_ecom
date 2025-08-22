import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://agqauzxqiruoestoyimr.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFncWF1enhxaXJ1b2VzdG95aW1yIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUxNjk4ODMsImV4cCI6MjA3MDc0NTg4M30.9R1f_m_rghSv8SgZmQzgQ1bJmbl4G89N0U38YAw7zJ4';
      
      // service_role: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFncWF1enhxaXJ1b2VzdG95aW1yIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTE2OTg4MywiZXhwIjoyMDcwNzQ1ODgzfQ.V6Yi3KA_iOjd-EjjtZUGivQzCPw_5mZcQAYfok3hrdM

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      headers: {'apikey': supabaseAnonKey},
    );
  }

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

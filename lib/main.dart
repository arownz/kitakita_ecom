import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/app.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");

    const supabaseUrl = 'https://irfkajxfonujbjxzveka.supabase.co';
    final supabaseKey = dotenv.env['SUPABASE_KEY']!;

    // Initialize Supabase with settings that skip email confirmation
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        // Don't redirect for email confirmation
        detectSessionInUri: false,
      ),
    );

    if (kDebugMode) {
      print('✅ Supabase initialized successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Failed to initialize Supabase: $e');
    }
    // Continue running the app even if Supabase initialization fails
  }

  runApp(const ProviderScope(child: KitaKitaApp()));
}

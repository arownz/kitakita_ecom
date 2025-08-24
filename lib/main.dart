import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/app.dart';
import 'package:flutter/foundation.dart';

const supabaseUrl = 'https://plnbvoltpxqgxhckquwd.supabase.co';
const supabaseKey = String.fromEnvironment('SUPABASE_KEY');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Supabase using the template approach
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  } catch (e) {
    if (kDebugMode) {
      print('Failed to initialize Supabase: $e');
    }
    // Continue running the app even if Supabase initialization fails
  }

  runApp(const ProviderScope(child: KitaKitaApp()));
}

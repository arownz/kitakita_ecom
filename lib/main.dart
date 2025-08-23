import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared/services/supabase_service.dart';
import 'core/app.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Supabase
    await SupabaseService.initialize();
  } catch (e) {
    if (kDebugMode) {
      print('Failed to initialize Supabase: $e');
    }
    // Continue running the app even if Supabase initialization fails
  }

  runApp(const ProviderScope(child: KitaKitaApp()));
}

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseService {
  static const url = 'https://vmqedusamwdgfatgtgck.supabase.co';
  static const publishableKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZtcWVkdXNhbXdkZ2ZhdGd0Z2NrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk0MTIzNTYsImV4cCI6MjEwNDk4ODM1Nn0.-olHKoENMJXjjVTSFP0mMJRpjQs6Mt0jZUxqSux_sJI';

  static bool get isReady {
    try {
      return Supabase.instance.isInitialized;
    } catch (_) {
      return false;
    }
  }

  static Future<void> init() async {
    try {
      await Supabase.initialize(
        url: url,
        publishableKey: publishableKey,
      );
    } catch (e) {
      debugPrint('Supabase init failed: $e');
    }
  }

  static SupabaseClient? get client {
    try {
      return isReady ? Supabase.instance.client : null;
    } catch (_) {
      return null;
    }
  }
}

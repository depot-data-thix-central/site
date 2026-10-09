import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseService {
  static const url = 'https://emtrxkbnqzlwdumsavhx.supabase.co';
  static const publishableKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVtdHJ4a2JucXpsd2R1bXNhdmh4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE1MDYxMjQsImV4cCI6MjEwNzA4MjEyNH0.ZYl2Wc0RUQHqCct41ZCx1Fl8pyErPq0e__irKCXgsSc';

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

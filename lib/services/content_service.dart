import 'package:flutter/foundation.dart';
import '../models/content.dart';
import 'supabase_service.dart';

class ContentService {
  Future<SiteContent> loadPublished() async {
    final client = SupabaseService.client;
    if (client == null) {
      debugPrint('Supabase not ready → fallback content');
      return const SiteContent();
    }

    try {
      final row = await client
          .from('content_published')
          .select('data')
          .eq('id', 1)
          .maybeSingle()
          .timeout(const Duration(seconds: 6));

      if (row == null || row['data'] == null) {
        return const SiteContent();
      }

      return SiteContent.fromJson(
        Map<String, dynamic>.from(row['data'] as Map),
      );
    } catch (e) {
      debugPrint('loadPublished error: $e');
      return const SiteContent(); // jamais de crash
    }
  }
}

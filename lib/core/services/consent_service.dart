import 'package:shared_preferences/shared_preferences.dart';

/// Consentement RGPD : aucun stockage avant choix explicite.
class ConsentService {
  static const _key = 'sonathix_consent_v1';

  Future<bool?> load() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString(_key);
    return v == null ? null : v == 'granted';
  }

  Future<void> save(bool granted) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, granted ? 'granted' : 'refused');
  }
}

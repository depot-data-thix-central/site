import 'package:url_launcher/url_launcher.dart';
import 'validators.dart';

/// Ouverture de liens : schémas et hôtes strictement whitelistés.
/// Bloque javascript:, data:, file: et tout domaine non approuvé.
class SafeLaunch {
  static const Set<String> _allowedHosts = {
    'sonathix.group', 'www.sonathix.group',
    'linkedin.com', 'www.linkedin.com',
    'x.com', 'www.x.com',
    'youtube.com', 'www.youtube.com',
    't.me', 'telegram.me',
  };

  static Future<bool> open(Uri uri) async {
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'mailto') {
      if (Validators.validateEmail(uri.path) != null) return false;
    } else if (scheme == 'https') {
      if (!_allowedHosts.contains(uri.host.toLowerCase())) return false;
      if (uri.userInfo.isNotEmpty) return false; // bloque user@host tricks
    } else {
      return false;
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

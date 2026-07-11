import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// External URLs referenced across the site.
abstract final class Links {
  static const String github = 'https://github.com/BirjuVachhani/shiki_flutter';
  static const String pubDev = 'https://pub.dev/packages/shiki_flutter';
  static const String author = 'https://github.com/BirjuVachhani';
  static const String shiki = 'https://shiki.style';
  static const String vscodeTextmate =
      'https://github.com/microsoft/vscode-textmate';

  /// Opens [url] in a new browser tab (or the platform default handler).
  static Future<void> open(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error) {
      debugPrint('Could not open $url: $error');
    }
  }
}

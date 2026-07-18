import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shiki_flutter/shiki_flutter.dart';

import 'src/router/app_router.dart';
import 'src/theme/app_theme.dart';
import 'src/theme/theme_controller.dart';

void main() {
  // Clean URLs for the web (/, /docs) instead of hash fragments.
  usePathUrlStrategy();
  // Dogfood async highlighting: code appears immediately in the theme's base
  // color and swaps to the highlighted result when tokenization finishes (on a
  // background isolate on native, or a browser Web Worker on web, installed via
  // `dart run shiki_flutter:install_web_worker` into web/), with results cached
  // so rebuilds are instant. This keeps the UI thread from freezing on the
  // one-time grammar compile.
  ShikiHighlighter.config = const ShikiHighlighterConfig(asyncWeb: true);
  runApp(const ShikiSite());
}

/// Root of the showcase site. Owns the [ThemeController] and rebuilds the app
/// when the light/dark mode changes.
class ShikiSite extends StatefulWidget {
  const ShikiSite({super.key});

  @override
  State<ShikiSite> createState() => _ShikiSiteState();
}

class _ShikiSiteState extends State<ShikiSite> {
  final ThemeController _theme = ThemeController();

  @override
  void dispose() {
    _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTheme(
      controller: _theme,
      child: ListenableBuilder(
        listenable: _theme,
        builder: (context, _) {
          return MaterialApp.router(
            title: 'shiki_flutter: syntax highlighting for Flutter',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(Brightness.light),
            darkTheme: buildTheme(Brightness.dark),
            themeMode: _theme.value,
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}

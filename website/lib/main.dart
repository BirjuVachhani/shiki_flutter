import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shiki_flutter/shiki_flutter.dart';
import 'package:shiki_flutter_native_engine/shiki_flutter_native_engine.dart';

import 'src/router/app_router.dart';
import 'src/theme/app_theme.dart';
import 'src/theme/theme_controller.dart';
import 'src/widgets/nav_sheet.dart';

void main() {
  // Clean URLs for the web (/, /docs) instead of hash fragments.
  usePathUrlStrategy();
  // Dogfood off-main-thread highlighting on both platforms: code appears
  // immediately in the theme's base color and swaps to the highlighted result
  // when tokenization finishes, with results cached so rebuilds are instant.
  // This keeps the UI thread from freezing on the one-time grammar compile.
  //   * IO (desktop/mobile): the native Oniguruma engine (dart:ffi) on a
  //     background isolate.
  //   * Web: the pure-Dart embedded engine in a browser Web Worker
  //     (web/shiki_tokenize_worker.js, from `dart run shiki_flutter:install`).
  // The engine/async split lives in engine_config.dart so the web build never
  // pulls in the native engine's WebAssembly.
  ShikiHighlighter.config = const ShikiHighlighterConfig(
    ioEngine: ShikiHighlighterNativeEngine(),
    webEngine: ShikiHighlighterEmbeddedEngine(),
    asyncIO: true,
    asyncWeb: true,
    defaultTheme: .dual(
      light: PierreThemes.pierreLight,
      dark: PierreThemes.pierreDark,
    ),
  );
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

  /// Bridges the docs page's section list to the app-wide nav popup. Lives above
  /// the router so the shell's nav bar and the docs page share one instance.
  final NavSheetController _navSheet = NavSheetController();

  @override
  void dispose() {
    _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTheme(
      controller: _theme,
      child: NavSheetScope(
        controller: _navSheet,
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
      ),
    );
  }
}

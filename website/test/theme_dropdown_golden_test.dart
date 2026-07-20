import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiki_flutter_website/src/theme/app_theme.dart';
import 'package:shiki_flutter_website/src/theme/tokens.dart';
import 'package:shiki_flutter_website/src/widgets/theme_dropdown.dart';

/// Golden tests used to match the diffs.com theme dropdown 1:1. Run with
/// `flutter test --update-goldens test/theme_dropdown_golden_test.dart` to
/// regenerate the PNGs under `test/goldens/`, then eyeball them against the
/// reference.

const _choices = <ThemeChoice>[
  (id: 'github-dark', isDark: true),
  (id: 'github-light', isDark: false),
  (id: 'one-dark-pro', isDark: true),
  (id: 'dracula', isDark: true),
  (id: 'nord', isDark: true),
  (id: 'vitesse-dark', isDark: true),
  (id: 'vitesse-light', isDark: false),
  (id: 'vesper', isDark: true),
];

Future<void> _loadFonts() async {
  final geist = FontLoader('Geist');
  for (final w in ['400', '500', '600', '700']) {
    final bytes = File('assets/fonts/Geist-$w.ttf').readAsBytesSync();
    geist.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await geist.load();

  // Load Material's icon font from the Flutter SDK cache so `Icons.*` render as
  // real glyphs, not tofu. Walk up from the running executable (which is
  // flutter_tester, under <flutter>/bin/cache/artifacts/engine/...) until an
  // ancestor contains artifacts/material_fonts/.
  final iconsPath = _materialIconsPath();
  if (iconsPath != null) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(
        Future.value(ByteData.sublistView(File(iconsPath).readAsBytesSync())),
      );
    await loader.load();
  }
}

String? _materialIconsPath() {
  var dir = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 12; i++) {
    final candidate = File(
      '${dir.path}/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (candidate.existsSync()) return candidate.path;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return null;
}

/// Sets the test surface from a *logical* size at [dpr] (physicalSize is in
/// physical pixels, so it must be logical * dpr).
void _setSurface(WidgetTester tester, Size logical, {double dpr = 3.0}) {
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = logical * dpr;
}

Widget _harness(Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildTheme(Brightness.dark),
    home: Builder(
      builder: (context) => Scaffold(
        backgroundColor: context.colors.background,
        body: Center(
          child: Padding(padding: const EdgeInsets.all(24), child: child),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('trigger', (tester) async {
    _setSurface(tester, const Size(300, 120));
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _harness(
        const Align(
          alignment: Alignment.centerLeft,
          child: ThemeDropdownTrigger(
            choice: (id: 'github-dark', isDark: true),
            open: false,
            onTap: _noop,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ThemeDropdownTrigger),
      matchesGoldenFile('goldens/theme_dropdown_trigger.png'),
    );
  });

  testWidgets('panel', (tester) async {
    _setSurface(tester, const Size(340, 460));
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _harness(
        Align(
          alignment: Alignment.topLeft,
          child: ThemeDropdownPanel(
            choices: _choices,
            selectedId: 'github-dark',
            width: 272,
            onSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ThemeDropdownPanel),
      matchesGoldenFile('goldens/theme_dropdown_panel.png'),
    );
  });
}

void _noop() {}

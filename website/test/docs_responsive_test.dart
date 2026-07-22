import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiki_flutter_website/main.dart';
import 'package:shiki_flutter_website/src/router/app_router.dart';

/// Guards the docs page against UI overflow across the responsive range. Each
/// width renders the app fresh and deep-links straight to `/docs` (navigating
/// before the first pump so the home page never renders into the frame), which
/// keeps navigation width-agnostic and the capture scoped to the docs page.
/// The page uses one scroll view whose Column lays out every section in a
/// frame, so a single pump exercises all section content. Widths straddle the
/// 900px compact breakpoint, from small phones to wide desktop.
void main() {
  const widths = <double>[320, 360, 390, 414, 600, 768, 900, 1024, 1280, 1600];

  for (final width in widths) {
    testWidgets('docs page has no overflow at ${width}px wide', (tester) async {
      tester.view.physicalSize = Size(width, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      appRouter.go('/docs');
      await tester.pumpWidget(const ShikiSite());
      await tester.pumpAndSettle();

      // Any RenderFlex/layout overflow is reported during paint and surfaces
      // here as a pending exception.
      expect(
        tester.takeException(),
        isNull,
        reason: 'The docs page overflowed at ${width}px wide.',
      );
    });
  }
}

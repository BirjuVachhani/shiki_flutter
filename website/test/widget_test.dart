import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiki_flutter_website/main.dart';

void main() {
  testWidgets('home renders and Documentation navigates to docs', (
    tester,
  ) async {
    // Use a desktop-sized surface so the wide layout (nav links, sidebar) runs.
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ShikiSite());
    await tester.pumpAndSettle();

    // Brand wordmark appears and the hero CTA is present.
    expect(find.text('Shiki'), findsWidgets);
    expect(find.text('Documentation'), findsOneWidget);

    // Navigate to the docs page.
    await tester.tap(find.text('Documentation'));
    await tester.pumpAndSettle();

    // The docs sidebar + section heading render.
    expect(find.text('Introduction'), findsWidgets);
    expect(find.text('Installation'), findsWidgets);
  });
}

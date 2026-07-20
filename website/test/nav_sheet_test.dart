import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shiki_flutter_website/src/data/docs_sections.dart';
import 'package:shiki_flutter_website/src/theme/app_theme.dart';
import 'package:shiki_flutter_website/src/theme/theme_controller.dart';
import 'package:shiki_flutter_website/src/widgets/nav_sheet.dart';

/// Records section-scroll requests so a test can assert the popup routed a tap
/// back to the docs page.
class _FakeDocsNav implements DocsSectionNavigator {
  int scrolledTo = -1;

  @override
  int get activeSection => 0;

  @override
  void scrollToSection(int index) => scrolledTo = index;
}

/// A minimal app that opens the shared nav sheet from a button, wired with the
/// same scopes (`AppTheme`, `NavSheetScope`, a `GoRouter`) the sheet needs.
Widget _harness(NavSheetController controller, {required String route}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => TextButton(
                onPressed: () => showAppNavSheet(context, currentRoute: route),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ],
  );
  return AppTheme(
    controller: ThemeController(),
    child: NavSheetScope(
      controller: controller,
      child: MaterialApp.router(
        theme: buildTheme(Brightness.dark),
        routerConfig: router,
      ),
    ),
  );
}

void main() {
  testWidgets('shows site links only when no docs page is registered', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(NavSheetController(), route: '/'));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Site links are present...
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Docs'), findsOneWidget);
    expect(find.text('GitHub'), findsOneWidget);
    expect(find.text('pub.dev'), findsOneWidget);
    // ...but the docs section list is not, since no page registered.
    expect(find.text('GETTING STARTED'), findsNothing);
    expect(find.text('Introduction'), findsNothing);
  });

  testWidgets('appends the section list and scrolls when docs is registered', (
    tester,
  ) async {
    // A compact width (the sheet only opens below the compact breakpoint), tall
    // enough that the whole section list fits without scrolling so the last
    // section stays on-screen for the tap.
    tester.view.physicalSize = const Size(600, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fake = _FakeDocsNav();
    await tester.pumpWidget(
      _harness(NavSheetController()..docs = fake, route: '/docs'),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Site links plus the full grouped section list are present.
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('GETTING STARTED'), findsOneWidget);
    expect(find.text('Introduction'), findsOneWidget);
    expect(find.text('Limitations'), findsOneWidget);

    // Tapping a section scrolls the page to it and closes the sheet.
    await tester.tap(find.text('Limitations'));
    await tester.pumpAndSettle();

    final expected = docsSections.indexWhere((s) => s.title == 'Limitations');
    expect(fake.scrolledTo, expected);
    expect(find.text('GETTING STARTED'), findsNothing);
  });
}

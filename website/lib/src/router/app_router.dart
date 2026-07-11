import 'package:go_router/go_router.dart';

import '../pages/docs_page.dart';
import '../pages/home_page.dart';
import '../widgets/app_shell.dart';

/// Site routes. Each page is wrapped in [AppShell] so the nav bar and drawer
/// are shared. Unknown paths fall back to the home page.
final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: AppShell(currentRoute: '/', child: HomePage()),
      ),
    ),
    GoRoute(
      path: '/docs',
      pageBuilder: (context, state) => NoTransitionPage(
        child: AppShell(
          currentRoute: '/docs',
          child: DocsPage(
            initialSection: state.uri.queryParameters['section'],
          ),
        ),
      ),
    ),
  ],
  errorBuilder: (context, state) =>
      const AppShell(currentRoute: '/', child: HomePage()),
);

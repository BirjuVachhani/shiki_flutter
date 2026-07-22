import 'package:go_router/go_router.dart';

import '../pages/docs_page.dart';
import '../pages/home_page.dart';
import '../seo/page_meta.dart';
import '../widgets/app_shell.dart';

/// Site routes. Each page is wrapped in [AppShell] so the nav bar and drawer
/// are shared. Unknown paths fall back to the home page.
final GoRouter appRouter = GoRouter(
  // Keep the document title and meta description in step with the active route.
  // Runs on the initial load and every navigation; always returns null, so it
  // never actually redirects. Web-only in effect (a no-op stub off web).
  redirect: (context, state) {
    applyPageMetaForLocation(state.uri.toString());
    return null;
  },
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

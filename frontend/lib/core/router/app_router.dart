import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../../features/auth/pages/login_page.dart';
import '../../features/auth/pages/register_page.dart';
import '../../features/splash/pages/splash_page.dart';
import '../../features/dashboard/pages/dashboard_home_page.dart';
import '../../features/vision/pages/vision_dashboard_page.dart';
import '../../features/nlp/pages/nlp_dashboard_page.dart';
import '../../features/generative/pages/generative_chat_page.dart';
import '../widgets/dashboard_layout.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        final location = state.uri.path;
        int selectedIndex = 0;
        if (location.startsWith('/vision'))
          selectedIndex = 1;
        else if (location.startsWith('/nlp'))
          selectedIndex = 2;
        else if (location.startsWith('/generative'))
          selectedIndex = 3;
        else if (location.startsWith('/history'))
          selectedIndex = 4;
        else if (location.startsWith('/analytics'))
          selectedIndex = 5;
        else if (location.startsWith('/settings')) selectedIndex = 6;

        return DashboardLayout(
          selectedIndex: selectedIndex,
          onNavigate: (index) {
            switch (index) {
              case 0:
                context.go('/');
                break;
              case 1:
                context.go('/vision');
                break;
              case 2:
                context.go('/nlp');
                break;
              case 3:
                context.go('/generative');
                break;
              case 4:
                context.go('/history');
                break;
              case 5:
                context.go('/analytics');
                break;
              case 6:
                context.go('/settings');
                break;
            }
          },
          child: child,
        );
      },
      routes: [
        GoRoute(
            path: '/',
            builder: (context, state) => DashboardHomePage(
                  onNavigateToVision: () => context.go('/vision'),
                  onNavigateToNLP: () => context.go('/nlp'),
                  onNavigateToGenerative: () => context.go('/generative'),
                )),
        GoRoute(
            path: '/vision',
            builder: (context, state) => const VisionDashboardPage()),
        GoRoute(
            path: '/nlp',
            builder: (context, state) => const NlpDashboardPage()),
        GoRoute(
            path: '/generative',
            builder: (context, state) => const GenerativeChatPage()),
        GoRoute(
            path: '/history',
            builder: (context, state) =>
                const _PlaceholderPage(title: 'Historique')),
        GoRoute(
            path: '/analytics',
            builder: (context, state) =>
                const _PlaceholderPage(title: 'Analytics')),
        GoRoute(
            path: '/settings',
            builder: (context, state) =>
                const _PlaceholderPage(title: 'Paramètres')),
      ],
    ),
  ],
);

class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction_rounded,
              size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Cette page est en cours de développement',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/pages/login_page.dart';
import '../../features/auth/pages/register_page.dart';
import '../../features/splash/pages/splash_page.dart';
import '../../features/home/pages/home_page.dart';
import '../../features/centers/pages/centers_page.dart';

import '../../features/generative/pages/chat_page.dart';
import '../../features/datahub/pages/datahub_page.dart';
import '../../features/quiz/pages/quiz_page.dart';
import '../../features/quiz/pages/quiz_session_page.dart';
import '../../features/quiz/pages/quiz_result_page.dart';
import '../../features/quiz/pages/quiz_history_loader_page.dart';
import '../../features/profile/pages/profile_page.dart';
import '../../features/eco_smart/pages/eco_smart_page.dart';
import '../../features/classification/pages/waste_classification_page.dart';
import '../../features/collecte/pages/collecte_page.dart';
import '../../features/dashboard/pages/eco_impact_page.dart';
import '../widgets/mobile_shell.dart';

// Google ML Kit Vision Premium Pages
import '../../features/vision/pages/vision_page.dart';
import '../../features/vision/pages/realtime_vision_page.dart';

/// Premium mobile-first router configuration
final premiumRouter = GoRouter(
  initialLocation: '/splash',
  debugLogDiagnostics: false,
  routes: [
    // ══════════════════════════════════════════════════════════════
    // AUTH ROUTES
    // ══════════════════════════════════════════════════════════════
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SplashPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),

    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LoginPage(),
        transitionsBuilder: _slideTransition,
      ),
    ),

    GoRoute(
      path: '/register',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const RegisterPage(),
        transitionsBuilder: _slideTransition,
      ),
    ),

    GoRoute(
      path: '/vision',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const VisionPage(),
        transitionsBuilder: _slideUpTransition,
      ),
      routes: [
        GoRoute(
          path: 'realtime',
          pageBuilder: (context, state) {
            final mode = state.uri.queryParameters['mode'];
            return CustomTransitionPage(
              key: state.pageKey,
              child: RealtimeVisionPage(initialMode: mode),
              transitionsBuilder: _slideUpTransition,
            );
          },
        ),
        GoRoute(
          path: 'text-recognition',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const RealtimeVisionPage(initialMode: 'ocr'),
            transitionsBuilder: _slideUpTransition,
          ),
        ),
        GoRoute(
          path: 'object-detection',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const RealtimeVisionPage(initialMode: 'scanDechet'),
            transitionsBuilder: _slideUpTransition,
          ),
        ),
        GoRoute(
          path: 'barcode-scan',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const RealtimeVisionPage(initialMode: 'barcode'),
            transitionsBuilder: _slideUpTransition,
          ),
        ),
      ],
    ),

    // ══════════════════════════════════════════════════════════════
    // MAIN APP (Shell with bottom navigation)
    // ══════════════════════════════════════════════════════════════
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MobileShell(
          currentIndex: navigationShell.currentIndex,
          onNavigate: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
          child: navigationShell,
        );
      },
      branches: [
        // ─────────────────────────────────────────────────────────
        // HOME BRANCH
        // ─────────────────────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: HomePage(),
              ),
              routes: [
                GoRoute(
                  path: 'eco-smart',
                  pageBuilder: (context, state) {
                    final prefillRapport = state.uri.queryParameters['prefillRapport'];
                    final prefillPoids = double.tryParse(state.uri.queryParameters['prefillPoids'] ?? '');
                    final prefillVolume = double.tryParse(state.uri.queryParameters['prefillVolume'] ?? '');
                    final prefillConductivite = double.tryParse(state.uri.queryParameters['prefillConductivite'] ?? '');
                    final prefillOpacite = double.tryParse(state.uri.queryParameters['prefillOpacite'] ?? '');
                    final prefillRigidite = double.tryParse(state.uri.queryParameters['prefillRigidite'] ?? '');
                    
                    return CustomTransitionPage(
                      key: state.pageKey,
                      child: EcoSmartPage(
                        prefillRapport: prefillRapport,
                        prefillPoids: prefillPoids,
                        prefillVolume: prefillVolume,
                        prefillConductivite: prefillConductivite,
                        prefillOpacite: prefillOpacite,
                        prefillRigidite: prefillRigidite,
                      ),
                      transitionsBuilder: _slideUpTransition,
                    );
                  },
                ),
                GoRoute(
                  path: 'eco-impact',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: const EcoImpactPage(),
                    transitionsBuilder: _slideUpTransition,
                  ),
                ),
                GoRoute(
                  path: 'classification',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: const WasteClassificationPage(),
                    transitionsBuilder: _slideUpTransition,
                  ),
                ),
                GoRoute(
                  path: 'collecte',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: const CollectePage(),
                    transitionsBuilder: _slideUpTransition,
                  ),
                ),
              ],
            ),
          ],
        ),

        // ─────────────────────────────────────────────────────────
        // CENTERS BRANCH
        // ─────────────────────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/centers',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: CentersPage(),
              ),
            ),
          ],
        ),



        // ─────────────────────────────────────────────────────────
        // GENERATIVE AI BRANCH
        // ─────────────────────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/ai',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ChatPage(),
              ),
              routes: [
                GoRoute(
                  path: 'quiz',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: const QuizPage(),
                    transitionsBuilder: _slideUpTransition,
                  ),
                  routes: [
                    GoRoute(
                      path: 'history',
                      pageBuilder: (context, state) => CustomTransitionPage(
                        key: state.pageKey,
                        child: const QuizHistoryLoaderPage(),
                        transitionsBuilder: _slideUpTransition,
                      ),
                    ),
                    GoRoute(
                      path: 'session',
                      pageBuilder: (context, state) {
                        final args = state.extra as QuizSessionArgs;
                        return CustomTransitionPage(
                          key: state.pageKey,
                          child: QuizSessionPage(quiz: args.quiz),
                          transitionsBuilder: _slideUpTransition,
                        );
                      },
                    ),
                    GoRoute(
                      path: 'result',
                      pageBuilder: (context, state) {
                        final args = state.extra as QuizResultArgs;
                        return CustomTransitionPage(
                          key: state.pageKey,
                          child: QuizResultPage(
                            quiz: args.quiz,
                            result: args.result,
                          ),
                          transitionsBuilder: _slideUpTransition,
                        );
                      },
                    ),
                  ],
                ),
                GoRoute(
                  path: 'datahub',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: const DataHubPage(),
                    transitionsBuilder: _slideUpTransition,
                  ),
                ),
              ],
            ),
          ],
        ),

        // ─────────────────────────────────────────────────────────
        // PROFILE BRANCH
        // ─────────────────────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ProfilePage(),
              ),
              routes: [
                GoRoute(
                  path: 'settings',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: const _FeaturePlaceholder(
                      title: 'Paramètres',
                      icon: Icons.settings_rounded,
                    ),
                    transitionsBuilder: _slideUpTransition,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

// ══════════════════════════════════════════════════════════════
// TRANSITION ANIMATIONS
// ══════════════════════════════════════════════════════════════

Widget _slideTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    )),
    child: child,
  );
}

Widget _slideUpTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    )),
    child: FadeTransition(
      opacity: animation,
      child: child,
    ),
  );
}

// ══════════════════════════════════════════════════════════════
// PLACEHOLDER FOR FEATURES (temporary)
// ══════════════════════════════════════════════════════════════

class _FeaturePlaceholder extends StatelessWidget {
  final String title;
  final IconData icon;

  const _FeaturePlaceholder({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Bientôt disponible',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

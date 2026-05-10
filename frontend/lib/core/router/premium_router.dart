import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/pages/login_page.dart';
import '../../features/auth/pages/register_page.dart';
import '../../features/splash/pages/splash_page.dart';
import '../../features/home/pages/home_page.dart';
import '../../features/vision/pages/vision_page.dart';
import '../../features/vision/pages/realtime_vision_page.dart';
import '../../features/vision/pages/ocr_page.dart';
import '../../features/vision/pages/face_detection_page.dart';
import '../../features/vision/pages/object_detection_page.dart';
import '../../features/vision/pages/barcode_scan_page.dart';
import '../../features/nlp/pages/nlp_page.dart';
import '../../features/nlp/pages/translation_page.dart';
import '../../features/nlp/pages/sentiment_page.dart';
import '../../features/nlp/pages/entity_extraction_page.dart';
import '../../features/nlp/pages/language_detection_page.dart';
import '../../features/nlp/pages/smart_reply_page.dart';
import '../../features/nlp/pages/summarization_page.dart';
import '../../features/nlp/pages/classification_page.dart';
import '../../features/generative/pages/chat_page.dart';
import '../../features/datahub/pages/datahub_page.dart';
import '../../features/profile/pages/profile_page.dart';
import '../widgets/mobile_shell.dart';

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
            ),
          ],
        ),

        // ─────────────────────────────────────────────────────────
        // VISION BRANCH
        // ─────────────────────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/vision',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: VisionPage(),
              ),
              routes: [
                GoRoute(
                  path: 'realtime',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: const RealtimeVisionPage(),
                    transitionsBuilder: _slideUpTransition,
                  ),
                ),
                GoRoute(
                  path: 'text-recognition',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: const OCRPage(),
                    transitionsBuilder: _slideUpTransition,
                  ),
                ),
                GoRoute(
                  path: 'face-detection',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: const FaceDetectionPage(),
                    transitionsBuilder: _slideUpTransition,
                  ),
                ),
                GoRoute(
                  path: 'object-detection',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: const ObjectDetectionPage(),
                    transitionsBuilder: _slideUpTransition,
                  ),
                ),
                GoRoute(
                  path: 'barcode-scan',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: const BarcodeScanPage(),
                    transitionsBuilder: _slideUpTransition,
                  ),
                ),
              ],
            ),
          ],
        ),

        // ─────────────────────────────────────────────────────────
        // NLP BRANCH
        // ─────────────────────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/nlp',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: NLPPage(),
              ),
              routes: [
                GoRoute(
                  path: 'translation',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: const TranslationPage(),
                    transitionsBuilder: _slideUpTransition,
                  ),
                ),
                GoRoute(
                  path: 'sentiment',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: const SentimentPage(),
                    transitionsBuilder: _slideUpTransition,
                  ),
                ),
                GoRoute(
                  path: 'entity-extraction',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: const EntityExtractionPage(),
                    transitionsBuilder: _slideUpTransition,
                  ),
                ),
                GoRoute(
                  path: 'language-detection',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: const LanguageDetectionPage(),
                    transitionsBuilder: _slideUpTransition,
                  ),
                ),
                GoRoute(
                  path: 'summarization',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: const SummarizationPage(),
                    transitionsBuilder: _slideUpTransition,
                  ),
                ),
                GoRoute(
                  path: 'classification',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: const ClassificationPage(),
                    transitionsBuilder: _slideUpTransition,
                  ),
                ),
                GoRoute(
                  path: 'smart-reply',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: const SmartReplyPage(),
                    transitionsBuilder: _slideUpTransition,
                  ),
                ),
              ],
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

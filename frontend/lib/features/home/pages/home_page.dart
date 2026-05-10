import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/design_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/premium_theme.dart';
import '../../../core/widgets/premium_components.dart';
import '../../auth/repository/auth_repository.dart';
import '../../generative/repository/generative_repository.dart';

/// Premium Home Page - Clean, minimal design
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _cacheKey = 'home_stats_cache_v1';

  late Future<_HomeStats> _statsFuture;
  _HomeStats? _cachedStats;

  @override
  void initState() {
    super.initState();
    _hydrateStatsFromCache();
    _statsFuture = _loadStats();
  }

  Future<void> _hydrateStatsFromCache() async {
    try {
      final prefs = getIt<SharedPreferences>();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;

      final stats = _HomeStats.fromJson(decoded);
      if (!mounted) return;
      setState(() => _cachedStats = stats);
    } catch (_) {
      // Ignore malformed cache.
    }
  }

  void _refreshStats() {
    setState(() {
      _statsFuture = _loadStats();
    });
  }

  Future<_HomeStats> _loadStats() async {
    int analyses = 0;
    int conversations = 0;
    bool requiresLogin = false;

    try {
      final profile = await getIt<AuthRepository>().getProfile();
      analyses = profile.apiCallsCount;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        requiresLogin = true;
      }
    } catch (_) {
      // Keep fallback to 0 if user is not authenticated or request fails.
    }

    try {
      final convos = await getIt<GenerativeRepository>().getConversations();
      conversations = convos.length;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        requiresLogin = true;
      }
    } catch (_) {
      // Keep fallback to 0 if request fails.
    }

    final stats = _HomeStats(
      analyses: analyses,
      conversations: conversations,
      requiresLogin: requiresLogin,
      updatedAt: DateTime.now(),
    );

    _cachedStats = stats;
    try {
      final prefs = getIt<SharedPreferences>();
      await prefs.setString(_cacheKey, jsonEncode(stats.toJson()));
    } catch (_) {
      // Ignore cache write failure.
    }
    return stats;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final features = Theme.of(context).extension<FeatureColors>()!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            backgroundColor: isDark
                ? DesignColors.backgroundDark
                : DesignColors.backgroundLight,
            surfaceTintColor: Colors.transparent,
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: DesignColors.goldGradient,
                    borderRadius: DesignRadius.radiusSm,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: DesignColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'ML Kit',
                  style: DesignTypography.headlineSmall(
                    isDark
                        ? DesignColors.textPrimaryDark
                        : DesignColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => HapticFeedback.lightImpact(),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Content
          SliverPadding(
            padding: EdgeInsets.only(
              left: DesignSpacing.md,
              right: DesignSpacing.md,
              top: DesignSpacing.md,
              bottom: DesignSpacing.bottomNavHeight + DesignSpacing.xxl,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Hero Section
                _HeroCard(isDark: isDark),
                const SizedBox(height: 32),

                // Quick Actions
                SectionHeader(
                    title: 'Actions rapides', padding: EdgeInsets.zero),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.camera_alt_rounded,
                        label: 'Scanner',
                        color: features.vision,
                        onTap: () => context.go('/vision'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.mic_rounded,
                        label: 'Parler',
                        color: features.nlp,
                        onTap: () => context.go('/nlp'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.chat_bubble_rounded,
                        label: 'Chat IA',
                        color: features.generative,
                        onTap: () => context.go('/ai'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Features Section
                SectionHeader(
                  title: 'Fonctionnalités',
                  subtitle: 'Explorez les capacités ML Kit',
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),

                FeatureCard(
                  icon: Icons.visibility_rounded,
                  title: 'Vision par ordinateur',
                  subtitle:
                      'Reconnaissance de texte, détection de visages et d\'objets',
                  accentColor: features.vision,
                  onTap: () => context.go('/vision'),
                ),
                const SizedBox(height: 12),
                FeatureCard(
                  icon: Icons.translate_rounded,
                  title: 'Traitement du langage',
                  subtitle:
                      'Traduction, analyse de sentiment, extraction d\'entités',
                  accentColor: features.nlp,
                  onTap: () => context.go('/nlp'),
                ),
                const SizedBox(height: 12),
                FeatureCard(
                  icon: Icons.auto_awesome_rounded,
                  title: 'IA Générative',
                  subtitle:
                      'Chat intelligent avec des modèles de langage avancés',
                  accentColor: features.generative,
                  onTap: () => context.go('/ai'),
                ),
                const SizedBox(height: 32),

                // Stats Section
                Row(
                  children: [
                    const Expanded(
                      child: SectionHeader(
                          title: 'Statistiques', padding: EdgeInsets.zero),
                    ),
                    IconButton(
                      tooltip: 'Rafraichir',
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: _refreshStats,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FutureBuilder<_HomeStats>(
                  future: _statsFuture,
                  builder: (context, snapshot) {
                    final stats = snapshot.data ?? _cachedStats;
                    final isLoading =
                        snapshot.connectionState == ConnectionState.waiting &&
                            stats == null;

                    final analysesValue = stats?.analyses ?? 0;
                    final conversationsValue = stats?.conversations ?? 0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                value: isLoading ? '...' : '$analysesValue',
                                label: 'Analyses',
                                icon: Icons.analytics_rounded,
                                accentColor: features.vision,
                                trend: isLoading ? '...' : 'Live',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatCard(
                                value:
                                    isLoading ? '...' : '$conversationsValue',
                                label: 'Conversations',
                                icon: Icons.chat_rounded,
                                accentColor: features.generative,
                                trend: isLoading ? '...' : 'Live',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          stats != null
                              ? 'Mise a jour: ${_formatTime(stats.updatedAt)} (${_relativeTime(stats.updatedAt)})'
                              : 'Mise a jour: --:--',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? DesignColors.textSecondaryDark
                                        : DesignColors.textSecondaryLight,
                                  ),
                        ),
                        if (stats?.requiresLogin == true) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Connectez-vous pour voir des statistiques completes.',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.orange[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeStats {
  final int analyses;
  final int conversations;
  final bool requiresLogin;
  final DateTime updatedAt;

  const _HomeStats({
    required this.analyses,
    required this.conversations,
    required this.requiresLogin,
    required this.updatedAt,
  });

  factory _HomeStats.fromJson(Map<String, dynamic> json) {
    return _HomeStats(
      analyses: json['analyses'] as int? ?? 0,
      conversations: json['conversations'] as int? ?? 0,
      requiresLogin: json['requiresLogin'] as bool? ?? false,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'analyses': analyses,
      'conversations': conversations,
      'requiresLogin': requiresLogin,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

String _formatTime(DateTime time) {
  final hh = time.hour.toString().padLeft(2, '0');
  final mm = time.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

String _relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inSeconds < 60) return 'il y a quelques secondes';
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
  return 'il y a ${diff.inDays} j';
}

class _HeroCard extends StatelessWidget {
  final bool isDark;
  const _HeroCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF1A1F36), Color(0xFF2D3452)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [DesignColors.primary, DesignColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: DesignRadius.radiusXl,
        boxShadow: DesignColors.shadowLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: DesignColors.accent,
              borderRadius: DesignRadius.radiusFull,
            ),
            child: Text(
              'Premium',
              style: DesignTypography.labelSmall(DesignColors.primary),
            ),
          ),
          const SizedBox(height: 20),
          Text('Bienvenue', style: DesignTypography.displaySmall(Colors.white)),
          const SizedBox(height: 8),
          Text(
            'Explorez la puissance du Machine Learning sur mobile',
            style: DesignTypography.bodyMedium(
                Colors.white.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _HeroStat(label: 'Modèles', value: '10+'),
              const SizedBox(width: 24),
              _HeroStat(label: 'Précision', value: '98%'),
              const SizedBox(width: 24),
              _HeroStat(label: 'Temps réel', value: '< 1s'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: DesignTypography.titleLarge(Colors.white)),
        Text(label,
            style:
                DesignTypography.caption(Colors.white.withValues(alpha: 0.7))),
      ],
    );
  }
}

class _QuickActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: DesignDurations.fast);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: isDark ? 0.15 : 0.1),
            borderRadius: DesignRadius.radiusLg,
            border: Border.all(
                color: widget.color.withValues(alpha: 0.2), width: 1),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: DesignRadius.radiusMd,
                  boxShadow: DesignColors.shadowColored(widget.color),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                widget.label,
                style: DesignTypography.labelMedium(
                  isDark
                      ? DesignColors.textPrimaryDark
                      : DesignColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

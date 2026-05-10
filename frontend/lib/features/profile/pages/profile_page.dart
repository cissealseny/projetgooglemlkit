import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/design_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/premium_components.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/repository/auth_repository.dart';
import '../../generative/repository/generative_repository.dart';
import '../../nlp/repository/nlp_repository.dart';

/// Premium Profile Page
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const String _cacheKey = 'profile_stats_cache_v1';

  late Future<_ProfileStats> _statsFuture;
  _ProfileStats? _cachedStats;

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

      final stats = _ProfileStats.fromJson(decoded);
      if (!mounted) return;
      setState(() => _cachedStats = stats);
    } catch (_) {
      // Ignore malformed cache.
    }
  }

  Future<_ProfileStats> _loadStats() async {
    int analyses = 0;
    int translations = 0;
    int messages = 0;

    try {
      final profile = await getIt<AuthRepository>().getProfile();
      analyses = profile.apiCallsCount;
    } catch (_) {}

    try {
      final nlpHistory = await getIt<NLPRepository>().getHistory();
      translations = nlpHistory
          .where(
            (item) =>
                item is Map &&
                item['analysis_type']?.toString() == 'translation',
          )
          .length;
    } catch (_) {}

    try {
      final conversations =
          await getIt<GenerativeRepository>().getConversations();
      messages = conversations.fold<int>(0, (sum, item) {
        if (item is Map && item['message_count'] is int) {
          return sum + (item['message_count'] as int);
        }
        return sum;
      });
    } catch (_) {}

    final stats = _ProfileStats(
      analyses: analyses,
      translations: translations,
      messages: messages,
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

  void _refreshStats() {
    setState(() {
      _statsFuture = _loadStats();
    });
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.unauthenticated) {
            context.go('/login');
          }
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220 + topPadding,
              floating: false,
              pinned: true,
              backgroundColor: isDark
                  ? DesignColors.backgroundDark
                  : DesignColors.backgroundLight,
              surfaceTintColor: Colors.transparent,
              actions: [
                IconButton(
                  tooltip: 'Rafraichir les stats',
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _refreshStats,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                      gradient: DesignColors.premiumGradient),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      child: BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: DesignRadius.radiusXl,
                                  boxShadow: DesignColors.shadowMd,
                                ),
                                child: Center(
                                  child: Text(
                                    _getInitials(state.user?.username ?? 'U'),
                                    style: DesignTypography.headlineMedium(
                                        DesignColors.primary),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                state.user?.username ?? 'Utilisateur',
                                style:
                                    DesignTypography.titleLarge(Colors.white),
                              ),
                              if (state.user?.email != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  state.user!.email,
                                  style: DesignTypography.bodySmall(
                                      Colors.white.withValues(alpha: 0.8)),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.only(
                left: DesignSpacing.md,
                right: DesignSpacing.md,
                top: DesignSpacing.lg,
                bottom: DesignSpacing.bottomNavHeight + DesignSpacing.xxl,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Stats Cards
                  FutureBuilder<_ProfileStats>(
                    future: _statsFuture,
                    builder: (context, snapshot) {
                      final stats = snapshot.data ?? _cachedStats;
                      if (snapshot.hasData) {
                        _cachedStats = snapshot.data;
                      }
                      final isLoading =
                          snapshot.connectionState == ConnectionState.waiting &&
                              stats == null;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.remove_red_eye_rounded,
                                  value: isLoading
                                      ? '...'
                                      : '${stats?.analyses ?? 0}',
                                  label: 'Analyses',
                                  color: DesignColors.vision,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.translate_rounded,
                                  value: isLoading
                                      ? '...'
                                      : '${stats?.translations ?? 0}',
                                  label: 'Traductions',
                                  color: DesignColors.nlp,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.chat_rounded,
                                  value: isLoading
                                      ? '...'
                                      : '${stats?.messages ?? 0}',
                                  label: 'Messages',
                                  color: DesignColors.generative,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            stats != null
                                ? 'Mise a jour: ${_formatTime(stats.updatedAt)} (${_relativeTime(stats.updatedAt)})'
                                : 'Mise a jour: --:--',
                            style: DesignTypography.bodySmall(isDark
                                ? DesignColors.textSecondaryDark
                                : DesignColors.textSecondaryLight),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Account Section
                  SectionHeader(title: 'Compte', padding: EdgeInsets.zero),
                  const SizedBox(height: 12),
                  _SettingsTile(
                      icon: Icons.person_rounded,
                      title: 'Modifier le profil',
                      subtitle: 'Nom, photo, bio',
                      onTap: () {}),
                  const SizedBox(height: 8),
                  _SettingsTile(
                      icon: Icons.lock_rounded,
                      title: 'Sécurité',
                      subtitle: 'Mot de passe, 2FA',
                      onTap: () {}),
                  const SizedBox(height: 8),
                  _SettingsTile(
                      icon: Icons.history_rounded,
                      title: 'Historique',
                      subtitle: 'Voir vos activités',
                      onTap: () {}),

                  const SizedBox(height: 24),

                  // App Section
                  SectionHeader(title: 'Application', padding: EdgeInsets.zero),
                  const SizedBox(height: 12),
                  _SettingsTile(
                      icon: Icons.palette_rounded,
                      title: 'Thème',
                      subtitle: isDark ? 'Sombre' : 'Clair',
                      trailing: _ThemeSwitch(),
                      onTap: () {}),
                  const SizedBox(height: 8),
                  _SettingsTile(
                      icon: Icons.language_rounded,
                      title: 'Langue',
                      subtitle: 'Français',
                      onTap: () {}),
                  const SizedBox(height: 8),
                  _SettingsTile(
                      icon: Icons.notifications_rounded,
                      title: 'Notifications',
                      subtitle: 'Gérer les alertes',
                      onTap: () {}),

                  const SizedBox(height: 24),

                  // Support Section
                  SectionHeader(title: 'Support', padding: EdgeInsets.zero),
                  const SizedBox(height: 12),
                  _SettingsTile(
                      icon: Icons.help_rounded,
                      title: 'Aide',
                      subtitle: 'FAQ et guides',
                      onTap: () {}),
                  const SizedBox(height: 8),
                  _SettingsTile(
                      icon: Icons.info_rounded,
                      title: 'À propos',
                      subtitle: 'Version 1.0.0',
                      onTap: () {}),

                  const SizedBox(height: 32),

                  // Logout Button
                  _LogoutButton(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStats {
  final int analyses;
  final int translations;
  final int messages;
  final DateTime updatedAt;

  const _ProfileStats({
    required this.analyses,
    required this.translations,
    required this.messages,
    required this.updatedAt,
  });

  factory _ProfileStats.fromJson(Map<String, dynamic> json) {
    return _ProfileStats(
      analyses: json['analyses'] as int? ?? 0,
      translations: json['translations'] as int? ?? 0,
      messages: json['messages'] as int? ?? 0,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'analyses': analyses,
      'translations': translations,
      'messages': messages,
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatCard(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? DesignColors.surfaceDark : DesignColors.surfaceLight,
        borderRadius: DesignRadius.radiusLg,
        boxShadow: DesignColors.shadowSm,
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: DesignRadius.radiusMd),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: DesignTypography.headlineSmall(isDark
                  ? DesignColors.textPrimaryDark
                  : DesignColors.textPrimaryLight)),
          const SizedBox(height: 2),
          Text(label,
              style: DesignTypography.labelSmall(isDark
                  ? DesignColors.textSecondaryDark
                  : DesignColors.textSecondaryLight)),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  const _SettingsTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      this.trailing,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: PremiumCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (isDark
                        ? DesignColors.textTertiaryDark
                        : DesignColors.textTertiaryLight)
                    .withValues(alpha: 0.1),
                borderRadius: DesignRadius.radiusMd,
              ),
              child: Icon(icon,
                  color: isDark
                      ? DesignColors.textSecondaryDark
                      : DesignColors.textSecondaryLight,
                  size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: DesignTypography.titleSmall(isDark
                            ? DesignColors.textPrimaryDark
                            : DesignColors.textPrimaryLight)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: DesignTypography.bodySmall(isDark
                            ? DesignColors.textSecondaryDark
                            : DesignColors.textSecondaryLight)),
                  ]),
            ),
            if (trailing != null)
              trailing!
            else
              Icon(Icons.chevron_right_rounded,
                  color: isDark
                      ? DesignColors.textTertiaryDark
                      : DesignColors.textTertiaryLight),
          ],
        ),
      ),
    );
  }
}

class _ThemeSwitch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 52,
      height: 28,
      decoration: BoxDecoration(
        gradient: isDark ? DesignColors.premiumGradient : null,
        color: isDark ? null : DesignColors.borderLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: DesignDurations.fast,
            left: isDark ? 26 : 2,
            top: 2,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: DesignColors.shadowSm),
              child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  size: 14,
                  color: DesignColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: DesignRadius.radiusLg),
            title: Text('Déconnexion',
                style: DesignTypography.titleLarge(
                    Theme.of(context).brightness == Brightness.dark
                        ? DesignColors.textPrimaryDark
                        : DesignColors.textPrimaryLight)),
            content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Annuler')),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.read<AuthBloc>().add(LogoutRequested());
                },
                child: Text('Déconnexion',
                    style: TextStyle(color: DesignColors.error)),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: DesignColors.error.withValues(alpha: 0.1),
          borderRadius: DesignRadius.radiusLg,
          border: Border.all(color: DesignColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: DesignColors.error, size: 20),
            const SizedBox(width: 8),
            Text('Se déconnecter',
                style: DesignTypography.titleSmall(DesignColors.error)),
          ],
        ),
      ),
    );
  }
}

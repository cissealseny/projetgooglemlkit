import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/repository/auth_repository.dart';
import '../../generative/repository/generative_repository.dart';
import '../../nlp/repository/nlp_repository.dart';
import '../../vision/repository/vision_repository.dart';

/// Dashboard Home Page with Statistics and Feature Cards
class DashboardHomePage extends StatefulWidget {
  final VoidCallback onNavigateToVision;
  final VoidCallback onNavigateToNLP;
  final VoidCallback onNavigateToGenerative;

  const DashboardHomePage({
    super.key,
    required this.onNavigateToVision,
    required this.onNavigateToNLP,
    required this.onNavigateToGenerative,
  });

  @override
  State<DashboardHomePage> createState() => _DashboardHomePageState();
}

class _DashboardHomePageState extends State<DashboardHomePage> {
  static const String _cacheKeyPrefix = 'dashboard_metrics_cache_v1_';

  late Future<_DashboardMetrics> _metricsFuture;
  _DashboardMetrics? _cachedMetrics;
  int _selectedWindowDays = 7;

  @override
  void initState() {
    super.initState();
    _hydrateMetricsFromCache();
    _metricsFuture = _loadMetrics(days: _selectedWindowDays);
  }

  String get _cacheKey => '$_cacheKeyPrefix$_selectedWindowDays';

  Future<void> _hydrateMetricsFromCache() async {
    try {
      final prefs = getIt<SharedPreferences>();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;

      final metrics = _DashboardMetrics.fromJson(decoded);
      if (!mounted) return;
      setState(() => _cachedMetrics = metrics);
    } catch (_) {
      // Ignore malformed cache.
    }
  }

  Future<_DashboardMetrics> _loadMetrics({required int days}) async {
    int apiCalls = 0;
    int imagesProcessed = 0;
    int textAnalyzed = 0;
    int aiConversations = 0;
    bool requiresLogin = false;

    final today = DateUtils.dateOnly(DateTime.now());
    final dailyCount = <DateTime, int>{};
    for (int i = days - 1; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      dailyCount[day] = 0;
    }

    try {
      final profile = await getIt<AuthRepository>().getProfile();
      apiCalls = profile.apiCallsCount;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        requiresLogin = true;
      }
    } catch (_) {}

    try {
      final visionHistory = await getIt<VisionRepository>().getHistory();
      imagesProcessed = visionHistory.length;
      for (final item in visionHistory) {
        final date = _extractDate(item, const ['created_at', 'createdAt']);
        if (date != null) {
          final day = DateUtils.dateOnly(date);
          if (dailyCount.containsKey(day)) {
            dailyCount[day] = (dailyCount[day] ?? 0) + 1;
          }
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        requiresLogin = true;
      }
    } catch (_) {}

    try {
      final nlpHistory = await getIt<NLPRepository>().getHistory();
      textAnalyzed = nlpHistory.length;
      for (final item in nlpHistory) {
        final date = _extractDate(item, const ['created_at', 'createdAt']);
        if (date != null) {
          final day = DateUtils.dateOnly(date);
          if (dailyCount.containsKey(day)) {
            dailyCount[day] = (dailyCount[day] ?? 0) + 1;
          }
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        requiresLogin = true;
      }
    } catch (_) {}

    try {
      final conversations =
          await getIt<GenerativeRepository>().getConversations();
      aiConversations = conversations.length;
      for (final item in conversations) {
        final date =
            _extractDate(item, const ['updated_at', 'created_at', 'updatedAt']);
        if (date != null) {
          final day = DateUtils.dateOnly(date);
          if (dailyCount.containsKey(day)) {
            dailyCount[day] = (dailyCount[day] ?? 0) + 1;
          }
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        requiresLogin = true;
      }
    } catch (_) {}

    final weekData = dailyCount.entries
        .map((e) => _DailyPoint(day: e.key, count: e.value))
        .toList()
      ..sort((a, b) => a.day.compareTo(b.day));

    final metrics = _DashboardMetrics(
      apiCalls: apiCalls,
      imagesProcessed: imagesProcessed,
      textAnalyzed: textAnalyzed,
      aiConversations: aiConversations,
      weekData: weekData,
      requiresLogin: requiresLogin,
      updatedAt: DateTime.now(),
      windowDays: days,
    );

    _cachedMetrics = metrics;
    try {
      final prefs = getIt<SharedPreferences>();
      await prefs.setString(_cacheKey, jsonEncode(metrics.toJson()));
    } catch (_) {
      // Ignore cache write failure.
    }
    return metrics;
  }

  DateTime? _extractDate(dynamic item, List<String> keys) {
    if (item is! Map) return null;

    for (final key in keys) {
      final raw = item[key];
      if (raw is String) {
        final parsed = DateTime.tryParse(raw);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  void _refresh() {
    setState(() {
      _metricsFuture = _loadMetrics(days: _selectedWindowDays);
    });
  }

  void _setWindowDays(int days) {
    if (_selectedWindowDays == days) return;
    setState(() {
      _selectedWindowDays = days;
      _metricsFuture = _loadMetrics(days: _selectedWindowDays);
    });
    _hydrateMetricsFromCache();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(context),
          const SizedBox(height: 24),
          FutureBuilder<_DashboardMetrics>(
            future: _metricsFuture,
            builder: (context, snapshot) {
              final metrics =
                  snapshot.data ?? _cachedMetrics ?? _DashboardMetrics.empty();
              final isLoading =
                  snapshot.connectionState == ConnectionState.waiting &&
                      snapshot.data == null &&
                      _cachedMetrics == null;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsGrid(
                    context,
                    metrics: metrics,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 24),
                  _buildWeeklyAnalyticsSection(
                    context,
                    metrics: metrics,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mise a jour: ${_formatTime(metrics.updatedAt)} (${_relativeTime(metrics.updatedAt)})',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (metrics.requiresLogin) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Connectez-vous pour voir des statistiques completes.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          _buildFeatureSection(context),
          const SizedBox(height: 32),
          _buildRecentActivitySection(context),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenue sur ML Kit Pro 👋',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Explorez les fonctionnalités de Vision, NLP et IA Générative.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: widget.onNavigateToGenerative,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Commencer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 60,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    BuildContext context, {
    required _DashboardMetrics metrics,
    required bool isLoading,
  }) {
    final stats = [
      _StatItem(
        label: 'Total API Calls',
        value: isLoading ? '...' : '${metrics.apiCalls}',
        change: isLoading ? '...' : 'Live',
        isPositive: true,
        icon: Icons.api_rounded,
        gradient: AppColors.primaryGradient,
      ),
      _StatItem(
        label: 'Images Processed',
        value: isLoading ? '...' : '${metrics.imagesProcessed}',
        change: isLoading ? '...' : 'Live',
        isPositive: true,
        icon: Icons.image_rounded,
        gradient: AppColors.visionGradient,
      ),
      _StatItem(
        label: 'Text Analyzed',
        value: isLoading ? '...' : '${metrics.textAnalyzed}',
        change: isLoading ? '...' : 'Live',
        isPositive: true,
        icon: Icons.text_snippet_rounded,
        gradient: AppColors.nlpGradient,
      ),
      _StatItem(
        label: 'AI Conversations',
        value: isLoading ? '...' : '${metrics.aiConversations}',
        change: isLoading ? '...' : 'Live',
        isPositive: true,
        icon: Icons.chat_rounded,
        gradient: AppColors.generativeGradient,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200
            ? 4
            : constraints.maxWidth > 800
                ? 2
                : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.8,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            return _buildStatCard(context, stats[index]);
          },
        );
      },
    );
  }

  Widget _buildWeeklyAnalyticsSection(
    BuildContext context, {
    required _DashboardMetrics metrics,
    required bool isLoading,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxCount = metrics.weekData.fold<int>(1, (max, e) {
      return e.count > max ? e.count : max;
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Analytics (${_selectedWindowDays} jours)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                tooltip: 'Rafraichir',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _refresh,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ChoiceChip(
                label: const Text('7j'),
                selected: _selectedWindowDays == 7,
                onSelected: (_) => _setWindowDays(7),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('30j'),
                selected: _selectedWindowDays == 30,
                onSelected: (_) => _setWindowDays(30),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const LinearProgressIndicator()
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: metrics.weekData.map((point) {
                final ratio = maxCount == 0 ? 0.0 : point.count / maxCount;
                final barHeight = 12 + (ratio * 72);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${point.count}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _weekdayLabel(point.day.weekday),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Lun';
      case DateTime.tuesday:
        return 'Mar';
      case DateTime.wednesday:
        return 'Mer';
      case DateTime.thursday:
        return 'Jeu';
      case DateTime.friday:
        return 'Ven';
      case DateTime.saturday:
        return 'Sam';
      default:
        return 'Dim';
    }
  }

  Widget _buildStatCard(BuildContext context, _StatItem stat) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: stat.gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  stat.icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: stat.isPositive
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      stat.isPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 14,
                      color:
                          stat.isPositive ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      stat.change,
                      style: TextStyle(
                        color: stat.isPositive
                            ? AppColors.success
                            : AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stat.value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                stat.label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fonctionnalités',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 900
                ? 3
                : constraints.maxWidth > 600
                    ? 2
                    : 1;

            return GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.3,
              ),
              children: [
                _buildFeatureCard(
                  context,
                  title: 'Vision AI',
                  description:
                      'OCR, détection d\'objets, reconnaissance faciale et labélisation d\'images.',
                  icon: Icons.remove_red_eye_rounded,
                  gradient: AppColors.visionGradient,
                  features: [
                    'OCR',
                    'Face Detection',
                    'Object Detection',
                    'Image Labeling'
                  ],
                  onTap: widget.onNavigateToVision,
                ),
                _buildFeatureCard(
                  context,
                  title: 'NLP',
                  description:
                      'Analyse de sentiments, traduction, extraction d\'entités et résumé de texte.',
                  icon: Icons.text_fields_rounded,
                  gradient: AppColors.nlpGradient,
                  features: ['Sentiment', 'Translation', 'Entities', 'Summary'],
                  onTap: widget.onNavigateToNLP,
                ),
                _buildFeatureCard(
                  context,
                  title: 'IA Générative',
                  description:
                      'Chat intelligent, génération de texte et de code avec Ollama et Hugging Face.',
                  icon: Icons.smart_toy_rounded,
                  gradient: AppColors.generativeGradient,
                  features: ['Chat', 'Text Gen', 'Code Gen', 'Embeddings'],
                  onTap: widget.onNavigateToGenerative,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Gradient gradient,
    required List<String> features,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Explorer',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: features.map((feature) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.backgroundDark
                          : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      feature,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activities = [
      _Activity('OCR sur document.pdf', 'Vision AI',
          Icons.remove_red_eye_rounded, AppColors.visionAccent, '2 min'),
      _Activity('Analyse de sentiment', 'NLP', Icons.text_fields_rounded,
          AppColors.nlpAccent, '5 min'),
      _Activity('Chat avec Llama 3.2', 'Generative AI', Icons.smart_toy_rounded,
          AppColors.generativeAccent, '12 min'),
      _Activity('Détection d\'objets', 'Vision AI',
          Icons.remove_red_eye_rounded, AppColors.visionAccent, '1h'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Activité récente',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () {},
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            itemBuilder: (context, index) {
              final activity = activities[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: activity.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    activity.icon,
                    color: activity.color,
                    size: 22,
                  ),
                ),
                title: Text(
                  activity.title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                subtitle: Text(
                  activity.category,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: Text(
                  activity.time,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final String change;
  final bool isPositive;
  final IconData icon;
  final Gradient gradient;

  _StatItem({
    required this.label,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.icon,
    required this.gradient,
  });
}

class _Activity {
  final String title;
  final String category;
  final IconData icon;
  final Color color;
  final String time;

  _Activity(this.title, this.category, this.icon, this.color, this.time);
}

class _DashboardMetrics {
  final int apiCalls;
  final int imagesProcessed;
  final int textAnalyzed;
  final int aiConversations;
  final List<_DailyPoint> weekData;
  final bool requiresLogin;
  final DateTime updatedAt;
  final int windowDays;

  const _DashboardMetrics({
    required this.apiCalls,
    required this.imagesProcessed,
    required this.textAnalyzed,
    required this.aiConversations,
    required this.weekData,
    required this.requiresLogin,
    required this.updatedAt,
    required this.windowDays,
  });

  factory _DashboardMetrics.fromJson(Map<String, dynamic> json) {
    final rawWeek = json['weekData'];
    final week = <_DailyPoint>[];
    if (rawWeek is List) {
      for (final item in rawWeek) {
        if (item is Map<String, dynamic>) {
          week.add(_DailyPoint.fromJson(item));
        } else if (item is Map) {
          week.add(_DailyPoint.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return _DashboardMetrics(
      apiCalls: json['apiCalls'] as int? ?? 0,
      imagesProcessed: json['imagesProcessed'] as int? ?? 0,
      textAnalyzed: json['textAnalyzed'] as int? ?? 0,
      aiConversations: json['aiConversations'] as int? ?? 0,
      weekData: week,
      requiresLogin: json['requiresLogin'] as bool? ?? false,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      windowDays: json['windowDays'] as int? ?? 7,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'apiCalls': apiCalls,
      'imagesProcessed': imagesProcessed,
      'textAnalyzed': textAnalyzed,
      'aiConversations': aiConversations,
      'weekData': weekData.map((e) => e.toJson()).toList(),
      'requiresLogin': requiresLogin,
      'updatedAt': updatedAt.toIso8601String(),
      'windowDays': windowDays,
    };
  }

  factory _DashboardMetrics.empty() {
    final today = DateUtils.dateOnly(DateTime.now());
    final week = <_DailyPoint>[];
    for (int i = 6; i >= 0; i--) {
      week.add(_DailyPoint(day: today.subtract(Duration(days: i)), count: 0));
    }

    return _DashboardMetrics(
      apiCalls: 0,
      imagesProcessed: 0,
      textAnalyzed: 0,
      aiConversations: 0,
      weekData: week,
      requiresLogin: false,
      updatedAt: DateTime.now(),
      windowDays: 7,
    );
  }
}

class _DailyPoint {
  final DateTime day;
  final int count;

  const _DailyPoint({required this.day, required this.count});

  factory _DailyPoint.fromJson(Map<String, dynamic> json) {
    return _DailyPoint(
      day: DateTime.tryParse(json['day']?.toString() ?? '') ?? DateTime.now(),
      count: json['count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day.toIso8601String(),
      'count': count,
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

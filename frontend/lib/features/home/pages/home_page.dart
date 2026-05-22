import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/di/injection.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/design_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/premium_components.dart';

/// Eco-smart landing page
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<_HomeStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<_HomeStats> _loadStats() async {
    final response = await getIt<ApiClient>().getUserStats();
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return _HomeStats.fromJson(data);
    }
    if (data is Map) {
      return _HomeStats.fromJson(Map<String, dynamic>.from(data));
    }
    return _HomeStats.empty();
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                    gradient: DesignColors.ecoSmartGradient,
                    borderRadius: DesignRadius.radiusSm,
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Eco-smart',
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
                icon: const Icon(Icons.quiz_rounded),
                tooltip: 'Quiz',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.go('/ai/quiz');
                },
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
                _HeroEcoCard(
                  isDark: isDark,
                  onTap: () => context.go('/vision'),
                ),
                const SizedBox(height: 20),
                _PrimaryActions(onScan: () => context.go('/vision')),
                const SizedBox(height: 28),
                FutureBuilder<_HomeStats>(
                  future: _statsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const _StatsPlaceholder(height: 92);
                    }
                    if (snapshot.hasError) {
                      return _StatsErrorCard(isDark: isDark);
                    }
                    final stats = snapshot.data ?? _HomeStats.empty();
                    return _EcoStatsStrip(stats: stats);
                  },
                ),
                const SizedBox(height: 28),
                SectionHeader(
                  title: 'Vos Statistiques',
                  subtitle: 'Résumé de votre impact et de vos gains.',
                  padding: EdgeInsets.zero,
                  trailing: TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.go('/eco-impact');
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Détails'),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FutureBuilder<_HomeStats>(
                  future: _statsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const _StatsPlaceholder(height: 220);
                    }
                    if (snapshot.hasError) {
                      return _StatsErrorCard(isDark: isDark);
                    }
                    final stats = snapshot.data ?? _HomeStats.empty();
                    return _UserStatisticsSection(
                      isDark: isDark,
                      stats: stats,
                    );
                  },
                ),
                const SizedBox(height: 28),
                SectionHeader(
                  title: 'Collecte',
                  subtitle: 'Ajoutez une collecte et obtenez une estimation.',
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                _CollecteCtaCard(
                  isDark: isDark,
                  onTap: () => context.go('/collecte'),
                ),
                const SizedBox(height: 28),
                SectionHeader(
                  title: 'Le projet Eco-smart',
                  subtitle:
                      'Un assistant eco-responsable pour trier, estimer et localiser.',
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                _ProjectHighlights(
                  isDark: isDark,
                  onTap: () => context.go('/eco-smart'),
                ),
                const SizedBox(height: 28),
                SectionHeader(
                  title: 'Fonctionnement du systeme',
                  subtitle: 'De la photo au centre de collecte en 3 etapes.',
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                _HowItWorksTimeline(
                  isDark: isDark,
                  onStep1Tap: () => context.go('/vision/realtime'),
                  onStep2Tap: () => context.go('/eco-smart'),
                  onStep3Tap: () => context.go('/centers'),
                ),
                const SizedBox(height: 28),
                SectionHeader(
                  title: 'Types de dechets detectes',
                  subtitle: 'Classification intelligente et locale.',
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                _WasteTypesGrid(
                  onTap: () => context.go('/vision'),
                ),
                const SizedBox(height: 28),
                SectionHeader(
                  title: 'Benefices ecologiques',
                  subtitle: 'Impact positif et engagement citoyen.',
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                _EcoBenefitsGrid(
                  isDark: isDark,
                  onTap: () => context.go('/eco-smart'),
                ),
                const SizedBox(height: 28),
                SectionHeader(
                  title: 'Tester une image',
                  subtitle: 'Lancez une detection maintenant.',
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                _TestImageCallout(onTap: () => context.go('/vision')),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatMonthLabel(String value) {
  final parts = value.split('-');
  if (parts.length != 2) return value;
  final month = int.tryParse(parts[1]) ?? 0;
  const labels = [
    'Jan',
    'Fev',
    'Mar',
    'Avr',
    'Mai',
    'Jun',
    'Jul',
    'Aou',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  if (month < 1 || month > 12) return value;
  return labels[month - 1];
}

class _HomeStats {
  final int apiCallsCount;
  final int scansTotal;
  final List<_MonthlyStat> months;
  final double totalKg;
  final double totalTnd;
  final int totalPoints;

  const _HomeStats({
    required this.apiCallsCount,
    required this.scansTotal,
    required this.months,
    required this.totalKg,
    required this.totalTnd,
    required this.totalPoints,
  });

  factory _HomeStats.empty() => const _HomeStats(
        apiCallsCount: 0,
        scansTotal: 0,
        months: [],
        totalKg: 0,
        totalTnd: 0,
        totalPoints: 0,
      );

  factory _HomeStats.fromJson(Map<String, dynamic> json) {
    final monthsRaw = json['months'] as List? ?? const [];
    final months = monthsRaw
        .whereType<Map>()
        .map((item) => _MonthlyStat.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();

    final totals = json['totals'] is Map
        ? Map<String, dynamic>.from(json['totals'] as Map)
        : <String, dynamic>{};

    return _HomeStats(
      apiCallsCount: _asInt(json['api_calls_count']),
      scansTotal: _asInt(json['scans_total']),
      months: months,
      totalKg: _asDouble(totals['kg']),
      totalTnd: _asDouble(totals['price_tnd']),
      totalPoints: _asInt(totals['points']),
    );
  }
}

class _MonthlyStat {
  final String month;
  final int scans;
  final double kg;

  const _MonthlyStat({
    required this.month,
    required this.scans,
    required this.kg,
  });

  factory _MonthlyStat.fromJson(Map<String, dynamic> json) => _MonthlyStat(
        month: (json['month'] ?? '').toString(),
        scans: _asInt(json['scans']),
        kg: _asDouble(json['kg']),
      );
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

class _StatsPlaceholder extends StatelessWidget {
  final double height;
  const _StatsPlaceholder({required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: PremiumCard(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'Chargement...',
            style: DesignTypography.labelSmall(
              Theme.of(context).brightness == Brightness.dark
                  ? DesignColors.textSecondaryDark
                  : DesignColors.textSecondaryLight,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsErrorCard extends StatelessWidget {
  final bool isDark;
  const _StatsErrorCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Text(
        'Impossible de charger les donnees. Connectez-vous et reessayez.',
        style: DesignTypography.bodySmall(
          isDark ? DesignColors.textSecondaryDark : DesignColors.textSecondaryLight,
        ),
      ),
    );
  }
}

class _CollecteCtaCard extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _CollecteCtaCard({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: DesignColors.ecoSmart.withValues(alpha: 0.15),
              borderRadius: DesignRadius.radiusSm,
            ),
            child: const Icon(
              Icons.assignment_rounded,
              color: DesignColors.ecoSmart,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nouvelle collecte',
                  style: DesignTypography.titleSmall(
                    isDark
                        ? DesignColors.textPrimaryDark
                        : DesignColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enregistrez une collecte et lancez une estimation.',
                  style: DesignTypography.bodySmall(
                    isDark
                        ? DesignColors.textSecondaryDark
                        : DesignColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: const Text('Ouvrir'),
          ),
        ],
      ),
    );
  }
}

// ── User Statistics Section ─────────────────────────────────────────────────
class _UserStatisticsSection extends StatelessWidget {
  final bool isDark;
  final _HomeStats stats;
  const _UserStatisticsSection({required this.isDark, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _ScansBarChart(isDark: isDark, stats: stats)),
            const SizedBox(width: 12),
            Expanded(child: _KgLineChart(isDark: isDark, stats: stats)),
          ],
        ),
        const SizedBox(height: 12),
        _ProgressStatsCard(isDark: isDark, stats: stats),
      ],
    );
  }
}

// ── Bar Chart : Scans par mois ──────────────────────────────────────────────
class _ScansBarChart extends StatelessWidget {
  final bool isDark;
  final _HomeStats stats;
  const _ScansBarChart({required this.isDark, required this.stats});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F5F5);
    final data = stats.months.map((m) => m.scans.toDouble()).toList();
    final months = stats.months.map((m) => _formatMonthLabel(m.month)).toList();

    return Container(
      height: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: DesignRadius.radiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scans / mois',
            style: DesignTypography.labelSmall(
              isDark
                  ? DesignColors.textSecondaryDark
                  : DesignColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RepaintBoundary(
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= months.length) {
                            return const SizedBox();
                          }
                          return Text(
                            months[idx],
                            style: TextStyle(
                              fontSize: 9,
                              color: isDark
                                  ? DesignColors.textSecondaryDark
                                  : DesignColors.textSecondaryLight,
                            ),
                          );
                        },
                        reservedSize: 20,
                      ),
                    ),
                  ),
                  barGroups: List.generate(data.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: data[i],
                          color: DesignColors.ecoSmart,
                          width: 14,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Line Chart : Kg recyclés sur 6 mois ────────────────────────────────────
class _KgLineChart extends StatelessWidget {
  final bool isDark;
  final _HomeStats stats;
  const _KgLineChart({required this.isDark, required this.stats});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F5F5);
    final spots = stats.months
        .asMap()
        .entries
        .map((entry) => FlSpot(
              entry.key.toDouble(),
              entry.value.kg,
            ))
        .toList();

    return Container(
      height: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: DesignRadius.radiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kg recyclés',
            style: DesignTypography.labelSmall(
              isDark
                  ? DesignColors.textSecondaryDark
                  : DesignColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RepaintBoundary(
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(
                    leftTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: const Color(0xFF5DB075),
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF5DB075).withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Progress Bars ───────────────────────────────────────────────────────────
class _ProgressStatsCard extends StatelessWidget {
  final bool isDark;
  final _HomeStats stats;
  const _ProgressStatsCard({required this.isDark, required this.stats});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F5F5);

    const pointsTarget = 2000.0;
    const tndTarget = 100.0;
    const kgTarget = 50.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: DesignRadius.radiusMd,
      ),
      child: Column(
        children: [
          _ProgressRow(
            label: 'Points gagnés',
            value: stats.totalPoints.toDouble(),
            max: pointsTarget,
            color: DesignColors.accent,
            display: '${stats.totalPoints} / ${pointsTarget.toInt()}',
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _ProgressRow(
            label: 'Gains TND',
            value: stats.totalTnd,
            max: tndTarget,
            color: const Color(0xFFE9A840),
            display: '${stats.totalTnd.toStringAsFixed(2)} TND',
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _ProgressRow(
            label: 'Kg recyclés',
            value: stats.totalKg,
            max: kgTarget,
            color: const Color(0xFF5DB075),
            display: '${stats.totalKg.toStringAsFixed(1)} / ${kgTarget.toInt()} kg',
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final Color color;
  final String display;
  final bool isDark;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    required this.display,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (value / max).clamp(0.0, 1.0);
    final textColor = isDark
        ? DesignColors.textSecondaryDark
        : DesignColors.textSecondaryLight;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: DesignTypography.caption(textColor)),
            Text(display, style: DesignTypography.labelSmall(color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// ── Hero Card ───────────────────────────────────────────────────────────────
class _HeroEcoCard extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onTap;
  const _HeroEcoCard({required this.isDark, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap!();
              },
        borderRadius: DesignRadius.radiusXl,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0C4B4A), Color(0xFF2E8B57)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: DesignRadius.radiusXl,
            boxShadow: DesignColors.shadowLg,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: DesignRadius.radiusFull,
                          ),
                          child: Text(
                            'Eco-smart',
                            style: DesignTypography.labelSmall(Colors.white),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.bolt_rounded,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Recyclez malin, en temps reel',
                      style: DesignTypography.displaySmall(Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Photo + IA locale + geolocalisation pour estimer la valeur et le centre proche.',
                      style: DesignTypography.bodyMedium(
                        Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _HeroChip(label: 'Vision ML Kit'),
                        _HeroChip(label: 'Chat eco'),
                        _HeroChip(label: 'TND reel'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 120,
                height: 120,
                child: SvgPicture.asset(
                  'assets/images/ia_image_placeholder.svg',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final String label;
  const _HeroChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: DesignRadius.radiusFull,
      ),
      child: Text(
        label,
        style: DesignTypography.labelSmall(Colors.white),
      ),
    );
  }
}

// ── Primary Actions ─────────────────────────────────────────────────────────
class _PrimaryActions extends StatelessWidget {
  final VoidCallback onScan;
  const _PrimaryActions({required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              onScan();
            },
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('Tester une image'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              context.go('/ai');
            },
            icon: const Icon(Icons.chat_bubble_rounded),
            label: const Text('Assistant'),
          ),
        ),
      ],
    );
  }
}

// ── Eco Stats Strip ─────────────────────────────────────────────────────────
class _EcoStatsStrip extends StatelessWidget {
  final _HomeStats stats;
  const _EcoStatsStrip({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Kg recycles',
            value: '${stats.totalKg.toStringAsFixed(1)} kg',
            icon: Icons.recycling_rounded,
            color: DesignColors.ecoSmart,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            label: 'Gains TND',
            value: '${stats.totalTnd.toStringAsFixed(2)}',
            icon: Icons.payments_rounded,
            color: const Color(0xFFE9A840),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            label: 'Points',
            value: stats.totalPoints.toString(),
            icon: Icons.stars_rounded,
            color: DesignColors.accent,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: DesignRadius.radiusSm,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: DesignTypography.caption(
                    Theme.of(context).brightness == Brightness.dark
                        ? DesignColors.textSecondaryDark
                        : DesignColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: DesignTypography.titleMedium(color)),
        ],
      ),
    );
  }
}

// ── Project Highlights ──────────────────────────────────────────────────────
class _ProjectHighlights extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onTap;
  const _ProjectHighlights({required this.isDark, this.onTap});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap!();
              },
        borderRadius: DesignRadius.radiusMd,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'IA Image + Donnees locales',
                      style: DesignTypography.titleMedium(
                        isDark
                            ? DesignColors.textPrimaryDark
                            : DesignColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Detection des dechets, prix reel en TND, et centre de collecte le plus proche.',
                      style: DesignTypography.bodySmall(
                        isDark
                            ? DesignColors.textSecondaryDark
                            : DesignColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 92,
                height: 92,
                child: SvgPicture.asset(
                  'assets/images/waste_hero_placeholder.svg',
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── How It Works Timeline ───────────────────────────────────────────────────
class _HowItWorksTimeline extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onStep1Tap;
  final VoidCallback? onStep2Tap;
  final VoidCallback? onStep3Tap;

  const _HowItWorksTimeline({
    required this.isDark,
    this.onStep1Tap,
    this.onStep2Tap,
    this.onStep3Tap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StepTile(
          step: '1',
          title: 'Prendre une photo',
          subtitle: 'ML Kit detecte le type de dechet et le code-barres.',
          icon: Icons.camera_alt_rounded,
          onTap: onStep1Tap,
        ),
        const SizedBox(height: 10),
        _StepTile(
          step: '2',
          title: 'Analyse IA locale',
          subtitle: 'Classification + estimation du prix en TND.',
          icon: Icons.auto_awesome_rounded,
          onTap: onStep2Tap,
        ),
        const SizedBox(height: 10),
        _StepTile(
          step: '3',
          title: 'Centre proche',
          subtitle: 'Geolocalisation et recommandations de tri.',
          icon: Icons.place_rounded,
          onTap: onStep3Tap,
        ),
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  final String step;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const _StepTile({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PremiumCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap!();
              },
        borderRadius: DesignRadius.radiusMd,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: DesignColors.ecoSmart.withValues(alpha: 0.15),
                  borderRadius: DesignRadius.radiusSm,
                ),
                child: Center(
                  child: Text(
                    step,
                    style: DesignTypography.titleSmall(DesignColors.ecoSmart),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: DesignTypography.titleSmall(
                        isDark
                            ? DesignColors.textPrimaryDark
                            : DesignColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: DesignTypography.bodySmall(
                        isDark
                            ? DesignColors.textSecondaryDark
                            : DesignColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(icon, color: DesignColors.ecoSmart),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Waste Types Grid ────────────────────────────────────────────────────────
class _WasteTypesGrid extends StatelessWidget {
  final VoidCallback? onTap;
  const _WasteTypesGrid({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _WasteChip(
          label: 'Plastique',
          icon: Icons.local_drink_rounded,
          onTap: onTap,
        ),
        _WasteChip(
          label: 'Verre',
          icon: Icons.wine_bar_rounded,
          onTap: onTap,
        ),
        _WasteChip(
          label: 'Metal',
          icon: Icons.construction_rounded,
          onTap: onTap,
        ),
        _WasteChip(
          label: 'Papier',
          icon: Icons.description_rounded,
          onTap: onTap,
        ),
        _WasteChip(
          label: 'Organique',
          icon: Icons.eco_rounded,
          onTap: onTap,
        ),
        _WasteChip(
          label: 'Electronique',
          icon: Icons.memory_rounded,
          onTap: onTap,
        ),
      ],
    );
  }
}

class _WasteChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  const _WasteChip({required this.label, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap!();
              },
        borderRadius: DesignRadius.radiusFull,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: DesignColors.ecoSmart.withValues(alpha: 0.12),
            borderRadius: DesignRadius.radiusFull,
            border:
                Border.all(color: DesignColors.ecoSmart.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: DesignColors.ecoSmart),
              const SizedBox(width: 8),
              Text(label,
                  style: DesignTypography.labelMedium(DesignColors.ecoSmart)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Eco Benefits Grid ───────────────────────────────────────────────────────
class _EcoBenefitsGrid extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onTap;
  const _EcoBenefitsGrid({required this.isDark, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BenefitTile(
          icon: Icons.insights_rounded,
          title: 'Decision rapide',
          subtitle: 'Estimation immediate de la valeur.',
          onTap: onTap,
        ),
        const SizedBox(height: 10),
        _BenefitTile(
          icon: Icons.public_rounded,
          title: 'Impact local',
          subtitle: 'Centres proches et donnees tunisiennes.',
          onTap: onTap,
        ),
        const SizedBox(height: 10),
        _BenefitTile(
          icon: Icons.savings_rounded,
          title: 'Gain economique',
          subtitle: 'Revente en TND avec prix reels.',
          onTap: onTap,
        ),
      ],
    );
  }
}

class _BenefitTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _BenefitTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PremiumCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap!();
              },
        borderRadius: DesignRadius.radiusMd,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: DesignColors.ecoSmart.withValues(alpha: 0.15),
                  borderRadius: DesignRadius.radiusSm,
                ),
                child: Icon(icon, color: DesignColors.ecoSmart),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: DesignTypography.titleSmall(
                        isDark
                            ? DesignColors.textPrimaryDark
                            : DesignColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: DesignTypography.bodySmall(
                        isDark
                            ? DesignColors.textSecondaryDark
                            : DesignColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Test Image Callout ──────────────────────────────────────────────────────
class _TestImageCallout extends StatelessWidget {
  final VoidCallback onTap;
  const _TestImageCallout({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: DesignColors.ecoSmartGradient,
              borderRadius: DesignRadius.radiusMd,
            ),
            child: const Icon(Icons.camera_alt_rounded, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tester une image maintenant',
                  style: DesignTypography.titleMedium(
                    Theme.of(context).brightness == Brightness.dark
                        ? DesignColors.textPrimaryDark
                        : DesignColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ouvrez la camera et laissez l IA detecter votre dechet.',
                  style: DesignTypography.bodySmall(
                    Theme.of(context).brightness == Brightness.dark
                        ? DesignColors.textSecondaryDark
                        : DesignColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/di/injection.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/design_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/premium_components.dart';

class EcoImpactPage extends StatefulWidget {
  const EcoImpactPage({super.key});

  @override
  State<EcoImpactPage> createState() => _EcoImpactPageState();
}

class _EcoImpactPageState extends State<EcoImpactPage> {
  late Future<Map<String, dynamic>> _statsFuture;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadEcoStats();
  }

  Future<Map<String, dynamic>> _loadEcoStats() async {
    final response = await getIt<ApiClient>().getUserStats();
    if (response.data is Map) {
      return Map<String, dynamic>.from(response.data);
    }
    throw Exception('Données invalides.');
  }

  Color _getWasteColor(String type) {
    switch (type.toLowerCase()) {
      case 'plastique':
        return const Color(0xFF2D9CDB); // Blue
      case 'verre':
        return const Color(0xFF27AE60); // Green
      case 'papier':
        return const Color(0xFFF2C94C); // Yellow
      case 'carton':
        return const Color(0xFFF2994A); // Orange
      case 'métal':
        return const Color(0xFFEB5757); // Red
      default:
        return const Color(0xFF9B51E0); // Purple / Autre
    }
  }

  IconData _getWasteIcon(String type) {
    switch (type.toLowerCase()) {
      case 'plastique':
        return Icons.local_drink_rounded;
      case 'verre':
        return Icons.hourglass_empty_rounded;
      case 'papier':
        return Icons.description_rounded;
      case 'carton':
        return Icons.inventory_2_rounded;
      case 'métal':
        return Icons.build_rounded;
      default:
        return Icons.eco_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? DesignColors.textPrimaryDark : DesignColors.textPrimaryLight;
    final subColor = isDark ? DesignColors.textSecondaryDark : DesignColors.textSecondaryLight;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              HapticFeedback.lightImpact();
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
          title: Text(
            'Eco-Impact',
            style: DesignTypography.headlineSmall(textColor),
          ),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Mon Impact', icon: Icon(Icons.analytics_rounded)),
              Tab(text: 'Classement & Trophées', icon: Icon(Icons.emoji_events_rounded)),
            ],
            indicatorColor: DesignColors.ecoSmart,
            labelColor: DesignColors.ecoSmart,
            unselectedLabelColor: subColor,
          ),
          backgroundColor: isDark ? DesignColors.backgroundDark : DesignColors.backgroundLight,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _statsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingIndicator(message: 'Chargement de votre impact...');
            }
            if (snapshot.hasError) {
              return EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Erreur',
                description: 'Impossible de charger vos statistiques d\'impact.',
                action: FilledButton(
                  onPressed: () {
                    setState(() {
                      _statsFuture = _loadEcoStats();
                    });
                  },
                  child: const Text('Réessayer'),
                ),
              );
            }
  
            final data = snapshot.data ?? {};
            final totals = data['totals'] is Map ? Map<String, dynamic>.from(data['totals']) : {};
            final wasteDist = data['waste_distribution'] is Map
                ? Map<String, dynamic>.from(data['waste_distribution'])
                : <String, dynamic>{};
            final history = data['history'] is List ? List<dynamic>.from(data['history']) : [];
  
            final totalKg = _asDouble(totals['kg']);
            final totalPoints = _asInt(totals['points']);
            final totalTnd = _asDouble(totals['price_tnd']);
            final totalEvents = _asInt(totals['count']);
  
            // Setup waste distribution points
            final List<MapEntry<String, double>> activeCategories = [];
            wasteDist.forEach((key, value) {
              final kg = _asDouble(value);
              if (kg > 0) {
                activeCategories.add(MapEntry(key, kg));
              }
            });
  
            final List<PieChartSectionData> chartSections = [];
            for (int i = 0; i < activeCategories.length; i++) {
              final key = activeCategories[i].key;
              final kg = activeCategories[i].value;
              final isTouched = i == _touchedIndex;
              final radius = isTouched ? 58.0 : 50.0;
              final fontSize = isTouched ? 15.0 : 12.0;
  
              chartSections.add(
                PieChartSectionData(
                  color: _getWasteColor(key),
                  value: kg,
                  title: '${((kg / (totalKg > 0 ? totalKg : 1)) * 100).round()}%',
                  radius: radius,
                  titleStyle: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              );
            }
  
            final activeEntry = (_touchedIndex >= 0 && _touchedIndex < activeCategories.length)
                ? activeCategories[_touchedIndex]
                : null;
            final activeWasteKey = activeEntry?.key ?? '';
            final activeWasteKg = activeEntry?.value ?? 0.0;
  
            // Calculate environmental savings
            double co2Saved = 0.0;
            double waterSaved = 0.0;
            double petroleumSaved = 0.0;
            double energySaved = 0.0;
  
            wasteDist.forEach((key, value) {
              final kg = _asDouble(value);
              switch (key.toLowerCase()) {
                case 'plastique':
                  co2Saved += kg * 1.5;
                  petroleumSaved += kg * 2.0;
                  energySaved += kg * 5.7;
                  break;
                case 'verre':
                  co2Saved += kg * 0.3;
                  energySaved += kg * 1.2;
                  break;
                case 'papier':
                case 'carton':
                  co2Saved += kg * 0.9;
                  waterSaved += kg * 20.0;
                  energySaved += kg * 4.0;
                  break;
                case 'métal':
                  co2Saved += kg * 4.5;
                  energySaved += kg * 14.0;
                  break;
                default:
                  co2Saved += kg * 0.5;
                  break;
              }
            });
  
            return TabBarView(
              children: [
                RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _statsFuture = _loadEcoStats();
                    });
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignSpacing.md,
                      vertical: DesignSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // KPI Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      StatCard(
                        value: '${totalKg.toStringAsFixed(1)} kg',
                        label: 'Total recyclé',
                        icon: Icons.eco_rounded,
                        accentColor: DesignColors.ecoSmart,
                      ),
                      StatCard(
                        value: '$totalPoints',
                        label: 'Points accumulés',
                        icon: Icons.stars_rounded,
                        accentColor: Colors.amber,
                      ),
                      StatCard(
                        value: '${totalTnd.toStringAsFixed(2)} TND',
                        label: 'Gains totaux',
                        icon: Icons.payments_rounded,
                        accentColor: const Color(0xFFE9A840),
                      ),
                      StatCard(
                        value: '$totalEvents',
                        label: 'Collectes enregistrées',
                        icon: Icons.assignment_turned_in_rounded,
                        accentColor: DesignColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Environmental Savings Section
                  SectionHeader(
                    title: 'Bilan Écologique Épargné',
                    subtitle: 'Ressources préservées grâce à vos tris.',
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  PremiumCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _SavingsRow(
                          icon: Icons.cloud_done_rounded,
                          iconColor: const Color(0xFF56CCF2),
                          label: 'Émissions de CO₂ évitées',
                          value: '${co2Saved.toStringAsFixed(1)} kg',
                          description: 'L\'équivalent de ${((co2Saved * 5.0)).toStringAsFixed(1)} km en voiture.',
                          isDark: isDark,
                        ),
                        const Divider(height: 20),
                        _SavingsRow(
                          icon: Icons.water_drop_rounded,
                          iconColor: const Color(0xFF2D9CDB),
                          label: 'Eau douce préservée',
                          value: '${waterSaved.toStringAsFixed(0)} L',
                          description: 'Soit environ ${(waterSaved / 150.0).toStringAsFixed(1)} baignoires.',
                          isDark: isDark,
                        ),
                        const Divider(height: 20),
                        _SavingsRow(
                          icon: Icons.local_fire_department_rounded,
                          iconColor: const Color(0xFFF2994A),
                          label: 'Pétrole économisé',
                          value: '${petroleumSaved.toStringAsFixed(1)} L',
                          description: 'Évite la fabrication de nouveaux plastiques.',
                          isDark: isDark,
                        ),
                        const Divider(height: 20),
                        _SavingsRow(
                          icon: Icons.bolt_rounded,
                          iconColor: const Color(0xFFF2C94C),
                          label: 'Énergie électrique sauvée',
                          value: '${energySaved.toStringAsFixed(1)} kWh',
                          description: 'Assez pour un téléviseur pendant ${(energySaved * 10).toStringAsFixed(0)} h.',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Chart Section
                  SectionHeader(
                    title: 'Répartition des Déchets',
                    subtitle: 'Part par type de déchet en kilogrammes.',
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  PremiumCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        if (chartSections.isEmpty)
                          SizedBox(
                            height: 160,
                            child: Center(
                              child: Text(
                                'Aucune donnée de tri pour le moment.',
                                style: DesignTypography.bodyMedium(subColor),
                              ),
                            ),
                          )
                        else ...[
                          Row(
                            children: [
                              SizedBox(
                                width: 140,
                                height: 140,
                                child: PieChart(
                                  PieChartData(
                                    pieTouchData: PieTouchData(
                                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                        setState(() {
                                          if (!event.isInterestedForInteractions ||
                                              pieTouchResponse == null ||
                                              pieTouchResponse.touchedSection == null) {
                                            _touchedIndex = -1;
                                            return;
                                          }
                                          _touchedIndex = pieTouchResponse
                                              .touchedSection!.touchedSectionIndex;
                                        });
                                      },
                                    ),
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 30,
                                    sections: chartSections,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: wasteDist.entries.map((entry) {
                                    final kg = _asDouble(entry.value);
                                    if (kg == 0) return const SizedBox();
                                    final isTouched = entry.key.toLowerCase() == activeWasteKey.toLowerCase();
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: _getWasteColor(entry.key),
                                              shape: BoxShape.circle,
                                              border: isTouched
                                                  ? Border.all(color: textColor, width: 1.5)
                                                  : null,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              entry.key,
                                              style: DesignTypography.labelSmall(textColor).copyWith(
                                                fontWeight: isTouched ? FontWeight.bold : FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${kg.toStringAsFixed(1)} kg',
                                            style: DesignTypography.bodySmall(
                                              isTouched ? textColor : subColor,
                                            ).copyWith(
                                              fontWeight: isTouched ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                          if (_touchedIndex != -1 && activeWasteKey.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: _getWasteColor(activeWasteKey).withValues(alpha: 0.12),
                                borderRadius: DesignRadius.radiusMd,
                                border: Border.all(
                                  color: _getWasteColor(activeWasteKey).withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _getWasteIcon(activeWasteKey),
                                    color: _getWasteColor(activeWasteKey),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          activeWasteKey,
                                          style: DesignTypography.titleSmall(textColor).copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Part du total : ${((activeWasteKg / (totalKg > 0 ? totalKg : 1)) * 100).toStringAsFixed(1)}%',
                                          style: DesignTypography.bodySmall(subColor),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${activeWasteKg.toStringAsFixed(1)} kg',
                                    style: DesignTypography.titleMedium(textColor).copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: _getWasteColor(activeWasteKey),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // History Section
                  SectionHeader(
                    title: 'Historique des Activités',
                    subtitle: 'Vos 20 dernières transactions de recyclage.',
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  if (history.isEmpty)
                    PremiumCard(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.history_toggle_off_rounded,
                              size: 48,
                              color: subColor,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Aucune collecte enregistrée.',
                              style: DesignTypography.titleSmall(textColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Vos collectes apparaîtront ici.',
                              style: DesignTypography.bodySmall(subColor),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: history.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final event = Map<String, dynamic>.from(history[index]);
                        final wType = (event['waste_type'] ?? 'Autre').toString();
                        final comp = (event['company_name'] ?? '').toString();
                        final weight = _asDouble(event['weight_kg']);
                        final price = _asDouble(event['price_tnd']);
                        final pts = _asInt(event['points']);
                        final dateStr = (event['created_at'] ?? '').toString();
                        
                        String formattedDate = '';
                        try {
                          final dt = DateTime.parse(dateStr).toLocal();
                          formattedDate = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
                        } catch (_) {
                          formattedDate = dateStr;
                        }

                        return PremiumCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _getWasteColor(wType).withValues(alpha: 0.15),
                                  borderRadius: DesignRadius.radiusSm,
                                ),
                                child: Icon(
                                  _getWasteIcon(wType),
                                  color: _getWasteColor(wType),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      comp.isNotEmpty ? comp : 'Collecte',
                                      style: DesignTypography.titleSmall(textColor),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$wType • $formattedDate',
                                      style: DesignTypography.caption(subColor),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${weight.toStringAsFixed(1)} kg',
                                    style: DesignTypography.labelSmall(textColor),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '+$pts pts • ${price.toStringAsFixed(2)} TND',
                                    style: DesignTypography.caption(DesignColors.ecoSmart),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                      ],
                    ),
                  ),
                ),
                _buildLeaderboardAndTrophiesTab(
                  context,
                  totalPoints,
                  totalKg,
                  co2Saved,
                  waterSaved,
                  isDark,
                  textColor,
                  subColor,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLeaderboardAndTrophiesTab(
      BuildContext context,
      int totalPoints,
      double totalKg,
      double co2Saved,
      double waterSaved,
      bool isDark,
      Color textColor,
      Color subColor) {
    final mockUsers = [
      _LeaderboardUser(name: 'Yousra Belhadj', points: 1500, city: 'Tunis', isMe: false),
      _LeaderboardUser(name: 'Khalil Ayed', points: 1100, city: 'Sousse', isMe: false),
      _LeaderboardUser(name: 'Amina Gharbi', points: 850, city: 'Sfax', isMe: false),
      _LeaderboardUser(name: 'Slim Oueslati', points: 420, city: 'Bizerte', isMe: false),
      _LeaderboardUser(name: 'Meriam Khelifi', points: 280, city: 'Ariana', isMe: false),
    ];

    final me = _LeaderboardUser(
        name: 'Vous (Moi)', points: totalPoints, city: 'Tunis', isMe: true);
    
    final allUsers = [...mockUsers, me]..sort((a, b) => b.points.compareTo(a.points));
    final myRank = allUsers.indexWhere((u) => u.isMe) + 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignSpacing.md,
        vertical: DesignSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SectionHeader(
                  title: 'Classement Éco-Citoyens',
                  subtitle: 'Les meilleurs recycleurs de Tunisie.',
                  padding: EdgeInsets.zero,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: DesignColors.ecoSmart.withValues(alpha: 0.12),
                  borderRadius: DesignRadius.radiusSm,
                ),
                child: Text(
                  'Mon Rang : #$myRank',
                  style: DesignTypography.labelSmall(DesignColors.ecoSmart).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PremiumCard(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allUsers.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final user = allUsers[index];
                final rank = index + 1;
                
                Color? rankColor;
                if (rank == 1) rankColor = Colors.amber;
                if (rank == 2) rankColor = const Color(0xFFC0C0C0);
                if (rank == 3) rankColor = const Color(0xFFCD7F32);

                return Container(
                  color: user.isMe
                      ? DesignColors.ecoSmart.withValues(alpha: 0.08)
                      : Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: rank <= 3
                            ? Icon(Icons.emoji_events_rounded, color: rankColor, size: 20)
                            : Text(
                                '$rank',
                                style: DesignTypography.titleSmall(subColor),
                              ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: user.isMe
                            ? DesignColors.ecoSmart
                            : (isDark ? DesignColors.backgroundDark : DesignColors.backgroundLight),
                        child: Text(
                          user.name[0],
                          style: TextStyle(
                            color: user.isMe ? Colors.white : textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: DesignTypography.titleSmall(textColor).copyWith(
                                fontWeight: user.isMe ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                            Text(
                              user.city,
                              style: DesignTypography.caption(subColor),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${user.points} pts',
                        style: DesignTypography.titleSmall(textColor).copyWith(
                          fontWeight: FontWeight.bold,
                          color: user.isMe ? DesignColors.ecoSmart : null,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 28),
          SectionHeader(
            title: 'Trophées Écologiques',
            subtitle: 'Défis à accomplir pour devenir un héros vert.',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
          _TrophyItem(
            title: '🌱 Graine d\'Écolo',
            description: 'Enregistrez votre première collecte.',
            progressValue: totalKg > 0 ? 1.0 : 0.0,
            progressText: totalKg > 0 ? 'Débloqué !' : '0/1 collecte',
            isUnlocked: totalKg > 0,
            iconColor: const Color(0xFF27AE60),
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _TrophyItem(
            title: '💧 Gardien des Rivières',
            description: 'Épargnez 100 L d\'eau douce grâce au carton/papier.',
            progressValue: (waterSaved / 100.0).clamp(0.0, 1.0),
            progressText: '${waterSaved.toStringAsFixed(0)} / 100 L',
            isUnlocked: waterSaved >= 100.0,
            iconColor: const Color(0xFF2D9CDB),
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _TrophyItem(
            title: '🚗 Protecteur du Climat',
            description: 'Évitez 20 kg d\'émissions de CO₂.',
            progressValue: (co2Saved / 20.0).clamp(0.0, 1.0),
            progressText: '${co2Saved.toStringAsFixed(1)} / 20 kg',
            isUnlocked: co2Saved >= 20.0,
            iconColor: const Color(0xFF56CCF2),
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _TrophyItem(
            title: '👑 Champion de la Valorisation',
            description: 'Recyclez un total cumulé de 50 kg de déchets.',
            progressValue: (totalKg / 50.0).clamp(0.0, 1.0),
            progressText: '${totalKg.toStringAsFixed(1)} / 50 kg',
            isUnlocked: totalKg >= 50.0,
            iconColor: const Color(0xFFF2994A),
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _TrophyItem(
            title: '🧠 Érudit Vert',
            description: 'Gagnez au moins 100 points au total.',
            progressValue: (totalPoints / 100.0).clamp(0.0, 1.0),
            progressText: '$totalPoints / 100 pts',
            isUnlocked: totalPoints >= 100,
            iconColor: Colors.amber,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class _SavingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String description;
  final bool isDark;

  const _SavingsRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.description,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? DesignColors.textPrimaryDark : DesignColors.textPrimaryLight;
    final subColor = isDark ? DesignColors.textSecondaryDark : DesignColors.textSecondaryLight;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: DesignTypography.labelSmall(textColor).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: DesignTypography.bodySmall(subColor),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: DesignTypography.titleMedium(textColor).copyWith(
            fontWeight: FontWeight.bold,
            color: iconColor,
          ),
        ),
      ],
    );
  }
}

class _LeaderboardUser {
  final String name;
  final int points;
  final String city;
  final bool isMe;

  _LeaderboardUser({
    required this.name,
    required this.points,
    required this.city,
    required this.isMe,
  });
}

class _TrophyItem extends StatelessWidget {
  final String title;
  final String description;
  final double progressValue;
  final String progressText;
  final bool isUnlocked;
  final Color iconColor;
  final bool isDark;

  const _TrophyItem({
    required this.title,
    required this.description,
    required this.progressValue,
    required this.progressText,
    required this.isUnlocked,
    required this.iconColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? DesignColors.textPrimaryDark : DesignColors.textPrimaryLight;
    final subColor = isDark ? DesignColors.textSecondaryDark : DesignColors.textSecondaryLight;

    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? iconColor.withValues(alpha: 0.12)
                  : (isDark ? DesignColors.backgroundDark : DesignColors.backgroundLight),
              borderRadius: DesignRadius.radiusMd,
              border: Border.all(
                color: isUnlocked
                    ? iconColor.withValues(alpha: 0.3)
                    : (isDark ? DesignColors.borderDark : DesignColors.borderLight).withValues(alpha: 0.5),
              ),
            ),
            child: Icon(
              isUnlocked ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
              color: isUnlocked ? iconColor : subColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: DesignTypography.titleSmall(textColor).copyWith(
                          fontWeight: FontWeight.bold,
                          color: isUnlocked ? null : subColor,
                        ),
                      ),
                    ),
                    Text(
                      progressText,
                      style: DesignTypography.caption(
                        isUnlocked ? DesignColors.ecoSmart : subColor,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: DesignTypography.bodySmall(subColor),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: isDark
                        ? DesignColors.backgroundDark
                        : DesignColors.backgroundLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isUnlocked ? iconColor : subColor.withValues(alpha: 0.5),
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

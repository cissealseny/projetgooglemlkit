import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/injection.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/design_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/premium_components.dart';

class CentersPage extends StatefulWidget {
  const CentersPage({super.key});

  @override
  State<CentersPage> createState() => _CentersPageState();
}

class _CentersPageState extends State<CentersPage> {
  late Future<List<_CenterLocation>> _centersFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCityFilter;

  @override
  void initState() {
    super.initState();
    _centersFuture = _loadCenters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _launchNavigation(double lat, double lon) async {
    final googleMapsUrl = Uri.parse('google.navigation:q=$lat,$lon');
    final appleMapsUrl = Uri.parse('maps://?q=$lat,$lon');
    final webUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl);
      } else if (await canLaunchUrl(appleMapsUrl)) {
        await launchUrl(appleMapsUrl);
      } else {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _launchCaller(String phone) async {
    final cleanPhone = phone.replaceAll(' ', '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  Future<List<_CenterLocation>> _loadCenters() async {
    final response = await getIt<ApiClient>().getEcoCenters();
    final data = response.data;
    if (data is Map && data['centers'] is List) {
      final raw = data['centers'] as List;
      final centers = raw
          .whereType<Map>()
          .map((item) => _CenterLocation.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();

      final byKey = <String, _CenterLocation>{};
      for (final center in centers) {
        final key = '${center.name}::${center.city}::${center.zone}';
        byKey[key] = center;
      }
      return byKey.values.toList();
    }
    return const [];
  }

  void _showCenterDetails(_CenterLocation center) {
    final acceptedMaterials = <String>[];
    if (center.avgPriceTnd > 1.5) {
      acceptedMaterials.addAll(['Métal', 'Plastique', 'Carton']);
    } else if (center.avgPriceTnd > 0.8) {
      acceptedMaterials.addAll(['Plastique', 'Papier', 'Verre']);
    } else {
      acceptedMaterials.addAll(['Verre', 'Papier']);
    }

    final phoneHash = (center.name.hashCode % 900000) + 100000;
    final phoneNumber = '+216 71 $phoneHash';
    const openingHours = '08h00 - 18h00 • Lun - Sam';

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor =
            isDark ? DesignColors.textSecondaryDark : DesignColors.textSecondaryLight;
        final primaryText = isDark ? DesignColors.textPrimaryDark : DesignColors.textPrimaryLight;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            center.name,
                            style: DesignTypography.titleLarge(primaryText).copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${center.city} • ${center.zone}',
                            style: DesignTypography.bodySmall(textColor),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Ouvert',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 16, color: textColor),
                    const SizedBox(width: 8),
                    Text(
                      openingHours,
                      style: DesignTypography.bodySmall(textColor),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone_rounded, size: 16, color: textColor),
                    const SizedBox(width: 8),
                    Text(
                      phoneNumber,
                      style: DesignTypography.bodySmall(textColor),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Déchets acceptés',
                  style: DesignTypography.labelSmall(primaryText).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: acceptedMaterials.map((material) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: DesignColors.ecoSmart.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: DesignColors.ecoSmart.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        material,
                        style: const TextStyle(
                          color: DesignColors.ecoSmart,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                _DetailRow(
                  label: 'Prix moyen',
                  value: '${center.avgPriceTnd.toStringAsFixed(2)} TND / kg',
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _DetailRow(
                  label: 'Latitude',
                  value: center.latitude.toStringAsFixed(5),
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _DetailRow(
                  label: 'Longitude',
                  value: center.longitude.toStringAsFixed(5),
                  isDark: isDark,
                ),
                const Divider(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: isDark ? Colors.white24 : Colors.black12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: DesignRadius.radiusMd,
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _launchCaller(phoneNumber);
                        },
                        icon: const Icon(Icons.phone_outlined, size: 20),
                        label: Text(
                          'Appeler',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: DesignColors.ecoSmart,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: DesignRadius.radiusMd,
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _launchNavigation(center.latitude, center.longitude);
                        },
                        icon: const Icon(Icons.navigation_rounded, size: 20),
                        label: const Text(
                          'Itinéraire',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Centres de collecte'),
      ),
      body: FutureBuilder<List<_CenterLocation>>(
        future: _centersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _CentersErrorState(isDark: isDark);
          }
          
          final allCenters = snapshot.data ?? const [];
          if (allCenters.isEmpty) {
            return _CentersEmptyState(isDark: isDark);
          }

          // Get unique cities for filter chips
          final cities = allCenters
              .map((c) => c.city.trim())
              .where((c) => c.isNotEmpty)
              .map((c) => c.substring(0, 1).toUpperCase() + c.substring(1).toLowerCase())
              .toSet()
              .toList()
            ..sort();

          // Filter centers based on query and city chip
          final centers = allCenters.where((center) {
            final matchesQuery = _searchQuery.isEmpty ||
                center.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                center.city.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                center.zone.toLowerCase().contains(_searchQuery.toLowerCase());
            
            final matchesCity = _selectedCityFilter == null ||
                center.city.toLowerCase() == _selectedCityFilter!.toLowerCase();
                
            return matchesQuery && matchesCity;
          }).toList();

          final totalLat =
              allCenters.fold<double>(0, (sum, center) => sum + center.latitude);
          final totalLon =
              allCenters.fold<double>(0, (sum, center) => sum + center.longitude);
          final averageLat = totalLat / (allCenters.isEmpty ? 1 : allCenters.length);
          final averageLon = totalLon / (allCenters.isEmpty ? 1 : allCenters.length);

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  DesignSpacing.md,
                  DesignSpacing.md,
                  DesignSpacing.md,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Carte des centres',
                        style: DesignTypography.titleSmall(
                          isDark
                              ? DesignColors.textPrimaryDark
                              : DesignColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 240,
                        child: ClipRRect(
                          borderRadius: DesignRadius.radiusMd,
                          child: Theme.of(context).platform == TargetPlatform.windows
                              ? _WindowsMapMockup(
                                  centers: allCenters,
                                  onCenterSelected: _showCenterDetails,
                                )
                              : GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: LatLng(averageLat, averageLon),
                                    zoom: 6.4,
                                  ),
                                  markers: allCenters.map(
                                    (center) => Marker(
                                      markerId: MarkerId('${center.name}-${center.city}-${center.zone}'),
                                      position: LatLng(center.latitude, center.longitude),
                                      infoWindow: InfoWindow(
                                        title: center.name,
                                        snippet: '${center.city} • ${center.zone}',
                                      ),
                                      onTap: () => _showCenterDetails(center),
                                    ),
                                  ).toSet(),
                                  zoomControlsEnabled: false,
                                  myLocationButtonEnabled: false,
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Rechercher un centre...',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF1E1E2F)
                              : const Color(0xFFF3F4F6),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: DesignRadius.radiusMd,
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // City Filter Choice Chips
                      if (cities.isNotEmpty) ...[
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ChoiceChip(
                                label: const Text('Tous'),
                                selected: _selectedCityFilter == null,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCityFilter = null;
                                  });
                                },
                                selectedColor: DesignColors.ecoSmart.withValues(alpha: 0.15),
                                labelStyle: TextStyle(
                                  color: _selectedCityFilter == null
                                      ? DesignColors.ecoSmart
                                      : (isDark ? Colors.white70 : Colors.black87),
                                  fontWeight: _selectedCityFilter == null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ...cities.map((city) {
                                final isSelected = _selectedCityFilter == city;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(city),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedCityFilter = selected ? city : null;
                                      });
                                    },
                                    selectedColor: DesignColors.ecoSmart.withValues(alpha: 0.15),
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? DesignColors.ecoSmart
                                          : (isDark ? Colors.white70 : Colors.black87),
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      Text(
                        'Entreprises (${centers.length})',
                        style: DesignTypography.titleSmall(
                          isDark
                              ? DesignColors.textPrimaryDark
                              : DesignColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              if (centers.isEmpty)
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: DesignSpacing.md),
                  sliver: SliverToBoxAdapter(
                    child: _CentersEmptyState(isDark: isDark),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    DesignSpacing.md,
                    0,
                    DesignSpacing.md,
                    DesignSpacing.bottomNavHeight + DesignSpacing.xl,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final center = centers[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CenterTile(
                            isDark: isDark,
                            center: center,
                            onTap: () => _showCenterDetails(center),
                          ),
                        );
                      },
                      childCount: centers.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CenterLocation {
  final String name;
  final String city;
  final String zone;
  final double latitude;
  final double longitude;
  final double avgPriceTnd;

  const _CenterLocation({
    required this.name,
    required this.city,
    required this.zone,
    required this.latitude,
    required this.longitude,
    required this.avgPriceTnd,
  });

  factory _CenterLocation.fromJson(Map<String, dynamic> json) {
    return _CenterLocation(
      name: (json['name'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      zone: (json['zone'] ?? '').toString(),
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      avgPriceTnd: _asDouble(json['avg_price_tnd']),
    );
  }
}

class _CenterTile extends StatelessWidget {
  final bool isDark;
  final _CenterLocation center;
  final VoidCallback onTap;

  const _CenterTile({
    required this.isDark,
    required this.center,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: DesignRadius.radiusMd,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: DesignColors.ecoSmart.withValues(alpha: 0.15),
                borderRadius: DesignRadius.radiusSm,
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: DesignColors.ecoSmart,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    center.name,
                    style: DesignTypography.titleSmall(
                      isDark
                          ? DesignColors.textPrimaryDark
                          : DesignColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${center.city} • ${center.zone}',
                    style: DesignTypography.caption(
                      isDark
                          ? DesignColors.textSecondaryDark
                          : DesignColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${center.avgPriceTnd.toStringAsFixed(2)} TND',
              style: DesignTypography.labelSmall(
                isDark ? DesignColors.textSecondaryDark : DesignColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor =
        isDark ? DesignColors.textSecondaryDark : DesignColors.textSecondaryLight;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: DesignTypography.caption(labelColor)),
        Text(
          value,
          style: DesignTypography.labelSmall(
            isDark
                ? DesignColors.textPrimaryDark
                : DesignColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }
}

class _CentersEmptyState extends StatelessWidget {
  final bool isDark;
  const _CentersEmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: PremiumCard(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Aucun centre trouve dans le dataset.',
          style: DesignTypography.bodySmall(
            isDark
                ? DesignColors.textSecondaryDark
                : DesignColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }
}

class _CentersErrorState extends StatelessWidget {
  final bool isDark;
  const _CentersErrorState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: PremiumCard(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Impossible de charger les centres. Reessayez plus tard.',
          style: DesignTypography.bodySmall(
            isDark
                ? DesignColors.textSecondaryDark
                : DesignColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }
}

double _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

class _WindowsMapMockup extends StatefulWidget {
  final List<_CenterLocation> centers;
  final Function(_CenterLocation) onCenterSelected;

  const _WindowsMapMockup({
    required this.centers,
    required this.onCenterSelected,
  });

  @override
  State<_WindowsMapMockup> createState() => _WindowsMapMockupState();
}

class _WindowsMapMockupState extends State<_WindowsMapMockup> {
  String? _selectedCity;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mapBgColor = isDark ? const Color(0xFF1E1E2F) : const Color(0xFFF0F4F8);
    final gridColor = isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04);
    final activeNodeColor = DesignColors.ecoSmart;

    // Group centers by city
    final cityCounts = <String, int>{};
    final cityCenters = <String, List<_CenterLocation>>{};
    for (final center in widget.centers) {
      if (center.city.isEmpty) continue;
      final cityDisplay = center.city.substring(0, 1).toUpperCase() + center.city.substring(1).toLowerCase();
      cityCounts[cityDisplay] = (cityCounts[cityDisplay] ?? 0) + 1;
      cityCenters[cityDisplay] = cityCenters[cityDisplay] ?? [];
      cityCenters[cityDisplay]!.add(center);
    }

    // Coordinates of main Tunisian cities normalized (x, y between 0 and 1)
    final cityCoordinates = {
      'Bizerte': const Offset(0.50, 0.12),
      'Tunis': const Offset(0.55, 0.23),
      'Ariana': const Offset(0.53, 0.20),
      'Ben Arous': const Offset(0.57, 0.25),
      'Manouba': const Offset(0.51, 0.24),
      'Nabeul': const Offset(0.68, 0.29),
      'Sousse': const Offset(0.61, 0.44),
      'Monastir': const Offset(0.65, 0.48),
      'Mahdia': const Offset(0.64, 0.54),
      'Sfax': const Offset(0.54, 0.65),
      'Kairouan': const Offset(0.46, 0.48),
      'Gabes': const Offset(0.48, 0.78),
      'Gafsa': const Offset(0.30, 0.68),
      'Tozeur': const Offset(0.15, 0.75),
      'Medenine': const Offset(0.55, 0.88),
      'Kasserine': const Offset(0.25, 0.55),
      'Sidi Bouzid': const Offset(0.38, 0.58),
      'Beja': const Offset(0.38, 0.23),
      'Jendouba': const Offset(0.28, 0.25),
      'Kef': const Offset(0.26, 0.36),
      'Siliana': const Offset(0.40, 0.38),
      'Zaghouan': const Offset(0.50, 0.32),
      'Tataouine': const Offset(0.60, 0.95),
      'Kebili': const Offset(0.32, 0.84),
    };

    return Container(
      decoration: BoxDecoration(
        color: mapBgColor,
        borderRadius: DesignRadius.radiusMd,
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: ClipRRect(
        borderRadius: DesignRadius.radiusMd,
        child: Stack(
          children: [
            // Abstract grid background
            Positioned.fill(
              child: CustomPaint(
                painter: _GridPainter(gridColor),
              ),
            ),
            
            // Map watermark text
            Positioned(
              bottom: 12,
              left: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.desktop_windows_rounded,
                        size: 14,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Carte Interactive (Mode Desktop)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white38 : Colors.black38,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Cliquez sur une ville pour explorer les centres',
                    style: TextStyle(
                      fontSize: 9,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),

            // Render cities with centers
            ...cityCounts.entries.map((entry) {
              final cityName = entry.key;
              final count = entry.value;
              final coords = cityCoordinates[cityName] ?? const Offset(0.5, 0.5);

              return LayoutBuilder(
                builder: (context, constraints) {
                  final x = coords.dx * constraints.maxWidth;
                  final y = coords.dy * constraints.maxHeight;

                  final isSelected = _selectedCity == cityName;

                  return Positioned(
                    left: x - 10,
                    top: y - 10,
                    child: Tooltip(
                      message: '$cityName : $count centre(s)',
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCity = isSelected ? null : cityName;
                          });
                          // Show the first center of the selected city
                          final list = cityCenters[cityName];
                          if (list != null && list.isNotEmpty) {
                            widget.onCenterSelected(list.first);
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? activeNodeColor
                                : activeNodeColor.withValues(alpha: 0.2),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: activeNodeColor.withValues(alpha: 0.5),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : null,
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            size: isSelected ? 20 : 14,
                            color: isSelected ? Colors.white : activeNodeColor,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

            // If a city is selected, show mini card in top-right
            if (_selectedCity != null)
              Positioned(
                top: 12,
                right: 12,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2E2E3E) : Colors.white,
                    borderRadius: DesignRadius.radiusSm,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                    border: Border.all(
                      color: activeNodeColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: DesignColors.ecoSmart,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_selectedCity',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${cityCounts[_selectedCity]} centres)',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCity = null;
                          });
                        },
                        child: Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

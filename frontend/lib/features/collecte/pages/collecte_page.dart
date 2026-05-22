import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/design_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/premium_components.dart';

class CollectePage extends StatefulWidget {
  const CollectePage({super.key});

  @override
  State<CollectePage> createState() => _CollectePageState();
}

class _CollectePageState extends State<CollectePage> {
  late Future<List<_CenterLocation>> _centersFuture;
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _priceController = TextEditingController();
  final _pointsController = TextEditingController();
  final _reportController = TextEditingController();
  _CenterLocation? _selectedCenter;
  String _selectedWasteType = 'Plastique';
  bool _savingEvent = false;
  bool _estimating = false;
  String? _formMessage;
  Map<String, dynamic>? _estimateResult;

  @override
  void initState() {
    super.initState();
    _centersFuture = _loadCenters();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _priceController.dispose();
    _pointsController.dispose();
    _reportController.dispose();
    super.dispose();
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

  double? _parseDouble(String value) {
    if (value.trim().isEmpty) return null;
    return double.tryParse(value.replaceAll(',', '.'));
  }

  int? _parseInt(String value) {
    if (value.trim().isEmpty) return null;
    return int.tryParse(value);
  }

  Future<void> _submitRecyclingEvent() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _formMessage = null;
      _estimateResult = null;
    });

    if (!_formKey.currentState!.validate()) return;
    if (_selectedCenter == null) {
      setState(() => _formMessage = 'Selectionnez une entreprise.');
      return;
    }

    final weight = _parseDouble(_weightController.text);
    final price = _parseDouble(_priceController.text);
    final points = _parseInt(_pointsController.text);
    if (weight == null || price == null || points == null) {
      setState(() => _formMessage = 'Renseignez poids, prix et points.');
      return;
    }

    setState(() => _savingEvent = true);
    try {
      await getIt<ApiClient>().createRecyclingEvents([
        {
          'company_name': _selectedCenter!.name,
          'city': _selectedCenter!.city,
          'zone': _selectedCenter!.zone,
          'latitude': _selectedCenter!.latitude,
          'longitude': _selectedCenter!.longitude,
          'weight_kg': weight,
          'price_tnd': price,
          'points': points,
          'waste_type': _selectedWasteType,
        },
      ]);
      setState(() => _formMessage = 'Enregistrement reussi.');
    } catch (_) {
      setState(() => _formMessage = 'Echec de lenregistrement.');
    } finally {
      if (mounted) {
        setState(() => _savingEvent = false);
      }
    }
  }

  Future<void> _estimateFromForm() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _formMessage = null;
      _estimateResult = null;
    });

    if (!_formKey.currentState!.validate()) return;
    if (_selectedCenter == null) {
      setState(() => _formMessage = 'Selectionnez une entreprise.');
      return;
    }

    final weight = _parseDouble(_weightController.text) ?? 0;
    final payload = {
      'poids': weight,
      'source': _selectedCenter!.name,
      'latitude': _selectedCenter!.latitude,
      'longitude': _selectedCenter!.longitude,
      'rapport_collecte': _reportController.text.trim(),
    };

    setState(() => _estimating = true);
    try {
      final response = await getIt<ApiClient>().ecoEstimate(payload);
      final data = response.data;
      if (data is Map) {
        setState(() => _estimateResult = Map<String, dynamic>.from(data));
      }
    } catch (_) {
      setState(() => _formMessage = 'Echec de lestimation.');
    } finally {
      if (mounted) {
        setState(() => _estimating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collecte'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<List<_CenterLocation>>(
        future: _centersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const _CollecteLoadingState();
          }
          if (snapshot.hasError) {
            return _CollecteErrorState(isDark: isDark);
          }
          final centers = snapshot.data ?? const [];
          if (centers.isEmpty) {
            return _CollecteEmptyState(isDark: isDark);
          }
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              DesignSpacing.md,
              DesignSpacing.md,
              DesignSpacing.md,
              DesignSpacing.bottomNavHeight + DesignSpacing.xl,
            ),
            child: _RecyclingEventForm(
              isDark: isDark,
              centers: centers,
              formKey: _formKey,
              weightController: _weightController,
              priceController: _priceController,
              pointsController: _pointsController,
              reportController: _reportController,
              selectedCenter: _selectedCenter,
              onCenterChanged: (center) {
                setState(() => _selectedCenter = center);
              },
              selectedWasteType: _selectedWasteType,
              onWasteTypeChanged: (type) {
                if (type != null) {
                  setState(() => _selectedWasteType = type);
                }
              },
              isSaving: _savingEvent,
              isEstimating: _estimating,
              message: _formMessage,
              estimateResult: _estimateResult,
              onSubmit: _submitRecyclingEvent,
              onEstimate: _estimateFromForm,
            ),
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

class _RecyclingEventForm extends StatelessWidget {
  final bool isDark;
  final List<_CenterLocation> centers;
  final GlobalKey<FormState> formKey;
  final TextEditingController weightController;
  final TextEditingController priceController;
  final TextEditingController pointsController;
  final TextEditingController reportController;
  final _CenterLocation? selectedCenter;
  final ValueChanged<_CenterLocation?> onCenterChanged;
  final String selectedWasteType;
  final ValueChanged<String?> onWasteTypeChanged;
  final bool isSaving;
  final bool isEstimating;
  final String? message;
  final Map<String, dynamic>? estimateResult;
  final VoidCallback onSubmit;
  final VoidCallback onEstimate;

  const _RecyclingEventForm({
    required this.isDark,
    required this.centers,
    required this.formKey,
    required this.weightController,
    required this.priceController,
    required this.pointsController,
    required this.reportController,
    required this.selectedCenter,
    required this.onCenterChanged,
    required this.selectedWasteType,
    required this.onWasteTypeChanged,
    required this.isSaving,
    required this.isEstimating,
    required this.message,
    required this.estimateResult,
    required this.onSubmit,
    required this.onEstimate,
  });

  double? _tryParseDouble(String value) {
    if (value.trim().isEmpty) return null;
    return double.tryParse(value.replaceAll(',', '.'));
  }

  @override
  Widget build(BuildContext context) {
    final labelColor =
        isDark ? DesignColors.textSecondaryDark : DesignColors.textSecondaryLight;
    final isBusy = isSaving || isEstimating;

    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<_CenterLocation>(
              value: selectedCenter,
              items: centers
                  .map(
                    (center) => DropdownMenuItem(
                      value: center,
                      child: Text('${center.name} • ${center.city}'),
                    ),
                  )
                  .toList(),
              onChanged: isBusy ? null : onCenterChanged,
              decoration: InputDecoration(
                labelText: 'Entreprise',
                labelStyle: TextStyle(color: labelColor),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedWasteType,
              items: const [
                DropdownMenuItem(value: 'Plastique', child: Text('Plastique')),
                DropdownMenuItem(value: 'Verre', child: Text('Verre')),
                DropdownMenuItem(value: 'Papier', child: Text('Papier')),
                DropdownMenuItem(value: 'Carton', child: Text('Carton')),
                DropdownMenuItem(value: 'Métal', child: Text('Métal')),
                DropdownMenuItem(value: 'Autre', child: Text('Autre')),
              ],
              onChanged: isBusy ? null : onWasteTypeChanged,
              decoration: InputDecoration(
                labelText: 'Type de déchet',
                labelStyle: TextStyle(color: labelColor),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Poids (kg)',
                labelStyle: TextStyle(color: labelColor),
              ),
              validator: (value) {
                final parsed = _tryParseDouble(value ?? '');
                if (parsed == null || parsed <= 0) {
                  return 'Entrez un poids valide.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Prix (TND)',
                      labelStyle: TextStyle(color: labelColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: pointsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Points',
                      labelStyle: TextStyle(color: labelColor),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: reportController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Rapport collecte (optionnel)',
                labelStyle: TextStyle(color: labelColor),
              ),
            ),
            const SizedBox(height: 12),
            if (message != null && message!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  message!,
                  style: DesignTypography.bodySmall(labelColor),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isBusy ? null : onSubmit,
                    icon: const Icon(Icons.save_rounded),
                    label: Text(isSaving ? 'Enregistrement...' : 'Enregistrer'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isBusy ? null : onEstimate,
                    icon: const Icon(Icons.calculate_rounded),
                    label: Text(isEstimating ? 'Estimation...' : 'Estimer'),
                  ),
                ),
              ],
            ),
            if (estimateResult != null) ...[
              const SizedBox(height: 12),
              _EstimateResultCard(isDark: isDark, data: estimateResult!),
            ],
          ],
        ),
      ),
    );
  }
}

class _EstimateResultCard extends StatelessWidget {
  final bool isDark;
  final Map<String, dynamic> data;
  const _EstimateResultCard({required this.isDark, required this.data});

  @override
  Widget build(BuildContext context) {
    final price = _asDouble(data['price']);
    final minPrice = _asDouble(data['min_price']);
    final maxPrice = _asDouble(data['max_price']);
    final currency = (data['currency'] ?? 'TND').toString();
    final unit = (data['unit'] ?? 'kg').toString();
    final textColor =
        isDark ? DesignColors.textSecondaryDark : DesignColors.textSecondaryLight;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F5F5),
        borderRadius: DesignRadius.radiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Estimation', style: DesignTypography.titleSmall(textColor)),
          const SizedBox(height: 6),
          Text(
            '${price.toStringAsFixed(2)} $currency / $unit',
            style: DesignTypography.titleMedium(DesignColors.ecoSmart),
          ),
          const SizedBox(height: 4),
          Text(
            'Min: ${minPrice.toStringAsFixed(2)} • Max: ${maxPrice.toStringAsFixed(2)}',
            style: DesignTypography.caption(textColor),
          ),
        ],
      ),
    );
  }
}

class _CollecteLoadingState extends StatelessWidget {
  const _CollecteLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _CollecteErrorState extends StatelessWidget {
  final bool isDark;
  const _CollecteErrorState({required this.isDark});

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

class _CollecteEmptyState extends StatelessWidget {
  final bool isDark;
  const _CollecteEmptyState({required this.isDark});

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

double _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

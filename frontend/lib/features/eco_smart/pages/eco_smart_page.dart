import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/design_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/premium_components.dart';
import '../repository/eco_smart_repository.dart';

enum _EcoTab {
  classification,
  estimation,
  clustering,
  nlp,
  multimodal,
}

class EcoSmartPage extends StatefulWidget {
  final String? prefillRapport;
  final double? prefillPoids;
  final double? prefillVolume;
  final double? prefillConductivite;
  final double? prefillOpacite;
  final double? prefillRigidite;

  const EcoSmartPage({
    super.key,
    this.prefillRapport,
    this.prefillPoids,
    this.prefillVolume,
    this.prefillConductivite,
    this.prefillOpacite,
    this.prefillRigidite,
  });

  @override
  State<EcoSmartPage> createState() => _EcoSmartPageState();
}

class _EcoSmartPageState extends State<EcoSmartPage> {
  final EcoSmartRepository _repository = getIt<EcoSmartRepository>();
  final _poidsController = TextEditingController();
  final _volumeController = TextEditingController();
  final _conductiviteController = TextEditingController();
  final _opaciteController = TextEditingController();
  final _rigiditeController = TextEditingController();
  final _rapportController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.prefillRapport != null) {
      _rapportController.text = widget.prefillRapport!;
    }
    if (widget.prefillPoids != null) {
      _poidsController.text = widget.prefillPoids!.toString();
    }
    if (widget.prefillVolume != null) {
      _volumeController.text = widget.prefillVolume!.toString();
    }
    if (widget.prefillConductivite != null) {
      _conductiviteController.text = widget.prefillConductivite!.toString();
    }
    if (widget.prefillOpacite != null) {
      _opaciteController.text = widget.prefillOpacite!.toString();
    }
    if (widget.prefillRigidite != null) {
      _rigiditeController.text = widget.prefillRigidite!.toString();
    }
  }

  final List<String> _sources = const [
    'Municipal',
    'Industriel',
    'Commercial',
    'Association',
    'Autre',
  ];

  String _selectedSource = 'Municipal';

  final Map<_EcoTab, bool> _loading = {
    for (final tab in _EcoTab.values) tab: false,
  };
  final Map<_EcoTab, String?> _errors = {
    for (final tab in _EcoTab.values) tab: null,
  };
  final Map<_EcoTab, _EcoResult> _results = {};

  bool _isProcessingImage = false;
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _captureAndAnalyzeImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.camera);
      if (image == null) return;

      setState(() => _isProcessingImage = true);

      final inputImage = InputImage.fromFilePath(image.path);
      
      // 1. Labeling
      final options = ImageLabelerOptions(confidenceThreshold: 0.6);
      final labeler = ImageLabeler(options: options);
      final List<ImageLabel> labels = await labeler.processImage(inputImage);
      labeler.close();

      // 2. Barcode
      final barcodeScanner = BarcodeScanner();
      final List<Barcode> barcodes = await barcodeScanner.processImage(inputImage);
      barcodeScanner.close();

      String detectedText = '';
      if (labels.isNotEmpty) {
        final topLabel = labels.first.label;
        final confidence = (labels.first.confidence * 100).toStringAsFixed(1);
        detectedText = 'Objet detecte par AI: $topLabel ($confidence%)';
      }

      if (barcodes.isNotEmpty) {
        final code = barcodes.first.displayValue;
        detectedText += ' | Code-barres scane: $code';
      }

      if (detectedText.isNotEmpty) {
        setState(() {
          final currentText = _rapportController.text;
          _rapportController.text = currentText.isEmpty 
              ? detectedText 
              : '$currentText\n$detectedText';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analyse ML Kit reussie !')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun dechet clair ou code-barres trouve.')),
        );
      }
    } catch (e) {
      debugPrint('Erreur ML Kit: $e');
    } finally {
      setState(() => _isProcessingImage = false);
    }
  }

  @override
  void dispose() {
    _poidsController.dispose();
    _volumeController.dispose();
    _conductiviteController.dispose();
    _opaciteController.dispose();
    _rigiditeController.dispose();
    _rapportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    final initialTab = (widget.prefillRapport != null || widget.prefillPoids != null)
        ? _EcoTab.multimodal.index
        : 0;

    return DefaultTabController(
      length: _EcoTab.values.length,
      initialIndex: initialTab,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 200 + topPadding,
                pinned: true,
                backgroundColor: isDark
                    ? DesignColors.backgroundDark
                    : DesignColors.backgroundLight,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: DesignColors.ecoSmartGradient,
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: DesignRadius.radiusMd,
                              ),
                              child: const Icon(
                                Icons.eco_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Eco-smart',
                              style:
                                  DesignTypography.headlineLarge(Colors.white),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Du dechet brut a la valeur estimee',
                              style: DesignTypography.bodyMedium(
                                Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Container(
                    alignment: Alignment.centerLeft,
                    color: isDark
                        ? DesignColors.backgroundDark
                        : DesignColors.backgroundLight,
                    child: TabBar(
                      isScrollable: true,
                      tabs: const [
                        Tab(text: 'Classification'),
                        Tab(text: 'Estimation'),
                        Tab(text: 'Clustering'),
                        Tab(text: 'NLP'),
                        Tab(text: 'Multimodal'),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: _EcoTab.values
                .map((tab) => _buildTabContent(context, tab))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, _EcoTab tab) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = _results[tab];

    return ListView(
      padding: EdgeInsets.only(
        left: DesignSpacing.md,
        right: DesignSpacing.md,
        top: DesignSpacing.lg,
        bottom: DesignSpacing.bottomNavHeight + DesignSpacing.xxl,
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        _buildTabIntro(tab, isDark),
        const SizedBox(height: 16),
        _buildInputCard(isDark),
        const SizedBox(height: 16),
        _buildActionRow(tab),
        const SizedBox(height: 16),
        _buildResultCard(isDark, tab, result),
      ],
    );
  }

  Widget _buildTabIntro(_EcoTab tab, bool isDark) {
    final data = _tabMeta(tab);
    return PremiumCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: DesignColors.ecoSmartGradient,
              borderRadius: DesignRadius.radiusMd,
              boxShadow: DesignColors.shadowColored(DesignColors.ecoSmart),
            ),
            child: Icon(data.icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: DesignTypography.titleMedium(
                    isDark
                        ? DesignColors.textPrimaryDark
                        : DesignColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.subtitle,
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
    );
  }

  Widget _buildInputCard(bool isDark) {
    return PremiumCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Donnees d\'entree',
            style: DesignTypography.titleMedium(
              isDark
                  ? DesignColors.textPrimaryDark
                  : DesignColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 12),
          _buildTwoColumnRow(
            left: _numberField(
              label: 'Poids (kg)',
              controller: _poidsController,
              icon: Icons.scale_rounded,
            ),
            right: _numberField(
              label: 'Volume (L)',
              controller: _volumeController,
              icon: Icons.inventory_2_rounded,
            ),
          ),
          const SizedBox(height: 12),
          _buildTwoColumnRow(
            left: _numberField(
              label: 'Conductivite',
              controller: _conductiviteController,
              icon: Icons.flash_on_rounded,
            ),
            right: _numberField(
              label: 'Opacite',
              controller: _opaciteController,
              icon: Icons.opacity_rounded,
            ),
          ),
          const SizedBox(height: 12),
          _buildTwoColumnRow(
            left: _numberField(
              label: 'Rigidite',
              controller: _rigiditeController,
              icon: Icons.construction_rounded,
            ),
            right: _sourceField(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _rapportController,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Rapport_Collecte',
              hintText: 'Ex: Bouteilles plastique melangees a du carton humide',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: _isProcessingImage 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) 
                  : const Icon(Icons.camera_alt_rounded),
                onPressed: _isProcessingImage ? null : _captureAndAnalyzeImage,
                tooltip: 'Scanner objet / code-barres',
                color: DesignColors.ecoSmart,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Mode demo local: les resultats sont simules en attendant l\'API.',
            style: DesignTypography.bodySmall(
              isDark
                  ? DesignColors.textSecondaryDark
                  : DesignColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(_EcoTab tab) {
    final isLoading = _loading[tab] ?? false;
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : () => _runPrediction(tab),
            icon: isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow_rounded),
            label: const Text('Lancer la prediction'),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          tooltip: 'Reinitialiser',
          onPressed: _resetInputs,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }

  Widget _buildResultCard(bool isDark, _EcoTab tab, _EcoResult? result) {
    final error = _errors[tab];
    final isLoading = _loading[tab] ?? false;

    if (isLoading) {
      return PremiumCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analyse en cours...',
              style: DesignTypography.titleMedium(
                isDark
                    ? DesignColors.textPrimaryDark
                    : DesignColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
        ),
      );
    }

    if (error != null && error.isNotEmpty) {
      return PremiumCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: DesignColors.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error,
                style: DesignTypography.bodyMedium(
                  isDark
                      ? DesignColors.textSecondaryDark
                      : DesignColors.textSecondaryLight,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (result == null) {
      return PremiumCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(Icons.insights_rounded,
                color: DesignColors.ecoSmart.withValues(alpha: 0.7)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Aucun resultat pour le moment. Lancez une prediction.',
                style: DesignTypography.bodyMedium(
                  isDark
                      ? DesignColors.textSecondaryDark
                      : DesignColors.textSecondaryLight,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return PremiumCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.title,
            style: DesignTypography.titleMedium(
              isDark
                  ? DesignColors.textPrimaryDark
                  : DesignColors.textPrimaryLight,
            ),
          ),
          if (result.subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              result.subtitle,
              style: DesignTypography.bodySmall(
                isDark
                    ? DesignColors.textSecondaryDark
                    : DesignColors.textSecondaryLight,
              ),
            ),
          ],
          const SizedBox(height: 12),
          ...result.metrics.map(
            (metric) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      metric.label,
                      style: DesignTypography.bodySmall(
                        isDark
                            ? DesignColors.textSecondaryDark
                            : DesignColors.textSecondaryLight,
                      ),
                    ),
                  ),
                  Text(
                    metric.value,
                    style: DesignTypography.titleSmall(
                      isDark
                          ? DesignColors.textPrimaryDark
                          : DesignColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (result.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: DesignColors.ecoSmart.withValues(alpha: 0.12),
                        borderRadius: DesignRadius.radiusFull,
                      ),
                      child: Text(
                        tag,
                        style: DesignTypography.labelSmall(
                          DesignColors.ecoSmart,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTwoColumnRow({required Widget left, required Widget right}) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }

  Widget _numberField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
    );
  }

  Widget _sourceField() {
    return DropdownButtonFormField<String>(
      value: _selectedSource,
      decoration: const InputDecoration(
        labelText: 'Source',
        border: OutlineInputBorder(),
      ),
      items: _sources
          .map((source) => DropdownMenuItem(
                value: source,
                child: Text(source),
              ))
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() => _selectedSource = value);
      },
    );
  }

  void _resetInputs() {
    setState(() {
      _poidsController.clear();
      _volumeController.clear();
      _conductiviteController.clear();
      _opaciteController.clear();
      _rigiditeController.clear();
      _rapportController.clear();
      _selectedSource = _sources.first;
      _results.clear();
      for (final tab in _EcoTab.values) {
        _loading[tab] = false;
        _errors[tab] = null;
      }
    });
  }

  Future<void> _runPrediction(_EcoTab tab) async {
    if (!_hasAnyInput()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ajoutez au moins une valeur ou un texte')),
      );
      return;
    }

    setState(() {
      _loading[tab] = true;
      _errors[tab] = null;
    });

    double? lat;
    double? lon;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          Position position = await Geolocator.getCurrentPosition(
            locationSettings:
                const LocationSettings(accuracy: LocationAccuracy.medium),
          );
          lat = position.latitude;
          lon = position.longitude;
        }
      }
    } catch (e) {
      debugPrint('Avertissement géo: $e');
    }

    final payload = _buildPayload(lat, lon);
    final demo = _runDemoLocal(tab);

    try {
      final response = await _callApi(tab, payload);
      final result = _buildResultFromApi(tab, response, demo);
      setState(() {
        _results[tab] = result;
      });
    } catch (error) {
      setState(() {
        _errors[tab] = _formatError(error);
      });
    } finally {
      setState(() => _loading[tab] = false);
    }

    HapticFeedback.lightImpact();
  }

  _EcoResult _runDemoLocal(_EcoTab tab) {
    final poids = _parseDouble(_poidsController.text);
    final volume = _parseDouble(_volumeController.text);
    final conductivite = _parseDouble(_conductiviteController.text);
    final opacite = _parseDouble(_opaciteController.text);
    final rigidite = _parseDouble(_rigiditeController.text);
    final rapport = _rapportController.text.trim();

    final category = _inferCategory(rapport, conductivite, rigidite);
    final confidence = _inferConfidence(rapport, conductivite, rigidite);
    final price = _estimatePrice(
      poids: poids,
      volume: volume,
      conductivite: conductivite,
      opacite: opacite,
      rigidite: rigidite,
      category: category,
    );

    final cluster = _inferCluster(
      poids: poids,
      volume: volume,
      conductivite: conductivite,
      rigidite: rigidite,
    );

    final keywords = _extractKeywords(rapport);
    final summary = _summarizeReport(rapport, keywords);

    final result = _buildResultForTab(
      tab,
      category,
      confidence,
      price,
      cluster,
      keywords,
      summary,
    );

    return result;
  }

  bool _hasAnyInput() {
    return _poidsController.text.trim().isNotEmpty ||
        _volumeController.text.trim().isNotEmpty ||
        _conductiviteController.text.trim().isNotEmpty ||
        _opaciteController.text.trim().isNotEmpty ||
        _rigiditeController.text.trim().isNotEmpty ||
        _rapportController.text.trim().isNotEmpty;
  }

  double _parseDouble(String raw) {
    final normalized = raw.replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }

  double? _parseNullableDouble(String raw) {
    final normalized = raw.replaceAll(',', '.').trim();
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  Map<String, dynamic> _buildPayload(double? lat, double? lon) {
    final poids = _parseNullableDouble(_poidsController.text);
    final volume = _parseNullableDouble(_volumeController.text);
    final conductivite = _parseNullableDouble(_conductiviteController.text);
    final opacite = _parseNullableDouble(_opaciteController.text);
    final rigidite = _parseNullableDouble(_rigiditeController.text);
    final rapport = _rapportController.text.trim();

    return {
      if (poids != null) 'poids': poids,
      if (volume != null) 'volume': volume,
      if (conductivite != null) 'conductivite': conductivite,
      if (opacite != null) 'opacite': opacite,
      if (rigidite != null) 'rigidite': rigidite,
      'source': _selectedSource,
      if (rapport.isNotEmpty) 'rapport_collecte': rapport,
      if (lat != null) 'latitude': lat,
      if (lon != null) 'longitude': lon,
    };
  }

  Future<Map<String, dynamic>> _callApi(
    _EcoTab tab,
    Map<String, dynamic> payload,
  ) {
    switch (tab) {
      case _EcoTab.classification:
        return _repository.classify(payload);
      case _EcoTab.estimation:
        return _repository.estimate(payload);
      case _EcoTab.clustering:
        return _repository.cluster(payload);
      case _EcoTab.nlp:
        return _repository.nlp(payload);
      case _EcoTab.multimodal:
        return _repository.multimodal(payload);
    }
  }

  _EcoResult _buildResultFromApi(
    _EcoTab tab,
    Map<String, dynamic> data,
    _EcoResult fallback,
  ) {
    switch (tab) {
      case _EcoTab.classification:
        final category = _stringValue(
          data,
          ['categorie', 'category', 'label'],
          fallback: fallback.metrics.first.value,
        );
        final confidence = _doubleValue(
              data,
              ['confidence', 'score', 'probability'],
            ) ??
            _extractPercent(fallback);
        final provider = _stringValue(
          data,
          ['provider', 'model', 'model_name'],
          fallback: 'API',
        );
        return _EcoResult(
          title: 'Categorie predite',
          subtitle: 'Source: $provider',
          metrics: [
            _EcoMetric('Categorie', category),
            _EcoMetric(
                'Confiance', '${(confidence * 100).toStringAsFixed(1)}%'),
          ],
          tags: ['Source $_selectedSource', 'ML supervise'],
        );
      case _EcoTab.estimation:
        final price = _doubleValue(
              data,
              ['prix_revente', 'price', 'estimate', 'price_tnd'],
            ) ??
            _extractPriceValue(fallback);
        final minValue =
            _doubleValue(data, ['min', 'min_price', 'min_price_tnd']);
        final maxValue =
            _doubleValue(data, ['max', 'max_price', 'max_price_tnd']);
        final range = (minValue != null && maxValue != null)
            ? '${minValue.toStringAsFixed(3)} - ${maxValue.toStringAsFixed(3)} TND'
            : _formatPriceRange(price);

        final location = data['location'] as Map<String, dynamic>? ?? {};
        final ville = location['ville_proche'] as String? ?? 'Inconnue';
        final centre = location['centre_collecte'] as String? ?? 'Non defini';

        return _EcoResult(
          title: 'Estimation du prix & Centre',
          subtitle: 'Ville: $ville',
          metrics: [
            _EcoMetric('Prix estime', _formatPrice(price)),
            _EcoMetric('Intervalle', range),
            _EcoMetric('Centre suggere', centre),
          ],
          tags: ['Regression ($ville)', 'API'],
        );
      case _EcoTab.clustering:
        final label = _stringValue(
          data,
          ['cluster_label', 'label', 'cluster'],
          fallback: fallback.title,
        );
        final group = _stringValue(
          data,
          ['cluster_id', 'segment', 'group'],
          fallback: _extractMetricValue(fallback, 0),
        );
        final size = _stringValue(
          data,
          ['size_hint', 'size', 'taille'],
          fallback: _extractMetricValue(fallback, 1),
        );
        final features = _stringListValue(
          data,
          ['features', 'top_features'],
          fallback: fallback.tags,
        );
        return _EcoResult(
          title: label,
          subtitle: 'Segmentation non supervisee',
          metrics: [
            _EcoMetric('Groupe', group),
            _EcoMetric('Taille', size),
          ],
          tags: features,
        );
      case _EcoTab.nlp:
        final summary = _stringValue(
          data,
          ['summary', 'resume', 'synthese'],
          fallback: fallback.subtitle,
        );
        final keywords = _stringListValue(
          data,
          ['keywords', 'tokens', 'mots_cles'],
          fallback: _splitKeywords(_extractMetricValue(fallback, 0)),
        );
        final category = _stringValue(
          data,
          ['categorie', 'category', 'label'],
          fallback: _extractMetricValue(fallback, 1),
        );
        return _EcoResult(
          title: 'Caracteristiques extraites',
          subtitle: summary,
          metrics: [
            _EcoMetric(
              'Mots cles',
              keywords.isEmpty ? 'Aucun' : keywords.join(', '),
            ),
            _EcoMetric('Categorie suggeree', category),
          ],
          tags: ['NLP', 'Rapport_Collecte'],
        );
      case _EcoTab.multimodal:
        final category = _stringValue(
          data,
          ['categorie', 'category', 'label'],
          fallback: _extractMetricValue(fallback, 0),
        );
        final price = _doubleValue(
              data,
              ['price_tnd', 'prix_revente', 'price', 'estimate'],
            ) ??
            _extractPriceValue(fallback);
        final confidence = _doubleValue(
              data,
              ['confidence', 'score', 'probability'],
            ) ??
            _extractPercent(fallback);

        final location = data['location'] as Map<String, dynamic>? ?? {};
        final ville = location['ville_proche'] as String? ?? 'Inconnue';
        final centre = location['centre_collecte'] as String? ?? 'Non defini';

        return _EcoResult(
          title: 'Prediction multimodale',
          subtitle: 'Fusion texte + numerique ($ville)',
          metrics: [
            _EcoMetric('Categorie', category),
            _EcoMetric('Prix (TND)', _formatPrice(price)),
            _EcoMetric('Confiance', '${(confidence * 100).toStringAsFixed(1)}%'),
            _EcoMetric('Centre suggere', centre),
          ],
          tags: ['Multimodal', 'API', ville],
        );
    }
  }

  String _formatError(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status != null) {
        return 'Erreur API ($status): ${error.response?.statusMessage ?? 'Echec'}';
      }
      return 'Erreur reseau: ${error.message ?? 'Echec'}';
    }
    return 'Erreur: ${error.toString()}';
  }

  String _stringValue(
    Map<String, dynamic> data,
    List<String> keys, {
    required String fallback,
  }) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return fallback;
  }

  double? _doubleValue(
    Map<String, dynamic> data,
    List<String> keys, {
    double? fallback,
  }) {
    for (final key in keys) {
      final value = data[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value.replaceAll(',', '.'));
        if (parsed != null) return parsed;
      }
    }
    return fallback;
  }

  List<String> _stringListValue(
    Map<String, dynamic> data,
    List<String> keys, {
    required List<String> fallback,
  }) {
    for (final key in keys) {
      final value = data[key];
      if (value is List) {
        return value.map((item) => item.toString()).toList();
      }
      if (value is String && value.trim().isNotEmpty) {
        return _splitKeywords(value);
      }
    }
    return fallback;
  }

  List<String> _splitKeywords(String raw) {
    return raw
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String _extractMetricValue(_EcoResult fallback, int index) {
    if (fallback.metrics.length <= index) return 'N/A';
    return fallback.metrics[index].value;
  }

  double _extractPriceValue(_EcoResult fallback) {
    final metric = fallback.metrics.firstWhere(
      (item) => item.label.toLowerCase().contains('prix'),
      orElse: () => fallback.metrics.first,
    );
    final value = metric.value.split(' ').first;
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }

  double _extractPercent(_EcoResult fallback) {
    final metric = fallback.metrics.firstWhere(
      (item) => item.label.toLowerCase().contains('confiance'),
      orElse: () => fallback.metrics.last,
    );
    final raw = metric.value.replaceAll('%', '').trim();
    final value = double.tryParse(raw.replaceAll(',', '.')) ?? 0;
    return (value / 100).clamp(0.0, 1.0);
  }

  _EcoResult _buildResultForTab(
    _EcoTab tab,
    String category,
    double confidence,
    double price,
    _EcoCluster cluster,
    List<String> keywords,
    String summary,
  ) {
    switch (tab) {
      case _EcoTab.classification:
        return _EcoResult(
          title: 'Categorie predite',
          subtitle: 'Mode demo local',
          metrics: [
            _EcoMetric('Categorie', category),
            _EcoMetric(
                'Confiance', '${(confidence * 100).toStringAsFixed(1)}%'),
          ],
          tags: ['Source $_selectedSource', 'ML supervise'],
        );
      case _EcoTab.estimation:
        final range = _formatPriceRange(price);
        return _EcoResult(
          title: 'Estimation du prix',
          subtitle: 'Estimation basee sur les features numeriques',
          metrics: [
            _EcoMetric('Prix estime', _formatPrice(price)),
            _EcoMetric('Intervalle', range),
          ],
          tags: ['Regression', 'Mode demo'],
        );
      case _EcoTab.clustering:
        return _EcoResult(
          title: cluster.label,
          subtitle: 'Segmentation non supervisee',
          metrics: [
            _EcoMetric('Groupe', cluster.group),
            _EcoMetric('Taille', cluster.sizeHint),
          ],
          tags: cluster.features,
        );
      case _EcoTab.nlp:
        return _EcoResult(
          title: 'Caracteristiques extraites',
          subtitle: summary,
          metrics: [
            _EcoMetric(
                'Mots cles', keywords.isEmpty ? 'Aucun' : keywords.join(', ')),
            _EcoMetric('Categorie suggeree', category),
          ],
          tags: ['NLP', 'Rapport_Collecte'],
        );
      case _EcoTab.multimodal:
        return _EcoResult(
          title: 'Prediction multimodale',
          subtitle: 'Fusion texte + numerique',
          metrics: [
            _EcoMetric('Categorie', category),
            _EcoMetric('Prix', _formatPrice(price)),
            _EcoMetric(
                'Confiance', '${(confidence * 100).toStringAsFixed(1)}%'),
          ],
          tags: ['Multimodal', 'Stacking'],
        );
    }
  }

  String _inferCategory(String report, double conductivite, double rigidite) {
    final text = report.toLowerCase();
    if (text.contains('plastique')) return 'Plastique';
    if (text.contains('verre')) return 'Verre';
    if (text.contains('metal') ||
        text.contains('acier') ||
        text.contains('alu')) {
      return 'Metal';
    }
    if (text.contains('papier') || text.contains('carton')) return 'Papier';
    if (text.contains('organique') ||
        text.contains('compost') ||
        text.contains('aliment')) {
      return 'Organique';
    }
    if (text.contains('electronique') || text.contains('batterie')) {
      return 'Electronique';
    }

    if (conductivite > 7 || rigidite > 7) return 'Metal';
    if (conductivite < 1 && rigidite < 4) return 'Plastique';
    return 'Mixte';
  }

  double _inferConfidence(String report, double conductivite, double rigidite) {
    double score = 0.45;
    final text = report.toLowerCase();
    if (text.contains('plastique') ||
        text.contains('verre') ||
        text.contains('metal') ||
        text.contains('papier') ||
        text.contains('organique')) {
      score += 0.25;
    }
    if (conductivite > 6 || rigidite > 6) score += 0.15;
    if (report.length > 60) score += 0.05;
    return score.clamp(0.35, 0.9);
  }

  double _estimatePrice({
    required double poids,
    required double volume,
    required double conductivite,
    required double opacite,
    required double rigidite,
    required String category,
  }) {
    double base = poids * 0.7 + volume * 0.2 + conductivite * 0.3;
    base += rigidite * 0.15 - opacite * 0.1;

    final multiplier = switch (category) {
      'Metal' => 1.3,
      'Electronique' => 1.6,
      'Plastique' => 0.7,
      'Papier' => 0.5,
      'Verre' => 0.6,
      'Organique' => 0.2,
      _ => 0.8,
    };

    final price = base * multiplier;
    return max(0.15, price);
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(3)} TND / kg';
  }

  String _formatPriceRange(double price) {
    final min = max(0.05, price * 0.85);
    final maxValue = price * 1.15;
    return '${min.toStringAsFixed(3)} - ${maxValue.toStringAsFixed(3)} TND';
  }

  _EcoCluster _inferCluster({
    required double poids,
    required double volume,
    required double conductivite,
    required double rigidite,
  }) {
    if (poids < 2 && volume < 2) {
      return const _EcoCluster(
        label: 'Cluster A: Leger & compact',
        group: 'A1',
        sizeHint: 'Petits volumes',
        features: ['leger', 'compact', 'faible densite'],
      );
    }
    if (conductivite > 6) {
      return const _EcoCluster(
        label: 'Cluster B: Conducteur',
        group: 'B3',
        sizeHint: 'Valeur elevee',
        features: ['conducteur', 'dense', 'recyclable'],
      );
    }
    if (rigidite > 6) {
      return const _EcoCluster(
        label: 'Cluster C: Rigide',
        group: 'C2',
        sizeHint: 'Structure stable',
        features: ['rigide', 'volume moyen', 'traitement mecanique'],
      );
    }

    return const _EcoCluster(
      label: 'Cluster D: Mixte',
      group: 'D4',
      sizeHint: 'Profil heterogene',
      features: ['mixte', 'tri requis', 'valeur variable'],
    );
  }

  List<String> _extractKeywords(String report) {
    if (report.trim().isEmpty) return [];

    const stopWords = {
      'avec',
      'sans',
      'dans',
      'pour',
      'par',
      'plus',
      'moins',
      'tres',
      'trop',
      'mais',
      'pas',
      'comme',
      'cette',
      'cela',
      'celui',
      'celle',
      'leurs',
      'leur',
      'dont',
      'alors',
      'ainsi',
      'apres',
      'avant',
      'entre',
      'dechets',
      'dechet',
      'rapport',
      'collecte',
      'presence',
    };

    final tokens = report
        .toLowerCase()
        .split(RegExp(r"[^a-zA-Zàâäéèêëîïôöùûüç]+"))
        .where((token) => token.length > 4 && !stopWords.contains(token))
        .toList();

    final unique = <String>{};
    final keywords = <String>[];
    for (final token in tokens) {
      if (unique.add(token)) {
        keywords.add(token);
      }
      if (keywords.length == 6) break;
    }

    return keywords;
  }

  String _summarizeReport(String report, List<String> keywords) {
    if (report.trim().isEmpty) {
      return 'Aucun rapport fourni.';
    }

    final sentences = report.split(RegExp(r'[.!?]'));
    final first = sentences.firstWhere(
      (s) => s.trim().isNotEmpty,
      orElse: () => report,
    );

    final trimmed = first.trim();
    if (trimmed.length <= 90) return trimmed;
    return '${trimmed.substring(0, 90)}...';
  }

  _EcoTabMeta _tabMeta(_EcoTab tab) {
    switch (tab) {
      case _EcoTab.classification:
        return const _EcoTabMeta(
          title: 'Classification des dechets',
          subtitle: 'Predire la categorie a partir des donnees brutes.',
          icon: Icons.category_rounded,
        );
      case _EcoTab.estimation:
        return const _EcoTabMeta(
          title: 'Estimation du prix',
          subtitle: 'Regression du prix de revente par kg.',
          icon: Icons.price_check_rounded,
        );
      case _EcoTab.clustering:
        return const _EcoTabMeta(
          title: 'Segmentation',
          subtitle: 'Decouvrir des sous-groupes de materiaux.',
          icon: Icons.hub_rounded,
        );
      case _EcoTab.nlp:
        return const _EcoTabMeta(
          title: 'Analyse NLP',
          subtitle: 'Extraire les caracteristiques du rapport.',
          icon: Icons.text_snippet_rounded,
        );
      case _EcoTab.multimodal:
        return const _EcoTabMeta(
          title: 'Fusion multimodale',
          subtitle: 'Combiner texte et numerique pour la prediction.',
          icon: Icons.merge_type_rounded,
        );
    }
  }
}

class _EcoResult {
  final String title;
  final String subtitle;
  final List<_EcoMetric> metrics;
  final List<String> tags;

  const _EcoResult({
    required this.title,
    required this.subtitle,
    required this.metrics,
    required this.tags,
  });
}

class _EcoMetric {
  final String label;
  final String value;

  const _EcoMetric(this.label, this.value);
}

class _EcoCluster {
  final String label;
  final String group;
  final String sizeHint;
  final List<String> features;

  const _EcoCluster({
    required this.label,
    required this.group,
    required this.sizeHint,
    required this.features,
  });
}

class _EcoTabMeta {
  final String title;
  final String subtitle;
  final IconData icon;

  const _EcoTabMeta({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// NLP Dashboard Page with Modern Card Design
class NlpDashboardPage extends StatefulWidget {
  const NlpDashboardPage({super.key});

  @override
  State<NlpDashboardPage> createState() => _NlpDashboardPageState();
}

class _NlpDashboardPageState extends State<NlpDashboardPage> {
  final TextEditingController _textController = TextEditingController();
  String? _selectedFeature;
  bool _isProcessing = false;
  Map<String, dynamic>? _result;

  final List<_NlpFeature> _features = [
    _NlpFeature(
      id: 'sentiment',
      title: 'Analyse de Sentiment',
      subtitle: 'Opinion Mining',
      description: 'Détectez les émotions et sentiments dans le texte.',
      icon: Icons.sentiment_satisfied_alt_rounded,
      color: Color(0xFF10B981),
    ),
    _NlpFeature(
      id: 'translation',
      title: 'Traduction',
      subtitle: 'Multi-langues',
      description: 'Traduisez du texte entre différentes langues.',
      icon: Icons.translate_rounded,
      color: Color(0xFF3B82F6),
    ),
    _NlpFeature(
      id: 'entity',
      title: 'Extraction d\'Entités',
      subtitle: 'NER',
      description: 'Identifiez les personnes, lieux et organisations.',
      icon: Icons.hub_rounded,
      color: Color(0xFFEC4899),
    ),
    _NlpFeature(
      id: 'summary',
      title: 'Résumé',
      subtitle: 'Summarization',
      description: 'Générez des résumés de longs textes.',
      icon: Icons.short_text_rounded,
      color: Color(0xFFF59E0B),
    ),
    _NlpFeature(
      id: 'language',
      title: 'Détection de Langue',
      subtitle: 'Language ID',
      description: 'Identifiez automatiquement la langue du texte.',
      icon: Icons.language_rounded,
      color: Color(0xFF8B5CF6),
    ),
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildMainContent(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppColors.nlpGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.text_fields_rounded,
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
                'NLP - Traitement du Langage',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                'Analyse et traitement de texte intelligent',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: _buildFeatureList(context, isDark),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: _buildWorkArea(context, isDark),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              _buildFeatureChips(context, isDark),
              const SizedBox(height: 24),
              _buildWorkArea(context, isDark),
            ],
          );
        }
      },
    );
  }

  Widget _buildFeatureChips(BuildContext context, bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _features.map((feature) {
        final isSelected = _selectedFeature == feature.id;
        return FilterChip(
          selected: isSelected,
          onSelected: (_) => setState(() => _selectedFeature = feature.id),
          avatar: Icon(
            feature.icon,
            size: 18,
            color: isSelected ? Colors.white : feature.color,
          ),
          label: Text(feature.title),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : null,
            fontWeight: isSelected ? FontWeight.w600 : null,
          ),
          backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
          selectedColor: feature.color,
          showCheckmark: false,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        );
      }).toList(),
    );
  }

  Widget _buildFeatureList(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Sélectionner un service',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          ..._features
              .map((feature) => _buildFeatureItem(context, feature, isDark)),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
      BuildContext context, _NlpFeature feature, bool isDark) {
    final isSelected = _selectedFeature == feature.id;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedFeature = feature.id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? feature.color.withValues(alpha: 0.1)
                : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: isSelected ? feature.color : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: feature.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  feature.icon,
                  color: feature.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      feature.subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: feature.color,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkArea(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  _selectedFeature != null
                      ? _features
                          .firstWhere((f) => f.id == _selectedFeature)
                          .title
                      : 'Entrée de texte',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                if (_textController.text.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _textController.clear();
                        _result = null;
                      });
                    },
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    label: const Text('Effacer'),
                  ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildInputArea(context, isDark),
          ),
          if (_result != null) ...[
            Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: _buildResultArea(context, isDark),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea(BuildContext context, bool isDark) {
    return Column(
      children: [
        TextField(
          controller: _textController,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'Entrez votre texte ici...',
            filled: true,
            fillColor:
                isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                '${_textController.text.length} caractères',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _selectedFeature != null &&
                      _textController.text.isNotEmpty &&
                      !_isProcessing
                  ? _processText
                  : null,
              icon: _isProcessing
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow_rounded),
              label: Text(_isProcessing ? 'Traitement...' : 'Analyser'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultArea(BuildContext context, bool isDark) {
    final feature = _features.firstWhere((f) => f.id == _selectedFeature);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: feature.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                feature.icon,
                color: feature.color,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Résultat de ${feature.title}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildResultWidget(context, isDark),
      ],
    );
  }

  Widget _buildResultWidget(BuildContext context, bool isDark) {
    switch (_selectedFeature) {
      case 'sentiment':
        return _buildSentimentResult(context, isDark);
      case 'translation':
        return _buildTranslationResult(context, isDark);
      default:
        return _buildGenericResult(context, isDark);
    }
  }

  Widget _buildSentimentResult(BuildContext context, bool isDark) {
    final sentiment = _result?['sentiment'] ?? 'positive';
    final score = _result?['score'] ?? 0.85;

    Color sentimentColor;
    IconData sentimentIcon;
    String sentimentLabel;

    switch (sentiment) {
      case 'positive':
        sentimentColor = AppColors.success;
        sentimentIcon = Icons.sentiment_satisfied_alt_rounded;
        sentimentLabel = 'Positif';
        break;
      case 'negative':
        sentimentColor = AppColors.error;
        sentimentIcon = Icons.sentiment_dissatisfied_rounded;
        sentimentLabel = 'Négatif';
        break;
      default:
        sentimentColor = AppColors.warning;
        sentimentIcon = Icons.sentiment_neutral_rounded;
        sentimentLabel = 'Neutre';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: sentimentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: sentimentColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: sentimentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              sentimentIcon,
              color: sentimentColor,
              size: 36,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sentimentLabel,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: sentimentColor,
                      ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: score,
                  backgroundColor: sentimentColor.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(sentimentColor),
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                Text(
                  'Confiance: ${(score * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationResult(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'FR → EN',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.swap_horiz_rounded,
                color: Theme.of(context).colorScheme.outline,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _result?['translation'] ?? 'Sample translation result...',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildGenericResult(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _result.toString(),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
            ),
      ),
    );
  }

  Future<void> _processText() async {
    if (_selectedFeature == null || _textController.text.isEmpty) return;

    setState(() => _isProcessing = true);

    // Simulate processing
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isProcessing = false;
      _result = {
        'feature': _selectedFeature,
        'status': 'success',
        'sentiment': 'positive',
        'score': 0.87,
        'translation': 'This is a sample translated text.',
        'entities': ['Entity 1', 'Entity 2'],
      };
    });
  }
}

class _NlpFeature {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;

  _NlpFeature({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
  });
}

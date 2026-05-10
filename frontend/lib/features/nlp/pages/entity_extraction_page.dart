import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/design_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../bloc/nlp_bloc.dart';
import '../utils/nlp_provider_prefs.dart';

class EntityExtractionPage extends StatelessWidget {
  const EntityExtractionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NLPBloc>(
      create: (_) => getIt<NLPBloc>(),
      child: const _EntityExtractionView(),
    );
  }
}

class _EntityExtractionView extends StatefulWidget {
  const _EntityExtractionView();

  @override
  State<_EntityExtractionView> createState() => _EntityExtractionViewState();
}

class _EntityExtractionViewState extends State<_EntityExtractionView> {
  final _textController = TextEditingController();
  String _selectedLanguage = 'en';
  bool _useLocalProcessing = true;
  String _remoteProvider = 'huggingface';

  final _providers = const [
    {'id': 'auto', 'label': 'Auto'},
    {'id': 'huggingface', 'label': 'Hugging Face'},
    {'id': 'google', 'label': 'Google'},
  ];

  final _languages = [
    {'code': 'en', 'name': 'Anglais'},
    {'code': 'fr', 'name': 'Français'},
    {'code': 'de', 'name': 'Allemand'},
    {'code': 'es', 'name': 'Espagnol'},
    {'code': 'it', 'name': 'Italien'},
    {'code': 'pt', 'name': 'Portugais'},
  ];

  final _sampleTexts = [
    {
      'text':
          'Meet me at 123 Main Street, New York on January 15, 2024 at 3:00 PM. Call me at +1-555-123-4567.',
      'lang': 'en'
    },
    {
      'text':
          'Rendez-vous au 45 Rue de la Paix, Paris le 20 mars 2024 à 14h30. Mon email: contact@example.com',
      'lang': 'fr'
    },
    {
      'text':
          'Der Termin ist am 5. April 2024 um 10:00 Uhr in der Berliner Straße 100. Preis: 50€',
      'lang': 'de'
    },
  ];

  @override
  void initState() {
    super.initState();
    _remoteProvider = NlpProviderPrefs.getProvider();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Extraction d'entités"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<NLPBloc, NLPState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        DesignColors.nlp.withValues(alpha: 0.1),
                        DesignColors.nlp.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: DesignRadius.radiusLg,
                    border: Border.all(
                        color: DesignColors.nlp.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.label_rounded,
                          color: DesignColors.nlp, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ML Kit Entity Extraction',
                                style: DesignTypography.titleSmall(isDark
                                    ? DesignColors.textPrimaryDark
                                    : DesignColors.textPrimaryLight)),
                            Text('Détecte dates, adresses, numéros, prix, etc.',
                                style: DesignTypography.bodySmall(isDark
                                    ? DesignColors.textSecondaryDark
                                    : DesignColors.textSecondaryLight)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Language Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? DesignColors.surfaceDark : Colors.white,
                    borderRadius: DesignRadius.radiusMd,
                    border: Border.all(
                      color: isDark
                          ? DesignColors.borderDark
                          : DesignColors.borderLight,
                    ),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedLanguage,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: _languages.map((lang) {
                      return DropdownMenuItem(
                        value: lang['code'],
                        child: Text(lang['name']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedLanguage = value);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? DesignColors.surfaceDark : Colors.white,
                    borderRadius: DesignRadius.radiusMd,
                    border: Border.all(
                      color: isDark
                          ? DesignColors.borderDark
                          : DesignColors.borderLight,
                    ),
                  ),
                  child: SwitchListTile(
                    title: const Text('Extraction locale (ML Kit)'),
                    subtitle: Text(_useLocalProcessing
                        ? 'Rapide, sur appareil'
                        : 'Serveur NLP (Hugging Face / Google)'),
                    value: _useLocalProcessing,
                    onChanged: (value) {
                      setState(() => _useLocalProcessing = value);
                    },
                  ),
                ),
                if (!_useLocalProcessing) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? DesignColors.surfaceDark : Colors.white,
                      borderRadius: DesignRadius.radiusMd,
                      border: Border.all(
                        color: isDark
                            ? DesignColors.borderDark
                            : DesignColors.borderLight,
                      ),
                    ),
                    child: DropdownButton<String>(
                      value: _remoteProvider,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: _providers
                          .map(
                            (provider) => DropdownMenuItem(
                              value: provider['id'],
                              child: Text(provider['label']!),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _remoteProvider = value);
                          NlpProviderPrefs.setProvider(value);
                        }
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Text Input
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? DesignColors.surfaceDark : Colors.white,
                    borderRadius: DesignRadius.radiusMd,
                    border: Border.all(
                      color: isDark
                          ? DesignColors.borderDark
                          : DesignColors.borderLight,
                    ),
                  ),
                  child: TextField(
                    controller: _textController,
                    maxLines: 5,
                    style: DesignTypography.bodyMedium(isDark
                        ? DesignColors.textPrimaryDark
                        : DesignColors.textPrimaryLight),
                    decoration: InputDecoration(
                      hintText: 'Entrez un texte contenant des entités...',
                      hintStyle: DesignTypography.bodyMedium(isDark
                          ? DesignColors.textTertiaryDark
                          : DesignColors.textTertiaryLight),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Sample texts
                Text('Exemples :',
                    style: DesignTypography.labelMedium(isDark
                        ? DesignColors.textSecondaryDark
                        : DesignColors.textSecondaryLight)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _sampleTexts.map((sample) {
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _textController.text = sample['text']!;
                        setState(() => _selectedLanguage = sample['lang']!);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: DesignColors.nlp.withValues(alpha: 0.1),
                          borderRadius: DesignRadius.radiusSm,
                        ),
                        child: Text(
                          _languages.firstWhere(
                              (l) => l['code'] == sample['lang'])['name']!,
                          style: DesignTypography.labelSmall(DesignColors.nlp),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Extract Button
                _PrimaryButton(
                  label: 'Extraire les entités',
                  icon: Icons.search_rounded,
                  isLoading: state.status == NLPStatus.loading,
                  onPressed: _textController.text.isNotEmpty &&
                          state.status != NLPStatus.loading
                      ? _extractEntities
                      : null,
                ),
                const SizedBox(height: 24),

                // Results
                if (state.status == NLPStatus.success &&
                    state.result != null) ...[
                  _buildResults(context, state.result!, isDark),
                ],

                if (state.status == NLPStatus.failure) ...[
                  _ErrorCard(message: state.error ?? 'Une erreur est survenue'),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResults(
      BuildContext context, Map<String, dynamic> result, bool isDark) {
    final entities = result['entities'] as List? ?? [];
    final processingTime = result['processingTime'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Entités détectées (${entities.length})',
                style: DesignTypography.titleMedium(isDark
                    ? DesignColors.textPrimaryDark
                    : DesignColors.textPrimaryLight)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: DesignColors.nlp.withValues(alpha: 0.1),
                borderRadius: DesignRadius.radiusSm,
              ),
              child: Text('${processingTime.toStringAsFixed(2)}s',
                  style: DesignTypography.labelSmall(DesignColors.nlp)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (entities.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? DesignColors.surfaceDark : Colors.grey[50],
              borderRadius: DesignRadius.radiusMd,
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.search_off_rounded,
                      size: 48,
                      color: isDark
                          ? DesignColors.textTertiaryDark
                          : Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text('Aucune entité détectée',
                      style: DesignTypography.bodyMedium(isDark
                          ? DesignColors.textSecondaryDark
                          : DesignColors.textSecondaryLight)),
                ],
              ),
            ),
          )
        else
          ...entities
              .map((entity) => _EntityCard(entity: entity, isDark: isDark)),
      ],
    );
  }

  void _extractEntities() {
    HapticFeedback.mediumImpact();
    context.read<NLPBloc>().add(
          ExtractEntities(
            text: _textController.text,
            useLocal: _useLocalProcessing,
            language: _selectedLanguage,
            provider: _remoteProvider,
          ),
        );
  }
}

class _EntityCard extends StatelessWidget {
  final Map<String, dynamic> entity;
  final bool isDark;

  const _EntityCard({required this.entity, required this.isDark});

  IconData _getEntityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'datetime':
        return Icons.calendar_today_rounded;
      case 'address':
        return Icons.location_on_rounded;
      case 'phone':
        return Icons.phone_rounded;
      case 'email':
        return Icons.email_rounded;
      case 'url':
        return Icons.link_rounded;
      case 'money':
        return Icons.attach_money_rounded;
      case 'flightnumber':
        return Icons.flight_rounded;
      case 'iban':
        return Icons.account_balance_rounded;
      case 'isbn':
        return Icons.book_rounded;
      case 'trackingnumber':
        return Icons.local_shipping_rounded;
      default:
        return Icons.label_rounded;
    }
  }

  Color _getEntityColor(String type) {
    switch (type.toLowerCase()) {
      case 'datetime':
        return Colors.blue;
      case 'address':
        return Colors.green;
      case 'phone':
        return Colors.orange;
      case 'email':
        return Colors.purple;
      case 'url':
        return Colors.teal;
      case 'money':
        return Colors.amber;
      default:
        return DesignColors.nlp;
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = entity['text'] ?? 'N/A';
    final types = entity['types'] as List? ?? [];
    final mainType =
        types.isNotEmpty ? (types.first['type'] ?? 'Unknown') : 'Unknown';
    final color = _getEntityColor(mainType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? DesignColors.surfaceDark : Colors.white,
        borderRadius: DesignRadius.radiusMd,
        border: Border.all(
          color: isDark ? DesignColors.borderDark : DesignColors.borderLight,
        ),
        boxShadow: DesignColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: DesignRadius.radiusSm,
                ),
                child: Icon(_getEntityIcon(mainType), color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mainType.toUpperCase(),
                        style: DesignTypography.labelMedium(color)),
                    if (types.length > 1)
                      Text('+ ${types.length - 1} autres types',
                          style: DesignTypography.bodySmall(isDark
                              ? DesignColors.textSecondaryDark
                              : DesignColors.textSecondaryLight)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.grey[100],
              borderRadius: DesignRadius.radiusSm,
            ),
            child: SelectableText(
              text,
              style: DesignTypography.bodyMedium(isDark
                  ? DesignColors.textPrimaryDark
                  : DesignColors.textPrimaryLight),
            ),
          ),
          if (types.length > 1) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: types.skip(1).map((t) {
                final typeName = t['type'] ?? 'Unknown';
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getEntityColor(typeName).withValues(alpha: 0.1),
                    borderRadius: DesignRadius.radiusSm,
                  ),
                  child: Text(typeName,
                      style: DesignTypography.labelSmall(
                          _getEntityColor(typeName))),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: onPressed != null ? DesignColors.nlpGradient : null,
        color: onPressed == null ? Colors.grey.shade400 : null,
        borderRadius: DesignRadius.radiusMd,
        boxShadow: onPressed != null
            ? DesignColors.shadowColored(DesignColors.nlp)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: DesignRadius.radiusMd,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Text(label,
                          style: DesignTypography.labelLarge(Colors.white)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: DesignRadius.radiusMd,
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
              child: Text(message, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

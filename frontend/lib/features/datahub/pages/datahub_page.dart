import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/design_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../repository/datahub_repository.dart';

class DataHubPage extends StatefulWidget {
  const DataHubPage({super.key});

  @override
  State<DataHubPage> createState() => _DataHubPageState();
}

class _DataHubPageState extends State<DataHubPage> {
  final DataHubRepository _repository = getIt<DataHubRepository>();

  final TextEditingController _youtubeQueryController =
      TextEditingController(text: 'restaurant dakar');
  final TextEditingController _facebookPageIdController =
      TextEditingController(text: '20531316728');
  final TextEditingController _placesQueryController =
      TextEditingController(text: 'restaurant');

  String _sourceFilter = 'youtube';
  bool _isLoadingRecords = true;
  bool _isLoadingJobs = true;
  bool _isCollectingYoutube = false;
  bool _isCollectingFacebook = false;
  bool _isCollectingMaps = false;

  List<dynamic> _records = const <dynamic>[];
  List<dynamic> _jobs = const <dynamic>[];

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  @override
  void dispose() {
    _youtubeQueryController.dispose();
    _facebookPageIdController.dispose();
    _placesQueryController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadRecords(),
      _loadJobs(),
    ]);
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoadingRecords = true);
    try {
      final records = await _repository.getRecords(source: _sourceFilter);
      if (!mounted) return;
      setState(() => _records = records);
    } catch (e) {
      _showError(_mapError(e));
    } finally {
      if (mounted) setState(() => _isLoadingRecords = false);
    }
  }

  Future<void> _loadJobs() async {
    setState(() => _isLoadingJobs = true);
    try {
      final jobs = await _repository.getJobs();
      if (!mounted) return;
      setState(() => _jobs = jobs);
    } catch (e) {
      _showError(_mapError(e));
    } finally {
      if (mounted) setState(() => _isLoadingJobs = false);
    }
  }

  Future<void> _collectYoutube() async {
    final query = _youtubeQueryController.text.trim();
    if (query.isEmpty) {
      _showError('Saisissez une requete YouTube.');
      return;
    }

    setState(() => _isCollectingYoutube = true);
    try {
      final result = await _repository.collectYouTube(query: query);
      if (!mounted) return;
      _showInfo(
        'YouTube: ${result['records_saved'] ?? 0} enregistrements sauvegardes.',
      );
      await _refreshAll();
    } catch (e) {
      _showError(_mapError(e));
    } finally {
      if (mounted) setState(() => _isCollectingYoutube = false);
    }
  }

  Future<void> _collectFacebook() async {
    final pageId = _facebookPageIdController.text.trim();
    if (pageId.isEmpty) {
      _showError('Saisissez un page_id Facebook.');
      return;
    }

    setState(() => _isCollectingFacebook = true);
    try {
      final result = await _repository.collectFacebook(pageId: pageId);
      if (!mounted) return;
      _showInfo(
        'Facebook: ${result['records_saved'] ?? 0} enregistrements sauvegardes.',
      );
      await _refreshAll();
    } catch (e) {
      _showError(_mapError(e));
    } finally {
      if (mounted) setState(() => _isCollectingFacebook = false);
    }
  }

  Future<void> _collectGoogleMaps() async {
    final query = _placesQueryController.text.trim();
    if (query.isEmpty) {
      _showError('Saisissez un type de lieu (restaurant, cafe, hotel).');
      return;
    }

    setState(() => _isCollectingMaps = true);
    try {
      final coords = await _resolveCoordinates();
      if (coords == null) {
        if (mounted) setState(() => _isCollectingMaps = false);
        return;
      }

      final placeType = _inferPlaceType(query);
      final result = await _repository.collectGoogleMaps(
        query: query,
        latitude: coords.$1,
        longitude: coords.$2,
        placeType: placeType,
        maxResults: 5,
      );

      if (!mounted) return;
      _showInfo(
        'Google Maps: ${result['records_saved'] ?? 0} lieux sauvegardes.',
      );
      setState(() => _sourceFilter = 'google_maps');
      await _refreshAll();
    } catch (e) {
      _showError(_mapError(e));
    } finally {
      if (mounted) setState(() => _isCollectingMaps = false);
    }
  }

  Future<(double, double)?> _resolveCoordinates() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      _showError('Activez la localisation pour collecter les lieux proches.');
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showError('Permission localisation refusee.');
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return (position.latitude, position.longitude);
  }

  String _inferPlaceType(String query) {
    final q = query.toLowerCase();
    if (q.contains('hotel') || q.contains('hôtel')) return 'lodging';
    if (q.contains('cafe') || q.contains('café')) return 'cafe';
    return 'restaurant';
  }

  String _mapError(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      if (statusCode == 401) {
        return 'Session expiree. Reconnectez-vous pour utiliser DataHub.';
      }
      if (data is Map && data['error'] is String) {
        return data['error'] as String;
      }
      if (data is Map) {
        for (final value in data.values) {
          if (value is List && value.isNotEmpty && value.first is String) {
            return value.first as String;
          }
          if (value is String && value.trim().isNotEmpty) {
            return value;
          }
        }
      }
      return error.message ?? 'Erreur reseau DataHub.';
    }
    return error.toString();
  }

  void _showInfo(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red[700]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DataHub'),
        actions: [
          IconButton(
            tooltip: 'Rafraichir',
            onPressed: _refreshAll,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCollectorCard(
            isDark: isDark,
            title: 'Collecte YouTube',
            subtitle: 'Ex: hotel dakar, restaurant abidjan',
            controller: _youtubeQueryController,
            hint: 'Requete YouTube',
            onCollect: _collectYoutube,
            isLoading: _isCollectingYoutube,
            color: DesignColors.generative,
            icon: Icons.ondemand_video_rounded,
          ),
          const SizedBox(height: 12),
          _buildCollectorCard(
            isDark: isDark,
            title: 'Collecte Facebook',
            subtitle: 'Utiliser un page_id public',
            controller: _facebookPageIdController,
            hint: 'Page ID Facebook',
            onCollect: _collectFacebook,
            isLoading: _isCollectingFacebook,
            color: const Color(0xFF1877F2),
            icon: Icons.facebook_rounded,
          ),
          const SizedBox(height: 12),
          _buildCollectorCard(
            isDark: isDark,
            title: 'Collecte Google Maps',
            subtitle: 'Lieux proches de votre position actuelle',
            controller: _placesQueryController,
            hint: 'Ex: restaurant, cafe, hotel',
            onCollect: _collectGoogleMaps,
            isLoading: _isCollectingMaps,
            color: const Color(0xFF34A853),
            icon: Icons.place_rounded,
          ),
          const SizedBox(height: 12),
          _buildSummaryCards(isDark),
          const SizedBox(height: 20),
          _buildSectionHeader(
            title: 'Jobs DataHub',
            trailing: _isLoadingJobs
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('${_jobs.length} jobs'),
          ),
          const SizedBox(height: 8),
          _buildJobsList(isDark),
          const SizedBox(height: 20),
          _buildSectionHeader(
            title: 'Records collectes',
            trailing: DropdownButton<String>(
              value: _sourceFilter,
              items: const [
                DropdownMenuItem(value: 'youtube', child: Text('YouTube')),
                DropdownMenuItem(value: 'facebook', child: Text('Facebook')),
                DropdownMenuItem(
                    value: 'google_maps', child: Text('Google Maps')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _sourceFilter = value);
                _loadRecords();
              },
            ),
          ),
          const SizedBox(height: 8),
          _buildRecordsList(isDark),
        ],
      ),
    );
  }

  Widget _buildCollectorCard({
    required bool isDark,
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required String hint,
    required VoidCallback onCollect,
    required bool isLoading,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? DesignColors.surfaceDark : DesignColors.surfaceLight,
        borderRadius: DesignRadius.radiusLg,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onCollect,
              icon: isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded),
              label: Text(isLoading ? 'Collecte...' : 'Lancer la collecte'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      {required String title, required Widget trailing}) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        trailing,
      ],
    );
  }

  Widget _buildJobsList(bool isDark) {
    if (_isLoadingJobs) {
      return const SizedBox.shrink();
    }
    if (_jobs.isEmpty) {
      return const ListTile(
        title: Text('Aucun job DataHub pour le moment.'),
      );
    }

    return Column(
      children: _jobs.take(10).map((job) {
        final map =
            job is Map ? Map<String, dynamic>.from(job) : <String, dynamic>{};
        final status = (map['status'] ?? 'unknown').toString();
        final isSuccess = status == 'success';
        final isFailed = status == 'failed';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color:
                isDark ? DesignColors.surfaceDark : DesignColors.surfaceLight,
            borderRadius: DesignRadius.radiusMd,
            border: Border.all(
              color: isFailed
                  ? Colors.red.withValues(alpha: 0.3)
                  : isSuccess
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.orange.withValues(alpha: 0.3),
            ),
          ),
          child: ListTile(
            dense: true,
            leading: CircleAvatar(
              backgroundColor: isFailed
                  ? Colors.red.withValues(alpha: 0.12)
                  : isSuccess
                      ? Colors.green.withValues(alpha: 0.12)
                      : Colors.orange.withValues(alpha: 0.12),
              child: Icon(
                isFailed
                    ? Icons.error_outline_rounded
                    : isSuccess
                        ? Icons.check_circle_outline_rounded
                        : Icons.timelapse_rounded,
                color: isFailed
                    ? Colors.red
                    : isSuccess
                        ? Colors.green
                        : Colors.orange,
                size: 18,
              ),
            ),
            title: Text(
              '${map['source'] ?? '-'} • ${map['query'] ?? ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              'status: $status • saved: ${map['records_count'] ?? 0} • ${_shortDate(map['started_at'])}',
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecordsList(bool isDark) {
    if (_isLoadingRecords) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_records.isEmpty) {
      return const ListTile(
        title: Text('Aucun record pour cette source.'),
      );
    }

    return Column(
      children: _records.take(20).map((record) {
        final map = record is Map
            ? Map<String, dynamic>.from(record)
            : <String, dynamic>{};

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color:
                isDark ? DesignColors.surfaceDark : DesignColors.surfaceLight,
            borderRadius: DesignRadius.radiusMd,
            border: Border.all(
              color: (map['source'] == 'youtube'
                      ? DesignColors.generative
                      : map['source'] == 'google_maps'
                          ? const Color(0xFF34A853)
                          : const Color(0xFF1877F2))
                  .withValues(alpha: 0.18),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: (map['source'] == 'youtube'
                                ? DesignColors.generative
                                : map['source'] == 'google_maps'
                                    ? const Color(0xFF34A853)
                                    : const Color(0xFF1877F2))
                            .withValues(alpha: 0.12),
                        borderRadius: DesignRadius.radiusFull,
                      ),
                      child: Text(
                        (map['source'] ?? '').toString().toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _shortDate(map['collected_at']),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  (map['title'] ?? map['external_id'] ?? '').toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  (map['author'] ?? map['text'] ?? '').toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _buildRecordChips(map),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryCards(bool isDark) {
    final totalRecords = _records.length;
    final totalJobs = _jobs.length;
    final successJobs = _jobs.where((job) {
      final map =
          job is Map ? Map<String, dynamic>.from(job) : <String, dynamic>{};
      return map['status'] == 'success';
    }).length;

    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            isDark: isDark,
            title: 'Records',
            value: '$totalRecords',
            icon: Icons.dataset_rounded,
            color: DesignColors.generative,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            isDark: isDark,
            title: 'Jobs',
            value: '$totalJobs',
            icon: Icons.work_history_rounded,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            isDark: isDark,
            title: 'Succes',
            value: '$successJobs',
            icon: Icons.check_circle_rounded,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required bool isDark,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? DesignColors.surfaceDark : DesignColors.surfaceLight,
        borderRadius: DesignRadius.radiusMd,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
          Text(title, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }

  List<Widget> _buildRecordChips(Map<String, dynamic> map) {
    final metadata = map['metadata'] is Map
        ? Map<String, dynamic>.from(map['metadata'] as Map)
        : <String, dynamic>{};

    final chips = <Widget>[];
    if ((map['source'] ?? '').toString() == 'youtube') {
      chips.add(
          _metricChip('Views', _formatCount(_readInt(metadata['view_count']))));
      chips.add(
          _metricChip('Likes', _formatCount(_readInt(metadata['like_count']))));
      chips.add(_metricChip(
          'Comments', _formatCount(_readInt(metadata['comment_count']))));
      final published = (metadata['published_at'] ?? '').toString();
      if (published.isNotEmpty) {
        chips.add(_metricChip('Publie', _shortDate(published)));
      }
    } else if ((map['source'] ?? '').toString() == 'facebook') {
      chips.add(_metricChip(
          'Reactions', _formatCount(_readInt(metadata['reactions_count']))));
      chips.add(_metricChip(
          'Comments', _formatCount(_readInt(metadata['comments_count']))));
      chips.add(_metricChip(
          'Shares', _formatCount(_readInt(metadata['shares_count']))));
      final created = (metadata['created_time'] ?? '').toString();
      if (created.isNotEmpty) {
        chips.add(_metricChip('Cree', _shortDate(created)));
      }
    } else {
      chips.add(_metricChip('Note', (metadata['rating'] ?? 'N/A').toString()));
      chips.add(_metricChip(
          'Avis', _formatCount(_readInt(metadata['user_ratings_total']))));
      final openNow = metadata['open_now'];
      if (openNow is bool) {
        chips.add(_metricChip('Ouvert', openNow ? 'Oui' : 'Non'));
      }
      final address =
          (metadata['formatted_address'] ?? metadata['vicinity'] ?? '')
              .toString();
      if (address.isNotEmpty) {
        chips.add(_metricChip('Adresse',
            address.length > 20 ? '${address.substring(0, 20)}...' : address));
      }
    }
    return chips;
  }

  Widget _metricChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: DesignColors.primary.withValues(alpha: 0.08),
        borderRadius: DesignRadius.radiusFull,
      ),
      child:
          Text('$label: $value', style: Theme.of(context).textTheme.labelSmall),
    );
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse((value ?? '0').toString()) ?? 0;
  }

  String _formatCount(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return '$value';
  }

  String _shortDate(dynamic value) {
    final raw = (value ?? '').toString();
    if (raw.isEmpty) return '--';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

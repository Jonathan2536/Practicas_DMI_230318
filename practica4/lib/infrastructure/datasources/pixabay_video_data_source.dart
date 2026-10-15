import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:practica4/config/environment/app_config.dart';
import 'package:practica4/domain/datasources/video_post_data_source.dart';
import 'package:practica4/domain/entities/video_post.dart';
import 'package:practica4/infrastructure/datasources/video_source_api_exception.dart';

class PixabayVideoDataSource implements VideoPostDataSource {
  PixabayVideoDataSource({
    AppConfig? config,
    http.Client? client,
    this.searchTerms = 'nature vertical',
    this.perPage = 20,
    this.cacheDuration = const Duration(minutes: 30),
    DateTime Function()? clock,
  }) : _config = config ?? AppConfig.instance,
       _client = client ?? http.Client(),
       _clock = clock ?? DateTime.now {
    assert(searchTerms != '');
    assert(perPage > 0 && perPage <= 200);
    assert(cacheDuration > Duration.zero);
  }

  static final Uri _endpoint = Uri.https('pixabay.com', '/api/videos/');
  static const _sourceName = 'Pixabay';
  static const _requestTimeout = Duration(seconds: 15);

  final AppConfig _config;
  final http.Client _client;
  final DateTime Function() _clock;
  final String searchTerms;
  final int perPage;
  final Duration cacheDuration;

  List<VideoPost>? _cachedVideos;
  DateTime? _cachedAt;
  Future<List<VideoPost>>? _pendingRequest;

  @override
  Future<List<VideoPost>> getVideoPosts() async {
    final cachedVideos = _cachedVideos;
    final cachedAt = _cachedAt;
    if (cachedVideos != null &&
        cachedAt != null &&
        _clock().difference(cachedAt) < cacheDuration) {
      return cachedVideos;
    }

    final pendingRequest = _pendingRequest;
    if (pendingRequest != null) return pendingRequest;

    final request = _fetchAndCache();
    _pendingRequest = request;
    try {
      return await request;
    } finally {
      if (identical(_pendingRequest, request)) _pendingRequest = null;
    }
  }

  Future<List<VideoPost>> _fetchAndCache() async {
    late final String apiKey;
    try {
      apiKey = _config.pixabayApiKey;
    } on MissingAppConfigurationException catch (error) {
      throw UnconfiguredVideoDataSourceException(_sourceName, error.message);
    }

    final uri = _endpoint.replace(
      queryParameters: {
        'key': apiKey,
        'q': searchTerms,
        'per_page': '$perPage',
        'safesearch': 'true',
      },
    );
    late final http.Response response;
    try {
      response = await _client.get(uri).timeout(_requestTimeout);
    } on http.ClientException {
      throw const VideoSourceApiException(
        _sourceName,
        'The request failed. Check your network connection.',
        kind: VideoSourceFailureKind.network,
      );
    } on TimeoutException {
      throw const VideoSourceApiException(
        _sourceName,
        'The request timed out. Try again when the network is available.',
        kind: VideoSourceFailureKind.network,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final isRateLimited = response.statusCode == 429;
      final isAuthenticationFailure =
          response.statusCode == 400 || response.statusCode == 401;
      final kind = isRateLimited
          ? VideoSourceFailureKind.rateLimited
          : isAuthenticationFailure
          ? VideoSourceFailureKind.authentication
          : VideoSourceFailureKind.http;
      final message = isRateLimited
          ? 'Pixabay request limit was reached.'
          : isAuthenticationFailure
          ? 'Pixabay rejected the API key or request.'
          : 'Pixabay returned HTTP ${response.statusCode}.';
      throw VideoSourceApiException(
        _sourceName,
        message,
        kind: kind,
        statusCode: response.statusCode,
      );
    }

    final payload = decodeJsonObject(response.body, _sourceName);
    final responseVideos = payload['hits'] ?? payload['videos'];
    if (responseVideos is! List) {
      final responseFields = payload.keys.toList()..sort();
      throw VideoSourceApiException(
        _sourceName,
        'The response did not contain a video results list '
        '(fields: ${responseFields.join(', ')}).',
        kind: VideoSourceFailureKind.invalidResponse,
      );
    }

    final candidates = <_PixabayCandidate>[];
    for (var index = 0; index < responseVideos.length; index++) {
      final candidate = _mapVideo(responseVideos[index], index);
      if (candidate != null) candidates.add(candidate);
    }
    candidates.sort((first, second) {
      final portraitComparison = (second.isPortrait ? 1 : 0).compareTo(
        first.isPortrait ? 1 : 0,
      );
      return portraitComparison != 0
          ? portraitComparison
          : first.index.compareTo(second.index);
    });

    final videos = List<VideoPost>.unmodifiable(
      candidates.map((candidate) => candidate.video),
    );
    _cachedVideos = videos;
    _cachedAt = _clock();
    return videos;
  }

  _PixabayCandidate? _mapVideo(Object? value, int index) {
    final item = jsonObject(value);
    if (item == null) return null;
    final videoId = item['id'];
    if (videoId is! int && videoId is! String) return null;
    final variants = jsonObject(item['videos']);
    if (variants == null) return null;

    VideoPost? video;
    for (final variantName in ['medium', 'small', 'tiny', 'large']) {
      final variant = jsonObject(variants[variantName]);
      final url = validHttpUrl(variant?['url']);
      if (url == null || !Uri.parse(url).path.toLowerCase().endsWith('.mp4')) {
        continue;
      }
      video = _createVideo(item, variant!, url, videoId.toString());
      break;
    }
    if (video == null) return null;
    return _PixabayCandidate(
      index,
      video,
      video.height != null &&
          video.width != null &&
          video.height! > video.width!,
    );
  }

  VideoPost _createVideo(
    Map<String, dynamic> item,
    Map<String, dynamic> variant,
    String url,
    String videoId,
  ) {
    final tags = item['tags'] is String ? (item['tags'] as String).trim() : '';
    final user = item['user'] is String ? (item['user'] as String).trim() : '';
    final pageUrl = validHttpUrl(item['pageURL']);
    final attributionParts = <String>[];
    if (user.isNotEmpty) attributionParts.add('Video by $user');
    attributionParts.add('Pixabay');
    if (pageUrl != null) attributionParts.add(pageUrl);

    return VideoPost(
      id: 'pixabay:$videoId',
      caption: tags.isEmpty ? 'Video from Pixabay' : tags,
      description: tags.isEmpty ? null : tags,
      tags: tags.isEmpty ? null : tags,
      videoUrl: url,
      source: VideoSourceType.pixabay,
      providerId: videoId,
      thumbnailUrl: validHttpUrl(item['picture']),
      attribution: attributionParts.join(' • '),
      durationSeconds: _positiveInt(item['duration']),
      width: _positiveInt(variant['width']),
      height: _positiveInt(variant['height']),
    );
  }

  int? _positiveInt(Object? value) {
    final parsed = value is int ? value : int.tryParse('$value');
    return parsed != null && parsed > 0 ? parsed : null;
  }
}

class _PixabayCandidate {
  const _PixabayCandidate(this.index, this.video, this.isPortrait);

  final int index;
  final VideoPost video;
  final bool isPortrait;
}

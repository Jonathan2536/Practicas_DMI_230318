import 'dart:async';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'package:practica4/config/environment/app_config.dart';
import 'package:practica4/config/helpers/vimeo_video_id.dart';
import 'package:practica4/domain/datasources/video_post_data_source.dart';
import 'package:practica4/domain/entities/video_post.dart';
import 'package:practica4/infrastructure/datasources/video_source_api_exception.dart';

class VimeoVideoDataSource implements VideoPostDataSource {
  VimeoVideoDataSource({AppConfig? config, http.Client? client})
    : _config = config ?? AppConfig.instance,
      _client = client ?? http.Client();

  static const _sourceName = 'Vimeo';
  static const _requestTimeout = Duration(seconds: 15);

  final AppConfig _config;
  final http.Client _client;

  @override
  Future<List<VideoPost>> getVideoPosts() async {
    final urls = _config.vimeoVideoUrls;
    if (urls.isEmpty) return const [];

    final videos = <VideoPost>[];
    final failures = <Object>[];
    for (final url in urls) {
      final videoId = vimeoVideoIdFromUrl(url);
      if (videoId == null) {
        failures.add(
          const VideoSourceApiException(
            _sourceName,
            'A configured URL is not a supported Vimeo video URL.',
            kind: VideoSourceFailureKind.invalidResponse,
          ),
        );
        continue;
      }

      try {
        final response = await _get(_oEmbedUri(url));
        final payload = decodeJsonObject(response.body, _sourceName);
        videos.add(_mapVideo(url, videoId, payload));
      } on VideoSourceApiException catch (error) {
        failures.add(error);
      }
    }

    if (videos.isEmpty && failures.isNotEmpty) {
      throw VideoDataSourceFailuresException(_sourceName, failures);
    }
    for (final failure in failures) {
      developer.log(
        'A Vimeo video could not be loaded; keeping other videos.',
        name: 'VimeoVideoDataSource',
        error: failure,
        level: 900,
      );
    }
    return List<VideoPost>.unmodifiable(videos);
  }

  Uri _oEmbedUri(String videoUrl) => Uri.https(
    'vimeo.com',
    '/api/oembed.json',
    {'url': videoUrl},
  );

  Future<http.Response> _get(Uri uri) async {
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
      throw VideoSourceApiException(
        _sourceName,
        'Vimeo oEmbed returned HTTP ${response.statusCode}.',
        kind: response.statusCode == 401 || response.statusCode == 403
            ? VideoSourceFailureKind.accessDenied
            : VideoSourceFailureKind.http,
        statusCode: response.statusCode,
      );
    }
    return response;
  }

  VideoPost _mapVideo(
    String url,
    String videoId,
    Map<String, dynamic> payload,
  ) {
    final title = _nonEmptyString(payload['title']);
    if (title == null) {
      throw const VideoSourceApiException(
        _sourceName,
        'Vimeo oEmbed did not return a video title.',
        kind: VideoSourceFailureKind.invalidResponse,
      );
    }
    final author = _nonEmptyString(payload['author_name']);

    return VideoPost(
      id: 'vimeo:$videoId',
      caption: title,
      videoUrl: url,
      source: VideoSourceType.vimeo,
      providerId: videoId,
      thumbnailUrl: validHttpUrl(payload['thumbnail_url']),
      attribution: author == null ? 'Vimeo' : '$author • Vimeo',
      description: _nonEmptyString(payload['description']),
      durationSeconds: _positiveInt(payload['duration']),
      width: _positiveInt(payload['width']),
      height: _positiveInt(payload['height']),
    );
  }

  String? _nonEmptyString(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  int? _positiveInt(Object? value) {
    final parsed = value is int ? value : int.tryParse('$value');
    return parsed != null && parsed > 0 ? parsed : null;
  }
}

class VideoDataSourceFailuresException implements Exception {
  const VideoDataSourceFailuresException(this.source, this.failures);

  final String source;
  final List<Object> failures;

  @override
  String toString() =>
      '$source failed to load all configured videos: ${failures.join('; ')}';
}

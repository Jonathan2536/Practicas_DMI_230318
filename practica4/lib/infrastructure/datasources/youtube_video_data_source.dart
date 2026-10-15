import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:practica4/config/environment/app_config.dart';
import 'package:practica4/domain/datasources/video_post_data_source.dart';
import 'package:practica4/domain/entities/video_post.dart';
import 'package:practica4/infrastructure/datasources/video_source_api_exception.dart';

class YouTubeVideoDataSource implements VideoPostDataSource {
  YouTubeVideoDataSource({
    AppConfig? config,
    http.Client? client,
    this.maxPages = 5,
  }) : _config = config ?? AppConfig.instance,
       _client = client ?? http.Client() {
    assert(maxPages > 0);
  }

  static final Uri _endpoint = Uri.https(
    'www.googleapis.com',
    '/youtube/v3/playlistItems',
  );

  static const _sourceName = 'YouTube';
  static const _requestTimeout = Duration(seconds: 15);

  final AppConfig _config;
  final http.Client _client;
  final int maxPages;

  @override
  Future<List<VideoPost>> getVideoPosts() async {
    late final String apiKey;
    late final String playlistId;
    try {
      apiKey = _config.youtubeApiKey;
      playlistId = _config.youtubePlaylistId;
    } on MissingAppConfigurationException catch (error) {
      throw UnconfiguredVideoDataSourceException(_sourceName, error.message);
    }

    final videos = <VideoPost>[];
    String? pageToken;

    for (var page = 0; page < maxPages; page++) {
      final query = <String, String>{
        'part': 'snippet,contentDetails',
        'maxResults': '50',
        'playlistId': playlistId,
        'key': apiKey,
        'pageToken': ?pageToken,
      };
      final uri = _endpoint.replace(queryParameters: query);
      final response = await _get(uri);
      final payload = decodeJsonObject(response.body, _sourceName);
      final items = payload['items'];
      if (items is! List) {
        throw const VideoSourceApiException(
          _sourceName,
          'The playlist response did not contain an items list.',
          kind: VideoSourceFailureKind.invalidResponse,
        );
      }

      for (final item in items) {
        final video = _mapPlaylistItem(item);
        videos.addAll([?video]);
      }

      final nextPageToken = payload['nextPageToken'];
      if (nextPageToken is! String || nextPageToken.isEmpty) break;
      pageToken = nextPageToken;
    }

    return List<VideoPost>.unmodifiable(videos);
  }

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
      final reason = _youtubeErrorReason(response.body);
      final kind = switch (reason) {
        'quotaExceeded' || 'dailyLimitExceeded' =>
          VideoSourceFailureKind.quotaExceeded,
        'keyInvalid' || 'ipRefererBlocked' =>
          VideoSourceFailureKind.authentication,
        'playlistNotFound' || 'forbidden' =>
          VideoSourceFailureKind.accessDenied,
        _ when response.statusCode == 403 =>
          VideoSourceFailureKind.accessDenied,
        _ => VideoSourceFailureKind.http,
      };
      final message = switch (kind) {
        VideoSourceFailureKind.quotaExceeded =>
          'YouTube API quota has been exceeded.',
        VideoSourceFailureKind.authentication =>
          'YouTube rejected the API key. Check its validity and API restrictions.',
        VideoSourceFailureKind.accessDenied =>
          'YouTube denied access to the playlist or API request.',
        _ => 'YouTube returned HTTP ${response.statusCode}.',
      };
      throw VideoSourceApiException(
        _sourceName,
        message,
        kind: kind,
        statusCode: response.statusCode,
      );
    }

    return response;
  }

  VideoPost? _mapPlaylistItem(Object? value) {
    final item = jsonObject(value);
    final snippet = jsonObject(item?['snippet']);
    final contentDetails = jsonObject(item?['contentDetails']);
    final resourceId = jsonObject(snippet?['resourceId']);
    final videoId = _nonEmptyString(contentDetails?['videoId']) ??
        _nonEmptyString(resourceId?['videoId']);
    final title = _nonEmptyString(snippet?['title']);

    if (videoId == null ||
        title == null ||
        title.toLowerCase() == 'private video' ||
        title.toLowerCase() == 'deleted video') {
      return null;
    }

    return VideoPost(
      id: 'youtube:$videoId',
      caption: title,
      description: _nonEmptyString(snippet?['description']),
      videoUrl: 'https://www.youtube.com/watch?v=$videoId',
      source: VideoSourceType.youtube,
      providerId: videoId,
      thumbnailUrl: _bestThumbnail(snippet?['thumbnails']),
      attribution: _nonEmptyString(snippet?['videoOwnerChannelTitle']) ??
          _nonEmptyString(snippet?['channelTitle']),
    );
  }

  String? _bestThumbnail(Object? value) {
    final thumbnails = jsonObject(value);
    for (final size in ['maxres', 'standard', 'high', 'medium', 'default']) {
      final thumbnail = jsonObject(thumbnails?[size]);
      final url = validHttpUrl(thumbnail?['url']);
      if (url != null) return url;
    }
    return null;
  }

  String? _youtubeErrorReason(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;
      final error = jsonObject(decoded['error']);
      final errors = error?['errors'];
      if (errors is! List || errors.isEmpty) return null;
      return _nonEmptyString(jsonObject(errors.first)?['reason']);
    } on FormatException {
      return null;
    }
  }

  String? _nonEmptyString(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:practica4/domain/entities/video_post.dart';
import 'package:practica4/domain/repositories/video_post_repository.dart';
import 'package:practica4/domain/services/local_storage_service.dart';

class DiscoverProvider extends ChangeNotifier {
  DiscoverProvider(this._repository, this._storage);

  final VideoPostRepository _repository;
  final LocalStorageService _storage;
  final Set<String> _pendingLikeUpdates = {};
  final Set<String> _pendingFavoriteUpdates = {};
  final Set<String> _unsupportedVideoIds = {};

  bool initialLoading = true;
  bool _loadingInProgress = false;
  List<VideoPost> videos = [];
  String? loadError;
  List<VideoPostSourceFailure> sourceFailures = const [];

  List<VideoPost> get forYouVideos {
    final recommendedVideos = List<VideoPost>.of(videos);
    recommendedVideos.sort((first, second) {
      final viewsComparison = second.views.compareTo(first.views);
      if (viewsComparison != 0) return viewsComparison;

      final likesComparison = second.likes.compareTo(first.likes);
      if (likesComparison != 0) return likesComparison;

      return first.id.compareTo(second.id);
    });
    return recommendedVideos;
  }

  List<VideoPost> get favoriteVideos =>
      videos.where((video) => video.isFavorite).toList();

  Future<void> loadNextPage() async {
    if (_loadingInProgress) return;
    _loadingInProgress = true;
    final repository = _repository;
    final diagnostics = repository is VideoPostRepositoryDiagnostics
        ? repository as VideoPostRepositoryDiagnostics
        : null;
    loadError = null;
    sourceFailures = diagnostics?.lastSourceFailures ?? const [];
    try {
      final newVideos = await repository.getVideoPosts();
      final restoredVideos = await Future.wait(
        newVideos.map((video) async {
          final videoWithLike = await _restoreLikeState(video);
          return _restoreFavoriteState(videoWithLike);
        }),
      );
      videos = restoredVideos
          .where((video) => !_unsupportedVideoIds.contains(video.id))
          .toList(growable: false);
      sourceFailures = diagnostics?.lastSourceFailures ?? const [];
    } catch (error, stackTrace) {
      loadError = 'No se pudieron cargar los videos. Revisa tu conexión e inténtalo de nuevo.';
      sourceFailures = diagnostics?.lastSourceFailures ?? const [];
      developer.log(
        'Initial video loading failed (${error.runtimeType}).',
        name: 'DiscoverProvider',
        stackTrace: stackTrace,
        level: 1000,
      );
    } finally {
      initialLoading = false;
      _loadingInProgress = false;
      notifyListeners();
    }
  }

  bool isLikeUpdatePending(String videoId) =>
      _pendingLikeUpdates.contains(videoId);

  Future<void> toggleLike(String videoId) async {
    if (_pendingLikeUpdates.contains(videoId)) return;

    final videoIndex = videos.indexWhere((video) => video.id == videoId);
    if (videoIndex == -1) {
      throw ArgumentError.value(videoId, 'videoId', 'Video was not found.');
    }

    final currentVideo = videos[videoIndex];
    final updatedVideo = currentVideo.copyWith(
      isLiked: !currentVideo.isLiked,
      likes: currentVideo.likes + (currentVideo.isLiked ? -1 : 1),
    );

    _pendingLikeUpdates.add(videoId);
    videos[videoIndex] = updatedVideo;
    notifyListeners();

    try {
      await _storage.setString(
        _storageKey(videoId),
        jsonEncode({
          'isLiked': updatedVideo.isLiked,
          'likes': updatedVideo.likes,
        }),
      );
    } catch (_) {
      videos[videoIndex] = currentVideo;
      notifyListeners();
      rethrow;
    } finally {
      _pendingLikeUpdates.remove(videoId);
      notifyListeners();
    }
  }

  bool isFavoriteUpdatePending(String videoId) =>
      _pendingFavoriteUpdates.contains(videoId);

  void excludeUnsupportedVideo(String videoId) {
    if (!videos.any((video) => video.id == videoId)) return;
    if (!_unsupportedVideoIds.add(videoId)) return;

    videos = videos
        .where((video) => video.id != videoId)
        .toList(growable: false);
    notifyListeners();
  }

  Future<void> toggleFavorite(String videoId) async {
    if (_pendingFavoriteUpdates.contains(videoId)) return;

    final videoIndex = videos.indexWhere((video) => video.id == videoId);
    if (videoIndex == -1) {
      throw ArgumentError.value(videoId, 'videoId', 'Video was not found.');
    }

    final currentVideo = videos[videoIndex];
    final updatedVideo = currentVideo.copyWith(
      isFavorite: !currentVideo.isFavorite,
    );

    _pendingFavoriteUpdates.add(videoId);
    videos[videoIndex] = updatedVideo;
    notifyListeners();

    try {
      await _storage.setBool(
        _favoriteStorageKey(videoId),
        updatedVideo.isFavorite,
      );
    } catch (_) {
      videos[videoIndex] = currentVideo;
      notifyListeners();
      rethrow;
    } finally {
      _pendingFavoriteUpdates.remove(videoId);
      notifyListeners();
    }
  }

  Future<VideoPost> _restoreLikeState(VideoPost video) async {
    final storedValue = await _storage.getString(_storageKey(video.id));
    if (storedValue == null) return video;

    final decoded = jsonDecode(storedValue);
    if (decoded is! Map<String, dynamic> ||
        decoded['isLiked'] is! bool ||
        decoded['likes'] is! int ||
        (decoded['isLiked'] as bool && (decoded['likes'] as int) < 1) ||
        (decoded['likes'] as int) < 0) {
      throw FormatException(
        'Invalid stored like state for video "${video.id}".',
      );
    }

    return video.copyWith(
      isLiked: decoded['isLiked'] as bool,
      likes: decoded['likes'] as int,
    );
  }

  Future<VideoPost> _restoreFavoriteState(VideoPost video) async {
    final isFavorite = await _storage.getBool(_favoriteStorageKey(video.id));
    if (isFavorite == null) return video;

    return video.copyWith(isFavorite: isFavorite);
  }

  String _storageKey(String videoId) => 'video_like_$videoId';

  String _favoriteStorageKey(String videoId) => 'video_favorite_$videoId';
}

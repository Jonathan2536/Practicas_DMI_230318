import 'dart:convert';

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

  bool initialLoading = true;
  List<VideoPost> videos = [];

  Future<void> loadNextPage() async {
    final newVideos = await _repository.getVideoPosts();
    videos = await Future.wait(
      newVideos.map((video) async {
        final videoWithLike = await _restoreLikeState(video);
        return _restoreFavoriteState(videoWithLike);
      }),
    );
    initialLoading = false;
    notifyListeners();
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
      await _storage.setBool(_favoriteStorageKey(videoId), updatedVideo.isFavorite);
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
      throw FormatException('Invalid stored like state for video "${video.id}".');
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

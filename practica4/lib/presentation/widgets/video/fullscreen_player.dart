import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:practica4/domain/entities/video_post.dart';
import 'package:practica4/presentation/providers/discover_provider.dart';
import 'package:practica4/presentation/widgets/shared/video_buttons.dart';
import 'package:practica4/presentation/widgets/video/video_background.dart';
import 'package:practica4/presentation/widgets/video/video_caption.dart';

const _videoUnavailableMessage =
    'Este video no está disponible. Prueba con otro video.';

class FullScreenPlayer extends StatefulWidget {
  final VideoPost videoPost;
  final bool isActive;

  const FullScreenPlayer({
    super.key,
    required this.videoPost,
    required this.isActive,
  });

  @override
  State<FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends State<FullScreenPlayer> {
  late VideoPlayerController controller;
  late Future<void> _initializeFuture;
  bool _isMuted = false;
  bool _isPlaying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoPost.videoUrl),
    );
    controller.addListener(_onControllerChanged);
    _initializeFuture = _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      await controller.initialize();
      if (!mounted) return;

      await controller.setLooping(true);
      await controller.setVolume(_isMuted ? 0 : 1);
      if (widget.isActive && mounted) {
        await _VideoPlaybackCoordinator.activate(
          controller,
          isStillActive: () => mounted && widget.isActive,
        );
      }
    } catch (error, stackTrace) {
      _showControllerError(error, stackTrace);
    }
  }

  void _onControllerChanged() {
    if (!mounted) return;

    final hasError = controller.value.hasError;
    final errorDescription = controller.value.errorDescription;
    if (hasError && _errorMessage == null) {
      developer.log(
        'Video player reported a playback error.',
        name: 'FullScreenPlayer',
        error: errorDescription,
      );
    }
    final errorMessage = hasError ? _videoUnavailableMessage : null;
    final isMuted = controller.value.volume == 0;
    final isPlaying = controller.value.isPlaying;
    if (_errorMessage == errorMessage &&
        _isMuted == isMuted &&
        _isPlaying == isPlaying) {
      return;
    }

    setState(() {
      _errorMessage = errorMessage;
      _isMuted = isMuted;
      _isPlaying = isPlaying;
    });
  }

  Future<void> _toggleMute() async {
    if (!controller.value.isInitialized) return;

    final shouldMute = controller.value.volume > 0;
    try {
      await controller.setVolume(shouldMute ? 0 : 1);
      if (!mounted) return;
      setState(() => _isMuted = shouldMute);
    } catch (error, stackTrace) {
      _showOperationError(error, stackTrace);
    }
  }

  Future<void> _togglePlayback() async {
    if (!widget.isActive || !controller.value.isInitialized) return;

    try {
      if (controller.value.isPlaying) {
        await _VideoPlaybackCoordinator.deactivate(controller);
      } else {
        await _VideoPlaybackCoordinator.activate(
          controller,
          isStillActive: () => mounted && widget.isActive,
        );
      }
    } catch (error, stackTrace) {
      _showOperationError(error, stackTrace);
    }
  }

  Future<void> _syncPlaybackWithActiveState() async {
    if (!controller.value.isInitialized) return;

    try {
      if (widget.isActive) {
        await _VideoPlaybackCoordinator.activate(
          controller,
          isStillActive: () => mounted && widget.isActive,
        );
      } else {
        await _VideoPlaybackCoordinator.deactivate(controller);
      }
    } catch (error, stackTrace) {
      _showOperationError(error, stackTrace);
    }
  }

  void _showControllerError(Object error, StackTrace stackTrace) {
    developer.log(
      'Video playback operation failed.',
      name: 'FullScreenPlayer',
      error: error,
      stackTrace: stackTrace,
    );
    if (!mounted) return;
    setState(() => _errorMessage = _videoUnavailableMessage);
  }

  void _showOperationError(Object error, StackTrace stackTrace) {
    developer.log(
      'Video playback operation failed.',
      name: 'FullScreenPlayer',
      error: error,
      stackTrace: stackTrace,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo actualizar la reproducción.')),
    );
  }

  @override
  void didUpdateWidget(covariant FullScreenPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      unawaited(_syncPlaybackWithActiveState());
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    unawaited(_disposeController());
    super.dispose();
  }

  Future<void> _disposeController() async {
    try {
      await _VideoPlaybackCoordinator.deactivate(controller);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to pause video before disposing its controller.',
        name: 'FullScreenPlayer',
        error: error,
        stackTrace: stackTrace,
      );
    }

    try {
      await controller.dispose();
    } catch (error, stackTrace) {
      developer.log(
        'Failed to dispose video controller.',
        name: 'FullScreenPlayer',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final discoverProvider = context.watch<DiscoverProvider>();

    return FutureBuilder(
      future: _initializeFuture,
      builder: (context, snapshot) {
        if (_errorMessage != null ||
            (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasError)) {
          return const _VideoPlaybackError();
        }

        if (snapshot.connectionState != ConnectionState.done ||
            !controller.value.isInitialized) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        return GestureDetector(
          onTap: _togglePlayback,
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: Stack(
              children: [
                VideoPlayer(controller),

                // Gradiente
                VideoBackground(stops: const [0.8, 1.0]),

                // Icono de Play (se muestra cuando está pausado)
                if (!_isPlaying)
                  Center(
                    child: Icon(
                      Icons.play_arrow,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),

                // Botones interactivos y mute
                Positioned(
                  bottom: 40,
                  right: 20,
                  child: VideoButtons(
                    video: widget.videoPost,
                    isMuted: _isMuted,
                    onToggleMute: () => unawaited(_toggleMute()),
                    isLikeUpdatePending: discoverProvider.isLikeUpdatePending(
                      widget.videoPost.id,
                    ),
                    onToggleLike: () => _toggleLike(context, discoverProvider),
                    isFavoriteUpdatePending: discoverProvider
                        .isFavoriteUpdatePending(widget.videoPost.id),
                    onToggleFavorite: () =>
                        _toggleFavorite(context, discoverProvider),
                  ),
                ),

                // Texto
                Positioned(
                  bottom: 50,
                  left: 20,
                  child: SizedBox(
                    width: MediaQuery.sizeOf(context).width * 0.6,
                    child: VideoCaption(caption: widget.videoPost.caption),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleLike(
    BuildContext context,
    DiscoverProvider discoverProvider,
  ) async {
    try {
      await discoverProvider.toggleLike(widget.videoPost.id);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el like: $error')),
      );
    }
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    DiscoverProvider discoverProvider,
  ) async {
    try {
      await discoverProvider.toggleFavorite(widget.videoPost.id);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el favorito: $error')),
      );
    }
  }
}

class _VideoPlaybackError extends StatelessWidget {
  const _VideoPlaybackError();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white70, size: 48),
            const SizedBox(height: 12),
            const Text(
              _videoUnavailableMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPlaybackCoordinator {
  static Future<void> _queue = Future<void>.value();
  static VideoPlayerController? _activeController;

  static Future<void> _enqueue(Future<void> Function() operation) {
    final result = _queue.then((_) => operation());
    _queue = result.catchError((Object _) {});
    return result;
  }

  static Future<void> activate(
    VideoPlayerController controller, {
    required bool Function() isStillActive,
  }) {
    return _enqueue(() async {
      if (!isStillActive() || !controller.value.isInitialized) return;

      final activeController = _activeController;
      if (activeController != null && activeController != controller) {
        if (activeController.value.isInitialized &&
            activeController.value.isPlaying) {
          await activeController.pause();
        }
      }

      if (!isStillActive()) return;
      await controller.play();
      _activeController = controller;
    });
  }

  static Future<void> deactivate(VideoPlayerController controller) {
    return _enqueue(() async {
      try {
        if (controller.value.isInitialized && controller.value.isPlaying) {
          await controller.pause();
        }
      } finally {
        if (_activeController == controller) {
          _activeController = null;
        }
      }
    });
  }
}

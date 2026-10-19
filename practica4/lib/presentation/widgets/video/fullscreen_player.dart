import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:practica4/domain/entities/video_post.dart';
import 'package:practica4/presentation/providers/discover_provider.dart';
import 'package:practica4/presentation/widgets/shared/video_buttons.dart';
import 'package:practica4/presentation/widgets/video/video_background.dart';
import 'package:practica4/presentation/widgets/video/video_caption.dart';
import 'package:practica4/presentation/widgets/video/video_playback_helpers.dart';
import 'package:practica4/presentation/widgets/video/vimeo_playback_helpers.dart';
import 'package:practica4/presentation/widgets/video/youtube_playback_helpers.dart';

const _videoUnavailableMessage =
    'Este video no está disponible. Prueba con otro video.';
const _videoStartupTimeoutMessage =
    'El video está tardando demasiado en iniciar. Revisa tu conexión e inténtalo de nuevo.';
const _videoStartupTimeout = Duration(seconds: 30);
const _youtubeCloseTimeout = Duration(seconds: 5);

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
  VideoPlayerController? _videoController;
  VoidCallback? _videoListener;
  YoutubePlayerController? _youtubeController;
  StreamSubscription<YoutubePlayerValue>? _youtubeSubscription;
  WebViewController? _vimeoController;
  Future<void> _playbackTransitionQueue = Future<void>.value();
  Timer? _startupTimer;
  String? _controllerIdentity;
  bool _youtubeReady = false;
  int _generation = 0;
  bool _isLoading = false;
  bool _isMuted = false;
  bool _isPlaying = false;
  bool _youtubePlayRequested = false;
  bool _vimeoReady = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _startPlayback();
  }

  @override
  void didUpdateWidget(covariant FullScreenPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPost.id != widget.videoPost.id ||
        oldWidget.videoPost.source != widget.videoPost.source ||
        oldWidget.videoPost.playbackUrl != widget.videoPost.playbackUrl ||
        oldWidget.videoPost.providerId != widget.videoPost.providerId ||
        oldWidget.isActive != widget.isActive) {
      _schedulePlaybackTransition(startWhenReleased: widget.isActive);
    }
  }

  void _schedulePlaybackTransition({required bool startWhenReleased}) {
    final transitionGeneration = ++_generation;
    final transition = _playbackTransitionQueue.then((_) async {
      await WidgetsBinding.instance.endOfFrame;
      await _releasePlayback();
      if (!mounted ||
          transitionGeneration != _generation ||
          !startWhenReleased ||
          !widget.isActive) {
        return;
      }
      _startPlayback();
    });
    _playbackTransitionQueue = transition.catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      developer.log(
        'Playback transition failed.',
        name: 'FullScreenPlayer',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted && transitionGeneration == _generation) {
        _setError(_videoUnavailableMessage, transitionGeneration);
      }
    });
  }

  void _startPlayback() {
    final generation = ++_generation;
    _startupTimer?.cancel();
    _errorMessage = null;
    _isLoading = true;
    _isPlaying = false;
    _youtubePlayRequested = false;
    _youtubeReady = false;
    _isMuted = videoStartsMuted(widget.videoPost.source);
    _controllerIdentity = _playbackIdentity(widget.videoPost);
    _startupTimer = Timer(_videoStartupTimeout, () {
      if (mounted && generation == _generation && _isLoading) {
        developer.log(
          'Video startup timed out for ${widget.videoPost.source.name}.',
          name: 'FullScreenPlayer',
          level: 900,
        );
        _setError(_videoStartupTimeoutMessage, generation);
      }
    });

    if (widget.videoPost.source == VideoSourceType.youtube) {
      _startYoutubePlayback(generation);
    } else if (widget.videoPost.source == VideoSourceType.vimeo) {
      _startVimeoPlayback(generation);
    } else {
      _startVideoPlayback(generation);
    }

    if (mounted) setState(() {});
  }

  void _startVideoPlayback(int generation) {
    final uri = Uri.tryParse(widget.videoPost.playbackUrl);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      _setError(_videoUnavailableMessage, generation);
      return;
    }

    developer.log(
      'Starting ${widget.videoPost.source.name} playback from ${uri.host}.',
      name: 'FullScreenPlayer',
    );
    final controller = VideoPlayerController.networkUrl(uri);
    _videoController = controller;
    void listener() => _onVideoControllerChanged(controller);

    _videoListener = listener;
    controller.addListener(listener);
    unawaited(_initializeVideoController(controller, generation));
  }

  Future<void> _initializeVideoController(
    VideoPlayerController controller,
    int generation,
  ) async {
    try {
      await controller.initialize().timeout(_videoStartupTimeout);
      if (!_isCurrent(controller, generation)) return;

      await controller.setLooping(true);
      await controller.setVolume(_isMuted ? 0 : 1);
      if (!_isCurrent(controller, generation)) return;

      if (widget.isActive) {
        await _PlaybackCoordinator.activate(
          controller,
          play: controller.play,
          pause: controller.pause,
          isStillActive: () => _isCurrent(controller, generation),
        );
      }
      if (!_isCurrent(controller, generation)) return;
      _startupTimer?.cancel();
      setState(() => _isLoading = false);
    } catch (error, stackTrace) {
      developer.log(
        'Video playback initialization failed for ${widget.videoPost.source.name} '
        'on ${Uri.tryParse(widget.videoPost.playbackUrl)?.host ?? "invalid URL"}.',
        name: 'FullScreenPlayer',
        error: error,
        stackTrace: stackTrace,
      );
      _setError(_videoUnavailableMessage, generation);
    }
  }

  void _onVideoControllerChanged(VideoPlayerController controller) {
    if (!mounted || controller != _videoController) return;

    final hasError = controller.value.hasError;
    if (hasError) {
      final errorDescription = controller.value.errorDescription;
      developer.log(
        'Video player reported an error for ${widget.videoPost.source.name}: '
        '${errorDescription ?? "unknown playback error"}.',
        name: 'FullScreenPlayer',
        level: 1000,
      );
      if (isUnsupportedVideoFormatError(errorDescription)) {
        debugPrint(
          '[Playback] skipping unsupported ${widget.videoPost.source.name} '
          'video ${widget.videoPost.id}',
        );
        developer.log(
          'Skipping video with an unsupported decoder format: '
          '${widget.videoPost.id}.',
          name: 'FullScreenPlayer',
          level: 900,
        );
        context.read<DiscoverProvider>().excludeUnsupportedVideo(
          widget.videoPost.id,
        );
        return;
      }
      _setError(_videoUnavailableMessage, _generation);
      return;
    }

    final muted = controller.value.volume == 0;
    final playing = controller.value.isPlaying;
    if (_isMuted == muted && _isPlaying == playing) return;
    setState(() {
      _isMuted = muted;
      _isPlaying = playing;
    });
  }

  void _startYoutubePlayback(int generation) {
    final videoId = youtubeVideoIdForPlayback(widget.videoPost);
    if (videoId == null) {
      _setError('El identificador de YouTube no es válido.', generation);
      return;
    }

    debugPrint('[YT] creating controller for video $videoId');
    final controller = YoutubePlayerController(
      key: videoId,
      params: const YoutubePlayerParams(
        mute: false,
        showControls: false,
        showFullscreenButton: false,
        enableCaption: true,
      ),
      onWebResourceError: (error) {
        if (!youtubeWebResourceErrorIsFatal(error)) return;
        final host = Uri.tryParse(error.url ?? '')?.host ?? 'unknown';
        debugPrint(
          '[YT] WebView main-frame error: '
          'code=${error.errorCode}, type=${error.errorType}, host=$host',
        );
        _setError(_videoUnavailableMessage, generation);
      },
    );
    _youtubeController = controller;
    _youtubeReady = false;
    _youtubeSubscription = controller.stream.listen(
      (value) => _onYoutubeValueChanged(controller, value, generation),
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('[YT] iframe stream error: $error');
        developer.log(
          'YouTube player state stream failed.',
          name: 'FullScreenPlayer',
          error: error,
          stackTrace: stackTrace,
        );
        _setError(_videoUnavailableMessage, generation);
      },
    );
    unawaited(
      controller.cueVideoById(videoId: videoId).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        debugPrint('[YT] failed to cue video: $error');
        _showOperationError(error, stackTrace);
      }),
    );
  }

  void _startVimeoPlayback(int generation) {
    final embedUri = vimeoEmbedUriForPlayback(widget.videoPost);
    if (embedUri == null) {
      _setError('El identificador de Vimeo no es válido.', generation);
      return;
    }

    _vimeoReady = false;
    final controller = WebViewController();
    _vimeoController = controller;
    unawaited(
      _loadVimeoPlayer(controller, embedUri, generation).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        developer.log(
          'Vimeo WebView initialization failed.',
          name: 'FullScreenPlayer',
          error: error,
          stackTrace: stackTrace,
        );
        _setError(_videoUnavailableMessage, generation);
      }),
    );
  }

  Future<void> _loadVimeoPlayer(
    WebViewController controller,
    Uri embedUri,
    int generation,
  ) async {
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setBackgroundColor(Colors.black);
    await controller.addJavaScriptChannel(
      'Vimeo',
      onMessageReceived: (message) {
        if (message.message == 'ready') {
          _onVimeoReady(controller, generation);
        } else if (message.message == 'error') {
          _setError(_videoUnavailableMessage, generation);
        }
      },
    );
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onWebResourceError: (error) {
          final host = Uri.tryParse(error.url ?? '')?.host ?? '';
          if (error.isForMainFrame == true ||
              host == 'player.vimeo.com' ||
              host.endsWith('.vimeo.com')) {
            _setError(_videoUnavailableMessage, generation);
          }
        },
      ),
    );

    final htmlEmbedUri = embedUri.toString().replaceAll('&', '&amp;');
    await controller.loadHtmlString('''
<!doctype html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
      html, body { margin: 0; padding: 0; width: 100%; height: 100%; background: #000; overflow: hidden; }
      iframe { position: absolute; inset: 0; width: 100%; height: 100%; border: 0; }
    </style>
  </head>
  <body>
    <iframe id="vimeo-player" src="$htmlEmbedUri"
      onload="this.contentWindow.postMessage(JSON.stringify({method: 'addEventListener', value: 'ready'}), 'https://player.vimeo.com');
              this.contentWindow.postMessage(JSON.stringify({method: 'addEventListener', value: 'error'}), 'https://player.vimeo.com');"
      allow="autoplay; fullscreen; picture-in-picture" allowfullscreen></iframe>
    <script>
      window.addEventListener('message', function (event) {
        if (event.origin !== 'https://player.vimeo.com') return;
        try {
          var payload = typeof event.data === 'string'
            ? JSON.parse(event.data)
            : event.data;
          if (payload && payload.event === 'ready') Vimeo.postMessage('ready');
          if (payload && payload.event === 'error') Vimeo.postMessage('error');
        } catch (_) {}
      });
    </script>
  </body>
</html>
''', baseUrl: 'https://vimeo.com');
  }

  void _onVimeoReady(WebViewController controller, int generation) {
    if (!mounted ||
        !widget.isActive ||
        generation != _generation ||
        controller != _vimeoController ||
        _vimeoReady) {
      return;
    }

    _vimeoReady = true;
    setState(() => _isLoading = false);
    unawaited(
      _PlaybackCoordinator.activate(
            controller,
            play: () => _sendVimeoCommand(controller, 'play'),
            pause: () => _sendVimeoCommand(controller, 'pause'),
            isStillActive: () =>
                mounted &&
                widget.isActive &&
                generation == _generation &&
                controller == _vimeoController,
          )
          .then((_) {
            if (mounted &&
                generation == _generation &&
                controller == _vimeoController) {
              setState(() => _isPlaying = true);
            }
          })
          .catchError((Object error, StackTrace stackTrace) {
            developer.log(
              'Vimeo playback could not start.',
              name: 'FullScreenPlayer',
              error: error,
              stackTrace: stackTrace,
            );
            _setError(_videoUnavailableMessage, generation);
          }),
    );
  }

  Future<void> _sendVimeoCommand(
    WebViewController controller,
    String method, {
    double? value,
  }) {
    final message = jsonEncode(jsonEncode({'method': method, 'value': ?value}));
    return controller.runJavaScript(
      'document.getElementById("vimeo-player")?.contentWindow?.postMessage('
      '$message, "*");',
    );
  }

  void _onYoutubeValueChanged(
    YoutubePlayerController controller,
    YoutubePlayerValue value,
    int generation,
  ) {
    if (!mounted ||
        controller != _youtubeController ||
        generation != _generation) {
      return;
    }

    final error = value.error;
    if (value.playerState != PlayerState.unknown ||
        error != YoutubeError.none) {
      _youtubeReady = true;
    }
    if (error != YoutubeError.none) {
      debugPrint('[YT] iframe error code ${error.code}');
      _setError(youtubeErrorMessageForCode(error.code), generation);
      return;
    }

    final state = value.playerState;
    debugPrint('[YT] player state changed: $state');
    if (state == PlayerState.cued && !_youtubePlayRequested) {
      _youtubePlayRequested = true;
      debugPrint('[YT] onReady for video ${widget.videoPost.providerId}');
      unawaited(_syncYoutubeMuteState(controller, generation));
      unawaited(
        _PlaybackCoordinator.activate(
          controller,
          play: controller.playVideo,
          pause: controller.pauseVideo,
          isStillActive: () =>
              mounted &&
              widget.isActive &&
              generation == _generation &&
              controller == _youtubeController,
        ).catchError((Object error, StackTrace stackTrace) {
          _showOperationError(error, stackTrace);
        }),
      );
    } else if (state == PlayerState.playing || state == PlayerState.buffering) {
      if (state == PlayerState.playing) {
        _startupTimer?.cancel();
        if (_isLoading || !_isPlaying) {
          setState(() {
            _isLoading = false;
            _isPlaying = true;
          });
        }
      } else {
        if (!_isLoading || _isPlaying) {
          setState(() {
            _isLoading = true;
            _isPlaying = false;
          });
        }
      }
    } else if (state == PlayerState.paused || state == PlayerState.ended) {
      _startupTimer?.cancel();
      if (_isLoading || _isPlaying) {
        setState(() {
          _isLoading = false;
          _isPlaying = false;
        });
      }
    }
  }

  Future<void> _syncYoutubeMuteState(
    YoutubePlayerController controller,
    int generation,
  ) async {
    try {
      final isMuted = await controller.isMuted;
      if (!mounted ||
          generation != _generation ||
          controller != _youtubeController ||
          _isMuted == isMuted) {
        return;
      }
      setState(() => _isMuted = isMuted);
    } catch (error, stackTrace) {
      developer.log(
        'Unable to read YouTube mute state.',
        name: 'FullScreenPlayer',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  bool _isCurrent(VideoPlayerController controller, int generation) =>
      mounted &&
      widget.isActive &&
      generation == _generation &&
      controller == _videoController;

  String _playbackIdentity(VideoPost video) =>
      '${video.source.name}|${video.id}|${video.providerId ?? ""}|${video.playbackUrl}';

  void _setError(String message, int generation) {
    if (!mounted || generation != _generation) return;
    _startupTimer?.cancel();
    setState(() {
      _isLoading = false;
      _isPlaying = false;
      _errorMessage = message;
    });
  }

  Future<void> _toggleMute() async {
    final videoController = _videoController;
    if (videoController != null && videoController.value.isInitialized) {
      final shouldMute = videoController.value.volume > 0;
      try {
        await videoController.setVolume(shouldMute ? 0 : 1);
        if (!mounted) return;
        setState(() => _isMuted = shouldMute);
      } catch (error, stackTrace) {
        _showOperationError(error, stackTrace);
      }
      return;
    }

    final youtubeController = _youtubeController;
    final vimeoController = _vimeoController;
    if (vimeoController != null && _vimeoReady && _errorMessage == null) {
      final shouldMute = !_isMuted;
      try {
        await _sendVimeoCommand(
          vimeoController,
          'setVolume',
          value: shouldMute ? 0 : 1,
        );
        if (!mounted) return;
        setState(() => _isMuted = shouldMute);
      } catch (error, stackTrace) {
        _showOperationError(error, stackTrace);
      }
      return;
    }

    if (youtubeController == null || _errorMessage != null) return;
    final shouldMute = !_isMuted;
    try {
      if (shouldMute) {
        await youtubeController.mute();
      } else {
        await youtubeController.unMute();
      }
      if (!mounted) return;
      setState(() => _isMuted = shouldMute);
    } catch (error, stackTrace) {
      _showOperationError(error, stackTrace);
    }
  }

  Future<void> _togglePlayback() async {
    if (!widget.isActive || _errorMessage != null || _isLoading) return;

    final videoController = _videoController;
    if (videoController != null && videoController.value.isInitialized) {
      final isPlaying = videoController.value.isPlaying;
      try {
        if (isPlaying) {
          await _PlaybackCoordinator.deactivate(
            videoController,
            pause: videoController.pause,
          );
        } else {
          await _PlaybackCoordinator.activate(
            videoController,
            play: videoController.play,
            pause: videoController.pause,
            isStillActive: () =>
                mounted &&
                widget.isActive &&
                videoController == _videoController,
          );
        }
      } catch (error, stackTrace) {
        _showOperationError(error, stackTrace);
      }
      return;
    }

    final youtubeController = _youtubeController;
    final vimeoController = _vimeoController;
    if (vimeoController != null && _vimeoReady) {
      try {
        if (_isPlaying) {
          await _PlaybackCoordinator.deactivate(
            vimeoController,
            pause: () => _sendVimeoCommand(vimeoController, 'pause'),
          );
          if (mounted) setState(() => _isPlaying = false);
        } else {
          await _PlaybackCoordinator.activate(
            vimeoController,
            play: () => _sendVimeoCommand(vimeoController, 'play'),
            pause: () => _sendVimeoCommand(vimeoController, 'pause'),
            isStillActive: () =>
                mounted &&
                widget.isActive &&
                vimeoController == _vimeoController,
          );
          if (mounted) setState(() => _isPlaying = true);
        }
      } catch (error, stackTrace) {
        _showOperationError(error, stackTrace);
      }
      return;
    }

    if (youtubeController == null) return;
    try {
      if (_isPlaying) {
        await _PlaybackCoordinator.deactivate(
          youtubeController,
          pause: youtubeController.pauseVideo,
        );
        if (mounted) setState(() => _isPlaying = false);
      } else {
        await _PlaybackCoordinator.activate(
          youtubeController,
          play: youtubeController.playVideo,
          pause: youtubeController.pauseVideo,
          isStillActive: () =>
              mounted &&
              widget.isActive &&
              youtubeController == _youtubeController,
        );
      }
    } catch (error, stackTrace) {
      _showOperationError(error, stackTrace);
    }
  }

  Future<void> _retryPlayback() async {
    _schedulePlaybackTransition(startWhenReleased: true);
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

  Future<void> _releasePlayback() async {
    _startupTimer?.cancel();
    _startupTimer = null;
    final videoController = _videoController;
    final youtubeController = _youtubeController;
    final vimeoController = _vimeoController;
    _videoController = null;
    _youtubeController = null;
    _vimeoController = null;
    _controllerIdentity = null;
    final youtubeWasReady = _youtubeReady;
    _youtubeReady = false;
    _vimeoReady = false;
    _isLoading = false;
    _isPlaying = false;

    await _youtubeSubscription?.cancel();
    _youtubeSubscription = null;

    if (videoController != null) {
      final listener = _videoListener;
      if (listener != null) videoController.removeListener(listener);
      _videoListener = null;
      try {
        await _PlaybackCoordinator.deactivate(
          videoController,
          pause: () async {
            if (videoController.value.isInitialized) {
              await videoController.pause();
            }
          },
        );
      } catch (error, stackTrace) {
        developer.log(
          'Failed to pause video before disposal.',
          name: 'FullScreenPlayer',
          error: error,
          stackTrace: stackTrace,
        );
      }
      try {
        await videoController.dispose();
      } catch (error, stackTrace) {
        developer.log(
          'Failed to dispose video controller.',
          name: 'FullScreenPlayer',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    if (youtubeController != null) {
      try {
        await _PlaybackCoordinator.deactivate(
          youtubeController,
          pause: youtubeWasReady ? youtubeController.pauseVideo : () async {},
        );
      } catch (error, stackTrace) {
        developer.log(
          'Failed to pause YouTube before closing its controller.',
          name: 'FullScreenPlayer',
          error: error,
          stackTrace: stackTrace,
        );
      }
      debugPrint('[YT] disposing controller for video ${widget.videoPost.id}');
      try {
        await youtubeController.close().timeout(_youtubeCloseTimeout);
      } catch (error, stackTrace) {
        developer.log(
          'YouTube controller cleanup failed or exceeded '
          '${_youtubeCloseTimeout.inSeconds} seconds.',
          name: 'FullScreenPlayer',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    if (vimeoController != null) {
      try {
        await _PlaybackCoordinator.deactivate(
          vimeoController,
          pause: () => _sendVimeoCommand(vimeoController, 'pause'),
        );
      } catch (error, stackTrace) {
        developer.log(
          'Failed to pause Vimeo before removing its WebView.',
          name: 'FullScreenPlayer',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  @override
  void dispose() {
    ++_generation;
    final release = _playbackTransitionQueue.then((_) async {
      await WidgetsBinding.instance.endOfFrame;
      await _releasePlayback();
    });
    _playbackTransitionQueue = release.catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      developer.log(
        'Playback disposal failed.',
        name: 'FullScreenPlayer',
        error: error,
        stackTrace: stackTrace,
      );
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final discoverProvider = context.watch<DiscoverProvider>();
    final youtubeId = widget.videoPost.source == VideoSourceType.youtube
        ? youtubeVideoIdForPlayback(widget.videoPost)
        : null;

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: Colors.black,
          child: widget.videoPost.source == VideoSourceType.vimeo
              ? Center(child: _buildPlaybackSurface(youtubeId))
              : GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _togglePlayback,
                  child: Center(child: _buildPlaybackSurface(youtubeId)),
                ),
        ),
        VideoBackground(stops: const [0.72, 1.0]),
        if (_errorMessage != null)
          Center(
            child: _VideoPlaybackError(
              message: _errorMessage!,
              onRetry: widget.isActive
                  ? () => unawaited(_retryPlayback())
                  : null,
            ),
          ),
        if (_isLoading && _errorMessage == null)
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        if (!_isPlaying && _errorMessage == null && !_isLoading)
          Center(
            child: Icon(
              Icons.play_arrow,
              size: 80,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
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
            isFavoriteUpdatePending: discoverProvider.isFavoriteUpdatePending(
              widget.videoPost.id,
            ),
            onToggleFavorite: () => _toggleFavorite(context, discoverProvider),
          ),
        ),
        Positioned(
          bottom: 50,
          left: 20,
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width * 0.6,
            child: VideoCaption(caption: widget.videoPost.caption),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackSurface(String? youtubeId) {
    if (!widget.isActive ||
        _controllerIdentity != _playbackIdentity(widget.videoPost)) {
      return const SizedBox.expand();
    }

    final youtubeController = _youtubeController;
    if (youtubeId != null && youtubeController != null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: YoutubePlayer(
          controller: youtubeController,
          aspectRatio: 16 / 9,
          autoFullScreen: false,
          keepAlive: false,
        ),
      );
    }

    final vimeoController = _vimeoController;
    if (widget.videoPost.source == VideoSourceType.vimeo &&
        vimeoController != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          WebViewWidget(controller: vimeoController),
          if (!_vimeoReady && widget.videoPost.thumbnailUrl != null)
            Positioned.fill(
              child: IgnorePointer(
                child: Image.network(
                  widget.videoPost.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
        ],
      );
    }

    final videoController = _videoController;
    if (videoController != null && videoController.value.isInitialized) {
      return AspectRatio(
        aspectRatio: videoController.value.aspectRatio,
        child: VideoPlayer(videoController),
      );
    }

    return const SizedBox.expand();
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
  const _VideoPlaybackError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

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
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const ValueKey('retry-video-playback'),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlaybackCoordinator {
  static Future<void> _queue = Future<void>.value();
  static Object? _activePlayer;
  static Future<void> Function()? _pauseActivePlayer;

  static Future<void> _enqueue(Future<void> Function() operation) {
    final result = _queue.then((_) => operation());
    _queue = result.catchError((Object _) {});
    return result;
  }

  static Future<void> activate(
    Object player, {
    required Future<void> Function() play,
    required Future<void> Function() pause,
    required bool Function() isStillActive,
  }) {
    return _enqueue(() async {
      if (!isStillActive()) return;
      final activePlayer = _activePlayer;
      if (activePlayer != null && activePlayer != player) {
        await _pauseActivePlayer?.call();
        if (_activePlayer == activePlayer) {
          _activePlayer = null;
          _pauseActivePlayer = null;
        }
      }
      if (!isStillActive()) return;
      await play();
      if (!isStillActive()) {
        await pause();
        return;
      }
      _activePlayer = player;
      _pauseActivePlayer = pause;
    });
  }

  static Future<void> deactivate(
    Object player, {
    required Future<void> Function() pause,
  }) {
    return _enqueue(() async {
      try {
        await pause();
      } finally {
        if (_activePlayer == player) {
          _activePlayer = null;
          _pauseActivePlayer = null;
        }
      }
    });
  }
}

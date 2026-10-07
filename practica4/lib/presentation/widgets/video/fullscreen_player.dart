import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:practica4/domain/entities/video_post.dart';
import 'package:practica4/presentation/providers/discover_provider.dart';
import 'package:practica4/presentation/widgets/shared/video_buttons.dart';
import 'package:practica4/presentation/widgets/video/video_background.dart';

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
  bool isMuted = false;

  @override
  void initState() {
    super.initState();

    controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoPost.videoUrl),
    );
    _initializeFuture = controller.initialize().then((_) {
      controller.setVolume(isMuted ? 0 : 1);
      controller.setLooping(true);
      if (widget.isActive) {
        controller.play();
      }
    });
  }

  void _toggleMute() {
    setState(() {
      isMuted = !isMuted;
      controller.setVolume(isMuted ? 0 : 1);
    });
  }

  @override
  void didUpdateWidget(covariant FullScreenPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Pause the video if it goes off-screen, play it if it comes on-screen
    if (oldWidget.isActive != widget.isActive &&
        controller.value.isInitialized) {
      if (widget.isActive) {
        controller.play();
      } else {
        controller.pause();
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final discoverProvider = context.watch<DiscoverProvider>();

    return FutureBuilder(
      future: _initializeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        return GestureDetector(
          onTap: () {
            if (controller.value.isPlaying) {
              controller.pause();
            } else {
              controller.play();
            }
            setState(() {});
          },
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: Stack(
              children: [
                VideoPlayer(controller),

                // Gradiente
                VideoBackground(stops: const [0.8, 1.0]),

                // Icono de Play (se muestra cuando está pausado)
                if (!controller.value.isPlaying)
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
                    isMuted: isMuted,
                    onToggleMute: _toggleMute,
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
                  child: _VideoCaption(caption: widget.videoPost.caption),
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

class _VideoCaption extends StatelessWidget {
  final String caption;

  const _VideoCaption({required this.caption});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final titleStyle = Theme.of(context).textTheme.titleLarge;

    return SizedBox(
      width: size.width * 0.6,
      child: Text(caption, maxLines: 2, style: titleStyle),
    );
  }
}

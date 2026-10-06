import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:tistos/domain/entities/video_post.dart';
import 'package:tistos/presentation/widgets/shared/video_buttons.dart';
import 'package:tistos/presentation/widgets/video/video_background.dart';
import 'package:video_player/video_player.dart';

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

    controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoPost.videoUrl));
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
                      color: Colors.white.withOpacity(0.5),
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
}

class _VideoCaption extends StatelessWidget {
  final String caption;

  const _VideoCaption({super.key, required this.caption});

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

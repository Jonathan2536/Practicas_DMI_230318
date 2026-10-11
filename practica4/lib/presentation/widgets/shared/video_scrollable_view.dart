import 'package:flutter/material.dart';
import 'package:practica4/domain/entities/video_post.dart';
import 'package:practica4/presentation/widgets/video/fullscreen_player.dart';

class VideoScrollableView extends StatefulWidget {
  final List<VideoPost> videos;
  final bool isActive;

  const VideoScrollableView({
    super.key,
    required this.videos,
    this.isActive = true,
  });

  @override
  State<VideoScrollableView> createState() => _VideoScrollableViewState();
}

class _VideoScrollableViewState extends State<VideoScrollableView> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      scrollDirection: Axis.vertical,
      physics: const BouncingScrollPhysics(),
      itemCount: widget.videos.length,
      onPageChanged: (index) => setState(() => _currentIndex = index),
      itemBuilder: (context, index) {
        final VideoPost videoPost = widget.videos[index];

        return Stack(
          children: [
            // Video Player + gradiente
            SizedBox.expand(
              child: FullScreenPlayer(
                videoPost: videoPost,
                isActive: widget.isActive && index == _currentIndex,
              ),
            ),
          ],
        );
      },
    );
  }
}

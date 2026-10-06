import 'package:flutter/material.dart';
import 'package:tistos/domain/entities/video_post.dart';
import 'package:tistos/presentation/widgets/video/fullscreen_player.dart';

class VideoScrollableView extends StatefulWidget {
  
  final List<VideoPost> videos;
  
  const VideoScrollableView({
    super.key, 
    required this.videos
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
                isActive: index == _currentIndex,
              )
            ),
            
          ],
        );

      },
    );
  }
}
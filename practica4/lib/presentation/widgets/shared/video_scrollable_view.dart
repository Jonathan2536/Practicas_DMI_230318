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
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void didUpdateWidget(covariant VideoScrollableView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_hasSameVideoOrder(oldWidget.videos, widget.videos)) return;

    final currentVideoId = oldWidget.videos.isEmpty
        ? null
        : oldWidget.videos[_currentIndex.clamp(0, oldWidget.videos.length - 1)]
              .id;
    final preservedIndex = currentVideoId == null
        ? -1
        : widget.videos.indexWhere((video) => video.id == currentVideoId);
    final nextIndex = preservedIndex < 0
        ? _currentIndex.clamp(0, widget.videos.length - 1)
        : preservedIndex;
    _currentIndex = nextIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _pageController.hasClients &&
          widget.videos.isNotEmpty) {
        _pageController.jumpToPage(nextIndex);
      }
    });
  }

  bool _hasSameVideoOrder(List<VideoPost> first, List<VideoPost> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index].id != second[index].id) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
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

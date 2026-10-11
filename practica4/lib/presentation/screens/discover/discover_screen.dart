import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:practica4/domain/entities/video_post.dart';
import 'package:practica4/presentation/providers/discover_provider.dart';
import 'package:practica4/presentation/widgets/shared/video_scrollable_view.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  static const _sections = ['Discover', 'For You', 'Favorites'];

  final PageController _pageController = PageController();
  int _selectedSection = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectSection(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final discoverProvider = context.watch<DiscoverProvider>();

    if (discoverProvider.initialLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final sectionVideos = [
      discoverProvider.videos,
      discoverProvider.forYouVideos,
      discoverProvider.favoriteVideos,
    ];

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            key: const ValueKey('video-sections-page-view'),
            controller: _pageController,
            itemCount: _sections.length,
            onPageChanged: (index) {
              setState(() => _selectedSection = index);
            },
            itemBuilder: (context, index) => _VideoSection(
              videos: sectionVideos[index],
              sectionName: _sections[index],
              isActive: _selectedSection == index,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: List.generate(_sections.length, (index) {
                  final isSelected = index == _selectedSection;

                  return Expanded(
                    child: Semantics(
                      key: ValueKey('section-semantic-${_sections[index]}'),
                      button: true,
                      selected: isSelected,
                      child: InkWell(
                        key: ValueKey('section-tab-${_sections[index]}'),
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => _selectSection(index),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 4,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _sections[index],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(height: 6),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                height: 3,
                                width: isSelected ? 32 : 0,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoSection extends StatelessWidget {
  const _VideoSection({
    required this.videos,
    required this.sectionName,
    required this.isActive,
  });

  final List<VideoPost> videos;
  final String sectionName;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              sectionName == 'Favorites'
                  ? Icons.bookmark_border
                  : Icons.video_library_outlined,
              color: Colors.white70,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              sectionName == 'Favorites'
                  ? 'No tienes videos favoritos'
                  : 'No hay videos disponibles',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return VideoScrollableView(videos: videos, isActive: isActive);
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:practica4/domain/entities/video_post.dart';
import 'package:practica4/presentation/providers/discover_provider.dart';
import 'package:practica4/presentation/providers/seasonal_theme_provider.dart';
import 'package:practica4/presentation/screens/splash/seasonal_theme.dart';
import 'package:practica4/presentation/screens/splash/splash_screen.dart';
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

  Future<void> _selectSeason(String id) async {
    final seasonalThemeProvider = context.read<SeasonalThemeProvider>();
    final theme = id == 'auto' ? null : SeasonalTheme.fromId(id);
    if (id != 'auto' && theme == null) {
      throw ArgumentError.value(id, 'id', 'Unknown seasonal theme.');
    }
    if (seasonalThemeProvider.selectedOverride == theme) return;

    try {
      await seasonalThemeProvider.selectTheme(theme);
      if (!mounted) return;
      unawaited(context.read<DiscoverProvider>().loadNextPage());
      unawaited(
        Navigator.of(context).pushReplacement<void, void>(
          MaterialPageRoute<void>(
            builder: (_) => const SplashScreen(destination: DiscoverScreen()),
          ),
        ),
      );
    } on Object catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'TokTik seasonal theme selector',
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar la temporada seleccionada.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final discoverProvider = context.watch<DiscoverProvider>();
    final seasonalThemeProvider = context.watch<SeasonalThemeProvider>();

    if (discoverProvider.initialLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (discoverProvider.videos.isEmpty && discoverProvider.loadError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 48),
                const SizedBox(height: 12),
                Text(discoverProvider.loadError!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => discoverProvider.loadNextPage(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final sectionVideos = [
      discoverProvider.videos,
      discoverProvider.forYouVideos,
      discoverProvider.favoriteVideos,
    ];

    return Scaffold(
      body: Column(
        children: [
          if (discoverProvider.sourceFailures.isNotEmpty)
            SafeArea(
              bottom: false,
              child: MaterialBanner(
                content: Text(
                  'No se pudieron cargar: '
                  '${discoverProvider.sourceFailures.map((failure) => failure.source).join(', ')}. '
                  'Comprueba la conexión, configuración y que fecha y hora '
                  'automáticas estén activadas en Android.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => discoverProvider.loadNextPage(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Stack(
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
                      children: [
                        ...List.generate(_sections.length, (index) {
                          final isSelected = index == _selectedSection;

                          return Expanded(
                            child: Semantics(
                              key: ValueKey(
                                'section-semantic-${_sections[index]}',
                              ),
                              button: true,
                              selected: isSelected,
                              child: InkWell(
                                key: ValueKey(
                                  'section-tab-${_sections[index]}',
                                ),
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
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        height: 3,
                                        width: isSelected ? 32 : 0,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                        PopupMenuButton<String>(
                          tooltip: 'Seleccionar temporada',
                          onSelected: (id) => _selectSeason(id),
                          itemBuilder: (context) => [
                            CheckedPopupMenuItem<String>(
                              value: 'auto',
                              checked:
                                  seasonalThemeProvider.selectedOverride ==
                                  null,
                              child: const Text(
                                'Automático (fecha del dispositivo)',
                              ),
                            ),
                            ...SeasonalTheme.values.map(
                              (theme) => CheckedPopupMenuItem<String>(
                                value: theme.launcherIconTheme,
                                checked:
                                    seasonalThemeProvider.selectedOverride ==
                                    theme,
                                child: Text(theme.name),
                              ),
                            ),
                            const PopupMenuItem<String>(
                              enabled: false,
                              child: Text(
                                'Mantén fecha y hora automáticas para HTTPS.',
                              ),
                            ),
                          ],
                          icon: const Icon(
                            Icons.palette_outlined,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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

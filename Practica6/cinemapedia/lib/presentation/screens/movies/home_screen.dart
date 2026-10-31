import 'package:cinemapedia/presentation/views/views.dart';
import 'package:cinemapedia/presentation/widgets/shared/custom_bottom_navigation.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  static const name = 'home-screen';

  final int pageIndex;

  const HomeScreen({super.key, required this.pageIndex});

  @override
  Widget build(BuildContext context) {
    final selectedIndex = pageIndex >= 0 && pageIndex <= 2 ? pageIndex : 0;
    final Widget page = switch (selectedIndex) {
      1 => const Center(child: Text('Categorías próximamente')),
      2 => const FavoritesView(),
      _ => const HomeView(),
    };

    return Scaffold(
      body: page,
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: selectedIndex,
      ),
    );
  }
}

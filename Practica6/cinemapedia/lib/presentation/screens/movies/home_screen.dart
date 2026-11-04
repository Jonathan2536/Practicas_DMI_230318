import 'package:cinemapedia/presentation/views/views.dart';
import 'package:cinemapedia/presentation/widgets/shared/custom_bottom_navigation.dart';
import 'package:cinemapedia/presentation/widgets/shared/cinemapedia_drawer.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  static const name = 'home-screen';

  final int pageIndex;

  const HomeScreen({super.key, required this.pageIndex});

  @override
  Widget build(BuildContext context) {
    final selectedIndex = pageIndex >= 0 && pageIndex <= 3 ? pageIndex : 0;
    final Widget page = switch (selectedIndex) {
      1 => const Center(child: Text('Categorías próximamente')),
      2 => const FavoritesView(),
      3 => const Section15View(),
      _ => const HomeView(),
    };

    return Scaffold(
      body: page,
      drawer: const CinemapediaDrawer(),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: selectedIndex <= 2 ? selectedIndex : 0,
      ),
    );
  }
}

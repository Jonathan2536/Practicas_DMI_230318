import 'package:cinemapedia/presentation/widgets/shared/country_filter_selector.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CinemapediaDrawer extends StatelessWidget {
  const CinemapediaDrawer({super.key});

  void _navigate(BuildContext context, String location) {
    Navigator.of(context).pop();
    context.go(location);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: colors.primaryContainer),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Cinemapedia',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Inicio'),
              onTap: () => _navigate(context, '/home/0'),
            ),
            ListTile(
              leading: const Icon(Icons.category_outlined),
              title: const Text('Categorías'),
              onTap: () => _navigate(context, '/home/1'),
            ),
            ListTile(
              leading: const Icon(Icons.favorite_outline),
              title: const Text('Favoritos'),
              onTap: () => _navigate(context, '/home/2'),
            ),
            ListTile(
              leading: const Icon(Icons.movie_filter_outlined),
              title: const Text('Sección 15'),
              onTap: () => _navigate(context, '/home/3'),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Filtrar por país',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: CountryFilterSelector(),
            ),
          ],
        ),
      ),
    );
  }
}

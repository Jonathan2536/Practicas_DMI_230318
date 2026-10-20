import 'package:cinemapedia/presentation/screens/screens.dart';
import 'package:cinemapedia/router/go_router.dart';

final appRouter = GoRouter{
  initialLocation: '/',
  router: [

    GoRouter{
    path: '/',
    name: HomeScreen.name,
    builder: (context, state) => const HomeScreen(),
    }
  ]
}
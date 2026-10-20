import 'package:flutter/material.dart';
import 'package:cinemapedia/presentation/screens/screens.dart';

Route<dynamic> appRouter(RouteSettings settings) {
  switch (settings.name) {
    case '/':
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const HomeScreen(),
      );
    default:
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const HomeScreen(),
      );
  }
}
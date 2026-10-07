import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:practica4/config/theme/app_theme.dart';
import 'package:practica4/domain/services/local_storage_service.dart';
import 'package:practica4/infrastructure/services/shared_preferences_storage_service.dart';
import 'package:practica4/presentation/providers/discover_provider.dart';
import 'package:practica4/presentation/screens/discover/discover_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final localStorage = SharedPreferencesStorageService();
  await localStorage.initialize();

  runApp(MyApp(localStorage: localStorage));
}

class MyApp extends StatelessWidget {
  final LocalStorageService localStorage;

  const MyApp({super.key, required this.localStorage});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<LocalStorageService>.value(value: localStorage),
        ChangeNotifierProvider( 
          lazy: false,
          create: (_) => DiscoverProvider()..loadNextPage() 
        ),
      ],
      child: MaterialApp(
        title: 'TokTik',
        debugShowCheckedModeBanner: false,
        theme: AppTheme().getTheme(),
        home: const DiscoverScreen()
      ),
    );
  }
}

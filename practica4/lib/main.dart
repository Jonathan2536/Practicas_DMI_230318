import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:practica4/config/environment/app_config.dart';
import 'package:practica4/config/theme/app_theme.dart';
import 'package:practica4/domain/repositories/video_post_repository.dart';
import 'package:practica4/domain/services/local_storage_service.dart';
import 'package:practica4/infrastructure/datasources/local_video_post_data_source.dart';
import 'package:practica4/infrastructure/datasources/pixabay_video_data_source.dart';
import 'package:practica4/infrastructure/datasources/vimeo_video_data_source.dart';
import 'package:practica4/infrastructure/datasources/youtube_video_data_source.dart';
import 'package:practica4/infrastructure/repositories/video_post_repository_impl.dart';
import 'package:practica4/infrastructure/services/shared_preferences_storage_service.dart';
import 'package:practica4/presentation/providers/discover_provider.dart';
import 'package:practica4/presentation/screens/discover/discover_screen.dart';
import 'package:practica4/presentation/screens/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppConfig.load();

  final localStorage = SharedPreferencesStorageService();
  await localStorage.initialize();
  final httpClient = http.Client();
  final videoRepository = VideoPostRepositoryImpl([
    LocalVideoPostDataSource(),
    YouTubeVideoDataSource(
      config: AppConfig.instance,
      client: httpClient,
    ),
    PixabayVideoDataSource(
      config: AppConfig.instance,
      client: httpClient,
    ),
    VimeoVideoDataSource(
      config: AppConfig.instance,
      client: httpClient,
    ),
  ]);

  runApp(
    MyApp(
      localStorage: localStorage,
      videoRepository: videoRepository,
      httpClient: httpClient,
    ),
  );
}

class MyApp extends StatefulWidget {
  final LocalStorageService localStorage;
  final VideoPostRepository videoRepository;
  final http.Client httpClient;

  const MyApp({
    super.key,
    required this.localStorage,
    required this.videoRepository,
    required this.httpClient,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void dispose() {
    widget.httpClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<LocalStorageService>.value(value: widget.localStorage),
        Provider<VideoPostRepository>.value(value: widget.videoRepository),
        ChangeNotifierProvider(
          lazy: false,
          create: (context) => DiscoverProvider(
            context.read<VideoPostRepository>(),
            context.read<LocalStorageService>(),
          )..loadNextPage(),
        ),
      ],
      child: MaterialApp(
        title: 'TokTik',
        debugShowCheckedModeBanner: false,
        theme: AppTheme().getTheme(),
        home: const SplashScreen(destination: DiscoverScreen()),
      ),
    );
  }
}

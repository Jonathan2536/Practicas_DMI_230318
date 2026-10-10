import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:practica4/config/theme/app_theme.dart';
import 'package:practica4/domain/repositories/video_post_repository.dart';
import 'package:practica4/domain/services/local_storage_service.dart';
import 'package:practica4/infrastructure/datasources/instagram_video_data_source.dart';
import 'package:practica4/infrastructure/datasources/local_video_post_data_source.dart';
import 'package:practica4/infrastructure/datasources/youtube_video_data_source.dart';
import 'package:practica4/infrastructure/repositories/video_post_repository_impl.dart';
import 'package:practica4/infrastructure/services/shared_preferences_storage_service.dart';
import 'package:practica4/presentation/providers/discover_provider.dart';
import 'package:practica4/presentation/screens/discover/discover_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final localStorage = SharedPreferencesStorageService();
  await localStorage.initialize();
  final videoRepository = VideoPostRepositoryImpl(
    [
      LocalVideoPostDataSource(),
      YouTubeVideoDataSource(),
      InstagramVideoDataSource(),
    ],
  );

  runApp(
    MyApp(localStorage: localStorage, videoRepository: videoRepository),
  );
}

class MyApp extends StatelessWidget {
  final LocalStorageService localStorage;
  final VideoPostRepository videoRepository;

  const MyApp({
    super.key,
    required this.localStorage,
    required this.videoRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<LocalStorageService>.value(value: localStorage),
        Provider<VideoPostRepository>.value(value: videoRepository),
        ChangeNotifierProvider( 
          lazy: false,
          create: (context) => DiscoverProvider(
            context.read<VideoPostRepository>(),
            context.read<LocalStorageService>(),
          )..loadNextPage()
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

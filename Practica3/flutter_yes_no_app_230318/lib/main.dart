import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:flutter_yes_no_app_230318/config/theme/app_theme.dart';
import 'package:flutter_yes_no_app_230318/domain/usecases/get_yes_no_answer.dart';
import 'package:flutter_yes_no_app_230318/infrastructure/datasources/yes_no_datasource_impl.dart';
import 'package:flutter_yes_no_app_230318/infrastructure/repositories/yes_no_repository_impl.dart';
import 'package:flutter_yes_no_app_230318/presentation/providers/chat_provider.dart';
import 'package:flutter_yes_no_app_230318/presentation/screens/chat/chat_screen.dart';

void main() {
  final dio = Dio(BaseOptions(baseUrl: 'https://yesno.wtf'));
  final datasource = YesNoDatasourceImpl(dio);
  final repository = YesNoRepositoryImpl(datasource);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ChatProvider(GetYesNoAnswer(repository)),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yes No App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme(selectedColor: 1).theme(),
      home: const ChatScreen(),
    );
  }
}

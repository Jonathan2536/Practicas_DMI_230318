import 'dart:io';

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
  HttpOverrides.global = _YesNoApiHttpOverrides();

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

class _YesNoApiHttpOverrides extends HttpOverrides {
  static final _apiAddress = InternetAddress('188.166.14.102');

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.connectionFactory = (uri, proxyHost, proxyPort) async {
      final isYesNoHost = uri.host.toLowerCase() == 'yesno.wtf';
      final socketTask = isYesNoHost
          ? await _connectToYesNo(uri)
          : await Socket.startConnect(uri.host, uri.port);

      if (uri.scheme != 'https') return socketTask;

      final secureSocket = socketTask.socket.then(
        (socket) => SecureSocket.secure(
          socket,
          host: uri.host,
          context: context,
          supportedProtocols: const ['http/1.1'],
        ),
      );
      return ConnectionTask.fromSocket<Socket>(
        secureSocket,
        socketTask.cancel,
      );
    };
    client.findProxy = (_) => 'DIRECT';
    return client;
  }

  Future<ConnectionTask<Socket>> _connectToYesNo(Uri uri) async {
    try {
      final addresses = await InternetAddress.lookup(
        uri.host,
        type: InternetAddressType.IPv4,
      );
      return await Socket.startConnect(addresses.first, uri.port);
    } on SocketException {
      return Socket.startConnect(_apiAddress, uri.port);
    }
  }
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

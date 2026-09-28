import 'package:dio/dio.dart';
import 'package:flutter_yes_no_app_230318/domain/datasources/yes_no_datasource.dart';
import 'package:flutter_yes_no_app_230318/domain/entities/message.dart';

class YesNoDatasourceImpl implements YesNoDatasource {
  YesNoDatasourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<Message> getAnswer({required String force}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api',
      queryParameters: {'force': force},
    );
    final data = response.data;

    if (data == null || data['answer'] is! String) {
      throw const FormatException('La respuesta de yesno.wtf no es válida.');
    }

    final answer = switch ((data['answer'] as String).toLowerCase()) {
      'yes' => 'Sí',
      'no' => 'No',
      'maybe' => 'Tal vez',
      _ => throw const FormatException('La respuesta recibida no es válida.'),
    };
    final imageUrl = data['image'];

    return Message(
      text: answer,
      fromWho: FromWho.hers,
      imageUrl: imageUrl is String ? imageUrl : null,
    );
  }
}

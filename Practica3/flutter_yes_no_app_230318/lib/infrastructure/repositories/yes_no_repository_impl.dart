import 'package:flutter_yes_no_app_230318/domain/datasources/yes_no_datasource.dart';
import 'package:flutter_yes_no_app_230318/domain/entities/message.dart';
import 'package:flutter_yes_no_app_230318/domain/repositories/yes_no_repository.dart';

class YesNoRepositoryImpl implements YesNoRepository {
  YesNoRepositoryImpl(this._datasource);

  final YesNoDatasource _datasource;

  @override
  Future<Message> getYesNoAnswer({required String force}) {
    return _datasource.getAnswer(force: force);
  }
}

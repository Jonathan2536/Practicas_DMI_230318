import 'package:flutter_yes_no_app_230318/domain/entities/message.dart';

abstract interface class YesNoDatasource {
  Future<Message> getAnswer({required String force});
}

import 'package:flutter_yes_no_app_230318/domain/entities/message.dart';

abstract interface class YesNoRepository {
  Future<Message> getYesNoAnswer({required String force});
}

import 'dart:math';

import 'package:flutter_yes_no_app_230318/domain/entities/message.dart';
import 'package:flutter_yes_no_app_230318/domain/repositories/yes_no_repository.dart';

class GetYesNoAnswer {
  GetYesNoAnswer(this._repository, {Random? random})
    : _random = random ?? Random();

  static const _answers = ['yes', 'yes', 'no', 'no', 'maybe'];

  final YesNoRepository _repository;
  final Random _random;

  Future<Message> call() {
    final force = _answers[_random.nextInt(_answers.length)];
    return _repository.getYesNoAnswer(force: force);
  }
}

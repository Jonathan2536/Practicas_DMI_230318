// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_yes_no_app_230318/domain/entities/message.dart';
import 'package:flutter_yes_no_app_230318/domain/repositories/yes_no_repository.dart';
import 'package:flutter_yes_no_app_230318/domain/usecases/get_yes_no_answer.dart';
import 'package:flutter_yes_no_app_230318/presentation/providers/chat_provider.dart';
import 'package:flutter_yes_no_app_230318/presentation/screens/chat/chat_screen.dart';

void main() {
  test('uses the 40/40/20 force options', () async {
    final repository = _FakeYesNoRepository();
    const expectedForces = ['yes', 'yes', 'no', 'no', 'maybe'];

    for (var index = 0; index < expectedForces.length; index++) {
      await GetYesNoAnswer(repository, random: _FixedRandom(index)).call();
    }

    expect(repository.forces, expectedForces);
  });

  testWidgets('a question receives a translated bot answer', (tester) async {
    await tester.pumpWidget(_buildChatApp());
    await tester.enterText(find.byType(TextFormField), '¿Va a llover?');
    await tester.tap(find.byIcon(Icons.send_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('¿Va a llover?'), findsOneWidget);
    expect(find.text('Sí'), findsOneWidget);
  });

  testWidgets('a message without a question mark gets no bot answer', (
    tester,
  ) async {
    await tester.pumpWidget(_buildChatApp());
    await tester.enterText(find.byType(TextFormField), 'Hola');
    await tester.tap(find.byIcon(Icons.send_outlined));
    await tester.pump();

    expect(find.text('Hola'), findsOneWidget);
    expect(find.text('Sí'), findsNothing);
  });
}

Widget _buildChatApp() {
  return ChangeNotifierProvider(
    create: (_) => ChatProvider(GetYesNoAnswer(_FakeYesNoRepository())),
    child: const MaterialApp(home: ChatScreen()),
  );
}

class _FakeYesNoRepository implements YesNoRepository {
  final forces = <String>[];

  @override
  Future<Message> getYesNoAnswer({required String force}) async {
    forces.add(force);
    return Message(text: 'Sí', fromWho: FromWho.hers);
  }
}

class _FixedRandom implements Random {
  const _FixedRandom(this.value);

  final int value;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;

  @override
  int nextInt(int max) => value % max;
}

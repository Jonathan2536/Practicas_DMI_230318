import 'package:flutter/widgets.dart';
import 'package:flutter_yes_no_app_230318/domain/entities/message.dart';
import 'package:flutter_yes_no_app_230318/domain/usecases/get_yes_no_answer.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider(this._getYesNoAnswer)
    : _messages = [
        Message(text: '¡Hola! Hazme una pregunta.', fromWho: FromWho.hers),
      ];

  final GetYesNoAnswer _getYesNoAnswer;
  final List<Message> _messages;
  final ScrollController scrollController = ScrollController();

  List<Message> get messages => List.unmodifiable(_messages);

  void sendMessage(String text) {
    final messageText = text.trim();
    if (messageText.isEmpty) return;

    _addMessage(Message(text: messageText, fromWho: FromWho.me));

    if (messageText.endsWith('?')) {
      _getBotAnswer();
    }
  }

  Future<void> _getBotAnswer() async {
    try {
      final answer = await _getYesNoAnswer.call();
      _addMessage(answer);
    } on Exception {
      _addMessage(
        Message(
          text: 'No pude obtener una respuesta. Inténtalo de nuevo.',
          fromWho: FromWho.hers,
        ),
      );
    }
  }

  void _addMessage(Message message) {
    _messages.add(message);
    notifyListeners();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}

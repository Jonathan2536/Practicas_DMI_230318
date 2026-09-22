import 'package:flutter/material.dart';
import 'package:flutter_yes_no_app_230318/presentation/widgets/chat/her_message_bubble.dart';
import 'package:flutter_yes_no_app_230318/presentation/widgets/chat/my_message_bubble.dart';
import 'package:flutter_yes_no_app_230318/presentation/widgets/shared/message_field_box.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [
    const _ChatMessage(text: 'Hola Mundo', isMine: false),
    const _ChatMessage(text: 'Laboris duis dolore', isMine: true),
  ];

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isMine: true));
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(4.0),
          child: CircleAvatar(
            backgroundImage: AssetImage('src/spiterman.jpg'),
          ),
        ),
        title: const Text('El espiterman'),
        centerTitle: false,
      ),
      body: _ChatView(
        messages: _messages,
        onSend: _sendMessage,
        scrollController: _scrollController,
      ),
    );
  }
}

class _ChatView extends StatelessWidget {
  final List<_ChatMessage> messages;
  final ValueChanged<String> onSend;
  final ScrollController scrollController;

  const _ChatView({
    required this.messages,
    required this.onSend,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return message.isMine
                      ? MyMessageBubble(text: message.text)
                      : HerMessageBubble(text: message.text);
                },
              ),
            ),
            MessageFieldBox(onSend: onSend),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isMine;

  const _ChatMessage({
    required this.text,
    required this.isMine,
  });
}

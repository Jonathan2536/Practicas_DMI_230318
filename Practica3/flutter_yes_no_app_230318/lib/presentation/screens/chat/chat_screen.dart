import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_yes_no_app_230318/domain/entities/message.dart';
import 'package:flutter_yes_no_app_230318/presentation/providers/chat_provider.dart';
import 'package:flutter_yes_no_app_230318/presentation/widgets/chat/her_message_bubble.dart';
import 'package:flutter_yes_no_app_230318/presentation/widgets/chat/my_message_bubble.dart';
import 'package:flutter_yes_no_app_230318/presentation/widgets/shared/message_field_box.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(4.0),
          child: CircleAvatar(backgroundImage: AssetImage('src/spiterman.jpg')),
        ),
        title: const Text('El espiterman'),
        centerTitle: false,
      ),
      body: _ChatView(
        messages: chatProvider.messages,
        onSend: chatProvider.sendMessage,
        scrollController: chatProvider.scrollController,
      ),
    );
  }
}

class _ChatView extends StatelessWidget {
  final List<Message> messages;
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
                  return message.fromWho == FromWho.me
                      ? MyMessageBubble(
                          text: message.text,
                          sentAt: message.sentAt,
                        )
                      : HerMessageBubble(
                          text: message.text,
                          sentAt: message.sentAt,
                          imageUrl: message.imageUrl,
                        );
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

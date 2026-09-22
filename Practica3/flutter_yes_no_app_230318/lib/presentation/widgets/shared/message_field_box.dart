import 'package:flutter/material.dart';

class MessageFieldBox extends StatefulWidget {
  final ValueChanged<String> onSend;

  const MessageFieldBox({
    super.key,
    required this.onSend,
  });

  @override
  State<MessageFieldBox> createState() => _MessageFieldBoxState();
}

class _MessageFieldBoxState extends State<MessageFieldBox> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    widget.onSend(text);
    _textController.clear();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outlineInputBorder = UnderlineInputBorder(
      borderSide: const BorderSide(color: Colors.transparent),
      borderRadius: BorderRadius.circular(40),
    );

    final inputDecoration = InputDecoration(
      hintText: 'End your message with a "?"',
      enabledBorder: outlineInputBorder,
      focusedBorder: outlineInputBorder,
      filled: true,
      suffixIcon: IconButton(
        icon: const Icon(Icons.send_outlined),
        onPressed: _sendMessage,
      ),
    );

    return TextFormField(
      onTapOutside: (event) {
        _focusNode.unfocus();
      },
      focusNode: _focusNode,
      controller: _textController,
      decoration: inputDecoration,
      onFieldSubmitted: (value) {
        _sendMessage();
      },
    );
  }
}

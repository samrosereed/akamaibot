import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class ChatMessage extends StatelessWidget {
  final types.TextMessage message;

  const ChatMessage({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isBotMessage = message.metadata != null && message.metadata!['isBot'] == true;
    if (kDebugMode) {
      print("Rendering message: ${message.text}, isBotMessage: $isBotMessage");
    } // Debug line

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isBotMessage)
          const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: Icon(Icons.android, color: Colors.green), // Bot icon
          ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: isBotMessage ? Colors.grey[200] : Colors.blue[100],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(message.text ?? ''),
          ),
        ),
      ],
    );
  }
}

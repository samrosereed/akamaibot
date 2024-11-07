import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';
import 'package:akamaibot/widget/chat_message.dart';

class ChatScreenPage extends StatefulWidget {
  const ChatScreenPage({Key? key}) : super(key: key);

  @override
  State<ChatScreenPage> createState() => _ChatScreenPageState();
}

class _ChatScreenPageState extends State<ChatScreenPage> {
  List<types.Message> _messages = [];
  final types.User user = const types.User(id: 'user-id'); // Your user ID here
  final Uuid uuid = const Uuid(); // UUID instance for unique message IDs

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

void _addWelcomeMessage() {
  final welcomeMessage = types.TextMessage(
    author: const types.User(id: 'bot-id', firstName: 'Bot'),
    createdAt: DateTime.now().millisecondsSinceEpoch,
    id: uuid.v4(),
    text: 'Aloha, welcome to the chat!',
    metadata: {'isBot': true}, // Adding metadata to mark as bot message
  );

    setState(() {
      _messages.insert(0, welcomeMessage);
    });
  }

  void handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: uuid.v4(),
      text: message.text,
    );

    setState(() {
      _messages.insert(0, textMessage);
    });
  }

Widget _customMessageBuilder(types.Message message, {required int messageWidth}) {
  if (message is types.TextMessage) {
    print("CustomMessageBuilder received message with metadata: ${message.metadata}"); // Debug line
    return ChatMessage(
      message: message,
    );
  } else {
    return const SizedBox.shrink();
  }
}


  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        appBarTheme: const AppBarTheme(
          color: Colors.black,
          foregroundColor: Colors.white,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('akamAI bot'),
        ),
        body: Chat(
          messages: _messages,
          onSendPressed: handleSendPressed,
          user: user,
          customMessageBuilder: _customMessageBuilder,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

const kIndigo = Color(0xFF6366F1);

class NewChatButton extends StatelessWidget {
  final VoidCallback onNewChat;
  final Function(ChatProvider) clearCurrentChat;

  const NewChatButton({
    super.key,
    required this.onNewChat,
    required this.clearCurrentChat,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        onNewChat();
        clearCurrentChat(context.read<ChatProvider>());
      },
      icon: const Icon(Icons.chat_bubble_outline, color: kIndigo),
      label: const Text('New chat'),
      style: ElevatedButton.styleFrom(
        foregroundColor: kIndigo,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: kIndigo),
        ),
      ),
    );
  }
} 
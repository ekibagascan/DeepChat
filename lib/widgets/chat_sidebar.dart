import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';

class ChatSidebar extends StatelessWidget {
  final List<ChatHistory> chatHistory;
  final Function(String) onChatSelected;
  final int selectedChatId;

  const ChatSidebar({
    super.key,
    required this.chatHistory,
    required this.onChatSelected,
    required this.selectedChatId,
  });

  List<MapEntry<String, List<ChatHistory>>> groupChatsByDate() {
    final Map<String, List<ChatHistory>> grouped = {};
    final now = DateTime.now();

    for (var chat in chatHistory) {
      String key;
      final difference = now.difference(chat.date).inDays;

      if (difference == 0) {
        key = 'Today';
      } else if (difference == 1) {
        key = 'Yesterday';
      } else if (difference < 7) {
        key = '${difference} days ago';
      } else if (difference < 30) {
        key = '${(difference / 7).floor()} weeks ago';
      } else {
        key = DateFormat('MMMM yyyy').format(chat.date);
      }

      grouped.putIfAbsent(key, () => []).add(chat);
    }

    return grouped.entries.toList()
      ..sort((a, b) {
        final dateOrder = {
          'Today': 0,
          'Yesterday': 1,
        };
        return (dateOrder[a.key] ?? 2).compareTo(dateOrder[b.key] ?? 2);
      });
  }

  @override
  Widget build(BuildContext context) {
    final groupedChats = groupChatsByDate();
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;

    return Container(
      width: 260,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // New Chat Button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: () => onChatSelected('new'),
              icon: const Icon(Icons.add),
              label: const Text('New Chat'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ),

          // Chat History List
          Expanded(
            child: ListView.builder(
              itemCount: groupedChats.length,
              itemBuilder: (context, index) {
                final group = groupedChats[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        group.key,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    ...group.value.map((chat) => ListTile(
                          selected: chat.id == selectedChatId,
                          leading: const Icon(Icons.chat_bubble_outline),
                          title: Text(
                            chat.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => onChatSelected(chat.id.toString()),
                        )),
                  ],
                );
              },
            ),
          ),

          // User Profile Section
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                ),
              ),
              title: Text(
                user?.email ?? 'User',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                // Navigate to account settings
                Navigator.pushNamed(context, '/account');
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ChatHistory {
  final int id;
  final String title;
  final DateTime date;

  ChatHistory({
    required this.id,
    required this.title,
    required this.date,
  });
} 
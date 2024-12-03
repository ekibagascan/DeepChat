import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/chat_history.dart';
import '../screens/settings_screen.dart';
import '../screens/subscription_screen.dart';
import 'profile_section.dart';

const kIndigo = Color(0xFF6366F1);
const kDarkGray = Color(0xFF505050);
const kPlaceholderGray = Color(0xFFC4C4C4);

class ChatSidebar extends StatelessWidget {
  final Function(String) onChatSelected;
  final int selectedChatId;

  const ChatSidebar({
    super.key,
    required this.onChatSelected,
    required this.selectedChatId,
  });

  List<MapEntry<String, List<Map<String, dynamic>>>> groupChatsByDate(List<Map<String, dynamic>> chats) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    final now = DateTime.now();

    for (var chat in chats) {
      final date = DateTime.parse(chat['created_at']);
      final difference = now.difference(date).inDays;

      String key;
      if (difference == 0) {
        key = 'Today';
      } else if (difference == 1) {
        key = 'Yesterday';
      } else if (difference < 7) {
        key = '${difference} days ago';
      } else if (difference < 30) {
        key = '${(difference / 7).floor()} weeks ago';
      } else {
        key = DateFormat('MMMM yyyy').format(date);
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
    final authService = context.watch<AuthService>();
    final chatProvider = context.watch<ChatProvider>();
    final user = authService.currentUser;
    final groupedChats = groupChatsByDate(chatProvider.chatHistory);
    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      width: screenWidth * 0.8,
      child: Drawer(
        child: Column(
          children: [
            // Logo and Close Button Row
            Container(
              padding: const EdgeInsets.fromLTRB(16, 71, 8, 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Centered Logo
                  const Center(
                    child: Text(
                      'deepchat',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: kDarkGray,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  // Close button aligned to the right
                  Positioned(
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: kPlaceholderGray),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),

            // New Chat Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: ElevatedButton.icon(
                onPressed: () => onChatSelected('new'),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('New Chat'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: kIndigo,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ),

            // Chat History List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 30),
                itemCount: groupedChats.length,
                itemBuilder: (context, index) {
                  final group = groupedChats[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 16, 1),
                        child: Text(
                          group.key,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ...group.value.map((chat) => Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          selected: chat['id'].toString() == selectedChatId.toString(),
                          selectedTileColor: kIndigo.withOpacity(0.1),
                          title: Text(
                            chat['title'] ?? 'New Chat',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: PopupMenuButton(
                              icon: const Icon(Icons.more_vert, color: kPlaceholderGray),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'rename',
                                  child: Text('Rename'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                              onSelected: (value) async {
                                if (value == 'rename') {
                                  final controller = TextEditingController(
                                    text: chat['title'] ?? 'New Chat'
                                  );
                                  final newTitle = await showDialog<String>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Rename Chat'),
                                      content: TextField(
                                        controller: controller,
                                        decoration: const InputDecoration(
                                          labelText: 'Chat Name',
                                        ),
                                        autofocus: true,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, controller.text),
                                          child: const Text('Rename'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (newTitle != null && newTitle.isNotEmpty) {
                                    await context.read<ChatProvider>().renameChat(
                                      chat['id'].toString(),
                                      newTitle,
                                    );
                                  }
                                } else if (value == 'delete') {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Chat'),
                                      content: const Text(
                                        'Are you sure you want to delete this chat? This action cannot be undone.'
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await context.read<ChatProvider>().deleteChat(
                                      chat['id'].toString(),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                          onTap: () => onChatSelected(chat['id'].toString()),
                        ),
                      )),
                      if (index < groupedChats.length - 1)
                        const SizedBox(height: 8),
                    ],
                  );
                },
              ),
            ),

            // Profile Section
            ProfileSection(sidebarWidth: screenWidth * 0.8),
          ],
        ),
      ),
    );
  }
} 
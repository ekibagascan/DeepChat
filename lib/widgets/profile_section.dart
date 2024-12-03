import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/chat_provider.dart';
import '../screens/settings_screen.dart';
import '../screens/subscription_screen.dart';

const kIndigo = Color(0xFF6366F1);
const kDarkGray = Color(0xFF505050);
const kPlaceholderGray = Color(0xFFC4C4C4);

class ProfileSection extends StatelessWidget {
  final double sidebarWidth;

  const ProfileSection({
    super.key,
    required this.sidebarWidth,
  });

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final chatProvider = context.watch<ChatProvider>();
    final user = authService.currentUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: sidebarWidth,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          minLeadingWidth: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Icon(Icons.person_outline, color: kDarkGray),
          ),
          title: const Text('My Profile'),
          trailing: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(Icons.chevron_right, color: kPlaceholderGray),
          ),
          onTap: () {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(12),
                  topLeft: Radius.circular(12),
                ),
              ),
              builder: (context) => Container(
                width: sidebarWidth,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Email with Avatar
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                      leading: CircleAvatar(
                        backgroundColor: kIndigo.withOpacity(0.1),
                        child: Text(
                          user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(
                            color: kIndigo,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        user?.email ?? 'No email',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      enabled: false,
                    ),
                    const Divider(height: 1),
                    
                    // Settings
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                      dense: true,
                      leading: const Icon(Icons.settings_outlined),
                      title: const Text('Settings'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/settings');
                      },
                    ),

                    // Subscriptions
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                      dense: true,
                      leading: const Icon(Icons.card_membership),
                      title: const Text('Subscriptions'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/subscription');
                      },
                    ),

                    // Delete All Chats
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                      dense: true,
                      leading: const Icon(Icons.delete_outline, color: Colors.red),
                      title: const Text('Delete All Chats', 
                        style: TextStyle(color: Colors.red)),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete All Chats'),
                            content: const Text(
                              'Are you sure you want to delete all chats? This action cannot be undone.'
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                  
                                  final userId = user?.id;
                                  if (userId != null) {
                                    await chatProvider.deleteAllChats(userId);
                                  }
                                },
                                child: const Text('Delete', 
                                  style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Contact Us
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                      dense: true,
                      leading: const Icon(Icons.mail_outline),
                      title: const Text('Contact Us'),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Contact: support@deepchat.com'),
                          ),
                        );
                      },
                    ),

                    // Log Out
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                      dense: true,
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text('Log Out', 
                        style: TextStyle(color: Colors.red)),
                      onTap: () async {
                        await context.read<AuthService>().signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushReplacementNamed('/login');
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
} 
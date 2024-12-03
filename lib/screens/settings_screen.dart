import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Profile Section
          const ListTile(
            title: Text('Profile Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Implement edit profile
            },
          ),

          const Divider(),

          // General Settings
          const ListTile(
            title: Text('General Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            trailing: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('English'),
                Icon(Icons.chevron_right),
              ],
            ),
            onTap: () {
              // Implement language selection
            },
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Theme'),
            trailing: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Light'),
                Icon(Icons.chevron_right),
              ],
            ),
            onTap: () {
              // Implement theme selection
            },
          ),

          const Divider(),

          // Notification Settings
          const ListTile(
            title: Text('Notifications',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Push Notifications'),
            value: true, // You should manage this with state
            onChanged: (bool value) {
              // Implement notification toggle
            },
          ),

          const Divider(),

          // About Section
          const ListTile(
            title: Text('About',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App Version'),
            trailing: const Text('1.0.0'),
          ),
        ],
      ),
    );
  }
} 
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuPressed;
  final VoidCallback onNewChatPressed;

  const CustomAppBar({
    super.key,
    required this.onMenuPressed,
    required this.onNewChatPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF9E9E9E), size: 24),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
          splashRadius: 20,
          hoverColor: Colors.grey[200],
        ),
      ),
      title: const Text(
        'deepchat',
        style: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.add_comment_outlined, color: Color(0xFF9E9E9E), size: 20),
          onPressed: onNewChatPressed,
          splashRadius: 20,
          hoverColor: Colors.grey[200],
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
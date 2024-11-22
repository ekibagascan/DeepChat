import 'package:flutter/material.dart';
import '../api/deepseek_api.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_sidebar.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/storage_service.dart';
import 'package:file_picker/file_picker.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _messages = <Map<String, String>>[];
  final _deepSeekAPI = DeepSeekAPI();
  bool _isLoading = false;
  int _selectedChatId = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isSidebarVisible = true;
  final _storageService = StorageService();
  final _picker = ImagePicker();

  // Sample chat history data
  final List<ChatHistory> _chatHistory = [
    ChatHistory(
      id: 1,
      title: "Flutter Development Discussion",
      date: DateTime.now(),
    ),
    ChatHistory(
      id: 2,
      title: "API Integration Help",
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ChatHistory(
      id: 3,
      title: "Database Design",
      date: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarVisible = !_isSidebarVisible;
      if (_isSidebarVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final userMessage = _messageController.text;
    setState(() {
      _messages.add({'role': 'user', 'content': userMessage});
      _isLoading = true;
    });
    _messageController.clear();

    try {
      final response = await _deepSeekAPI.sendMessage(userMessage);
      setState(() {
        _messages.add({'role': 'assistant', 'content': response});
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleChatSelected(String chatId) {
    setState(() {
      _selectedChatId = int.parse(chatId);
      // For mobile devices, hide sidebar after selection
      if (MediaQuery.of(context).size.width < 600) {
        _toggleSidebar();
      }
    });
  }

  Future<void> _handleImageSelection() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() => _isLoading = true);
      
      try {
        final imageFile = File(image.path);
        final userId = context.read<AuthService>().currentUser!.id;
        
        // Upload image
        final imageUrl = await _storageService.uploadImage(imageFile, userId);
        
        // Send message with image
        await context.read<ChatProvider>().sendMessage(
          'Sent an image',
          imageUrl: imageUrl,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send image: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
    );
    
    if (result != null && result.files.single.path != null) {
      setState(() => _isLoading = true);
      
      try {
        final file = File(result.files.single.path!);
        final userId = context.read<AuthService>().currentUser!.id;
        
        // Upload file
        final fileResult = await _storageService.uploadFile(file, userId);
        
        // Send message with file
        final displayName = fileResult.fileName.length > 20 
            ? '${fileResult.fileName.substring(0, 17)}...' 
            : fileResult.fileName;
            
        await context.read<ChatProvider>().sendMessage(
          'Sent a file: $displayName',
          fileUrl: fileResult.url,
          mimeType: fileResult.mimeType,
          fileName: fileResult.fileName,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send file: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main Chat Area
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    // App Bar with menu button
                    AppBar(
                      leading: IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: _toggleSidebar,
                      ),
                      title: const Text('Chat'),
                    ),
                    // Messages List
                    Expanded(
                      child: ListView.builder(
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return MessageBubble(
                            message: message['content']!,
                            isUser: message['role'] == 'user',
                          );
                        },
                      ),
                    ),
                    
                    // Loading Indicator
                    if (_isLoading) const LinearProgressIndicator(),
                    
                    // Message Input
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.attach_file),
                            onPressed: _handleImageSelection,
                          ),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                hintText: 'Type a message...',
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          IconButton(
                            onPressed: _sendMessage,
                            icon: const Icon(Icons.send),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Sidebar with gesture detection
          if (_isSidebarVisible)
            GestureDetector(
              onTap: _toggleSidebar,
              child: Container(
                color: Colors.black54,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
              ),
            ),

          // Animated Sidebar
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return GestureDetector(
                onHorizontalDragUpdate: (details) {
                  if (details.delta.dx < -10 && _isSidebarVisible) {
                    _toggleSidebar();
                  } else if (details.delta.dx > 10 && !_isSidebarVisible) {
                    _toggleSidebar();
                  }
                },
                child: Transform.translate(
                  offset: Offset(-260 * (1 - _animation.value), 0),
                  child: child,
                ),
              );
            },
            child: ChatSidebar(
              chatHistory: _chatHistory,
              onChatSelected: _handleChatSelected,
              selectedChatId: _selectedChatId,
            ),
          ),
        ],
      ),
    );
  }
} 
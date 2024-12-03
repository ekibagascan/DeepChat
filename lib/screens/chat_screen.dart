import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/deepseek_api.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_sidebar.dart';
import '../services/auth_service.dart';
import '../providers/chat_provider.dart';
import '../services/storage_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/chat_history.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/chat_input_section.dart';
import '../widgets/new_chat_button.dart';

// Add these color constants at the top of the file
const kLightGray = Color(0xFFF8F9FB);
const kPlaceholderGray = Color(0xFFC4C4C4);
const kDarkGray = Color(0xFF505050);
const kIndigo = Color(0xFF6366F1);
const kLightIndigo = Color(0xFFEEF4FF);

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _deepSeekAPI = DeepSeekAPI();
  bool _isLoading = false;
  bool _isAIResponding = false;
  int _selectedChatId = 0;
  bool _isNewChat = true;
  final _storageService = StorageService();
  final _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();
  bool _isSendEnabled = false;
  FileUploadState? _uploadedFile;
  bool _isUploading = false;
  bool _uploadCancelled = false;

  void _handleStopResponse() {
    setState(() {
      _isAIResponding = false;
    });
    context.read<ChatProvider>().stopAIResponse();
  }

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() {
        _isSendEnabled = _messageController.text.isNotEmpty;
      });
    });

    // Load chat history when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthService>().currentUser?.id;
      if (userId != null) {
        context.read<ChatProvider>().loadChatHistory(userId);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty && _uploadedFile == null) return;
    if (_isUploading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for file upload to complete')),
      );
      return;
    }

    final message = _messageController.text;
    final fileToSend = _uploadedFile;  // Store reference before clearing
    
    // Clear input immediately
    _messageController.clear();

    try {
      final userId = context.read<AuthService>().currentUser?.id;
      if (userId == null) {
        debugPrint('No user ID found');
        return;
      }

      final chatProvider = context.read<ChatProvider>();

      // Create new chat if needed
      if (chatProvider.currentChatId == null) {
        await chatProvider.createNewChat(
          userId, 
          message.isNotEmpty ? message : 'Sent a file',
          fileUrl: fileToSend?.previewUrl,
          mimeType: fileToSend?.mimeType,
          fileName: fileToSend?.fileName,
        );
      } else {
        // Only send message if not creating a new chat
        await chatProvider.sendMessage(
          message.isNotEmpty ? message : 'Sent a file',
          fileUrl: fileToSend?.previewUrl,
          mimeType: fileToSend?.mimeType,
          fileName: fileToSend?.fileName,
        );
      }

      // Clear attachment immediately after sending message
      if (mounted) {
        setState(() {
          _isNewChat = false;
          _uploadedFile = null;
        });
      }

      debugPrint('Message sent successfully');
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _handleChatSelected(String chatId) {
    final chatProvider = context.read<ChatProvider>();
    chatProvider.loadMessages(chatId);
    setState(() {
      _selectedChatId = int.tryParse(chatId) ?? 0;
      _isNewChat = false;
    });
  }

  Future<void> _handleImageSelection() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        final file = File(image.path);
        setState(() {
          _isUploading = true;
          _uploadCancelled = false;
          _uploadedFile = FileUploadState(
            fileName: image.name,
            fileSize: file.lengthSync(),
            previewUrl: image.path,
            mimeType: 'image/jpeg',
            onRemove: () async {
              if (_isUploading) {
                setState(() {
                  _uploadCancelled = true;
                  _uploadedFile = null;
                });
              } else {
                setState(() => _uploadedFile = null);
              }
            },
          );
        });

        // Start upload process
        await _processFile(file, null);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _handleCameraCapture() async {
    try {
      debugPrint('Starting camera capture...');
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      
      if (photo != null) {
        debugPrint('Photo captured: ${photo.path}');
        await _processFile(File(photo.path));
      } else {
        debugPrint('No photo captured');
      }
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing photo: $e')),
        );
      }
    }
  }

  Future<void> _handleFilePicker() async {
    try {
      debugPrint('Starting file picker...');
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );
      
      if (result != null && result.files.single.path != null) {
        debugPrint('File selected: ${result.files.single.path}');
        await _processFile(File(result.files.single.path!));
      } else {
        debugPrint('No file selected');
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting file: $e')),
        );
      }
    }
  }

  Future<void> _processFile(File file, [String? message]) async {
    setState(() {
      _isUploading = true;
      _uploadCancelled = false;
      // Set a temporary upload state to show loading
      _uploadedFile = FileUploadState(
        fileName: file.path.split('/').last,
        fileSize: file.lengthSync(),
        previewUrl: null,  // Will be updated after upload
        mimeType: file.path.toLowerCase().endsWith('.jpg') || file.path.toLowerCase().endsWith('.jpeg') 
          ? 'image/jpeg' 
          : file.path.toLowerCase().endsWith('.png') 
            ? 'image/png' 
            : 'application/octet-stream',
        onRemove: () async {
          setState(() {
            _uploadCancelled = true;
            _uploadedFile = null;
            _isUploading = false;
          });
        },
      );
    });

    try {
      final userId = context.read<AuthService>().currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Upload file
      final fileResult = await _storageService.uploadFile(file, userId);
      
      // Check if upload was cancelled
      if (_uploadCancelled) {
        // Clean up the uploaded file from storage
        await _storageService.deleteFile(fileResult.url);
        return;
      }

      debugPrint('File uploaded successfully');
      
      if (mounted) {
        // Update uploadedFile state with the uploaded file info
        setState(() {
          _isUploading = false;
          _uploadedFile = FileUploadState(
            fileName: fileResult.fileName,
            fileSize: file.lengthSync(),
            previewUrl: fileResult.url,
            mimeType: fileResult.mimeType,
            onRemove: () async {
              if (_isUploading) {
                setState(() {
                  _uploadCancelled = true;
                  _uploadedFile = null;
                });
              } else {
                // Delete the file from storage when removed
                await _storageService.deleteFile(fileResult.url);
                setState(() => _uploadedFile = null);
              }
            },
          );
        });
      }
    } catch (e) {
      debugPrint('Error processing file: $e');
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadedFile = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload file: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Add this method to handle new chat actions
  void _handleNewChat() {
    setState(() {
      _isNewChat = true;
      _selectedChatId = 0;
      context.read<ChatProvider>().clearCurrentChat();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final messages = chatProvider.messages;

    // Update _isAIResponding based on the last message
    if (messages.isNotEmpty) {
      final isTyping = messages.last['role'] == 'assistant_typing';
      if (isTyping != _isAIResponding) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _isAIResponding = isTyping;
          });
        });
      }
    }

    return Scaffold(
      extendBody: true,
      appBar: CustomAppBar(
        onMenuPressed: () {},
        onNewChatPressed: _handleNewChat,
      ),
      drawer: Builder(
        builder: (context) => ChatSidebar(
          onChatSelected: (chatId) {
            if (chatId == 'new') {
              _handleNewChat();
            } else {
              _handleChatSelected(chatId);
            }
            Navigator.pop(context);
          },
          selectedChatId: _selectedChatId,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Stack(
          children: [
            // Welcome message and logo for new chat
            if (_isNewChat)
              Stack(
                children: [
                  // Welcome message and logo
                  Positioned(
                    top: 167.0, // Explicit positioning
                    left: 30.0, // Align to the left
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset('assets/ai_avatar.png', height: 50),
                        const SizedBox(height: 16),
                        const Text(
                          "Hi, I'm DeepSeek.",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: kDarkGray,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "How can I help you today?",
                          style: TextStyle(
                            fontSize: 16,
                            color: kPlaceholderGray,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Message input section
                  Positioned(
                    top: 320.0,
                    left: 14.0,
                    right: 14.0,
                    child: Column(
                      children: [
                        if (!_isNewChat)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: NewChatButton(
                              onNewChat: _handleNewChat,
                              clearCurrentChat: (provider) => provider.clearCurrentChat(),
                            ),
                          ),
                        Material(
                          type: MaterialType.transparency,
                          child: ChatInputSection(
                            messageController: _messageController,
                            isNewChat: _isNewChat,
                            isSendEnabled: _isSendEnabled,
                            onNewChat: _handleNewChat,
                            onSendMessage: _sendMessage,
                            onFileSelection: _handleImageSelection,
                            onCameraCapture: _handleCameraCapture,
                            onFilePicker: _handleFilePicker,
                            clearCurrentChat: (provider) => provider.clearCurrentChat(),
                            uploadedFile: _uploadedFile,
                            isAIResponding: _isAIResponding,
                            onStopResponse: _handleStopResponse,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            // Main chat content
            if (!_isNewChat)  // Only show this when not in new chat state
              Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(bottom: 200),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        return MessageBubble(
                          message: message['content'],
                          isUser: message['role'] == 'user',
                          fileUrl: message['file_url'],
                          mimeType: message['file_type'],
                          fileName: message['file_name'],
                          userEmail: context.read<AuthService>().currentUser?.email,
                          isAssistant: message['role'] == 'assistant' || message['role'] == 'assistant_typing',
                          isTyping: message['role'] == 'assistant_typing',
                          messageId: message['id']?.toString(),
                        );
                      },
                    ),
                  ),
                  
                  // // New Chat Button
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  //   child: NewChatButton(
                  //     onNewChat: _handleNewChat,
                  //     clearCurrentChat: (provider) => provider.clearCurrentChat(),
                  //   ),
                  // ),
                  
                  // Input Section for chat mode
                  Material(
                    type: MaterialType.transparency,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: ChatInputSection(
                        messageController: _messageController,
                        isNewChat: _isNewChat,
                        isSendEnabled: _isSendEnabled,
                        onNewChat: _handleNewChat,
                        onSendMessage: _sendMessage,
                        onFileSelection: _handleImageSelection,
                        onCameraCapture: _handleCameraCapture,
                        onFilePicker: _handleFilePicker,
                        clearCurrentChat: (provider) => provider.clearCurrentChat(),
                        uploadedFile: _uploadedFile,
                        isAIResponding: _isAIResponding,
                        onStopResponse: _handleStopResponse,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
} 
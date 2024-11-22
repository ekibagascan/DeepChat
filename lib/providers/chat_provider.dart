import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';
import '../api/deepseek_api.dart';

class ChatProvider extends ChangeNotifier {
  final SupabaseService _supabaseService;
  final DeepSeekAPI _deepSeekAPI;
  String? _currentChatId;
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _chatHistory = [];
  bool _isLoading = false;

  ChatProvider({
    required SupabaseService supabaseService,
    required DeepSeekAPI deepSeekAPI,
  })  : _supabaseService = supabaseService,
        _deepSeekAPI = deepSeekAPI;

  List<Map<String, dynamic>> get messages => _messages;
  List<Map<String, dynamic>> get chatHistory => _chatHistory;
  bool get isLoading => _isLoading;
  String? get currentChatId => _currentChatId;

  Future<void> loadChatHistory(String userId) async {
    try {
      _chatHistory = await _supabaseService.getChatHistory(userId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createNewChat(String userId, String initialMessage) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Create new chat
      _currentChatId = await _supabaseService.createChat(
        userId,
        initialMessage.length > 50 
            ? '${initialMessage.substring(0, 47)}...' 
            : initialMessage,
      );

      // Save user message
      await _supabaseService.saveMessage(
        chatId: _currentChatId!,
        role: 'user',
        content: initialMessage,
      );

      // Get AI response
      final response = await _deepSeekAPI.sendMessage(initialMessage);

      // Save AI response
      await _supabaseService.saveMessage(
        chatId: _currentChatId!,
        role: 'assistant',
        content: response,
      );

      // Load messages
      await loadMessages(_currentChatId!);
      
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMessages(String chatId) async {
    try {
      _currentChatId = chatId;
      _messages = await _supabaseService.getChatMessages(chatId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendMessage(String content, {String? imageUrl}) async {
    if (_currentChatId == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      // Save user message with image if present
      await _supabaseService.saveMessage(
        chatId: _currentChatId!,
        role: 'user',
        content: content,
        imageUrl: imageUrl,
      );

      // Only get AI response if there's text content
      if (content.isNotEmpty && content != 'Sent an image') {
        // Get AI response
        final response = await _deepSeekAPI.sendMessage(content);

        // Save AI response
        await _supabaseService.saveMessage(
          chatId: _currentChatId!,
          role: 'assistant',
          content: response,
        );
      }

      // Reload messages
      await loadMessages(_currentChatId!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 
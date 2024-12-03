import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../api/deepseek_api.dart';

class ChatProvider extends ChangeNotifier {
  final SupabaseService _supabaseService;
  final DeepSeekAPI _deepSeekAPI;
  final _supabase = Supabase.instance.client;
  String? _currentChatId;
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _chatHistory = [];
  bool _isLoading = false;
  bool _shouldStopResponse = false;

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

  Future<void> createNewChat(
    String userId, 
    String initialMessage, {
    String? fileUrl,
    String? mimeType,
    String? fileName,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Create new chat in database
      final response = await _supabase
        .from('chats')
        .insert({
          'user_id': userId,
          'title': initialMessage.length > 50 
              ? '${initialMessage.substring(0, 47)}...' 
              : initialMessage,
        })
        .select()
        .single();

      // Update local state with new chat
      _currentChatId = response['id'];
      _chatHistory.insert(0, response); // Add to beginning of list
      notifyListeners();

      // Add user message immediately
      _messages = [
        {
          'role': 'user',
          'content': initialMessage,
          'file_url': fileUrl,
          'file_type': mimeType,
          'file_name': fileName,
          'timestamp': DateTime.now().toIso8601String(),
        }
      ];
      notifyListeners();

      // Add thinking indicator
      _messages.add({
        'role': 'assistant_typing',
        'content': '',
        'timestamp': DateTime.now().toIso8601String(),
      });
      notifyListeners();

      // Get AI response with empty history since this is a new chat
      String currentResponse = '';
      await for (final char in _deepSeekAPI.streamMessage(initialMessage, [])) {  // Pass empty list as history
        currentResponse += char;
        _messages.last['content'] = currentResponse;
        notifyListeners();
      }

      // Update final message
      _messages.last['role'] = 'assistant';
      notifyListeners();

      // Save initial user message with file info first
      await _supabaseService.saveMessage(
        chatId: _currentChatId!,
        role: 'user',
        content: initialMessage,
        fileUrl: fileUrl,
        mimeType: mimeType,
        fileName: fileName,
      );

      // Save final response after
      await _supabaseService.saveMessage(
        chatId: _currentChatId!,
        role: 'assistant',
        content: currentResponse,
      );
    } catch (e) {
      debugPrint('Error creating chat: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMessages(String chatId) async {
    try {
      _currentChatId = chatId;
      // Get messages and sort them by timestamp
      final messages = await _supabaseService.getChatMessages(chatId);
      _messages = List<Map<String, dynamic>>.from(messages)
        ..sort((a, b) => DateTime.parse(a['created_at'])
            .compareTo(DateTime.parse(b['created_at']))); // Sort by timestamp
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading messages: $e');
      rethrow;
    }
  }

  Future<void> sendMessage(
    String content, {
    String? fileUrl,
    String? mimeType,
    String? fileName,
  }) async {
    try {
      // Add user message immediately
      _messages.add({
        'role': 'user',
        'content': content,
        'file_url': fileUrl,
        'file_type': mimeType,
        'file_name': fileName,
        'timestamp': DateTime.now().toIso8601String(),
      });
      notifyListeners();

      // Save user message and notify completion
      await _supabaseService.saveMessage(
        chatId: _currentChatId!,
        role: 'user',
        content: content,
        fileUrl: fileUrl,
        mimeType: mimeType,
        fileName: fileName,
      );

      // Get AI response in a separate async operation
      _handleAIResponse(content);
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  Future<void> _handleAIResponse(String userMessage) async {
    try {
      _shouldStopResponse = false;
      // Add thinking indicator
      _messages.add({
        'role': 'assistant_typing',
        'content': '',
        'timestamp': DateTime.now().toIso8601String(),
      });
      notifyListeners();

      // Get AI response with conversation history
      String currentResponse = '';
      await for (final char in _deepSeekAPI.streamMessage(userMessage, _messages.where((m) => m['role'] != 'assistant_typing').toList())) {
        if (_shouldStopResponse) {
          // If stopped, update the last message with current response
          if (_messages.isNotEmpty && _messages.last['role'] == 'assistant_typing') {
            _messages.last['role'] = 'assistant';
            _messages.last['content'] = currentResponse;
            notifyListeners();
          }
          break;
        }
        currentResponse += char;
        // Update the typing message content
        if (_messages.isNotEmpty && _messages.last['role'] == 'assistant_typing') {
          _messages.last['content'] = currentResponse;
          notifyListeners();
        }
      }

      // Update final message if not stopped
      if (!_shouldStopResponse && _messages.isNotEmpty && _messages.last['role'] == 'assistant_typing') {
        _messages.last['role'] = 'assistant';
        notifyListeners();
      }

      // Save final response only if not stopped
      if (!_shouldStopResponse && _messages.isNotEmpty && _messages.last['role'] == 'assistant') {
        await _supabaseService.saveMessage(
          chatId: _currentChatId!,
          role: 'assistant',
          content: currentResponse,
        );
      }
    } catch (e) {
      debugPrint('Error getting AI response: $e');
      if (_messages.isNotEmpty && _messages.last['role'] == 'assistant_typing') {
        _messages.removeLast();
        notifyListeners();
      }
    }
  }

  void clearCurrentChat() {
    _currentChatId = null;
    _messages = [];
    notifyListeners();
  }

  Future<void> deleteAllChats(String userId) async {
    try {
      // Delete all messages first
      await _supabase
        .from('messages')
        .delete()
        .eq('user_id', userId);

      // Then delete all chats
      await _supabase
        .from('chats')
        .delete()
        .eq('user_id', userId);

      // Clear local state
      _chatHistory.clear();
      _messages.clear();
      _currentChatId = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting all chats: $e');
      rethrow;
    }
  }

  Future<void> renameChat(String chatId, String newTitle) async {
    try {
      await _supabase
        .from('chats')
        .update({'title': newTitle})
        .eq('id', chatId);

      // Update local state
      final index = _chatHistory.indexWhere((chat) => chat['id'].toString() == chatId);
      if (index != -1) {
        _chatHistory[index]['title'] = newTitle;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error renaming chat: $e');
      rethrow;
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      // Delete messages first
      await _supabase
        .from('messages')
        .delete()
        .eq('chat_id', chatId);

      // Then delete the chat
      await _supabase
        .from('chats')
        .delete()
        .eq('id', chatId);

      // Update local state
      _chatHistory.removeWhere((chat) => chat['id'].toString() == chatId);
      if (_currentChatId?.toString() == chatId) {
        _currentChatId = null;
        _messages.clear();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting chat: $e');
      rethrow;
    }
  }

  void stopAIResponse() {
    _shouldStopResponse = true;
  }

  Future<void> regenerateResponse(String previousUserMessage) async {
    try {
      // Remove the last assistant message
      if (_messages.isNotEmpty && _messages.last['role'] == 'assistant') {
        _messages.removeLast();
        notifyListeners();
      }

      // Get AI response again
      await _handleAIResponse(previousUserMessage);
    } catch (e) {
      debugPrint('Error regenerating response: $e');
      rethrow;
    }
  }

  Future<void> handleFeedback(String messageId, bool isLike, [String? feedbackMessage]) async {
    try {
      // Save feedback to database
      await _supabase
        .from('message_feedback')
        .upsert({
          'message_id': messageId,
          'is_like': isLike,
          'feedback_message': feedbackMessage,
          'created_at': DateTime.now().toIso8601String(),
        });

      // Optionally update local state if needed
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving feedback: $e');
      rethrow;
    }
  }
} 
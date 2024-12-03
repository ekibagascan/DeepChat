import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/subscription_model.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;

  // Chat Methods
  Future<List<Map<String, dynamic>>> getChatHistory(String userId) async {
    final response = await _supabase
        .from('chats')
        .select()
        .eq('user_id', userId)
        .order('last_message_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<String> createChat(String userId, String title) async {
    final response = await _supabase
        .from('chats')
        .insert({
          'user_id': userId,
          'title': title,
        })
        .select()
        .single();

    return response['id'];
  }

  Future<List<Map<String, dynamic>>> getChatMessages(String chatId) async {
    final response = await _supabase
        .from('messages')
        .select()
        .eq('chat_id', chatId)
        .order('created_at');

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> saveMessage({
    required String chatId,
    required String role,
    required String content,
    String? fileUrl,
    String? mimeType,
    String? fileName,
  }) async {
    // Save message
    await _supabase
        .from('messages')
        .insert({
          'chat_id': chatId,
          'role': role,
          'content': content,
          'file_url': fileUrl,
          'file_type': mimeType,
          'file_name': fileName,
        });

    // Update chat's last_message_at
    await _supabase
        .from('chats')
        .update({'last_message_at': DateTime.now().toIso8601String()})
        .eq('id', chatId);
  }

  // User Methods
  Future<UserModel?> getUser(String userId) async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('id', userId)
        .single();
    
    if (response != null) {
      return UserModel.fromJson(response);
    }
    return null;
  }

  Future<void> updateSubscriptionStatus(String userId, String status) async {
    await _supabase
        .from('users')
        .update({'subscription_status': status})
        .eq('id', userId);
  }

  Future<void> createSubscription(SubscriptionModel subscription) async {
    await _supabase
        .from('subscriptions')
        .insert(subscription.toJson());
  }
} 
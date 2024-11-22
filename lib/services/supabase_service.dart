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
        .order('last_message_at', ascending: false)
        .execute();

    if (response.error != null) {
      throw response.error!;
    }

    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<String> createChat(String userId, String title) async {
    final response = await _supabase
        .from('chats')
        .insert({
          'user_id': userId,
          'title': title,
        })
        .select()
        .single()
        .execute();

    if (response.error != null) {
      throw response.error!;
    }

    return response.data['id'];
  }

  Future<List<Map<String, dynamic>>> getChatMessages(String chatId) async {
    final response = await _supabase
        .from('messages')
        .select()
        .eq('chat_id', chatId)
        .order('created_at')
        .execute();

    if (response.error != null) {
      throw response.error!;
    }

    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<void> saveMessage({
    required String chatId,
    required String role,
    required String content,
    String? imageUrl,
  }) async {
    // Save message
    final messageResponse = await _supabase
        .from('messages')
        .insert({
          'chat_id': chatId,
          'role': role,
          'content': content,
          'image_url': imageUrl,
        })
        .execute();

    if (messageResponse.error != null) {
      throw messageResponse.error!;
    }

    // Update chat's last_message_at
    final chatResponse = await _supabase
        .from('chats')
        .update({'last_message_at': DateTime.now().toIso8601String()})
        .eq('id', chatId)
        .execute();

    if (chatResponse.error != null) {
      throw chatResponse.error!;
    }
  }

  // Existing methods...
  Future<UserModel?> getUser(String userId) async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('id', userId)
        .single()
        .execute();
    
    if (response.data != null) {
      return UserModel.fromJson(response.data);
    }
    return null;
  }

  Future<void> updateSubscriptionStatus(String userId, String status) async {
    await _supabase
        .from('users')
        .update({'subscription_status': status})
        .eq('id', userId)
        .execute();
  }

  Future<void> createSubscription(SubscriptionModel subscription) async {
    await _supabase
        .from('subscriptions')
        .insert(subscription.toJson())
        .execute();
  }
} 
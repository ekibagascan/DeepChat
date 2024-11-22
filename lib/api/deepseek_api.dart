import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DeepSeekAPI {
  final String baseUrl = 'https://api.deepseek.com/v1';
  final String apiKey = dotenv.env['DEEPSEEK_API_KEY']!;

  Future<String> sendMessage(String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'messages': [{'role': 'user', 'content': message}],
        'model': 'deepseek-chat',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Failed to get response from DeepSeek API');
    }
  }
} 
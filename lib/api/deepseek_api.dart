import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:characters/characters.dart';

class DeepSeekAPI {
  final String? _apiKey = dotenv.env['DEEPSEEK_API_KEY'];
  final _client = http.Client();
  final _dio = Dio();
  final _baseUrl = 'https://api.deepseek.com/v1';

  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  Stream<String> streamMessage(String message, List<Map<String, dynamic>> previousMessages, {String? imageUrl}) async* {
    if (!isConfigured) {
      debugPrint('DeepSeek API key not configured');
      yield 'Error: DeepSeek API key not configured. Please check your .env file.';
      return;
    }

    debugPrint('Sending message to DeepSeek: $message');
    debugPrint('Image URL if any: $imageUrl');
    
    try {
      // Convert previous messages to DeepSeek format
      final List<Map<String, dynamic>> messageHistory = previousMessages.map((msg) => {
        'role': msg['role'] == 'user' ? 'user' : 'assistant',
        'content': msg['content'],
      }).toList();

      // Add current message with image if provided
      if (imageUrl != null) {
        messageHistory.add({
          'role': 'user',
          'content': [
            {'type': 'text', 'text': message},
            {
              'type': 'image',
              'source': {
                'type': 'url',
                'url': imageUrl
              }
            }
          ]
        });
      } else {
        messageHistory.add({
          'role': 'user',
          'content': message,
        });
      }

      final requestBody = {
        'model': 'deepseek-chat',  // Use standard model which supports multimodal
        'messages': messageHistory,
        'temperature': 0.7,
        'max_tokens': 2000,
        'stream': true,
      };
      
      debugPrint('Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'Accept': 'text/event-stream',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(minutes: 3));

      if (response.statusCode == 200) {
        final String responseText = response.body;
        final List<String> chunks = responseText.split('\n');
        
        String accumulatedText = '';
        
        for (String chunk in chunks) {
          if (chunk.startsWith('data: ')) {
            final String jsonStr = chunk.substring(6);
            if (jsonStr == '[DONE]') break;
            
            try {
              final Map<String, dynamic> data = jsonDecode(jsonStr);
              if (data['choices'] != null && data['choices'].isNotEmpty) {
                final String? content = data['choices'][0]['delta']['content'];
                if (content != null) {
                  accumulatedText += content;
                  final characters = Characters(content);
                  for (final char in characters) {
                    yield char;
                    await Future.delayed(const Duration(milliseconds: 30));
                  }
                }
              }
            } catch (e) {
              debugPrint('Error parsing chunk: $e');
            }
          }
        }
        
        debugPrint('Complete response: $accumulatedText');
      } else {
        final errorMessage = 'API Error: ${response.statusCode} - ${response.body}';
        debugPrint(errorMessage);
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Error in DeepSeek API: $e');
      if (e is TimeoutException) {
        yield 'Sorry, the request timed out. Please try again.';
      } else {
        yield 'Sorry, I am having trouble responding right now. Please try again.';
      }
    } finally {
      _client.close();
    }
  }

  Future<String> analyzeImage(String imageUrl) async {
    if (!isConfigured) {
      return 'Error: DeepSeek API key not configured. Please check your .env file.';
    }

    try {
      final response = await _dio.post(
        '$_baseUrl/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': 'deepseek-chat',  // Use standard model for image analysis
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'Please analyze this image in detail and describe what you see:'
                },
                {
                  'type': 'image',
                  'source': {
                    'type': 'url',
                    'url': imageUrl
                  }
                }
              ]
            }
          ],
          'temperature': 0.7,
          'max_tokens': 2000,
        },
      );

      debugPrint('Image Analysis Response: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        return data['choices'][0]['message']['content'] as String;
      } else {
        debugPrint('Failed to analyze image: ${response.statusCode} - ${response.data}');
        throw Exception('Failed to analyze image: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error analyzing image: $e');
      throw Exception('Failed to analyze image: $e');
    }
  }

  Future<String> analyzePDF(String pdfUrl) async {
    if (!isConfigured) {
      return 'Error: DeepSeek API key not configured. Please check your .env file.';
    }

    try {
      final response = await _dio.post(
        '$_baseUrl/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'Please analyze this PDF document and provide a detailed summary:'
                },
                {
                  'type': 'document_url',
                  'document_url': {'url': pdfUrl}
                }
              ]
            }
          ],
          'temperature': 0.7,
          'max_tokens': 2000,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return data['choices'][0]['message']['content'] as String;
      } else {
        throw Exception('Failed to analyze PDF');
      }
    } catch (e) {
      debugPrint('Error analyzing PDF: $e');
      throw Exception('Failed to analyze PDF: $e');
    }
  }

  Future<String> analyzeWebpage(String url) async {
    if (!isConfigured) {
      return 'Error: DeepSeek API key not configured. Please check your .env file.';
    }

    try {
      final response = await _dio.post(
        '$_baseUrl/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'Please analyze this webpage and provide a detailed summary:'
                },
                {
                  'type': 'webpage_url',
                  'webpage_url': {'url': url}
                }
              ]
            }
          ],
          'temperature': 0.7,
          'max_tokens': 2000,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return data['choices'][0]['message']['content'] as String;
      } else {
        throw Exception('Failed to analyze webpage');
      }
    } catch (e) {
      debugPrint('Error analyzing webpage: $e');
      throw Exception('Failed to analyze webpage: $e');
    }
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => message;
} 
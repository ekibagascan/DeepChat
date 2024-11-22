import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PayPalAPI {
  final String clientId = dotenv.env['PAYPAL_CLIENT_ID']!;
  final String secret = dotenv.env['PAYPAL_SECRET']!;
  final bool sandbox = true;

  String get baseUrl => sandbox
      ? 'https://api-m.sandbox.paypal.com'
      : 'https://api-m.paypal.com';

  Future<String> getAccessToken() async {
    final response = await http.post(
      Uri.parse('$baseUrl/v1/oauth2/token'),
      headers: {
        'Authorization':
            'Basic ${base64Encode(utf8.encode('$clientId:$secret'))}',
      },
      body: {'grant_type': 'client_credentials'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access_token'];
    } else {
      throw Exception('Failed to get PayPal access token');
    }
  }

  Future<String> createSubscription() async {
    final accessToken = await getAccessToken();
    final response = await http.post(
      Uri.parse('$baseUrl/v1/billing/subscriptions'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'plan_id': 'YOUR_PLAN_ID', // Create this in PayPal dashboard
        'application_context': {
          'return_url': 'https://example.com/success',
          'cancel_url': 'https://example.com/cancel',
        },
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['id'];
    } else {
      throw Exception('Failed to create subscription');
    }
  }
} 
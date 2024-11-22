import 'package:flutter/material.dart';
import '../api/paypal_api.dart';
import '../services/supabase_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _paypalAPI = PayPalAPI();
  final _supabaseService = SupabaseService();
  bool _isLoading = false;

  Future<void> _subscribe() async {
    setState(() => _isLoading = true);
    try {
      final subscriptionId = await _paypalAPI.createSubscription();
      // Handle successful subscription
      // Update user's subscription status in Supabase
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscribe')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Premium Plan',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('$19/month'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _subscribe,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Subscribe with PayPal'),
            ),
          ],
        ),
      ),
    );
  }
} 
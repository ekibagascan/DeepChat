import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SocialAuthService {
  final _supabase = Supabase.instance.client;
  final _googleSignIn = GoogleSignIn(
    clientId: '719357110390-8689nise0vq2b0tfd9n1noirtksmme13.apps.googleusercontent.com',
    scopes: [
      'email',
      'profile',
      'openid',
    ],
  );

  // Google Sign In
  Future<AuthResponse> signInWithGoogle() async {
    try {
      debugPrint('Starting Google Sign In process...');
      
      // Start Google Sign In process
      final googleUser = await _googleSignIn.signIn();
      debugPrint('Google Sign In result: ${googleUser?.email}');
      
      if (googleUser == null) {
        throw 'Google Sign In was cancelled';
      }

      // Get auth details from request
      final googleAuth = await googleUser.authentication;
      debugPrint('Got Google authentication');

      // Create OAuth credential
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        throw 'No ID Token found';
      }

      debugPrint('Signing in with Supabase...');
      // Sign in with Supabase
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );
      
      debugPrint('Supabase sign in successful');
      return response;
    } catch (error) {
      debugPrint('Error in signInWithGoogle: $error');
      rethrow;
    }
  }

  // Apple Sign In
  Future<AuthResponse> signInWithApple() async {
    try {
      debugPrint('Starting Apple Sign In process...');
      
      // Generate random nonce
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256ofString(rawNonce);

      // Request credential for Apple Sign in
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      if (credential.identityToken == null) {
        throw 'No Identity Token found';
      }

      debugPrint('Signing in with Supabase...');
      // Sign in with Supabase
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: credential.identityToken!,
        nonce: rawNonce,
      );
      
      debugPrint('Supabase sign in successful');
      return response;
    } catch (error) {
      debugPrint('Error in signInWithApple: $error');
      rethrow;
    }
  }

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
} 
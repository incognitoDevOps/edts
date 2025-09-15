import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:moderntr/constants.dart';
import 'package:moderntr/main.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final String baseUrl = BASE_URL;
  final storage = const FlutterSecureStorage();
  final client = http.Client();

  final googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: SERVER_ID,
    clientId: CLIENT_ID,
  );

  Future<Map<String, dynamic>?> _handleResponse(http.Response response) async {
    // 1. Guard against HTML responses
    if (response.headers['content-type']?.contains('text/html') ?? false) {
      const msg = 'Server returned HTML instead of JSON';
      scaffoldMessengerKey.currentState
          ?.showSnackBar(SnackBar(content: Text(msg)));
      return null;
    }

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // 2. Success → return JSON
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      }

      final errorMsg = data['error'] ??
          data['detail'] ??
          (data['non_field_errors'] is List
              ? (data['non_field_errors'] as List).join('\n')
              : null) ??
          response.body;

      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red, // red background
          content: Row(
            children: [
              const Icon(Icons.error_outline,
                  color: Colors.white), // white icon
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  errorMsg,
                  style: const TextStyle(color: Colors.white), // white text
                ),
              ),
            ],
          ),
        ),
      );
      return null;
    } catch (e) {
      final msg = 'Failed to parse server response: ${e.toString()}';
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red, // red background
          content: Row(
            children: [
              const Icon(Icons.error_outline,
                  color: Colors.white), // white icon
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  msg,
                  style: const TextStyle(color: Colors.white), // white text
                ),
              ),
            ],
          ),
        ),
      );
      return null;
    }
  }

  Future<bool> login(String email, String password,
      {bool rememberMe = false}) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/auth/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = await _handleResponse(response);

      if (data == null) {
        return false;
      }

      await storage.write(key: 'token', value: data['access_token']);
      await storage.write(key: 'refresh_token', value: data['refresh_token']);
      if (rememberMe) {
        await storage.write(key: 'remember_me', value: 'true');
      }

      return true;
    } catch (e) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/auth/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          'cpassword': password, // Matching password for confirmation
        }),
      );

      var data = await _handleResponse(response);
      if (data == null) {
        return false;
      }

      return true;
    } catch (e) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      return false;
    }
  }

  Future<bool> verifyEmail(String uid, String token) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/verify-email/$uid/$token/'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = await _handleResponse(response);

      // Store tokens upon successful verification
      await storage.write(key: 'token', value: data?['tokens']['access']);
      await storage.write(
          key: 'refresh_token', value: data?['tokens']['refresh']);

      return true;
    } catch (e) {
      throw Exception('Verification error: $e');
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await storage.read(key: 'token');
    if (token == null) return false;

    try {
      final response = await client.get(
        Uri.parse('$baseUrl/auth/verify-token/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      final refreshToken = await storage.read(key: 'refresh_token');
      final token = await storage.read(key: 'token');
      if (refreshToken != null) {
        await client.post(
          Uri.parse('$baseUrl/auth/logout/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          },
          body: jsonEncode({'refresh_token': refreshToken}),
        );
      }
    } finally {
      await storage.deleteAll();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  Future<bool> requestPasswordReset(String email) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/auth/password-reset/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to request password reset: $e');
    }
  }

  Future<bool> resetPassword({
    required String uid,
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/password-reset-confirm/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
          'token': token,
          'new_password': newPassword,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    }
  }

  Future<void> signInWithGoogle() async {
  try {
    // Optional: Sign out to start fresh
    await googleSignIn.signOut();

    // Start Google Sign-In flow
    final GoogleSignInAccount? account = await googleSignIn.signIn();
    if (account == null) {
      throw Exception('User canceled Google sign-in');
    }

    final GoogleSignInAuthentication auth = await account.authentication;
    final String? accessToken = auth.accessToken; // ✅ Correct token for Django
    final String? idToken = auth.idToken; // Optional — not used in your backend

    if (accessToken == null) {
      throw Exception('Failed to get Google access token');
    }

    // Send access token to your Django backend
    final response = await client.post(
      Uri.parse('$baseUrl/auth/google/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'access_token': accessToken, // ✅ This is what Django expects
      }),
    );

    final data = await _handleResponse(response);
    if (data == null) return;

    // Extract access and refresh tokens from Django backend response
    final accessTokenResponse = data['access'] ?? data['access_token'];
    final refreshToken = data['refresh'] ?? data['refresh_token'];

    if (accessTokenResponse == null || refreshToken == null) {
      throw Exception('Invalid token response from server');
    }

    // Store tokens securely
    await storage.write(key: 'token', value: accessTokenResponse);
    await storage.write(key: 'refresh_token', value: refreshToken);

    debugPrint('✅ Google Sign-In successful!');
  } on PlatformException catch (e) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('Google sign-in failed: ${e.message}'),
        backgroundColor: Colors.red,
      ),
    );
    debugPrint('Google Sign-In Error: $e');
  } catch (e) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
    debugPrint('Error during Google Sign-In: $e');
  }
}


}

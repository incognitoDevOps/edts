// ignore_for_file: library_private_types_in_public_api, avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moderntr/constants.dart';
import 'package:moderntr/widgets/back_button_handler.dart';

class MyAccountPage extends StatefulWidget {
  const MyAccountPage({super.key});

  @override
  _MyAccountPageState createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _username;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  // Helper to handle 401 responses
  void _handleUnauthorized(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      context.go('/login');
    });
  }

  Future<void> _fetchUserDetails() async {
    try {
      // Retrieve the bearer token from secure storage.
      final token = await _secureStorage.read(key: 'token');
      if (token == null) {
        setState(() {
          _username = null;
          _isLoadingUser = false;
        });
        return;
      }

      // Replace with your actual API endpoint.
      final url = Uri.parse("$BASE_URL/auth/account/details");
      final response = await http.get(url, headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      });

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        setState(() {
          _username = userData['email'] ?? '';
          _isLoadingUser = false;
        });
      } else if (response.statusCode == 401) {
        // Handle 401 Unauthorized response.
        setState(() {
          _username = null;
          _isLoadingUser = false;
        });
        _handleUnauthorized("Token expired. Please log in.");
      } else {
        setState(() {
          _username = null;
          _isLoadingUser = false;
        });
        print("Failed to fetch user details: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _username = null;
        _isLoadingUser = false;
      });
      print("Error fetching user details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Display a loader while fetching the user details.
    if (_isLoadingUser) {
      return const BackButtonHandler(
        parentRoute: '/',
        child: Scaffold(
        body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return BackButtonHandler(
      parentRoute: '/',
      child: Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        child: Column(
          children: [
            _buildAccountOption(
              context,
              "My account",
              "/my-profile",
              Icons.account_circle,
              subtitle: (_username != null && _username!.isNotEmpty)
                  ? _username!
                  : "Not logged in",
              showLoginButton: (_username == null || _username!.isEmpty),
            ),
            _buildAccountOption(context, "My Listings", "/my-listings", Icons.shopping_bag),
            _buildAccountOption(context, "My Ads", "/my-ads", Icons.campaign),
            _buildAccountOption(context, "Store Settings", "/store-settings", Icons.store),
            _buildAccountOption(context, "Reviews", "/reviews", Icons.rate_review),
            _buildAccountOption(context, "FAQs", "/faqs", Icons.question_answer),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildAccountOption(BuildContext context, String title, String route, IconData icon,
      {String? subtitle, bool showLoginButton = false}) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: Colors.black54),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.brown,
          ),
        ),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: showLoginButton
            ? ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                onPressed: () {
                  context.go('/login');
                },
                child: const Text("Login"),
              )
            : null,
        onTap: () {
          // For "My account", if not logged in, redirect to login.
          if (title == "My account" && (subtitle == "Not logged in")) {
            context.go('/login');
            return;
          }
          context.go(route);
        },
      ),
    );
  }
}

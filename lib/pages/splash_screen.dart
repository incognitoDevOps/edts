// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasInternet = true;

  @override
  void initState() {
    super.initState();
    _checkInternetAndNavigate();
  }

  Future<void> _checkInternetAndNavigate() async {
    bool internetAvailable = await _checkInternetConnection();
    if (internetAvailable) {
      setState(() {
        _hasInternet = true;
      });
      Timer(const Duration(seconds: 3), () {
        context.go('/'); // Navigate to your home page.
      });
    } else {
      setState(() {
        _hasInternet = false;
      });
    }
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Widget _buildNoInternetWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "No Internet Connection",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "Please check your connection and try again.",
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                bool connected = await _checkInternetConnection();
                if (connected) {
                  setState(() {
                    _hasInternet = true;
                  });
                  Timer(const Duration(seconds: 1), () {
                    context.go('/');
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Still no internet connection")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              ),
              child: const Text("Refresh"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _hasInternet
          ? Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/firstscreen.png',
                  fit: BoxFit.cover,
                ),
              ],
            )
          : _buildNoInternetWidget(),
    );
  }
}

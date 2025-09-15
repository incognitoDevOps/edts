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

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _hasInternet = true; // Assume connection is available by default.

  @override
  void initState() {
    super.initState();

    // Create a scale animation for the logo.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);

    // Check for internet connection and proceed accordingly.
    _checkInternetAndNavigate();
  }

  Future<void> _checkInternetAndNavigate() async {
    bool internetAvailable = await _checkInternetConnection();
    if (internetAvailable) {
      setState(() {
        _hasInternet = true;
      });
      // Delay before navigating to the main page.
      Timer(const Duration(seconds: 3), () {
        context.go('/'); // Navigate to your home page.
      });
    } else {
      setState(() {
        _hasInternet = false;
      });
      // The no internet widget will be displayed.
    }
  }

  // Checks internet connectivity by attempting a DNS lookup.
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Widget to display when there is no internet connection.
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
                // Refresh: recheck connectivity.
                bool connected = await _checkInternetConnection();
                if (connected) {
                  setState(() {
                    _hasInternet = true;
                  });
                  // Navigate to main app after a short delay.
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _hasInternet
          ? Center(
              child: ScaleTransition(
                scale: _animation,
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 150,
                  height: 150,
                ),
              ),
            )
          : _buildNoInternetWidget(),
    );
  }
}

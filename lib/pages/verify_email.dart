import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moderntr/services/auth_service.dart';

class VerifyEmailPage extends StatefulWidget {
  final String? uid;
  final String? token;

  const VerifyEmailPage({super.key, this.uid, this.token});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool _isLoading = true;
  bool _isVerified = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _verifyEmail();
  }

  Future<void> _verifyEmail() async {
    if (widget.uid == null || widget.token == null) {
      setState(() {
        _isLoading = false;
        _isVerified = false;
        _errorMessage = 'Invalid verification link';
      });
      return;
    }

    try {
      final success = await AuthService().verifyEmail(widget.uid!, widget.token!);
      setState(() {
        _isLoading = false;
        _isVerified = success;
      });
      
      if (success && context.mounted) {
        Future.delayed(const Duration(seconds: 2), () {
          context.go('/');
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isVerified = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isLoading
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Verifying your email...'),
                  ],
                )
              : _isVerified
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 72),
                        const SizedBox(height: 24),
                        Text(
                          'Email Verified Successfully!',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        const Text('Redirecting to home page...'),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 72),
                        const SizedBox(height: 24),
                        Text(
                          'Verification Failed',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        Text(_errorMessage ?? 'Unknown error occurred'),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => context.go('/sign-up'),
                          child: const Text('Back to Sign Up'),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
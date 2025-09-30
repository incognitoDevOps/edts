import 'dart:async';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/ui/auth_screen/login_screen.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ResetPasswordSuccessScreen extends StatefulWidget {
  const ResetPasswordSuccessScreen({super.key});

  @override
  State<ResetPasswordSuccessScreen> createState() => _ResetPasswordSuccessScreenState();
}

class _ResetPasswordSuccessScreenState extends State<ResetPasswordSuccessScreen> {
  int countdown = 10;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startCountdown();
  }

  void startCountdown() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown > 0) {
        setState(() {
          countdown--;
        });
      } else {
        timer.cancel();
        Get.offAll(() => const LoginScreen());
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read,
                  size: 60,
                  color: Colors.green,
                ),
              ),

              const SizedBox(height: 40),

              // Title
              Text(
                "Email Sent Successfully!".tr,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Description
              Text(
                "We've sent a password reset link to your email address. Please check your inbox and follow the instructions to reset your password.".tr,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Countdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: themeChange.getThem()
                      ? AppColors.darkGray
                      : AppColors.lightGray,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  "Returning to login in $countdown seconds".tr,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: themeChange.getThem()
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Manual return button
              TextButton(
                onPressed: () {
                  timer?.cancel();
                  Get.offAll(() => const LoginScreen());
                },
                child: Text(
                  "Return to Login Now".tr,
                  style: GoogleFonts.poppins(
                    color: themeChange.getThem()
                        ? AppColors.darkModePrimary
                        : AppColors.primary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Additional instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Important".tr,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "• Check your spam/junk folder if you don't see the email\n• The reset link will expire in 1 hour\n• Make sure to use the same email address you registered with".tr,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blue[700],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
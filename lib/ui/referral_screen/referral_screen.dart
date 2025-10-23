import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:clipboard/clipboard.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controller/referral_controller.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/button_them.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart'; // Import share_plus package
import 'package:flutter_animate/flutter_animate.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<ReferralController>(
      init: ReferralController(),
      builder: (controller) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          body: controller.isLoading.value
              ? Constant.loader()
              : Stack(
                  children: [
                    // Gradient background
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF00C6A0),
                            Color(0xFF007C91),
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Column(
                        children: [
                          const SizedBox(height: 32),
                          // Celebratory icon with glass effect
                          Center(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.18), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.tealAccent.withOpacity(0.12),
                                    blurRadius: 32,
                                    spreadRadius: 2,
                                  ),
                                ],
                                color: Colors.white.withOpacity(0.10),
                              ),
                              padding: const EdgeInsets.all(18),
                              child: Icon(Icons.celebration, color: Colors.white, size: 48),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            "Refer & Earn Rewards!",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 26,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Invite friends and earn "+Constant.amountShow(amount: Constant.referralAmount.toString())+" each!",
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),
                          // Glassmorphism referral code card with shimmer
                          GestureDetector(
                            onTap: () {
                              FlutterClipboard.copy(controller.referralModel.value.referralCode.toString())
                                  .then((value) {
                                ShowToastDialog.showToast("Coupon code copied".tr);
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 24),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 24),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: Colors.white.withOpacity(0.13),
                                      border: Border.all(color: Colors.white.withOpacity(0.22), width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.10),
                                          blurRadius: 18,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.card_giftcard, color: Colors.tealAccent.shade100, size: 28),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                controller.referralModel.value.referralCode.toString(),
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 22,
                                                  letterSpacing: 2,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Icon(Icons.copy, color: Colors.white.withOpacity(0.85), size: 22),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "Tap to copy your referral code",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white.withOpacity(0.7),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ).animate().shimmer(duration: 1800.ms, color: Colors.white.withOpacity(0.18)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "How it works",
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withOpacity(0.85),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Timeline steps with shadcn style
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                _buildStep(
                                  icon: Icons.person_add_alt_1,
                                  label: "Invite a Friend",
                                  themeChange: themeChange,
                                ),
                                Divider(
                                  color: Colors.white.withOpacity(0.10),
                                  thickness: 1.2,
                                  indent: 36,
                                  endIndent: 36,
                                ),
                                _buildStep(
                                  icon: Icons.app_registration,
                                  label: "They Register",
                                  themeChange: themeChange,
                                ),
                                Divider(
                                  color: Colors.white.withOpacity(0.10),
                                  thickness: 1.2,
                                  indent: 36,
                                  endIndent: 36,
                                ),
                                _buildStep(
                                  icon: Icons.emoji_events,
                                  label: "Get Reward after their first order!",
                                  themeChange: themeChange,
                                  isLast: true,
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Share button with shadcn style and gradient
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                            child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF00C6A0), Color(0xFF007C91)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.all(Radius.circular(16)),
                                ),
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.share, color: Colors.white),
                                  label: Text(
                                    "REFER FRIEND",
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: () async {
                                    await share(controller.referralModel.value.referralCode.toString(), context);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 600.ms, curve: Curves.easeIn),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildStep({required IconData icon, required String label, required DarkThemeProvider themeChange, bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.13),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.22)),
            boxShadow: [
              BoxShadow(
                color: Colors.tealAccent.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> share(String referralCode, BuildContext context) async {
    try {
      // WhatsApp sharing
      final url = 'https://wa.me/?text=Join BuzRyde!%0ADownload the app: https://play.google.com/store/apps/details?id=com.buzryde.com%0AUse my referral code: $referralCode for exclusive offers!';

      // Check if the URL can be launched
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        // If WhatsApp is not installed or cannot launch, fallback to SMS sharing
        throw Exception('Could not launch WhatsApp');
      }

      // Fallback to SMS sharing
      await Share.share('Join BuzRyde!\nDownload the app: https://play.google.com/store/apps/details?id=com.buzryde.com\nUse my referral code: $referralCode for exclusive offers');
    } catch (e) {
      print('Error sharing referral code: $e');
      // Optionally, show a snackbar or alert to inform the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share: $e')),
      );
    }
  }
}

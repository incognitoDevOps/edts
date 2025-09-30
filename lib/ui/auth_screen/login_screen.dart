import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_code_picker/country_code_picker.dart';
<<<<<<< HEAD
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controller/login_controller.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/ui/auth_screen/email_login_screen.dart';
import 'package:customer/ui/auth_screen/information_screen.dart';
import 'package:customer/ui/auth_screen/otp_screen.dart';
import 'package:customer/ui/dashboard_screen.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
=======
import 'package:driver/controller/auth_controller.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/button_them.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/ui/auth_screen/register_screen.dart';
import 'package:driver/ui/auth_screen/reset_password_success_screen.dart';
import 'package:driver/ui/terms_and_condition/terms_and_condition_screen.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:flutter/gestures.dart';
>>>>>>> 7d7664a3f4dcb31b4429b902b784e67e905b9fc0
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final teal = const Color(0xFF008080);
    final isDark = themeChange.getThem();

    return GetBuilder<LoginController>(
      init: LoginController(),
      builder: (controller) {
        return Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/back.jpg',
                  fit: BoxFit.cover,
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Image.asset('assets/loader.png', height: 120),
                        const SizedBox(height: 30),
                        Text(
                          'Welcome to BuzRyde',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Your ride, your way — fast, safe, and reliable.',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildAuthButton(
                                icon: Icons.email,
                                text: 'Continue with Email',
                                color: teal,
                                onPressed: () =>
                                    Get.to(() => EmailLoginScreen()),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Colors.grey[300],
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Text(
                                      'OR',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Colors.grey[300],
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildAuthButton(
                                icon: Icons.g_mobiledata,
                                text: 'Continue with Google',
                                color: Colors.red,
                                onPressed: () =>
                                    _handleGoogleSignIn(controller),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Colors.grey[300],
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Text(
                                      'OR',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Colors.grey[300],
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildAuthButton(
                                icon: Icons.phone,
                                text: 'Continue with Phone',
                                color: Colors.green,
                                onPressed: () => _showPhoneLoginDialog(
                                    context, controller, isDark),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () => Get.to(() => InformationScreen()),
                          child: RichText(
                            text: TextSpan(
                              text: "Don't have an account? ",
                              style: GoogleFonts.poppins(color: Colors.white),
                              children: [
                                TextSpan(
                                  text: "Sign Up",
                                  style: GoogleFonts.poppins(
                                    color: teal,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAuthButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Text(
            text,
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _handleGoogleSignIn(LoginController controller) async {
    ShowToastDialog.showLoader("Signing in with Google...");
    await controller.signInWithGoogle().then((value) {
      ShowToastDialog.closeLoader();
      if (value != null) {
        _handleAuthResult(value);
      }
    });
  }

  void _handleAuthResult(UserCredential userCredential) {
    if (userCredential.additionalUserInfo!.isNewUser) {
      UserModel userModel = UserModel(
        id: userCredential.user!.uid,
        email: userCredential.user!.email,
        fullName: userCredential.user!.displayName,
        profilePic: userCredential.user!.photoURL,
        loginType: Constant.googleLoginType,
        isActive: true,
        createdAt: Timestamp.now(),
      );
      Get.to(() => InformationScreen(), arguments: {"userModel": userModel});
    } else {
      FireStoreUtils.userExitOrNot(userCredential.user!.uid)
          .then((userExit) async {
        if (userExit) {
          UserModel? userModel =
              await FireStoreUtils.getUserProfile(userCredential.user!.uid);
          if (userModel != null) {
            if (userModel.isActive == true) {
              Get.offAll(() => const DashBoardScreen());
            } else {
              await FirebaseAuth.instance.signOut();
              ShowToastDialog.showToast(
                  "This account is disabled. Please contact support.");
            }
          }
        } else {
          UserModel userModel = UserModel(
            id: userCredential.user!.uid,
            email: userCredential.user!.email,
            fullName: userCredential.user!.displayName,
            profilePic: userCredential.user!.photoURL,
            loginType: Constant.googleLoginType,
            isActive: true,
            createdAt: Timestamp.now(),
          );
          Get.to(() => InformationScreen(),
              arguments: {"userModel": userModel});
        }
      });
    }
  }

  void _showPhoneLoginDialog(
      BuildContext context, LoginController controller, bool isDark) {
    final teal = const Color(0xFF008080);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.phone, color: teal),
            const SizedBox(width: 8),
            Text("Phone Login",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Enter your phone number to receive a verification code.",
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Country Code and Phone Input
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Country Code",
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: teal),
                    color: isDark ? AppColors.darkBackground : Colors.white,
                  ),
                  child: CountryCodePicker(
                    onChanged: (value) {
                      controller.countryCode.value =
                          value.dialCode ?? '+1'; // Default to Canada
                      print(
                          "Selected country code: ${controller.countryCode.value}");
                    },
                    initialSelection: 'CA', // Default to Canada
                    favorite: ['+1', 'CA', 'US'], // Canada and US as favorites
                    showCountryOnly: false,
                    showOnlyCountryWhenClosed: false,
                    alignLeft: false,
                    dialogBackgroundColor: isDark
                        ? AppColors.darkBackground
                        : AppColors.background,
                    textStyle:
                        TextStyle(color: isDark ? Colors.white : Colors.black),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  "Phone Number (without leading zero)",
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: controller.phoneNumberController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'e.g., 111524408',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: isDark ? AppColors.darkTextField : Colors.white,
                    prefixText: '${controller.countryCode.value} ',
                    prefixStyle: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  onChanged: (value) {
                    // Real-time validation feedback could be added here
                  },
                ),

                const SizedBox(height: 8),

                // Helper text
                Text(
                  "Enter your number without the leading zero. Example: 111524408 instead of 0111524408",
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.orange[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.phoneNumberController.clear();
              Navigator.pop(context);
            },
            child: Text("Cancel", style: GoogleFonts.poppins()),
          ),
          Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () {
                        _sendOtp(controller, context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: teal,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: controller.isLoading.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        "Send OTP",
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
              )),
        ],
      ),
    );
  }

  void _sendOtp(LoginController controller, BuildContext context) {
    if (controller.phoneNumberController.text.isEmpty) {
      ShowToastDialog.showToast("Please enter phone number");
      return;
    }

    // Use the public method getFullPhoneNumber() which internally handles cleaning
    final fullPhoneNumber = controller.getFullPhoneNumber();
    print("Final phone number being sent: $fullPhoneNumber");

    // Simple validation - check if the number looks reasonable
    final phoneDigits =
        controller.phoneNumberController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (phoneDigits.length < 7 || phoneDigits.length > 15) {
      ShowToastDialog.showToast(
          "Please enter a valid phone number (7-15 digits)");
      return;
    }

    // Close the dialog first
    Navigator.pop(context);

    // Then send the code
    controller.sendCode();
  }
}

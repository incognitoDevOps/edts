import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controller/information_controller.dart';
import 'package:customer/controller/login_controller.dart';
import 'package:customer/model/referral_model.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/button_them.dart';
import 'package:customer/themes/text_field_them.dart';
import 'package:customer/ui/auth_screen/login_screen.dart';
import 'package:customer/ui/dashboard_screen.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class InformationScreen extends StatelessWidget {
  InformationScreen({Key? key}) : super(key: key);

  final Color teal = const Color(0xFF008080);
  final RxBool isPasswordStrong = false.obs;
  final RxBool isConfirmPasswordMatch = false.obs;
  final RxString passwordText = "".obs;
  final RxString confirmPasswordText = "".obs;

  bool _isPasswordStrong(String password) {
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
  }

  bool _hasMinLength(String password) => password.length >= 8;
  bool _hasUppercase(String password) => RegExp(r'[A-Z]').hasMatch(password);
  bool _hasLowercase(String password) => RegExp(r'[a-z]').hasMatch(password);
  bool _hasNumber(String password) => RegExp(r'[0-9]').hasMatch(password);
  bool _hasSpecialChar(String password) => RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

  // Helper method to build requirement rows with check/cross icons
  Widget _buildRequirementRow(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: isMet ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            text.tr,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isMet ? Colors.green : Colors.red,
              fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
  final themeChange = Provider.of<DarkThemeProvider>(context);
  final size = MediaQuery.of(context).size;
  final isDark = themeChange.getThem();
  final bgImage = 'assets/back.jpg';

  return GetX<InformationController>(
    init: InformationController(),
    builder: (controller) {
      return Scaffold(
        body: Stack(
          children: [
            // Background image
            SizedBox(
              width: size.width,
              height: size.height,
              child: Image.asset(
                bgImage,
                fit: BoxFit.cover,
              ),
            ),

            // Main content card
            Center(
              child: SingleChildScrollView(
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: size.width * 0.13),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 32),
                      width: size.width * 0.90,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withOpacity(0.85)
                            : Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Register".tr,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 28,
                              color: teal,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Create your new account and join our community".tr,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w400,
                              fontSize: 16,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Email field
                          TextFieldThem.buildTextFiled(
                            context,
                            hintText: 'Email Address'.tr,
                            controller: controller.emailController.value,
                          ),
                          const SizedBox(height: 12),

                          // Password field
                          Obx(() {
                            return TextField(
                              controller: controller.passwordController.value,
                              obscureText: true,
                              onChanged: (value) {
                                passwordText.value = value;
                                isPasswordStrong.value =
                                    _isPasswordStrong(value);
                              },
                              decoration: InputDecoration(
                                hintText: 'Password'.tr,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? AppColors.darkTextField
                                    : AppColors.textField,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: passwordText.value.isEmpty
                                        ? Colors.transparent
                                        : isPasswordStrong.value
                                            ? Colors.green
                                            : Colors.red,
                                    width: 2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: passwordText.value.isEmpty
                                        ? (isDark
                                            ? AppColors.darkModePrimary
                                            : AppColors.primary)
                                        : isPasswordStrong.value
                                            ? Colors.green
                                            : Colors.red,
                                    width: 2,
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 12),

                          // Password Requirements Helper Text
                          Obx(
                            () => Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkGray.withOpacity(0.3)
                                    : AppColors.gray.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Password must contain:".tr,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _buildRequirementRow(
                                    "• 8+ characters",
                                    _hasMinLength(passwordText.value),
                                  ),
                                  _buildRequirementRow(
                                    "• Uppercase letter (A-Z)",
                                    _hasUppercase(passwordText.value),
                                  ),
                                  _buildRequirementRow(
                                    "• Lowercase letter (a-z)",
                                    _hasLowercase(passwordText.value),
                                  ),
                                  _buildRequirementRow(
                                    "• Number (0-9)",
                                    _hasNumber(passwordText.value),
                                  ),
                                  _buildRequirementRow(
                                    "• Special character (!@#\$% etc.)",
                                    _hasSpecialChar(passwordText.value),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Confirm Password field
                          Obx(() {
                            return TextField(
                              controller:
                                  controller.confirmPasswordController.value,
                              obscureText: true,
                              onChanged: (value) {
                                confirmPasswordText.value = value;
                                isConfirmPasswordMatch.value =
                                    value == passwordText.value &&
                                        _isPasswordStrong(passwordText.value) &&
                                        value.isNotEmpty;
                              },
                              decoration: InputDecoration(
                                hintText: 'Confirm Password'.tr,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? AppColors.darkTextField
                                    : AppColors.textField,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: confirmPasswordText.value.isEmpty
                                        ? Colors.transparent
                                        : isConfirmPasswordMatch.value
                                            ? Colors.green
                                            : Colors.red,
                                    width: 2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: confirmPasswordText.value.isEmpty
                                        ? (isDark
                                            ? AppColors.darkModePrimary
                                            : AppColors.primary)
                                        : isConfirmPasswordMatch.value
                                            ? Colors.green
                                            : Colors.red,
                                    width: 2,
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 12),

                          // Phone field
                          TextFormField(
                            keyboardType: TextInputType.phone,
                            controller:
                                controller.phoneNumberController.value,
                            decoration: InputDecoration(
                              isDense: true,
                              filled: true,
                              fillColor: isDark
                                  ? AppColors.darkTextField
                                  : AppColors.textField,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              prefixIcon: CountryCodePicker(
                                onChanged: (value) {
                                  controller.countryCode.value =
                                      value.dialCode.toString();
                                },
                                dialogBackgroundColor: isDark
                                    ? AppColors.darkBackground
                                    : AppColors.background,
                                initialSelection: 'US',
                                favorite: ['+1', 'US'],
                              ),
                              hintText: "Enter phone number".tr,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Full name field
                          TextFieldThem.buildTextFiled(
                            context,
                            hintText: 'Full Name'.tr,
                            controller: controller.fullNameController.value,
                          ),
                          const SizedBox(height: 12),

                          // Referral code field
                          TextFieldThem.buildTextFiled(
                            context,
                            hintText: 'Referral Code (Optional)'.tr,
                            controller: controller.referralCodeController.value,
                          ),
                          const SizedBox(height: 24),

                          // Register button
                          Obx(() => ButtonThem.buildButton(
                                context,
                                title: controller.isLoading.value
                                    ? "Processing...".tr
                                    : "Register Now".tr,
                                onPress: () async {
                                  await _handleRegistration(controller);
                                },
                              )),
                          const SizedBox(height: 16),

                          // Apple Sign In (iOS only)
                          if (Platform.isIOS) ...[
                            ButtonThem.buildBorderButton(
                              context,
                              title: "Continue with Apple".tr,
                              iconVisibility: true,
                              iconAssetImage: 'assets/icons/ic_apple_gray.png',
                              onPress: () async {
                                final loginController =
                                    Get.put(LoginController());
                                await loginController.signInWithApple();
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Login link
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Already have an account? ",
                                  style: GoogleFonts.poppins(
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Get.to(() => LoginScreen()),
                                  child: Text(
                                    "Log in",
                                    style: GoogleFonts.poppins(
                                      color: teal,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Google Sign In (Android only)
                          if (Platform.isAndroid) ...[
                            ButtonThem.buildBorderButton(
                              context,
                              title: "Continue with Google".tr,
                              iconVisibility: true,
                              iconAssetImage: 'assets/icons/ic_google.png',
                              onPress: () async {
                                final loginController =
                                    Get.put(LoginController());
                                await loginController.signInWithGoogle();
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Terms and Privacy Links
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  // TODO: Open Terms of Service page
                                },
                                child: Text(
                                  'Terms of Service',
                                  style: GoogleFonts.poppins(
                                    color: teal,
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              Text('  |  ',
                                  style:
                                      GoogleFonts.poppins(color: Colors.grey)),
                              GestureDetector(
                                onTap: () {
                                  // TODO: Open Privacy Policy page
                                },
                                child: Text(
                                  'Privacy Policy',
                                  style: GoogleFonts.poppins(
                                    color: teal,
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

  Future<void> _handleRegistration(InformationController controller) async {
    if (controller.isLoading.value) return;
    controller.isLoading.value = true;

    try {
      // Validate fields
      if (controller.fullNameController.value.text.isEmpty) {
        throw "Please enter your full name";
      }
      if (controller.emailController.value.text.isEmpty) {
        throw "Please enter your email";
      }
      if (controller.passwordController.value.text.isEmpty) {
        throw "Please enter your password";
      }
      if (controller.phoneNumberController.value.text.isEmpty) {
        throw "Please enter your phone number";
      }

      // Password validation
      final password = controller.passwordController.value.text;
      if (!_isPasswordStrong(password)) {
        throw "Password must contain: 8+ characters, uppercase, lowercase, number, and special character";
      }

      // Confirm password validation
      if (controller.confirmPasswordController.value.text != password) {
        throw "Passwords do not match";
      }

      final emailValid =
          Constant.validateEmail(controller.emailController.value.text);
      if (emailValid == false) {
        throw "Please enter a valid email";
      }

      ShowToastDialog.showLoader("Creating account...".tr);

      // Create Firebase auth user
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: controller.emailController.value.text.trim(),
        password: controller.passwordController.value.text.trim(),
      );

      // Create user model
      UserModel userModel = UserModel(
        id: userCredential.user!.uid,
        fullName: controller.fullNameController.value.text,
        email: controller.emailController.value.text,
        countryCode: controller.countryCode.value,
        phoneNumber: controller.phoneNumberController.value.text,
        isActive: true,
        createdAt: Timestamp.now(),
        loginType: Constant.emailLoginType,
      );

      // Handle referral code
      if (controller.referralCodeController.value.text.isNotEmpty) {
        bool? isValid = await FireStoreUtils.checkReferralCodeValidOrNot(
            controller.referralCodeController.value.text);

        if (isValid != true) {
          throw "Referral code is invalid";
        }

        ReferralModel? referrer = await FireStoreUtils.getReferralUserByCode(
            controller.referralCodeController.value.text);

        ReferralModel referralModel = ReferralModel(
          id: userCredential.user!.uid,
          referralBy: referrer?.id ?? "",
          referralCode: Constant.getReferralCode(),
        );
        await FireStoreUtils.referralAdd(referralModel);
      }

      // Save user to Firestore
      await FireStoreUtils.updateUser(userModel);

      ShowToastDialog.closeLoader();
      controller.isLoading.value = false;
      Get.offAll(const DashBoardScreen());
    } catch (e) {
      ShowToastDialog.closeLoader();
      controller.isLoading.value = false;
      ShowToastDialog.showToast(e.toString().tr);
    }
  }
}
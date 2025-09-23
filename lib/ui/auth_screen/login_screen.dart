import 'dart:io';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:driver/controller/auth_controller.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/button_them.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/ui/auth_screen/register_screen.dart';
import 'package:driver/ui/terms_and_condition/terms_and_condition_screen.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<AuthController>(
      init: AuthController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: controller.loginFormKey.value,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo and header
                    Center(
                      child: Image.asset(
                        "assets/app_logo.png",
                        width: Responsive.width(40, context),
                        height: 120,
                      ),
                    ),
                    const SizedBox(height: 30),

                    Text(
                      "Welcome Back!".tr,
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Sign in to continue driving".tr,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Login type selector
                    Container(
                      decoration: BoxDecoration(
                        color: themeChange.getThem()
                            ? AppColors.darkGray
                            : AppColors.lightGray,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => controller.loginType.value = "email",
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: controller.loginType.value == "email"
                                      ? (themeChange.getThem()
                                          ? AppColors.darkModePrimary
                                          : AppColors.primary)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "Email".tr,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    color: controller.loginType.value == "email"
                                        ? (themeChange.getThem()
                                            ? Colors.black
                                            : Colors.white)
                                        : (themeChange.getThem()
                                            ? Colors.white
                                            : Colors.black),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => controller.loginType.value = "phone",
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: controller.loginType.value == "phone"
                                      ? (themeChange.getThem()
                                          ? AppColors.darkModePrimary
                                          : AppColors.primary)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "Phone".tr,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    color: controller.loginType.value == "phone"
                                        ? (themeChange.getThem()
                                            ? Colors.black
                                            : Colors.white)
                                        : (themeChange.getThem()
                                            ? Colors.white
                                            : Colors.black),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Email login form
                    if (controller.loginType.value == "email") ...[
                      TextFormField(
                        controller: controller.loginEmailController.value,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.poppins(
                          color: themeChange.getThem()
                              ? Colors.white
                              : Colors.black,
                        ),
                        decoration: InputDecoration(
                          labelText: "Email Address".tr,
                          prefixIcon: const Icon(Icons.email_outlined),
                          filled: true,
                          fillColor: themeChange.getThem()
                              ? AppColors.darkTextField
                              : AppColors.textField,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Please enter email address".tr;
                          }
                          if (!GetUtils.isEmail(value.trim())) {
                            return "Please enter valid email".tr;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Obx(() => TextFormField(
                            controller:
                                controller.loginPasswordController.value,
                            obscureText: !controller.isPasswordVisible.value,
                            style: GoogleFonts.poppins(
                              color: themeChange.getThem()
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            decoration: InputDecoration(
                              labelText: "Password".tr,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  controller.isPasswordVisible.value
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () =>
                                    controller.isPasswordVisible.toggle(),
                              ),
                              filled: true,
                              fillColor: themeChange.getThem()
                                  ? AppColors.darkTextField
                                  : AppColors.textField,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Please enter password".tr;
                              }
                              if (value.length < 6) {
                                return "Password must be at least 6 characters"
                                    .tr;
                              }
                              return null;
                            },
                          )),
                      const SizedBox(height: 16),
                      
                      // Forgot Password Link
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _showResetPasswordDialog(context, controller, themeChange),
                          child: Text(
                            "Forgot Password?".tr,
                            style: GoogleFonts.poppins(
                              color: themeChange.getThem()
                                  ? AppColors.darkModePrimary
                                  : AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Phone login form
                    if (controller.loginType.value == "phone") ...[
                      TextFormField(
                        controller: controller.loginPhoneController.value,
                        keyboardType: TextInputType.phone,
                        style: GoogleFonts.poppins(
                          color: themeChange.getThem()
                              ? Colors.white
                              : Colors.black,
                        ),
                        decoration: InputDecoration(
                          labelText: "Phone Number".tr,
                          filled: true,
                          fillColor: themeChange.getThem()
                              ? AppColors.darkTextField
                              : AppColors.textField,
                          prefixIcon: CountryCodePicker(
                            onChanged: (value) {
                              controller.countryCode.value =
                                  value.dialCode.toString();
                            },
                            initialSelection: controller.countryCode.value,
                            favorite: const ['+1', '+91', '+44'],
                            showCountryOnly: false,
                            showOnlyCountryWhenClosed: false,
                            alignLeft: false,
                            dialogBackgroundColor: themeChange.getThem()
                                ? AppColors.darkBackground
                                : AppColors.background,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Please enter phone number".tr;
                          }
                          if (value.trim().length < 10) {
                            return "Please enter valid phone number".tr;
                          }
                          return null;
                        },
                      ),
                    ],

                    const SizedBox(height: 30),

                    // Inside your build method, updated parts only

// Login button
                    Obx(() => ButtonThem.buildButton(
                          context,
                          title: controller.loginType.value == "phone"
                              ? "Send OTP".tr
                              : "Sign In".tr,
                          // Always provide a function, even when loading
                          onPress: controller.isLoading.value
                              ? () {}
                              : () {
                                  if (controller.loginType.value == "email") {
                                    controller.loginWithEmail();
                                  } else {
                                    controller.sendPhoneOTP();
                                  }
                                },
                        )),

                    const SizedBox(height: 30),

// OR divider
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "OR".tr,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 30),

// Social login buttons
                    ButtonThem.buildBorderButton(
                      context,
                      title: "Continue with Google".tr,
                      iconVisibility: true,
                      iconAssetImage: 'assets/icons/ic_google.png',
                      // Wrap in a lambda so type matches
                      onPress: controller.isLoading.value
                          ? () {}
                          : () {
                              controller.signInWithGoogle();
                            },
                    ),

                    if (Platform.isIOS) ...[
                      const SizedBox(height: 16),
                      ButtonThem.buildBorderButton(
                        context,
                        title: "Continue with Apple".tr,
                        iconVisibility: true,
                        iconAssetImage: 'assets/icons/ic_apple_gray.png',
                        onPress: controller.isLoading.value
                            ? () {}
                            : () {
                                controller.signInWithApple();
                              },
                      ),
                    ],

                    const SizedBox(height: 40),

                    // Sign up link
                    Center(
                      child: Text.rich(
                        TextSpan(
                          text: "Don't have an account? ".tr,
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                          children: [
                            TextSpan(
                              text: "Sign Up".tr,
                              style: GoogleFonts.poppins(
                                color: themeChange.getThem()
                                    ? AppColors.darkModePrimary
                                    : AppColors.primary,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap =
                                    () => Get.to(() => const RegisterScreen()),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Terms and privacy
                    Center(
                      child: Text.rich(
                        textAlign: TextAlign.center,
                        TextSpan(
                          text: 'By continuing, you agree to our '.tr,
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.grey[600]),
                          children: [
                            TextSpan(
                              text: 'Terms of Service'.tr,
                              style: GoogleFonts.poppins(
                                decoration: TextDecoration.underline,
                                color: themeChange.getThem()
                                    ? AppColors.darkModePrimary
                                    : AppColors.primary,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => Get.to(() =>
                                    const TermsAndConditionScreen(
                                        type: "terms")),
                            ),
                            TextSpan(
                                text: ' and '.tr,
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: Colors.grey[600])),
                            TextSpan(
                              text: 'Privacy Policy'.tr,
                              style: GoogleFonts.poppins(
                                decoration: TextDecoration.underline,
                                color: themeChange.getThem()
                                    ? AppColors.darkModePrimary
                                    : AppColors.primary,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => Get.to(() =>
                                    const TermsAndConditionScreen(
                                        type: "privacy")),
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
        );
      },
    );
  }

  void _showResetPasswordDialog(BuildContext context, AuthController controller, DarkThemeProvider themeChange) {
    Get.dialog(
      AlertDialog(
        title: Text(
          "Reset Password".tr,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Form(
          key: controller.resetPasswordFormKey.value,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Enter your email address and we'll send you a link to reset your password.".tr,
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: controller.resetEmailController.value,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.poppins(
                  color: themeChange.getThem() ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  labelText: "Email Address".tr,
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: themeChange.getThem()
                      ? AppColors.darkTextField
                      : AppColors.textField,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter email address".tr;
                  }
                  if (!GetUtils.isEmail(value.trim())) {
                    return "Please enter valid email".tr;
                  }
                  return null;
                },
              ),
            ],
          ),
<<<<<<< HEAD
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.resetEmailController.value.clear();
              Get.back();
            },
            child: Text(
              "Cancel".tr,
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          Obx(() => ElevatedButton(
                onPressed: controller.isResettingPassword.value
                    ? null
                    : controller.resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeChange.getThem()
                      ? AppColors.darkModePrimary
                      : AppColors.primary,
                  foregroundColor: themeChange.getThem()
                      ? Colors.black
                      : Colors.white,
                ),
                child: controller.isResettingPassword.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text("Send Reset Email".tr),
              )),
=======
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
      FireStoreUtils.userExitOrNot(userCredential.user!.uid).then((userExit) async {
        if (userExit) {
          UserModel? userModel = await FireStoreUtils.getUserProfile(userCredential.user!.uid);
          if (userModel != null) {
            if (userModel.isActive == true) {
              Get.offAll(() => const DashBoardScreen());
            } else {
              await FirebaseAuth.instance.signOut();
              ShowToastDialog.showToast("This account is disabled. Please contact support.");
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
          Get.to(() => InformationScreen(), arguments: {"userModel": userModel});
        }
      });
    }
  }

  void _showPhoneLoginDialog(BuildContext context, LoginController controller, bool isDark) {
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
            Text("Phone Login", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: teal),
                    color: isDark ? AppColors.darkBackground : Colors.white,
                  ),
                  child: CountryCodePicker(
                    onChanged: (value) => controller.countryCode.value = value.dialCode ?? '+1',
                    initialSelection: 'US',
                    favorite: ['+1', 'US'],
                    dialogBackgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
                    textStyle: TextStyle(color: isDark ? Colors.white : Colors.black),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller.phoneNumberController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Phone number',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: isDark ? AppColors.darkTextField : Colors.white,
                    ),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.poppins()),
          ),
          Obx(() => ElevatedButton(
            onPressed: controller.isLoading.value 
                ? null 
                : () {
                    Navigator.pop(context);
                    _sendOtp(controller);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
>>>>>>> b445605aeef0e60456b1c8e12db63c1b9b5583a5
        ],
      ),
    );
  }
<<<<<<< HEAD
=======

  void _sendOtp(LoginController controller) {
    if (controller.phoneNumberController.text.isEmpty) {
      ShowToastDialog.showToast("Please enter phone number");
      return;
    }
    
    // Validate phone number format
    final phoneNumber = controller.phoneNumberController.text.trim();
    if (phoneNumber.length < 10) {
      ShowToastDialog.showToast("Please enter a valid phone number");
      return;
    }
    
    controller.sendCode();
  }
>>>>>>> b445605aeef0e60456b1c8e12db63c1b9b5583a5
}

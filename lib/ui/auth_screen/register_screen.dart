import 'dart:io';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:driver/constant/show_toast_dialog.dart' show ShowToastDialog;
import 'package:driver/controller/auth_controller.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/button_them.dart';
import 'package:driver/ui/terms_and_condition/terms_and_condition_screen.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

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
                key: controller.registerFormKey.value,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.arrow_back),
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),

                    const SizedBox(height: 20),

                    Text(
                      "Create Account".tr,
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Join thousands of drivers earning with BuzRyde".tr,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Full Name
                    TextFormField(
                      controller: controller.registerFullNameController.value,
                      textCapitalization: TextCapitalization.words,
                      style: GoogleFonts.poppins(
                        color:
                            themeChange.getThem() ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: "Full Name".tr,
                        prefixIcon: const Icon(Icons.person_outline),
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
                          return "Please enter your full name".tr;
                        }
                        if (value.trim().length < 2) {
                          return "Name must be at least 2 characters".tr;
                        }
                        if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value.trim())) {
                          return "Name can only contain letters".tr;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Email
                    TextFormField(
                      controller: controller.registerEmailController.value,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.poppins(
                        color:
                            themeChange.getThem() ? Colors.white : Colors.black,
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

                    // Phone Number
                    TextFormField(
                      controller: controller.registerPhoneController.value,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: GoogleFonts.poppins(
                        color:
                            themeChange.getThem() ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: "Phone Number".tr,
                        hintText: "Enter phone number without country code".tr,
                        filled: true,
                        fillColor: themeChange.getThem()
                            ? AppColors.darkTextField
                            : AppColors.textField,
                        prefixIcon: CountryCodePicker(
                          onChanged: (value) {
                            controller.countryCode.value =
                                value.dialCode ?? "+1";
                          },
                          initialSelection: controller.countryCode.value,
                          favorite: const ['+1', '+254', '+91', '+44'],
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
                        if (value == null || value.isEmpty) {
                          return "Please enter phone number".tr;
                        }

                        // Remove any non-digit characters
                        final digitsOnly =
                            value.replaceAll(RegExp(r'[^\d]'), '');

                        // Validate based on country code
                        if (controller.countryCode.value == "+254") {
                          // Kenya
                          if (digitsOnly.length != 9) {
                            return "Kenyan numbers must be 9 digits".tr;
                          }
                          if (!digitsOnly.startsWith('7') &&
                              !digitsOnly.startsWith('1')) {
                            return "Kenyan numbers start with 7 or 1".tr;
                          }
                        }
                        // Add other country-specific validations as needed
                        else if (digitsOnly.length < 7) {
                          return "Phone number too short".tr;
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Password
                    Obx(() => TextFormField(
                          controller:
                              controller.registerPasswordController.value,
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
                            if (value == null || value.isEmpty) {
                              return "Please enter password".tr;
                            }
                            if (value.length < 8) {
                              return "Password must be at least 8 characters"
                                  .tr;
                            }
                            if (!value.contains(RegExp(r'[A-Z]'))) {
                              return "Include at least one uppercase letter".tr;
                            }
                            if (!value.contains(RegExp(r'[0-9]'))) {
                              return "Include at least one number".tr;
                            }
                            return null;
                          },
                        )),
                    const SizedBox(height: 20),

                    // Confirm Password
                    Obx(() => TextFormField(
                          controller: controller
                              .registerConfirmPasswordController.value,
                          obscureText:
                              !controller.isConfirmPasswordVisible.value,
                          style: GoogleFonts.poppins(
                            color: themeChange.getThem()
                                ? Colors.white
                                : Colors.black,
                          ),
                          decoration: InputDecoration(
                            labelText: "Confirm Password".tr,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                controller.isConfirmPasswordVisible.value
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () =>
                                  controller.isConfirmPasswordVisible.toggle(),
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
                            if (value == null || value.isEmpty) {
                              return "Please confirm password".tr;
                            }
                            if (value !=
                                controller
                                    .registerPasswordController.value.text) {
                              return "Passwords do not match".tr;
                            }
                            return null;
                          },
                        )),

                    const SizedBox(height: 40),

                    // Register button
                    // In your RegisterScreen's button section:
Obx(() {
  if (controller.isLoading.value) {
    return const Center(child: CircularProgressIndicator());
  }
  return ButtonThem.buildButton(
    context,
    title: "Create Account".tr,
    onPress: () async {
      print("===== REGISTER BUTTON PRESSED =====");
      
      try {
        // 1. Validate form
        if (controller.registerFormKey.value.currentState == null) {
          print("[ERROR] Form key is null");
          ShowToastDialog.showToast("Form error. Please try again.");
          return;
        }

        if (!controller.registerFormKey.value.currentState!.validate()) {
          print("[ERROR] Form validation failed");
          // Don't return here - let the form fields show their errors
        }

        // 2. Verify passwords match
        if (controller.registerPasswordController.value.text != 
            controller.registerConfirmPasswordController.value.text) {
          print("[ERROR] Passwords do not match");
          ShowToastDialog.showToast("Passwords do not match");
          return;
        }

        // 3. Prepare data with debug prints
        final fullName = controller.registerFullNameController.value.text.trim();
        final email = controller.registerEmailController.value.text.trim();
        final phone = controller.registerPhoneController.value.text.replaceAll(RegExp(r'[^\d]'), '');
        final password = controller.registerPasswordController.value.text;
        final countryCode = controller.countryCode.value;

        print("Registration data:");
        print("- Name: $fullName");
        print("- Email: $email");
        print("- Phone: $phone");
        print("- Country Code: $countryCode");
        print("- Password: ${password.replaceAll(RegExp('.'), '*')}"); // Mask password

        // 4. Call registration
        await controller.registerWithEmail(
          fullName: fullName,
          email: email,
          phoneNumber: phone,
          password: password,
          countryCode: countryCode,
        );

      } catch (e) {
        print("[UNEXPECTED ERROR] ${e.toString()}");
        ShowToastDialog.showToast("Registration failed. Please try again.");
      }
    },
  );
}),
                    // ... rest of your social login and other UI elements
                    const SizedBox(height: 30),
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

                    // Sign in link
                    Center(
                      child: Text.rich(
                        TextSpan(
                          text: "Already have an account? ".tr,
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                          children: [
                            TextSpan(
                              text: "Sign In".tr,
                              style: GoogleFonts.poppins(
                                color: themeChange.getThem()
                                    ? AppColors.darkModePrimary
                                    : AppColors.primary,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => Get.back(),
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
                          text: 'By creating an account, you agree to our '.tr,
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
}

import 'dart:developer';

import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/controller/auth_controller.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/button_them.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final arguments = Get.arguments as Map<String, dynamic>;
    final String countryCode = arguments['countryCode'] ?? '';
    final String phoneNumber = arguments['phoneNumber'] ?? '';
    final String verificationId = arguments['verificationId'] ?? '';
    final bool isLogin = arguments['isLogin'] ?? false;

    return GetX<AuthController>(
      init: AuthController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
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

                  const SizedBox(height: 40),

                  // Header
                  Text(
                    "Verify Phone Number".tr,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "We sent a verification code to".tr,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$countryCode $phoneNumber",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: themeChange.getThem()
                          ? AppColors.darkModePrimary
                          : AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 50),

                  // OTP Input
                  PinCodeTextField(
                    length: 6,
                    appContext: context,
                    keyboardType: TextInputType.number,
                    pinTheme: PinTheme(
                      fieldHeight: 60,
                      fieldWidth: 50,
                      activeColor: themeChange.getThem()
                          ? AppColors.darkModePrimary
                          : AppColors.primary,
                      selectedColor: themeChange.getThem()
                          ? AppColors.darkModePrimary
                          : AppColors.primary,
                      inactiveColor: themeChange.getThem()
                          ? AppColors.darkTextFieldBorder
                          : AppColors.textFieldBorder,
                      activeFillColor: themeChange.getThem()
                          ? AppColors.darkTextField
                          : AppColors.textField,
                      inactiveFillColor: themeChange.getThem()
                          ? AppColors.darkTextField
                          : AppColors.textField,
                      selectedFillColor: themeChange.getThem()
                          ? AppColors.darkTextField
                          : AppColors.textField,
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(12),
                      borderWidth: 2,
                    ),
                    enableActiveFill: true,
                    cursorColor: themeChange.getThem()
                        ? AppColors.darkModePrimary
                        : AppColors.primary,
                    controller: controller.otpController.value,
                    onCompleted: (otp) {
                      controller.verifyPhoneOTP(otp, verificationId);
                    },
                    onChanged: (value) {},
                  ),

                  const SizedBox(height: 40),

                  // Verify button
                  Obx(() => ButtonThem.buildButton(
                        context,
                        title: "Verify".tr,
                        onPress: controller.isLoading.value
                            ? () {}
                            : () {
                                if (controller
                                        .otpController.value.text.length ==
                                    6) {
                                  controller.verifyPhoneOTP(
                                      controller.otpController.value.text,
                                      verificationId);
                                } else {
                                  ShowToastDialog.showToast(
                                      "Please enter complete OTP".tr);
                                }
                              },
                      )),

                  const SizedBox(height: 30),

                  // Resend OTP
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // Implement resend OTP logic
                        Get.back();
                      },
                      child: Text(
                        "Didn't receive code? Resend".tr,
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
              ),
            ),
          ),
        );
      },
    );
  }
}

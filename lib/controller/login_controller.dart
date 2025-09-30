import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/ui/auth_screen/information_screen.dart';
import 'package:customer/ui/dashboard_screen.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/ui/auth_screen/reset_password_screen.dart';

class LoginController extends GetxController {
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final RxString countryCode = "+1".obs; // Default to Canada
  final RxBool isLoading = false.obs;
  final RxBool isResettingPassword = false.obs;

  void clearControllers() {
    phoneNumberController.clear();
    emailController.clear();
    passwordController.clear();
  }

  @override
  void onClose() {
    phoneNumberController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  /// Remove leading zero from phone number
  String removeLeadingZero(String phoneNumber) {
    // Remove all non-digit characters first
    String digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Remove leading zero if present
    if (digitsOnly.startsWith('0')) {
      digitsOnly = digitsOnly.substring(1);
    }

    return digitsOnly;
  }

  /// Validate if the phone number is valid after removing leading zero
  bool isValidPhoneNumber(String phoneNumber) {
    final cleanedNumber = removeLeadingZero(phoneNumber);
    // Kenyan numbers should be 9 digits after removing leading zero
    return cleanedNumber.length == 9;
  }

  /// Get the full international phone number in correct format
  String getFullPhoneNumber() {
    final cleanedNumber = removeLeadingZero(phoneNumberController.text);
    return countryCode.value + cleanedNumber;
  }

  Future<void> sendCode() async {
    if (phoneNumberController.text.isEmpty) {
      ShowToastDialog.showToast("Please enter phone number");
      return;
    }

    // Validate the phone number
    if (!isValidPhoneNumber(phoneNumberController.text)) {
      ShowToastDialog.showToast(
          "Please enter a valid 10-digit Canadian phone number (e.g., +198236691)");
      return;
    }

    final fullPhoneNumber = getFullPhoneNumber();
    print("Original input: ${phoneNumberController.text}");
    print(
        "After removing zero: ${removeLeadingZero(phoneNumberController.text)}");
    print("Full international number: $fullPhoneNumber");

    isLoading.value = true;
    ShowToastDialog.showLoader("Sending OTP...");

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,
        timeout: const Duration(seconds: 120),
        verificationCompleted: (PhoneAuthCredential credential) async {
          ShowToastDialog.closeLoader();
          isLoading.value = false;
          print("Auto verification completed");
          await _handlePhoneAuthCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          ShowToastDialog.closeLoader();
          isLoading.value = false;
          print("Verification failed: ${e.code} - ${e.message}");

          String errorMessage = "Verification failed";
          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage =
                  "Invalid phone number format. Please check your number.";
              break;
            case 'too-many-requests':
              errorMessage = "Too many requests. Please try again later.";
              break;
            default:
              errorMessage = "Verification failed: ${e.message}";
          }

          ShowToastDialog.showToast(errorMessage);
        },
        codeSent: (String verificationId, int? resendToken) {
          ShowToastDialog.closeLoader();
          isLoading.value = false;
          print("Code sent successfully. Verification ID: $verificationId");

          Get.toNamed('/otp', arguments: {
            "countryCode": countryCode.value,
            "phoneNumber": phoneNumberController.text,
            "verificationId": verificationId,
            "resendToken": resendToken,
            "fullPhoneNumber": fullPhoneNumber,
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print("Auto retrieval timeout for verification ID: $verificationId");
        },
      );
    } catch (e) {
      ShowToastDialog.closeLoader();
      isLoading.value = false;
      print("Phone verification error: $e");
      ShowToastDialog.showToast("Failed to send OTP. Please try again.");
    }
  }

  Future<void> _handlePhoneAuthCredential(
      PhoneAuthCredential credential) async {
    try {
      ShowToastDialog.showLoader("Verifying...");
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      ShowToastDialog.closeLoader();

      print("Phone authentication successful for: ${userCredential.user?.uid}");
      _handleUserAfterAuth(userCredential);
    } catch (e) {
      ShowToastDialog.closeLoader();
      print("Phone credential error: $e");
      ShowToastDialog.showToast("Authentication failed. Please try again.");
    }
  }

/*************  ✨ Windsurf Command ⭐  *************/
  /// Handle user authentication result after phone authentication
  /// 
  /// If user exists in Firestore, navigate to dashboard screen if user is active
  /// Otherwise, navigate to information screen with the user model
  /// If user does not exist in Firestore, navigate to information screen with the user model
  /// 
  /// [userCredential] The user credential object returned from phone authentication
  ///
  void _handleUserAfterAuth(UserCredential userCredential) {
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
        } else {
          UserModel newUserModel = UserModel(
            id: userCredential.user!.uid,
            phoneNumber: userCredential.user!.phoneNumber,
            loginType: Constant.phoneLoginType,
            isActive: true,
            createdAt: Timestamp.now(),
          );
          Get.to(() => InformationScreen(),
              arguments: {"userModel": newUserModel});
        }
      } else {
        UserModel userModel = UserModel(
          id: userCredential.user!.uid,
          phoneNumber: userCredential.user!.phoneNumber,
          loginType: Constant.phoneLoginType,
          isActive: true,
          createdAt: Timestamp.now(),
        );
        Get.to(() => InformationScreen(), arguments: {"userModel": userModel});
      }
    });
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (email.isEmpty) {
      ShowToastDialog.showToast("Please enter your email");
      return;
    }

    if (!_isValidEmail(email)) {
      ShowToastDialog.showToast("Please enter a valid email address");
      return;
    }

    isResettingPassword.value = true;
    ShowToastDialog.showLoader("Sending reset email...");

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      ShowToastDialog.closeLoader();
      isResettingPassword.value = false;

      Get.to(() => ResetPasswordScreen(email: email.trim()));
    } on FirebaseAuthException catch (e) {
      ShowToastDialog.closeLoader();
      isResettingPassword.value = false;

      String errorMessage = "Failed to send reset email";
      switch (e.code) {
        case 'user-not-found':
          errorMessage = "No account found with this email address";
          break;
        case 'invalid-email':
          errorMessage = "Invalid email address";
          break;
        case 'too-many-requests':
          errorMessage = "Too many requests. Please try again later";
          break;
        case 'network-request-failed':
          errorMessage = "Network error. Please check your connection";
          break;
        default:
          errorMessage = e.message ?? "Failed to send reset email";
      }

      ShowToastDialog.showToast(errorMessage);
    } catch (e) {
      ShowToastDialog.closeLoader();
      isResettingPassword.value = false;
      print("Password reset error: $e");
      ShowToastDialog.showToast(
          "Failed to send reset email. Please try again.");
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId: Platform.isIOS ? 'YOUR_IOS_CLIENT_ID' : null,
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        ShowToastDialog.showToast("Google sign-in cancelled");
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      ShowToastDialog.showToast("Google sign-in failed: ${e.message}");
      return null;
    } catch (e) {
      ShowToastDialog.showToast("Error during Google sign-in");
      return null;
    }
  }
}

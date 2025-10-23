import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';

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
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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
    String digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.startsWith('0')) {
      digitsOnly = digitsOnly.substring(1);
    }
    return digitsOnly;
  }

  bool isValidPhoneNumber(String phoneNumber) {
    final cleanedNumber = removeLeadingZero(phoneNumber);
    return cleanedNumber.length == 9;
  }

  String getFullPhoneNumber() {
    final cleanedNumber = removeLeadingZero(phoneNumberController.text);
    return countryCode.value + cleanedNumber;
  }

  Future<void> sendCode() async {
    if (phoneNumberController.text.isEmpty) {
      ShowToastDialog.showToast("Please enter phone number");
      return;
    }

    if (!isValidPhoneNumber(phoneNumberController.text)) {
      ShowToastDialog.showToast(
          "Please enter a valid 10-digit Canadian phone number (e.g., +198236691)");
      return;
    }

    final fullPhoneNumber = getFullPhoneNumber();
    isLoading.value = true;
    ShowToastDialog.showLoader("Sending OTP...");

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,
        timeout: const Duration(seconds: 120),
        verificationCompleted: (PhoneAuthCredential credential) async {
          ShowToastDialog.closeLoader();
          isLoading.value = false;
          await _handlePhoneAuthCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          ShowToastDialog.closeLoader();
          isLoading.value = false;
          ShowToastDialog.showToast("Verification failed: ${e.message}");
        },
        codeSent: (String verificationId, int? resendToken) {
          ShowToastDialog.closeLoader();
          isLoading.value = false;
          Get.toNamed('/otp', arguments: {
            "countryCode": countryCode.value,
            "phoneNumber": phoneNumberController.text,
            "verificationId": verificationId,
            "resendToken": resendToken,
            "fullPhoneNumber": fullPhoneNumber,
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      ShowToastDialog.closeLoader();
      isLoading.value = false;
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
      _handleUserAfterAuth(userCredential);
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Authentication failed. Please try again.");
    }
  }

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
      ShowToastDialog.showToast(e.message ?? "Failed to send reset email");
    } catch (e) {
      ShowToastDialog.closeLoader();
      isResettingPassword.value = false;
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
    } catch (e) {
      ShowToastDialog.showToast("Google sign-in failed: $e");
      return null;
    }
  }

  /// 🔑 Apple Sign In for Riders
  Future<UserCredential?> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      // Handle Firestore user
      UserModel? userModel =
          await FireStoreUtils.getUserProfile(userCredential.user!.uid);

      if (userModel == null) {
        userModel = UserModel(
          id: userCredential.user!.uid,
          email: appleCredential.email ?? userCredential.user?.email,
          fullName:
              "${appleCredential.givenName ?? ""} ${appleCredential.familyName ?? ""}".trim(),
          loginType: Constant.appleLoginType,
          isActive: true,
          createdAt: Timestamp.now(),
        );
        await FireStoreUtils.updateUser(userModel);
        Get.to(() => InformationScreen(), arguments: {"userModel": userModel});
      } else {
        if (userModel.isActive == true) {
          Get.offAll(() => const DashBoardScreen());
        } else {
          await FirebaseAuth.instance.signOut();
          ShowToastDialog.showToast(
              "This account is disabled. Please contact support.");
        }
      }

      return userCredential;
    } catch (e) {
      ShowToastDialog.showToast("Apple sign-in failed: $e");
      return null;
    }
  }

  /// Generate cryptographically secure nonce
  String _generateNonce([int length = 32]) {
    final charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
        length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// SHA256 hash of string
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}


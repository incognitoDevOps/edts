import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:customer/constant/show_toast_dialog.dart';

class LoginController extends GetxController {
  // Proper TextEditingController declarations
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final RxString countryCode = "+1".obs;
  final RxBool isLoading = false.obs;

  // Clear all controllers
  void clearControllers() {
    phoneNumberController.clear();
    emailController.clear();
    passwordController.clear();
  }

  @override
  void onClose() {
    // Dispose all controllers when the controller is disposed
    phoneNumberController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  Future<void> sendCode() async {
    if (phoneNumberController.text.isEmpty) {
      ShowToastDialog.showToast("Please enter phone number");
      return;
    }

    isLoading.value = true;
    ShowToastDialog.showLoader("Sending OTP...");

    try {
      // For Android, we need to add the SHA-1 fingerprint to Firebase Console
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: countryCode.value + phoneNumberController.text,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _handlePhoneAuthCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          ShowToastDialog.showToast("Verification failed: ${e.message}");
        },
        codeSent: (String verificationId, int? resendToken) {
          Get.toNamed('/otp', arguments: {
            "countryCode": countryCode.value,
            "phoneNumber": phoneNumberController.text,
            "verificationId": verificationId,
            "resendToken": resendToken,
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      ShowToastDialog.showToast("Failed to send OTP. Please try again.");
    } finally {
      isLoading.value = false;
      ShowToastDialog.closeLoader();
    }
  }

  Future<void> _handlePhoneAuthCredential(
      PhoneAuthCredential credential) async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      // Handle successful authentication
    } catch (e) {
      ShowToastDialog.showToast("Authentication failed. Please try again.");
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Ensure Google Sign-In is properly configured
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId: Platform.isIOS ? 'YOUR_IOS_CLIENT_ID' : null,
      );

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        ShowToastDialog.showToast("Google sign-in cancelled");
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
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

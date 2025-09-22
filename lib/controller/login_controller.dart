import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/ui/auth_screen/reset_password_screen.dart';

class LoginController extends GetxController {
  // Proper TextEditingController declarations
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final RxString countryCode = "+1".obs;
  final RxBool isLoading = false.obs;
  final RxBool isResettingPassword = false.obs;

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
      // Enhanced phone verification with better error handling
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: countryCode.value + phoneNumberController.text,
        timeout: const Duration(seconds: 120),
        verificationCompleted: (PhoneAuthCredential credential) async {
          ShowToastDialog.closeLoader();
          isLoading.value = false;
          await _handlePhoneAuthCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          ShowToastDialog.closeLoader();
          isLoading.value = false;
          String errorMessage = "Verification failed";
          
          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage = "Invalid phone number format";
              break;
            case 'too-many-requests':
              errorMessage = "Too many requests. Please try again later";
              break;
            case 'app-not-authorized':
              errorMessage = "App not authorized. Please contact support";
              break;
            case 'network-request-failed':
              errorMessage = "Network error. Please check your connection";
              break;
            default:
              errorMessage = e.message ?? "Verification failed";
          }
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
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
          print("Auto retrieval timeout for verification ID: $verificationId");
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
      
      // Check if user exists in Firestore and handle accordingly
      // This will be handled by the calling screen
      print("Phone authentication successful for: ${userCredential.user?.uid}");
    } catch (e) {
      ShowToastDialog.closeLoader();
      print("Phone credential error: $e");
      ShowToastDialog.showToast("Authentication failed. Please try again.");
    }
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
      
      // Navigate to reset password screen
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
      ShowToastDialog.showToast("Failed to send reset email. Please try again.");
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
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

import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controller/login_controller.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/ui/dashboard_screen.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class EmailLoginScreen extends StatelessWidget {
  final LoginController controller = Get.put(LoginController());
  final teal = const Color(0xFF008080);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Email Login"),
        backgroundColor: teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            TextField(
              controller: controller.emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller.passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => _loginWithEmail(),
              style: ElevatedButton.styleFrom(
                backgroundColor: teal,
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text("Login", style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => _showForgotPasswordDialog(context),
              child: const Text("Forgot Password?"),
            ),
          ],
        ),
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Forgot Password"),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            hintText: "Enter your email",
            prefixIcon: Icon(Icons.email),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) {
                ShowToastDialog.showToast("Please enter your email");
                return;
              }
              Navigator.pop(context);
              await _sendPasswordResetEmail(email);
            },
            child: const Text("Send Reset Link"),
          ),
        ],
      ),
    );
  }

  Future<void> _sendPasswordResetEmail(String email) async {
    ShowToastDialog.showLoader("Sending reset email...");
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ShowToastDialog.showToast("Reset email sent. Check your inbox.");
    } on FirebaseAuthException catch (e) {
      String message = "Something went wrong";
      if (e.code == 'user-not-found') {
        message = "No user found with this email";
      } else if (e.code == 'invalid-email') {
        message = "Invalid email address";
      }
      ShowToastDialog.showToast(message);
    } catch (e) {
      ShowToastDialog.showToast("Failed to send reset email");
    } finally {
      ShowToastDialog.closeLoader();
    }
  }

  Future<void> _loginWithEmail() async {
    if (controller.emailController.value.text.isEmpty ||
        controller.passwordController.value.text.isEmpty) {
      ShowToastDialog.showToast("Please fill all fields");
      return;
    }

    ShowToastDialog.showLoader("Logging in...");
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: controller.emailController.value.text.trim(),
        password: controller.passwordController.value.text.trim(),
      );

      // Check if user exists in Firestore
      bool userExists =
          await FireStoreUtils.userExitOrNot(userCredential.user!.uid);
      if (!userExists) {
        await FirebaseAuth.instance.signOut();
        ShowToastDialog.showToast("User not registered. Please sign up first.");
        return;
      }

      UserModel? userModel =
          await FireStoreUtils.getUserProfile(userCredential.user!.uid);
      if (userModel != null && userModel.isActive == true) {
        Get.offAll(() => const DashBoardScreen());
      } else {
        await FirebaseAuth.instance.signOut();
        ShowToastDialog.showToast("Account disabled. Contact support.");
      }
    } on FirebaseAuthException catch (e) {
      String message = "Login failed";
      if (e.code == 'user-not-found') {
        message = "No user found with this email";
      } else if (e.code == 'wrong-password') {
        message = "Incorrect password";
      }
      ShowToastDialog.showToast(message);
    } catch (e) {
      ShowToastDialog.showToast("Login failed. Please try again.");
    } finally {
      ShowToastDialog.closeLoader();
    }
  }
}

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
            Obx(() => ElevatedButton(
              onPressed: controller.isLoading.value ? null : () => _loginWithEmail(),
              style: ElevatedButton.styleFrom(
                backgroundColor: teal,
                minimumSize: Size(double.infinity, 50),
              ),
              child: controller.isLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text("Login", style: TextStyle(fontSize: 18)),
            )),
            const SizedBox(height: 20),
            Obx(() => TextButton(
              onPressed: controller.isResettingPassword.value 
                  ? null 
                  : () => _showForgotPasswordDialog(context),
              child: controller.isResettingPassword.value
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        const Text("Sending..."),
                      ],
                    )
                  : const Text("Forgot Password?"),
            )),
          ],
        ),
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final RxBool isProcessing = false.obs;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.lock_reset, color: teal),
            const SizedBox(width: 8),
            const Text("Reset Password"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Enter your email address and we'll send you a link to reset your password.",
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: "Enter your email",
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.poppins()),
          ),
          Obx(() => ElevatedButton(
            onPressed: isProcessing.value 
                ? null 
                : () async {
                    final email = emailController.text.trim();
                    if (email.isEmpty) {
                      Get.snackbar(
                        "Error", 
                        "Please enter your email",
                        backgroundColor: Colors.red.withOpacity(0.1),
                        colorText: Colors.red,
                      );
                      return;
                    }
                    
                    isProcessing.value = true;
                    Navigator.pop(context);
                    await controller.sendPasswordResetEmail(email);
                    isProcessing.value = false;
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isProcessing.value
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    "Send Reset Link",
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
          )),
        ],
      ),
    );
  }


  Future<void> _loginWithEmail() async {
    if (controller.isLoading.value) return;
    
    if (controller.emailController.value.text.isEmpty ||
        controller.passwordController.value.text.isEmpty) {
      ShowToastDialog.showToast("Please fill all fields");
      return;
    }

    controller.isLoading.value = true;
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
        ShowToastDialog.closeLoader();
        controller.isLoading.value = false;
        ShowToastDialog.showToast("User not registered. Please sign up first.");
        return;
      }

      UserModel? userModel =
          await FireStoreUtils.getUserProfile(userCredential.user!.uid);
      if (userModel != null && userModel.isActive == true) {
        ShowToastDialog.closeLoader();
        controller.isLoading.value = false;
        Get.offAll(() => const DashBoardScreen());
      } else {
        await FirebaseAuth.instance.signOut();
        ShowToastDialog.closeLoader();
        controller.isLoading.value = false;
        ShowToastDialog.showToast("Account disabled. Contact support.");
      }
    } on FirebaseAuthException catch (e) {
      ShowToastDialog.closeLoader();
      controller.isLoading.value = false;
      String message = "Login failed";
      if (e.code == 'user-not-found') {
        message = "No user found with this email";
      } else if (e.code == 'wrong-password') {
        message = "Incorrect password";
      } else if (e.code == 'invalid-email') {
        message = "Invalid email format";
      } else if (e.code == 'user-disabled') {
        message = "This account has been disabled";
      } else if (e.code == 'too-many-requests') {
        message = "Too many failed attempts. Please try again later";
      }
      ShowToastDialog.showToast(message);
    } catch (e) {
      ShowToastDialog.closeLoader();
      controller.isLoading.value = false;
      print("Login error: $e");
      ShowToastDialog.showToast("Login failed. Please try again.");
    }
  }
}

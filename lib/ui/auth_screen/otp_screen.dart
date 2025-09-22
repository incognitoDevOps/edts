import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/ui/auth_screen/information_screen.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer/controller/login_controller.dart';
import 'package:customer/ui/dashboard_screen.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({Key? key}) : super(key: key);

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final LoginController controller = Get.find<LoginController>();
  final List<TextEditingController> otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());

  @override
  void dispose() {
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> arguments = Get.arguments as Map<String, dynamic>;
    final String verificationId = arguments['verificationId'];
    final String phoneNumber = arguments['phoneNumber'];
    final String countryCode = arguments['countryCode'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Verify OTP', style: GoogleFonts.poppins()),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              'Enter the 6-digit OTP sent to',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '$countryCode$phoneNumber',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            
            // OTP Input Fields
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 45,
                  child: TextField(
                    controller: otpControllers[index],
                    focusNode: focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      if (value.length == 1 && index < 5) {
                        FocusScope.of(context).requestFocus(focusNodes[index + 1]);
                      } else if (value.isEmpty && index > 0) {
                        FocusScope.of(context).requestFocus(focusNodes[index - 1]);
                      }
                    },
                  ),
                );
              }),
            ),
            
            const SizedBox(height: 30),
            
            // Verify Button
            Obx(() => controller.isLoading.value
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () => _verifyOtp(verificationId),
                    child: Text('Verify OTP'),
                  ),
            ),
            
            const SizedBox(height: 20),
            
            // Resend OTP
            TextButton(
              onPressed: () => _resendOtp(countryCode, phoneNumber),
              child: Text('Resend OTP'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyOtp(String verificationId) async {
  String otp = otpControllers.map((c) => c.text).join();
  
  if (otp.length != 6) {
    ShowToastDialog.showToast('Please enter complete OTP');
    return;
  }

  controller.isLoading.value = true;
  ShowToastDialog.showLoader('Verifying...');

  try {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );

    UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    
    // Check if user exists in Firestore
    bool userExists = await FireStoreUtils.userExitOrNot(userCredential.user!.uid);
    if (!userExists) {
      // New user - collect additional info
      UserModel userModel = UserModel(
        id: userCredential.user!.uid,
        phoneNumber: userCredential.user!.phoneNumber,
        countryCode: Get.arguments['countryCode'],
        loginType: Constant.phoneLoginType,
        isActive: true,
        createdAt: Timestamp.now(),
      );
      Get.offAll(() => InformationScreen(), arguments: {
        "userModel": userModel,
      });
    } else {
      // Existing user - proceed to dashboard
      Get.offAll(() => const DashBoardScreen());
    }
  } on FirebaseAuthException catch (e) {
    ShowToastDialog.showToast('Invalid OTP. Please try again.');
  } finally {
    controller.isLoading.value = false;
    ShowToastDialog.closeLoader();
  }
}
  Future<void> _resendOtp(String countryCode, String phoneNumber) async {
    controller.isLoading.value = true;
    ShowToastDialog.showLoader('Resending OTP...');

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: countryCode + phoneNumber,
        verificationCompleted: (_) {},
        verificationFailed: (e) {
          ShowToastDialog.showToast('Failed: ${e.message}');
        },
        codeSent: (verificationId, _) {
          Get.back();
          Get.toNamed('/otp', arguments: {
            "verificationId": verificationId,
            "phoneNumber": phoneNumber,
            "countryCode": countryCode,
          });
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      ShowToastDialog.showToast('Failed to resend OTP');
    } finally {
      controller.isLoading.value = false;
      ShowToastDialog.closeLoader();
    }
  }
}
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
import 'package:customer/ui/auth_screen/information_screen.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/constant/constant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({Key? key}) : super(key: key);

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final LoginController controller = Get.find<LoginController>();
  final List<TextEditingController> otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());
  final RxBool isVerifying = false.obs;
  final RxBool isResending = false.obs;

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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Verify Phone Number', style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: const Color(0xFF008080),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              // Phone icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF008080).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phone_android,
                  size: 40,
                  color: Color(0xFF008080),
                ),
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'Verify Your Phone',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'We sent a 6-digit code to',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 4),
              
              Text(
                '$countryCode $phoneNumber',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF008080),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // OTP Input Fields with improved styling
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Enter Verification Code',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 45,
                          height: 55,
                          child: TextField(
                            controller: otpControllers[index],
                            focusNode: focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF008080),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            onChanged: (value) {
                              if (value.length == 1 && index < 5) {
                                FocusScope.of(context).requestFocus(focusNodes[index + 1]);
                              } else if (value.isEmpty && index > 0) {
                                FocusScope.of(context).requestFocus(focusNodes[index - 1]);
                              }
                              
                              // Auto-verify when all fields are filled
                              if (index == 5 && value.isNotEmpty) {
                                String otp = otpControllers.map((c) => c.text).join();
                                if (otp.length == 6) {
                                  _verifyOtp(verificationId);
                                }
                              }
                            },
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Verify Button
              Obx(() => SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isVerifying.value ? null : () => _verifyOtp(verificationId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008080),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: isVerifying.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Verify Code',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              )),
              
              const SizedBox(height: 24),
              
              // Resend OTP
              Obx(() => TextButton(
                onPressed: isResending.value 
                    ? null 
                    : () => _resendOtp(countryCode, phoneNumber, verificationId),
                child: isResending.value
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Resending...',
                            style: GoogleFonts.poppins(),
                          ),
                        ],
                      )
                    : Text(
                        'Didn\'t receive the code? Resend',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF008080),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              )),
              
              const SizedBox(height: 20),
              
              // Help text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The code may take a few minutes to arrive. Check your messages.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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

    if (isVerifying.value) return;
    
    isVerifying.value = true;
    ShowToastDialog.showLoader('Verifying...');

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      ShowToastDialog.closeLoader();
      isVerifying.value = false;
      
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
        // Existing user - check if active
        UserModel? userModel = await FireStoreUtils.getUserProfile(userCredential.user!.uid);
        if (userModel != null && userModel.isActive == true) {
          Get.offAll(() => const DashBoardScreen());
        } else {
          await FirebaseAuth.instance.signOut();
          ShowToastDialog.showToast("Account disabled. Please contact support.");
        }
      }
    } on FirebaseAuthException catch (e) {
      ShowToastDialog.closeLoader();
      isVerifying.value = false;
      
      String errorMessage = "Invalid OTP";
      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = "Invalid verification code. Please try again.";
          break;
        case 'session-expired':
          errorMessage = "Verification session expired. Please request a new code.";
          break;
        case 'too-many-requests':
          errorMessage = "Too many attempts. Please try again later.";
          break;
        default:
          errorMessage = e.message ?? "Verification failed";
      }
      
      ShowToastDialog.showToast(errorMessage);
      
      // Clear OTP fields on error
      for (var controller in otpControllers) {
        controller.clear();
      }
      focusNodes[0].requestFocus();
      
    } catch (e) {
      ShowToastDialog.closeLoader();
      isVerifying.value = false;
      print("OTP verification error: $e");
      ShowToastDialog.showToast("Verification failed. Please try again.");
    }
  }
  Future<void> _resendOtp(String countryCode, String phoneNumber, String oldVerificationId) async {
    if (isResending.value) return;
    
    isResending.value = true;
    ShowToastDialog.showLoader('Resending OTP...');

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: countryCode + phoneNumber,
        timeout: const Duration(seconds: 120),
        verificationCompleted: (_) {},
        verificationFailed: (FirebaseAuthException e) {
          ShowToastDialog.closeLoader();
          isResending.value = false;
          ShowToastDialog.showToast('Failed: ${e.message}');
        },
        codeSent: (verificationId, _) {
          ShowToastDialog.closeLoader();
          isResending.value = false;
          
          // Clear current OTP fields
          for (var controller in otpControllers) {
            controller.clear();
          }
          focusNodes[0].requestFocus();
          
          // Update the verification ID for this screen
          Get.off(() => const OtpScreen(), arguments: {
            "verificationId": verificationId,
            "phoneNumber": phoneNumber,
            "countryCode": countryCode,
          });
          
          ShowToastDialog.showToast("New verification code sent!");
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      ShowToastDialog.closeLoader();
      isResending.value = false;
      print("Resend OTP error: $e");
      ShowToastDialog.showToast('Failed to resend OTP');
    }
  }
}
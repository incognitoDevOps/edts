import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:customer/ui/auth_screen/login_screen.dart';
import 'package:customer/ui/dashboard_screen.dart';
import 'package:customer/ui/auth_screen/information_screen.dart';
import 'package:customer/ui/auth_screen/auth_choice_screen.dart';

import 'package:customer/model/user_model.dart';
import 'package:customer/utils/fire_store_utils.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleStartupLogic();
  }

  Future<void> _handleStartupLogic() async {
    await Future.delayed(const Duration(seconds: 2)); // For splash effect

    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser != null) {
      final userExists = await FireStoreUtils.userExitOrNot(firebaseUser.uid);

      if (userExists) {
        // Go to dashboard if profile is complete
        Get.offAll(() => const DashBoardScreen());
      } else {
        // Go to info screen to complete account
        final userModel = UserModel(
          id: firebaseUser.uid,
          email: firebaseUser.email,
          fullName: firebaseUser.displayName,
          profilePic: firebaseUser.photoURL,
        );

        Get.offAll(() => InformationScreen(), arguments: {
          'userModel': userModel,
        });
      }
    } else {
      // No user logged in — show Login/Signup choice screen
      Get.offAll(() => const AuthChoiceScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF008080),
      body: const Center(
        child: Text(
          'BuzRyde',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

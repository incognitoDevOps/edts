import 'dart:async';

import 'package:driver/ui/auth_screen/driver_info_screen.dart';
import 'package:driver/ui/auth_screen/login_screen.dart';
import 'package:driver/ui/auth_screen/pending_approval_screen.dart';
import 'package:driver/ui/dashboard_screen.dart';
import 'package:driver/ui/on_boarding_screen.dart';
import 'package:driver/utils/Preferences.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:get/get.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    // TODO: implement onInit
    Timer(const Duration(seconds: 3), () => redirectScreen());
    super.onInit();
  }

  redirectScreen() async {
    // Check if onboarding is completed
    if (Preferences.getBoolean(Preferences.isFinishOnBoardingKey) == false) {
      Get.offAll(const OnBoardingScreen());
      return;
    }

    // Check if user is logged in
    bool isLogin = await FireStoreUtils.isLogin();
    if (!isLogin) {
      Get.offAll(const LoginScreen());
      return;
    }

    // User is logged in, check their status
    try {
      DriverUserModel? user = await FireStoreUtils.getDriverProfile(FireStoreUtils.getCurrentUid());
      
      if (user == null) {
        Get.offAll(const LoginScreen());
        return;
      }

      // Navigate based on user status
      if (!user.profileCompleted! || !user.documentsSubmitted!) {
        Get.offAll(const DriverInfoScreen());
      } else if (user.approvalStatus == 'pending' || user.approvalStatus == 'rejected') {
        Get.offAll(const PendingApprovalScreen());
      } else if (user.approvalStatus == 'approved') {
        Get.offAll(const DashBoardScreen());
      } else {
        // Default fallback
        Get.offAll(const LoginScreen());
      }
    } catch (e) {
      // Error occurred, go to login
      Get.offAll(const LoginScreen());
    }
  }
}

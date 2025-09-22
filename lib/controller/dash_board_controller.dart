import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/ui/auth_screen/login_screen.dart';
import 'package:customer/ui/chat_screen/inbox_screen.dart';
import 'package:customer/ui/chat_bot/chatbot.dart';
import 'package:customer/ui/contact_us/contact_us_screen.dart';
import 'package:customer/ui/faq/faq_screen.dart';
import 'package:customer/ui/home_screens/home_screen_improved.dart';
import 'package:customer/ui/interCity/interCity_screen.dart';
import 'package:customer/ui/intercityOrders/intercity_order_screen.dart';
import 'package:customer/ui/orders/order_screen.dart';
import 'package:customer/ui/profile_screen/profile_screen.dart';
import 'package:customer/ui/referral_screen/referral_screen.dart';
import 'package:customer/ui/settings_screen/setting_screen.dart';
import 'package:customer/ui/wallet/wallet_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

class DashBoardController extends GetxController {
  final drawerItems = [
    DrawerItem('Ride Now'.tr, "assets/icons/ic_city.svg", ""),
    DrawerItem('City to city'.tr, "assets/icons/ic_intercity.svg", "Coming soon"),
    DrawerItem('Rides History'.tr, "assets/icons/ic_order.svg", ""),
    DrawerItem('OutStation History'.tr, "assets/icons/ic_order.svg", ""),
    DrawerItem('My Wallet'.tr, "assets/icons/ic_wallet.svg", ""),
    DrawerItem('Settings'.tr, "assets/icons/ic_settings.svg", ""),
    DrawerItem('Refer a friends'.tr, "assets/icons/ic_referral.svg", "Coming soon"),
    DrawerItem('Inbox'.tr, "assets/icons/ic_inbox.svg", ""),
    DrawerItem('My Profile'.tr, "assets/icons/ic_profile.svg", ""),
    DrawerItem('Support'.tr, "assets/icons/ic_support.svg", ""),
    DrawerItem('Contact us'.tr, "assets/icons/ic_contact_us.svg", ""),
    DrawerItem('FAQs'.tr, "assets/icons/ic_faq.svg", ""),
    DrawerItem('Log out'.tr, "assets/icons/ic_logout.svg", ""),
  ];

  getDrawerItemWidget(int pos) {
    switch (pos) {
      case 0:
        return const HomeScreenImproved();
      case 1:
        return const Center(child: Text("Coming Soon"));
      case 2:
        return const OrderScreen();
      case 3:
        return const InterCityOrderScreen();
      case 4:
        return const WalletScreen();
      case 5:
        return const SettingScreen();
      case 6:
        return const ReferralScreen();
      case 7:
        return const InboxScreen();
      case 8:
        return const ProfileScreen();
      case 9:
        return const ChatBotApp();
      case 10:
      return const ContactUsScreen();
      case 11:
        return const FaqScreen();
      default:
        return const Text("Error");
    }
  }

  RxInt selectedDrawerIndex = 0.obs;

  onSelectItem(int index) async {
    if (index == 12) {
      await FirebaseAuth.instance.signOut();
      Get.offAll(const LoginScreen());
    } else {
      selectedDrawerIndex.value = index;
      Get.back();
    }
  }

  Rx<DateTime> currentBackPressTime = DateTime.now().obs;

  Future<bool> onWillPop() {
    DateTime now = DateTime.now();
    if (now.difference(currentBackPressTime.value) > const Duration(seconds: 2)) {
      currentBackPressTime.value = now;
      ShowToastDialog.showToast("Double press to exit", position: EasyLoadingToastPosition.center);
      return Future.value(false);
    }
    return Future.value(true);
  }
}

class DrawerItem {
  String title;
  String icon;
  String status; // e.g. "Coming soon"

  DrawerItem(this.title, this.icon, this.status);
}

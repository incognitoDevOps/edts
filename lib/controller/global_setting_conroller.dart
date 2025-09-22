import 'dart:developer';

import 'package:customer/constant/constant.dart';
import 'package:customer/model/currency_model.dart';
import 'package:customer/model/language_model.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/services/localization_service.dart';
import 'package:customer/utils/Preferences.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/utils/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class GlobalSettingController extends GetxController {
  @override
  void onInit() {
    // TODO: implement onInit
    notificationInit();
    getCurrentCurrency();

    super.onInit();
  }

  getCurrentCurrency() async {
    if (Preferences.getString(Preferences.languageCodeKey).toString().isNotEmpty) {
      LanguageModel languageModel = Constant.getLanguage();
      LocalizationService().changeLocale(languageModel.code.toString());
    }

    try {
      await FireStoreUtils.getSettings(); // This method now handles loading Constant.currencyModel
      print("GlobalSettingConroller: FireStoreUtils.getSettings() COMPLETED.");
      if (Constant.currencyModel == null) {
        print("GlobalSettingConroller: Constant.currencyModel is STILL NULL after getSettings. Setting default.");
        // If getSettings didn't populate it (e.g., doc not found), set a default here
        Constant.currencyModel = CurrencyModel(id: "default", code: "CAD", decimalDigits: 2, enable: true, name: "Canadian Dollar", symbol: "C\$", symbolAtRight: false);
      } else {
        // Override symbol to C$ for Canadian Dollar
        Constant.currencyModel!.symbol = "C\$";
        print("GlobalSettingConroller: Constant.currencyModel has symbol: ${Constant.currencyModel?.symbol}");
      }
    } catch (e) {
      print("GlobalSettingConroller: Error in getSettings call: $e");
      print("GlobalSettingConroller: Setting default currency due to error.");
      Constant.currencyModel = CurrencyModel(id: "error_default", code: "CAD", decimalDigits: 2, enable: true, name: "Canadian Dollar", symbol: "C\$", symbolAtRight: false);
    }
  }

  NotificationService notificationService = NotificationService();

  notificationInit() {
    notificationService.initInfo().then((value) async {
      String token = await NotificationService.getToken();
      log(":::::::TOKEN:::::: $token");
      if (FirebaseAuth.instance.currentUser != null) {
        await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid()).then((value) {
          if (value != null) {
            UserModel driverUserModel = value;
            driverUserModel.fcmToken = token;
            FireStoreUtils.updateUser(driverUserModel);
          }
        });
      }
    });
  }
}

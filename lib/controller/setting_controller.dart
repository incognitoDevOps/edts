import 'package:customer/constant/constant.dart';
import 'package:customer/model/language_model.dart';
import 'package:customer/utils/Preferences.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class SettingController extends GetxController {
  @override
  void onInit() {
    loadInitialSettings(); 
    super.onInit();
  }

  RxBool isLoading = true.obs;
  RxList<LanguageModel> languageList = <LanguageModel>[].obs;
  RxList<String> modeList = <String>['Light mode', 'Dark mode', 'System'].obs;
  Rx<LanguageModel> selectedLanguage = LanguageModel().obs;
  Rx<String> selectedMode = "".obs;

  Future<void> loadInitialSettings() async {
    isLoading.value = true;

    try {
      await FireStoreUtils.getSettings(); // Corrected: Call static method directly
      print("SettingController: FireStoreUtils.getSettings() COMPLETED.");
    } catch (e) {
      print("SettingController: Error calling FireStoreUtils.getSettings(): $e");
    }

    // Now proceed to load language (which was the original getLanguage() method content)
    try {
      await FireStoreUtils.getLanguage().then((value) {
        if (value != null) {
          languageList.value = value;
          if (Preferences.getString(Preferences.languageCodeKey).toString().isNotEmpty) {
            LanguageModel pref = Constant.getLanguage();
            for (var element in languageList) {
              if (element.id == pref.id) {
                selectedLanguage.value = element;
              }
            }
          }
        }
      });
      if (Preferences.getString(Preferences.themKey).toString().isNotEmpty) {
        selectedMode.value = Preferences.getString(Preferences.themKey).toString();
      }
      print("SettingController: Language and Theme settings loaded.");
    } catch (e) {
      print("SettingController: Error loading language/theme settings: $e");
    }
    
    isLoading.value = false;
    update();
  }

  // getLanguage() async { // This method's content is now merged into loadInitialSettings
  //   await FireStoreUtils.getLanguage().then((value) {
  //     if (value != null) {
  //       languageList.value = value;
  //       if (Preferences.getString(Preferences.languageCodeKey).toString().isNotEmpty) {
  //         LanguageModel pref = Constant.getLanguage();
  //
  //         for (var element in languageList) {
  //           if (element.id == pref.id) {
  //             selectedLanguage.value = element;
  //           }
  //         }
  //       }
  //     }
  //   });
  //   if (Preferences.getString(Preferences.themKey).toString().isNotEmpty) {
  //     selectedMode.value = Preferences.getString(Preferences.themKey).toString();
  //   }
  //   isLoading.value = false;
  //   update();
  // }
}

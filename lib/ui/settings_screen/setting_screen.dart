import 'dart:convert';

import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/services/localization_service.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/ui/auth_screen/login_screen.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/Preferences.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controller/setting_controller.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final borderRadius = BorderRadius.circular(18);
    final cardShadow = [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
    // Ensure the controller is registered before using Get.find
    if (!Get.isRegistered<SettingController>()) {
      Get.put(SettingController());
    }
    final SettingController controller = Get.find<SettingController>();
    return GetBuilder<SettingController>(
        builder: (controller) {
          return Scaffold(
            backgroundColor: AppColors.primary,
            body: controller.isLoading.value
                ? Constant.loader()
                : Column(
                    children: [
                      // Top bar
                      Container(
                        height: Responsive.width(12, context),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                     
                      ),
                      // Main content
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.background,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(28),
                              topRight: Radius.circular(28),
                            ),
                            boxShadow: cardShadow,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Column(
                              children: [
                                Expanded(
                                  child: ListView(
                                    physics: const BouncingScrollPhysics(),
                                    children: [
                                      // Language
                                      _SettingsCard(
                                        borderRadius: borderRadius,
                                        child: Row(
                                          children: [
                                            _SettingsIcon('assets/icons/ic_language.svg'),
                                            const SizedBox(width: 18),
                                            Expanded(
                                              child: Text(
                                                "Language".tr,
                                                style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 16),
                                              ),
                                            ),
                                            SizedBox(
                                              width: Responsive.width(30, context),
                                              child: DropdownButtonFormField(
                                                isExpanded: true,
                                                decoration: _dropdownDecoration(),
                                                value: controller.selectedLanguage.value.id == null ? null : controller.selectedLanguage.value,
                                                onChanged: (value) {
                                                  controller.selectedLanguage.value = value!;
                                                  LocalizationService().changeLocale(value.code.toString());
                                                  Preferences.setString(Preferences.languageCodeKey, jsonEncode(controller.selectedLanguage.value));
                                                },
                                                hint: Text("select".tr),
                                                items: controller.languageList.map((item) {
                                                  return DropdownMenuItem(
                                                    value: item,
                                                    child: Text(item.name.toString(), style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      // Theme mode
                                      _SettingsCard(
                                        borderRadius: borderRadius,
                                        child: Row(
                                          children: [
                                            _SettingsIcon('assets/icons/ic_light_drak.svg'),
                                            const SizedBox(width: 18),
                                            Expanded(
                                              child: Text(
                                                "Light/dark mod".tr,
                                                style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 16),
                                              ),
                                            ),
                                            SizedBox(
                                              width: Responsive.width(30, context),
                                              child: DropdownButtonFormField<String>(
                                                isExpanded: true,
                                                decoration: _dropdownDecoration(),
                                                validator: (value) => value == null ? 'field required' : null,
                                                value: controller.selectedMode.isEmpty ? null : controller.selectedMode.value,
                                                onChanged: (value) {
                                                  controller.selectedMode.value = value!;
                                                  Preferences.setString(Preferences.themKey, value.toString());
                                                  if (controller.selectedMode.value == "Dark mode") {
                                                    themeChange.darkTheme = 0;
                                                  } else if (controller.selectedMode.value == "Light mode") {
                                                    themeChange.darkTheme = 1;
                                                  } else {
                                                    themeChange.darkTheme = 2;
                                                  }
                                                },
                                                hint: Text("select".tr),
                                                items: controller.modeList.map((item) {
                                                  return DropdownMenuItem(
                                                    value: item,
                                                    child: Text(item.toString(), style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      // Support 
                                      // _SettingsCard(
                                      //   borderRadius: borderRadius,
                                      //   child: InkWell(
                                      //     borderRadius: borderRadius,
                                      //     onTap: () async {
                                      //       final Uri url = Uri.parse(Constant.supportURL.toString());
                                      //       if (!await launchUrl(url)) {
                                      //         throw Exception('Could not launch \\${Constant.supportURL.toString()}'.tr);
                                      //       }
                                      //     },
                                      //     child: Row(
                                      //       children: [
                                      //         _SettingsIcon('assets/icons/ic_support.svg'),
                                      //         const SizedBox(width: 18),
                                      //         Text(
                                      //           "Support".tr,
                                      //           style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 16, color: Theme.of(context).colorScheme.primary),
                                      //         ),
                                      //         const Spacer(),
                                      //         Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey.shade400),
                                      //       ],
                                      //     ),
                                      //   ),
                                      // ),
                                      
                                      
                                      const SizedBox(height: 14),
                                      // Delete Account
                                      _SettingsCard(
                                        borderRadius: borderRadius,
                                        child: InkWell(
                                          borderRadius: borderRadius,
                                          onTap: () {
                                            showAlertDialog(context);
                                          },
                                          child: Row(
                                            children: [
                                              _SettingsIcon('assets/icons/ic_delete.svg', color: Colors.redAccent),
                                              const SizedBox(width: 18),
                                              Text(
                                                "Delete Account".tr,
                                                style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.redAccent),
                                              ),
                                              const Spacer(),
                                              Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.redAccent.withOpacity(0.5)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // App version
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Text(
                                    "V \\${Constant.appVersion}".tr,
                                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          );
        });
  }

  showAlertDialog(BuildContext context) {
    Widget okButton = TextButton(
      child: Text("OK".tr),
      onPressed: () async {
        ShowToastDialog.showLoader("Please wait".tr);
        await FireStoreUtils.deleteUser().then((value) {
          ShowToastDialog.closeLoader();
          if (value == true) {
            ShowToastDialog.showToast("Account delete".tr);
            Get.offAll(const LoginScreen());
          } else {
            ShowToastDialog.showToast("Please contact to administrator".tr);
          }
        });
      },
    );
    Widget cancel = TextButton(
      child: Text("Cancel".tr),
      onPressed: () {
        Get.back();
      },
    );
    AlertDialog alert = AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
          const SizedBox(width: 8),
          Text("Account delete".tr),
        ],
      ),
      content: Text("Are you sure want to delete Account.".tr),
      actions: [okButton, cancel],
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}

// --- Shadcn UI inspired widgets ---

InputDecoration _dropdownDecoration() => const InputDecoration(
      contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      disabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFe5e7eb), width: 1.2)),
      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFe5e7eb), width: 1)),
      errorBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.redAccent)),
      border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFe5e7eb))),
      isDense: true,
    );

class _SettingsCard extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  const _SettingsCard({required this.child, required this.borderRadius});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  final String asset;
  final Color? color;
  const _SettingsIcon(this.asset, {this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: SvgPicture.asset(
          asset,
          width: 22,
          color: color,
        ),
      ),
    );
  }
}

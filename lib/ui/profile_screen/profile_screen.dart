import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controller/profile_controller.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/themes/text_field_them.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<ProfileController>(
      init: ProfileController(),
      builder: (controller) {
        final fullName = controller.fullNameController.value.text;
        final img = controller.profileImage.value;
        final initial = _getInitials(fullName);

        print("🌟 [ProfileScreen] fullName = '$fullName', img = '$img'");

        return Scaffold(
          backgroundColor: AppColors.primary,
          body: Column(
            children: [
              Container(
                height: Responsive.width(45, context),
                width: double.infinity,
                color: AppColors.primary,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Positioned(
                      bottom: 50,
                      child: GestureDetector(
                        onTap: () => buildBottomSheet(context, controller),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6)),
                            ],
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: _buildAvatar(context, img, initial),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 50,
                      right: Responsive.width(36, context),
                      child: InkWell(
                        onTap: () => buildBottomSheet(context, controller),
                        child: ClipOval(
                          child: Container(
                            decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.95),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.18),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2)),
                                ]),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SvgPicture.asset(
                                'assets/icons/ic_edit_profile.svg',
                                width: 22,
                                height: 22,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Transform.translate(
                  offset: const Offset(0, -22),
                  child: controller.isLoading.value
                      ? Constant.loader()
                      : Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.background,
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(25),
                                topRight: Radius.circular(25)),
                          ),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Profile Information',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold)),
                                const SizedBox(height: 14),
                                TextFieldThem.buildTextFiled(context,
                                    hintText: 'Full name'.tr,
                                    controller:
                                        controller.fullNameController.value),
                                const SizedBox(height: 14),
                                TextFormField(
                                  validator: (value) =>
                                      (value?.isNotEmpty ?? false)
                                          ? null
                                          : 'Required'.tr,
                                  keyboardType: TextInputType.phone,
                                  controller:
                                      controller.phoneNumberController.value,
                                  enabled: true,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: themeChange.getThem()
                                        ? AppColors.darkTextField
                                        : AppColors.textField,
                                    prefixIcon: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CountryCodePicker(
                                            onChanged: (val) {
                                              controller.countryCode.value =
                                                  val.dialCode ?? "+1";
                                            },
                                            initialSelection:
                                                controller.countryCode.value,
                                            favorite: const ['+1', '+91', '+44'],
                                            showCountryOnly: false,
                                            showOnlyCountryWhenClosed: false,
                                            alignLeft: false,
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.phone,
                                              size: 18, color: Colors.grey),
                                        ]),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                    hintText: 'Phone number'.tr,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextFieldThem.buildTextFiled(context,
                                    hintText: 'Email'.tr,
                                    controller:
                                        controller.emailController.value,
                                    enable: false),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: controller.isUpdating.value || controller.isLoading.value
                                        ? null
                                        : () => controller.updateProfile(),
                                    child: controller.isUpdating.value
                                        ? const CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          )
                                        : Text(
                                            "Update Profile".tr,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar(BuildContext context, String img, String initial) {
    final size = Responsive.width(30, context);
    final radius = Responsive.width(15, context);

    if (img.isEmpty) {
      return CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.primary.withOpacity(0.8),
          child: Text(initial,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)));
    }

    if (img.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: img,
        imageBuilder: (_, imgProvider) =>
            CircleAvatar(radius: radius, backgroundImage: imgProvider),
        placeholder: (_, __) => CircleAvatar(
            radius: radius, 
            backgroundColor: AppColors.primary.withOpacity(0.8),
            child: const CircularProgressIndicator()),
        errorWidget: (_, __, ___) {
          print("❌ Image load failed, fallback to initials.");
          return CircleAvatar(
              radius: radius,
              backgroundColor: AppColors.primary.withOpacity(0.8),
              child: Text(initial,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)));
        },
      );
    }

    final file = File(img);
    return file.existsSync()
        ? CircleAvatar(radius: radius, backgroundImage: FileImage(file))
        : CircleAvatar(
            radius: radius,
            backgroundColor: AppColors.primary.withOpacity(0.8),
            child: Text(initial,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)));
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty || parts.first.isEmpty) return "?";
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  void buildBottomSheet(BuildContext context, ProfileController controller) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) => SizedBox(
        height: Responsive.height(22, ctx),
        child: Column(
          children: [
            const SizedBox(height: 15),
            Text("Please Select".tr,
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildImagePickerOption(ctx, "Camera", Icons.camera_alt,
                    () => controller.pickFile(source: ImageSource.camera)),
                _buildImagePickerOption(
                    ctx,
                    "Gallery",
                    Icons.photo_library_sharp,
                    () => controller.pickFile(source: ImageSource.gallery)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerOption(
      BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle),
            child: IconButton(
                onPressed: onTap,
                icon: Icon(icon, size: 32, color: AppColors.primary)),
          ),
          const SizedBox(height: 3),
          Text(label.tr),
        ],
      ),
    );
  }
}
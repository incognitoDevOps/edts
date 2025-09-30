import 'dart:io';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ProfileController extends GetxController {
  RxBool isLoading = true.obs;
  RxBool isUpdating = false.obs;
  Rx<UserModel> userModel = UserModel().obs;

  Rx<TextEditingController> fullNameController = TextEditingController().obs;
  Rx<TextEditingController> emailController = TextEditingController().obs;
  Rx<TextEditingController> phoneNumberController = TextEditingController().obs;
  RxString countryCode = "+1".obs;
  RxString profileImage = "".obs;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    getData();
  }

  Future<void> getData() async {
    print("📥 [ProfileController] getData()");
    try {
      final value =
          await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid());
      if (value != null) {
        userModel.value = value;
        fullNameController.value.text = value.fullName ?? "";
        emailController.value.text = value.email ?? "";
        phoneNumberController.value.text = value.phoneNumber ?? "";
        countryCode.value = value.countryCode ?? "+1";
        profileImage.value = value.profilePic ?? "";
        print("📤 fullName: ${fullNameController.value.text}");
        print("📤 profilePic: ${profileImage.value}");
      }
    } catch (e) {
      ShowToastDialog.showToast("Failed loading profile: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickFile({required ImageSource source}) async {
    try {
      final image = await _imagePicker.pickImage(source: source);
      if (image == null) return;
      Get.back();
      profileImage.value = image.path;
      print("📸 Picked image path: ${profileImage.value}");
    } on PlatformException catch (e) {
      ShowToastDialog.showToast("Failed to pick image: $e");
    }
  }

  Future<void> updateProfile() async {
    isUpdating.value = true;
    ShowToastDialog.showLoader("Updating profile...");
    
    try {
      String finalProfileImage = profileImage.value;
      
      // Only upload if it's a new local file (not a URL)
      if (profileImage.value.isNotEmpty && !profileImage.value.startsWith('http')) {
        try {
          print("🔼 Uploading profile image...");
          finalProfileImage = await _uploadProfileImageWithRetry(
            File(profileImage.value),
            "profileImage/${FireStoreUtils.getCurrentUid()}",
            File(profileImage.value).path.split('/').last,
          );
          print("✅ Image uploaded successfully: $finalProfileImage");
        } catch (e) {
          print("❌ Image upload failed: $e");
          // Continue with the update even if image upload fails
          ShowToastDialog.showToast("Profile updated but image upload failed");
        }
      }

      // Create updated user object
      UserModel updatedUser = userModel.value.copyWith(
        fullName: fullNameController.value.text.trim(),
        phoneNumber: phoneNumberController.value.text.trim(),
        countryCode: countryCode.value,
        profilePic: finalProfileImage,
      );
      
      // Update in Firestore
      await FireStoreUtils.updateUser(updatedUser);
      
      // Update local model
      userModel.value = updatedUser;
      profileImage.value = finalProfileImage;
      
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Profile updated successfully");
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Update failed: $e");
      print("❌ Update profile error: $e");
    } finally {
      isUpdating.value = false;
    }
  }

  // Helper method for retrying image upload
  Future<String> _uploadProfileImageWithRetry(File image, String filePath, String fileName, {int maxRetries = 2}) async {
    int attempt = 0;
    
    while (attempt < maxRetries) {
      try {
        attempt++;
        print("🔄 Image upload attempt $attempt");
        
        // Use a longer timeout for image uploads
        final downloadUrl = await Constant.uploadUserImageToFireStorage(
          image,
          filePath,
          fileName,
        ).timeout(const Duration(seconds: 30));
        
        return downloadUrl;
      } catch (e) {
        if (attempt >= maxRetries) {
          rethrow; // Re-throw if we've exhausted all retries
        }
        print("⏳ Retrying image upload in 2 seconds...");
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    
    throw Exception("Failed to upload image after $maxRetries attempts");
  }
}
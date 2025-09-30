import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InformationController extends GetxController {
  Rx<TextEditingController> fullNameController = TextEditingController().obs;
  Rx<TextEditingController> emailController = TextEditingController().obs;
  Rx<TextEditingController> passwordController = TextEditingController().obs;
  Rx<TextEditingController> phoneNumberController = TextEditingController().obs;
  Rx<TextEditingController> referralCodeController = TextEditingController().obs;
  RxString countryCode = "+1".obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    fullNameController.value.dispose();
    emailController.value.dispose();
    passwordController.value.dispose();
    phoneNumberController.value.dispose();
    referralCodeController.value.dispose();
    super.onClose();
  }
}
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class ContactUsController extends GetxController {
  RxBool isLoading = true.obs;

  Rx<TextEditingController> feedbackController = TextEditingController().obs;
  Rx<TextEditingController> userEmailController = TextEditingController().obs;

  RxString email = "".obs; // recipient (your admin/support email from Firebase)
  RxString subject = "".obs;

  @override
  void onInit() {
    getContactUsInformation();
    super.onInit();
  }

  getContactUsInformation() async {
    final value = await FireStoreUtils.fireStore
        .collection(CollectionName.settings)
        .doc("contact_us")
        .get();

    if (value.exists) {
      email.value = value.data()?["email"] ?? "";
      subject.value = value.data()?["subject"] ?? "User Feedback";
    }
    isLoading.value = false;
  }

  Future<void> sendFeedbackEmail() async {
    final userEmail = userEmailController.value.text.trim();
    final feedback = feedbackController.value.text.trim();

    if (userEmail.isEmpty || feedback.isEmpty) {
      Get.snackbar("Error", "Both fields are required");
      return;
    }

    final smtpServer = gmail('brianadem2@gmail.com', 'lzznojxulogwcsfe');

    final message = Message()
      ..from = Address('brianadem2@gmail.com', 'App Feedback')
      ..recipients.add(email.value)
      ..recipients.add("brianadem2@gmail.com")
      ..recipients.add("b3njaminbaya@gmail.com")
      ..recipients.add("buzlinholdingsinc@outlook.com")
      ..subject = subject.value.isNotEmpty ? subject.value : 'User Feedback'
      ..text = '''
You received new feedback from a user.

User Email: $userEmail

Feedback:
$feedback
'''
      ..headers = {
        'reply-to': userEmail,
      };

    // ✅ LOGGING SECTION
    // ignore: duplicate_ignore
    // ignore: avoid_print
    print("📧 Sending email...");
    print("From: ${message.from}");
    print("To: ${message.recipients}");
    print("Subject: ${message.subject}");
    print("Text:\n${message.text}");
    print("Headers: ${message.headers}");

    try {
      await send(message, smtpServer);
      Get.snackbar("Success", "Feedback submitted successfully");
      feedbackController.value.clear();
      userEmailController.value.clear();
    } catch (e) {
      Get.snackbar("Error", "Failed to send feedback: ${e.toString()}");
      print("❌ Email sending error: $e");
    }
  }
}

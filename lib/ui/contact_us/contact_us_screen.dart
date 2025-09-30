import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer/controller/contact_us_controller.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/button_them.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/themes/text_field_them.dart';
import 'package:customer/constant/constant.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<ContactUsController>(
      init: ContactUsController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppColors.primary,
          body: Column(
            children: [
              SizedBox(height: Responsive.width(8, context)),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: controller.isLoading.value
                        ? Constant.loader()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              Text("Send Feedback",
                                  style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 10),
                              Text("Let us know your issue or feedback",
                                  style: GoogleFonts.poppins()),
                              const SizedBox(height: 20),

                              /// User email input
                              TextFieldThem.buildTextFiled(
                                context,
                                hintText: 'Your Email',
                                controller: controller.userEmailController.value,
                              ),
                              const SizedBox(height: 20),

                              /// Feedback input
                              TextFieldThem.buildTextFiled(
                                context,
                                hintText: 'Your Feedback',
                                controller: controller.feedbackController.value,
                                maxLine: 5,
                              ),
                              const SizedBox(height: 20),

                              /// Submit button
                              ButtonThem.buildButton(
                                context,
                                title: "Submit",
                                onPress: () async {
                                  await controller.sendFeedbackEmail();
                                },
                              ),
                            ],
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
}

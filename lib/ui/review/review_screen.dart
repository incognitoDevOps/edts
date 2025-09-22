import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controller/rating_controller.dart';
import 'package:customer/model/driver_user_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/text_field_them.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/widget/my_separator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<RatingController>(
        init: RatingController(),
        builder: (controller) {
          final media = MediaQuery.of(context);
          final cardWidth = media.size.width * 0.92;
          final profilePicSize = media.size.width * 0.28;
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Review".tr, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
                  Text("Share your experience with the driver", style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
                ],
              ),
              leading: InkWell(
                  onTap: () {
                    Get.back();
                  },
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  )),
            ),
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0f2027), Color(0xFF2c5364)],
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: double.infinity,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        // Card with top padding for profile pic
                        Container(
                          margin: EdgeInsets.only(top: profilePicSize / 2),
                          width: cardWidth,
                          child: Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                            color: themeChange.getThem() ? Colors.grey[900] : Colors.white,
                            shadowColor: Colors.black.withOpacity(0.15),
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(22, profilePicSize / 2 + 16, 22, 28),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _DriverInfo(controller: controller),
                                  Text(
                                    'How was your ride?'.tr,
                                    style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 18),
                                  const MySeparator(color: Colors.grey),
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(top: 20),
                                    child: Text(
                                      'Rate for'.tr,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(letterSpacing: 0.8),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(top: 8),
                                    child: Text(
                                      controller.driverModel.value.fullName ?? "-",
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 16),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(top: 16),
                                    child: Obx(() => RatingBar.builder(
                                          initialRating: controller.rating.value,
                                          minRating: 0,
                                          direction: Axis.horizontal,
                                          allowHalfRating: true,
                                          itemCount: 5,
                                          itemSize: 38,
                                          itemPadding: const EdgeInsets.symmetric(horizontal: 6.0),
                                          itemBuilder: (context, _) => const Icon(
                                            Icons.star_rounded,
                                            color: Colors.amber,
                                          ),
                                          onRatingUpdate: (rating) {
                                            controller.rating(rating);
                                          },
                                        )),
                                  ),
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(top: 28),
                                    child: _CommentField(controller: controller),
                                  ),
                                  const SizedBox(height: 18),
                                  Obx(() => SizedBox(
                                        width: double.infinity,
                                        height: 48,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            elevation: 2,
                                          ),
                                          onPressed: controller.isLoading.value
                                              ? null
                                              : () async {
                                                  final confirmed = await showDialog<bool>(
                                                    context: context,
                                                    builder: (ctx) => AlertDialog(
                                                      title: const Text('Submit Review'),
                                                      content: const Text('Are you sure you want to submit your review?'),
                                                      actions: [
                                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                                        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit')),
                                                      ],
                                                    ),
                                                  );
                                                  if (confirmed != true) return;

                                                  ShowToastDialog.showLoader("Please wait".tr);

                                                  await FireStoreUtils.getDriver(
                                                          controller.type.value == "orderModel" ? controller.orderModel.value.driverId.toString() : controller.intercityOrderModel.value.driverId.toString())
                                                      .then((value) async {
                                                    if (value != null) {
                                                      DriverUserModel driverUserModel = value;

                                                      if (controller.reviewModel.value.id != null) {
                                                        driverUserModel.reviewsSum =
                                                            (double.parse(driverUserModel.reviewsSum.toString()) - double.parse(controller.reviewModel.value.rating.toString())).toString();
                                                        driverUserModel.reviewsCount = (double.parse(driverUserModel.reviewsCount.toString()) - 1).toString();
                                                      }
                                                      driverUserModel.reviewsSum = (double.parse(driverUserModel.reviewsSum.toString()) + double.parse(controller.rating.value.toString())).toString();
                                                      driverUserModel.reviewsCount = (double.parse(driverUserModel.reviewsCount.toString()) + 1).toString();
                                                      await FireStoreUtils.updateDriver(driverUserModel);
                                                    }
                                                  });

                                                  controller.reviewModel.value.id = controller.type.value == "orderModel" ? controller.orderModel.value.id : controller.intercityOrderModel.value.id;
                                                  controller.reviewModel.value.comment = controller.commentController.value.text;
                                                  controller.reviewModel.value.rating = controller.rating.value.toString();
                                                  controller.reviewModel.value.customerId = FireStoreUtils.getCurrentUid();
                                                  controller.reviewModel.value.driverId =
                                                      controller.type.value == "orderModel" ? controller.orderModel.value.driverId : controller.intercityOrderModel.value.driverId;
                                                  controller.reviewModel.value.date = Timestamp.now();
                                                  controller.reviewModel.value.type = controller.type.value == "orderModel" ? "city" : "intercity";

                                                  await FireStoreUtils.setReview(controller.reviewModel.value).then((value) {
                                                    ShowToastDialog.closeLoader();
                                                    if (value != null && value == true) {
                                                      showDialog(
                                                        context: context,
                                                        builder: (ctx) => AlertDialog(
                                                          title: const Icon(Icons.check_circle, color: Colors.green, size: 48),
                                                          content: Text("Review submitted successfully!".tr, textAlign: TextAlign.center),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () {
                                                                Navigator.pop(ctx);
                                                                Get.back();
                                                              },
                                                              child: const Text('OK'),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    } else {
                                                      ShowToastDialog.showToast("Failed to submit review. Please try again.".tr);
                                                    }
                                                  });
                                                },
                                          child: controller.isLoading.value
                                              ? const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                )
                                              : Text(
                                                  "Submit".tr,
                                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white),
                                                ),
                                        ),
                                      )),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Profile image attached to card
                        Positioned(
                          top: 0,
                          left: (media.size.width - profilePicSize) / 2,
                          child: Container(
                            width: profilePicSize,
                            height: profilePicSize,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(profilePicSize / 2),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.13),
                                  blurRadius: 10,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(profilePicSize / 2),
                              child: CachedNetworkImage(
                                imageUrl: controller.driverModel.value.profilePic?.toString() ?? Constant.userPlaceHolder,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Constant.loader(),
                                errorWidget: (context, url, error) => Image.network(Constant.userPlaceHolder),
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
          );
        });
  }
}

class _DriverInfo extends StatelessWidget {
  final RatingController controller;
  const _DriverInfo({required this.controller});

  @override
  Widget build(BuildContext context) {
    final driver = controller.driverModel.value;
    return Column(
      children: [
        Text(
          driver.fullName ?? "-",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(letterSpacing: 0.8, fontWeight: FontWeight.w800, fontSize: 20),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.star, size: 22, color: AppColors.ratingColour),
            const SizedBox(width: 5),
            Text(
              Constant.calculateReview(
                reviewCount: driver.reviewsCount?.toString() ?? "0",
                reviewSum: driver.reviewsSum?.toString() ?? "0",
              ),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(driver.vehicleInformation?.vehicleNumber ?? "-", style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            const SizedBox(width: 10),
            Text(driver.vehicleInformation?.vehicleType ?? "-", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
            const SizedBox(width: 10),
            Text(driver.vehicleInformation?.vehicleColor ?? "-", style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _CommentField extends StatefulWidget {
  final RatingController controller;
  const _CommentField({required this.controller});

  @override
  State<_CommentField> createState() => _CommentFieldState();
}

class _CommentFieldState extends State<_CommentField> {
  int charCount = 0;
  static const int maxChars = 250;

  @override
  void initState() {
    super.initState();
    widget.controller.commentController.value.addListener(_updateCount);
  }

  void _updateCount() {
    setState(() {
      charCount = widget.controller.commentController.value.text.length;
    });
  }

  @override
  void dispose() {
    widget.controller.commentController.value.removeListener(_updateCount);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextFieldThem.buildTextFiled(
          context,
          hintText: 'Comment..'.tr,
          controller: widget.controller.commentController.value,
          maxLine: 5,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2, right: 4),
          child: Text(
            '$charCount/$maxChars',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}

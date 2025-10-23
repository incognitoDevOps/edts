import 'package:clipboard/clipboard.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controller/complete_order_controller.dart';
import 'package:customer/model/driver_user_model.dart';
import 'package:customer/model/tax_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/widget/driver_view.dart';
import 'package:customer/widget/location_view.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CompleteOrderScreen extends StatelessWidget {
  const CompleteOrderScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<CompleteOrderController>(
        init: CompleteOrderController(),
        builder: (controller) {
          return WillPopScope(
            onWillPop: () async {
              Get.back();
              return false;
            },
            child: Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.primary,
              title: Text("Ride Details".tr),
              leading: InkWell(
                onTap: () {
                  Get.back();
                },
                child: const Icon(
                  Icons.arrow_back,
                ),
              ),
              // 🔥 NEW: Add refresh button
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    controller.refreshData();
                  },
                  tooltip: 'Refresh Data',
                ),
              ],
            ),
            body: Column(
              children: [
                Container(
                  height: Responsive.width(10, context),
                  width: Responsive.width(100, context),
                  color: AppColors.primary,
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
                                topRight: Radius.circular(25),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Order ID Section
                                        Container(
                                          decoration: BoxDecoration(
                                            color: themeChange.getThem()
                                                ? AppColors.darkContainerBackground
                                                : AppColors.containerBackground,
                                            borderRadius: const BorderRadius.all(Radius.circular(10)),
                                            border: Border.all(
                                              color: themeChange.getThem()
                                                  ? AppColors.darkContainerBorder
                                                  : AppColors.containerBorder,
                                              width: 0.5,
                                            ),
                                            boxShadow: themeChange.getThem()
                                                ? null
                                                : [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.10),
                                                      blurRadius: 5,
                                                      offset: const Offset(0, 4),
                                                    ),
                                                  ],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        "Order ID".tr,
                                                        style: GoogleFonts.poppins(
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                    InkWell(
                                                      onTap: () {
                                                        FlutterClipboard.copy(controller.orderModel.value.id.toString()).then((value) {
                                                          ShowToastDialog.showToast("OrderId copied".tr);
                                                        });
                                                      },
                                                      child: DottedBorder(
                                                        borderType: BorderType.RRect,
                                                        radius: const Radius.circular(4),
                                                        dashPattern: const [6, 6, 6, 6],
                                                        color: AppColors.textFieldBorder,
                                                        child: Padding(
                                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                                          child: Text(
                                                            "Copy".tr,
                                                            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(
                                                  height: 5,
                                                ),
                                                Text(
                                                  "#${controller.orderModel.value.id!.toUpperCase()}",
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),

                                        // 🔥 UPDATED: Driver Section using controller data
                                        _buildDriverSection(controller, themeChange),
                                        
                                        const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 5),
                                          child: Divider(thickness: 1),
                                        ),

                                        // 🔥 UPDATED: Vehicle Section using controller data
                                        _buildVehicleSectionWithController(controller, themeChange),
                                        
                                        const SizedBox(height: 20),

                                        // Pickup and Drop-off Locations
                                        Text(
                                          "Pickup and drop-off locations".tr,
                                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 10),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: themeChange.getThem()
                                                ? AppColors.darkContainerBackground
                                                : AppColors.containerBackground,
                                            borderRadius: const BorderRadius.all(Radius.circular(10)),
                                            border: Border.all(
                                              color: themeChange.getThem()
                                                  ? AppColors.darkContainerBorder
                                                  : AppColors.containerBorder,
                                              width: 0.5,
                                            ),
                                            boxShadow: themeChange.getThem()
                                                ? null
                                                : [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.10),
                                                      blurRadius: 5,
                                                      offset: const Offset(0, 4),
                                                    ),
                                                  ],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: LocationView(
                                              sourceLocation: controller.orderModel.value.sourceLocationName.toString(),
                                              destinationLocation: controller.orderModel.value.destinationLocationName.toString(),
                                            ),
                                          ),
                                        ),

                                        // Ride Status and Date
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 20),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: themeChange.getThem() ? AppColors.darkGray : AppColors.gray,
                                              borderRadius: const BorderRadius.all(Radius.circular(10)),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                              child: Center(
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        controller.orderModel.value.status.toString(),
                                                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                                                      ),
                                                    ),
                                                    Text(
                                                      controller.formattedDate,
                                                      style: GoogleFonts.poppins(),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Booking Summary
                                        Container(
                                          decoration: BoxDecoration(
                                            color: themeChange.getThem()
                                                ? AppColors.darkContainerBackground
                                                : AppColors.containerBackground,
                                            borderRadius: const BorderRadius.all(Radius.circular(10)),
                                            border: Border.all(
                                              color: themeChange.getThem()
                                                  ? AppColors.darkContainerBorder
                                                  : AppColors.containerBorder,
                                              width: 0.5,
                                            ),
                                            boxShadow: themeChange.getThem()
                                                ? null
                                                : [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.10),
                                                      blurRadius: 5,
                                                      offset: const Offset(0, 4),
                                                    ),
                                                  ],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        "Booking summary".tr,
                                                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                                      ),
                                                    ),
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        color: themeChange.getThem() ? AppColors.darkGray : AppColors.gray,
                                                        borderRadius: const BorderRadius.all(Radius.circular(5)),
                                                      ),
                                                      child: Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                                        child: Text(
                                                          controller.orderModel.value.paymentType.toString(),
                                                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const Divider(thickness: 1),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        "Ride Amount".tr,
                                                        style: GoogleFonts.poppins(color: AppColors.subTitleColor),
                                                      ),
                                                    ),
                                                    Text(
                                                      Constant.amountShow(amount: controller.orderModel.value.finalRate),
                                                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                                    ),
                                                  ],
                                                ),
                                                const Divider(thickness: 1),
                                                controller.orderModel.value.taxList == null
                                                    ? const SizedBox()
                                                    : ListView.builder(
                                                        itemCount: controller.orderModel.value.taxList!.length,
                                                        shrinkWrap: true,
                                                        padding: EdgeInsets.zero,
                                                        itemBuilder: (context, index) {
                                                          TaxModel taxModel = controller.orderModel.value.taxList![index];
                                                          return Column(
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Expanded(
                                                                    child: Text(
                                                                      "${taxModel.title.toString()} (${taxModel.type == "fix" ? Constant.amountShow(amount: taxModel.tax) : "${taxModel.tax}%"})",
                                                                      style: GoogleFonts.poppins(color: AppColors.subTitleColor),
                                                                    ),
                                                                  ),
                                                                  Text(
                                                                    Constant.amountShow(
                                                                      amount: Constant()
                                                                          .calculateTax(
                                                                            amount: (double.parse(controller.orderModel.value.finalRate.toString()) -
                                                                                    double.parse(controller.couponAmount.value.toString()))
                                                                                .toString(),
                                                                            taxModel: taxModel,
                                                                          )
                                                                          .toString(),
                                                                    ),
                                                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                                                  ),
                                                                ],
                                                              ),
                                                              const Divider(thickness: 1),
                                                            ],
                                                          );
                                                        },
                                                      ),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        "Discount".tr,
                                                        style: GoogleFonts.poppins(color: AppColors.subTitleColor),
                                                      ),
                                                    ),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          "(-${controller.couponAmount.value == "0.0" ? Constant.amountShow(amount: "0.0") : Constant.amountShow(amount: controller.couponAmount.value)})",
                                                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.red),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                const Divider(thickness: 1),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        "Payable amount".tr,
                                                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                                      ),
                                                    ),
                                                    Text(
                                                      Constant.amountShow(amount: controller.calculateAmountFormatted()),
                                                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
            ),
          );
        });
  }

  // 🔥 UPDATED: Build driver section using controller's driver data
  Widget _buildDriverSection(CompleteOrderController controller, DarkThemeProvider themeChange) {
    // Check if we have driver data loaded in controller
    if (controller.isDriverLoading.value) {
      return _buildDriverLoadingState();
    }

    if (!controller.hasDriverData && controller.driverError.value.isNotEmpty) {
      return _buildDriverErrorState(controller.driverError.value);
    }

    if (!controller.hasDriverData) {
      return _buildNoDriverState();
    }

    // Use DriverView with the loaded driver data
    return DriverView(
      driverId: controller.orderModel.value.driverId!,
      amount: controller.orderModel.value.finalRate.toString(),
    );
  }

  // 🔥 NEW: Build vehicle section using controller's driver data
  Widget _buildVehicleSectionWithController(CompleteOrderController controller, DarkThemeProvider themeChange) {
    // Check if we have driver data loaded
    if (controller.isDriverLoading.value) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Vehicle Details",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          _buildVehicleLoadingState(),
        ],
      );
    }

    if (!controller.hasDriverData) {
      return const SizedBox(); // Don't show vehicle section if no driver
    }

    final vehicle = controller.driverUserModel.value!.vehicleInformation;

    if (vehicle == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Vehicle Details",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          _buildVehicleErrorState("Vehicle details not found"),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Vehicle Details",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: themeChange.getThem() ? AppColors.darkContainerBackground : AppColors.containerBackground,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            border: Border.all(
              color: themeChange.getThem() ? AppColors.darkContainerBorder : AppColors.containerBorder,
              width: 0.5,
            ),
            boxShadow: themeChange.getThem()
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 5,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildVehicleDetail(
                  icon: SvgPicture.asset(
                    'assets/icons/ic_car.svg',
                    width: 18,
                    color: themeChange.getThem() ? Colors.white : Colors.black,
                  ),
                  label: "Type",
                  value: controller.vehicleType ?? "Unknown",
                ),
                _buildVehicleDetail(
                  icon: SvgPicture.asset(
                    'assets/icons/ic_color.svg',
                    width: 18,
                    color: themeChange.getThem() ? Colors.white : Colors.black,
                  ),
                  label: "Color",
                  value: controller.vehicleColor ?? "Unknown",
                ),
                _buildVehicleDetail(
                  icon: Image.asset(
                    'assets/icons/ic_number.png',
                    width: 18,
                    color: themeChange.getThem() ? Colors.white : Colors.black,
                  ),
                  label: "Number",
                  value: controller.vehicleNumber ?? "Unknown",
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 🔥 NEW: Reusable vehicle detail widget
  Widget _buildVehicleDetail({required Widget icon, required String label, required String value}) {
    return Expanded(
      child: Column(
        children: [
          icon,
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppColors.subTitleColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // 🔥 NEW: Build loading state for driver section
  Widget _buildDriverLoadingState() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.containerBackground,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(color: AppColors.containerBorder, width: 0.5),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Column(
            children: [
              SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(height: 8),
              Text(
                "Loading driver information...",
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔥 NEW: Build error state for driver section
  Widget _buildDriverErrorState(String message) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.containerBackground,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(color: Colors.orange, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.orange, size: 40),
            const SizedBox(height: 8),
            Text(
              "Driver Information",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: GoogleFonts.poppins(
                color: Colors.orange,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 UPDATED: Build loading state for vehicle section
  Widget _buildVehicleLoadingState() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.containerBackground,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(color: AppColors.containerBorder, width: 0.5),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }

  // 🔥 UPDATED: Build error state for vehicle section
  Widget _buildVehicleErrorState(String message) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.containerBackground,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(color: Colors.orange, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: Colors.orange, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: Colors.orange,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 UPDATED: Build state when no driver is assigned
  Widget _buildNoDriverState() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.containerBackground,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(color: Colors.grey, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Column(
          children: [
            Icon(Icons.person_off, color: Colors.grey, size: 40),
            const SizedBox(height: 8),
            Text(
              "No Driver Assigned",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "This ride does not have a driver assigned yet",
              style: GoogleFonts.poppins(
                color: Colors.grey,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
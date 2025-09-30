
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controller/payment_order_controller.dart';
import 'package:customer/model/driver_user_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/widget/driver_view.dart';
import 'package:customer/widget/location_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class PaymentOrderScreen extends StatelessWidget {
  const PaymentOrderScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<PaymentOrderController>(
      init: PaymentOrderController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppColors.primary,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            title: Text("Payment".tr),
            leading: InkWell(
              onTap: () => Get.back(),
              child: const Icon(Icons.arrow_back),
            ),
          ),
          body: Column(
            children: [
              Container(
                height: Responsive.width(8, context),
                width: Responsive.width(100, context),
                color: AppColors.primary,
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? Constant.loader()
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Driver Information Section
                              _buildDriverSection(context, controller, themeChange),
                              const SizedBox(height: 20),

                              // Vehicle Details Section
                              _buildVehicleSection(context, controller, themeChange),
                              const SizedBox(height: 20),

                              // Location Section
                              _buildLocationSection(context, controller, themeChange),
                              const SizedBox(height: 20),

                              // Payment Summary Section
                              _buildPaymentSummary(context, controller, themeChange),
                              const SizedBox(height: 20),

                              // Payment Method Selection
                              _buildPaymentMethodSection(context, controller, themeChange),
                              const SizedBox(height: 30),

                              // Payment Button
                              _buildPaymentButton(context, controller),
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

  Widget _buildDriverSection(BuildContext context, PaymentOrderController controller, DarkThemeProvider themeChange) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeChange.getThem() ? AppColors.darkContainerBackground : AppColors.containerBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeChange.getThem() ? AppColors.darkContainerBorder : AppColors.containerBorder,
          width: 0.5,
        ),
        boxShadow: themeChange.getThem()
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Driver Information",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Obx(() {
            if (controller.isDriverLoading.value) {
              return _buildDriverLoadingState();
            }
            
            if (controller.driverError.value.isNotEmpty) {
              return _buildDriverErrorState(controller.driverError.value);
            }
            
            return DriverView(
              driverId: controller.orderModel.value.driverId,
              amount: controller.orderModel.value.finalRate ?? "0",
              showCallButton: true,
              showMessageButton: true,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDriverLoadingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Loading driver information...",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  "Please wait",
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_outlined, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: GoogleFonts.poppins(
                color: Colors.orange,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildVehicleSection(BuildContext context, PaymentOrderController controller, DarkThemeProvider themeChange) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeChange.getThem() ? AppColors.darkContainerBackground : AppColors.containerBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeChange.getThem() ? AppColors.darkContainerBorder : AppColors.containerBorder,
          width: 0.5,
        ),
        boxShadow: themeChange.getThem()
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Vehicle Details".tr,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          FutureBuilder<DriverUserModel?>(
            future: FireStoreUtils.getDriver(controller.orderModel.value.driverId ?? ""),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildVehicleLoadingState();
              }
              
              if (snapshot.hasError || snapshot.data == null) {
                return _buildVehicleErrorState("Vehicle information not available");
              }
              
              final vehicle = snapshot.data!.vehicleInformation;
              if (vehicle == null) {
                return _buildVehicleErrorState("Vehicle details not found");
              }
              
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildVehicleDetail(
                    icon: Icons.directions_car,
                    label: "Type",
                    value: vehicle.vehicleType ?? "Unknown",
                  ),
                  _buildVehicleDetail(
                    icon: Icons.palette,
                    label: "Color",
                    value: vehicle.vehicleColor ?? "Unknown",
                  ),
                  _buildVehicleDetail(
                    icon: Icons.confirmation_number,
                    label: "Number",
                    value: vehicle.vehicleNumber ?? "Unknown",
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleDetail({required IconData icon, required String label, required String value}) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildVehicleLoadingState() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(3, (index) => Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 40,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 60,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      )),
    );
  }

  Widget _buildVehicleErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_outlined, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: GoogleFonts.poppins(
                color: Colors.orange,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(BuildContext context, PaymentOrderController controller, DarkThemeProvider themeChange) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeChange.getThem() ? AppColors.darkContainerBackground : AppColors.containerBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeChange.getThem() ? AppColors.darkContainerBorder : AppColors.containerBorder,
          width: 0.5,
        ),
        boxShadow: themeChange.getThem()
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Pickup and drop-off locations".tr,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          LocationView(
            sourceLocation: controller.orderModel.value.sourceLocationName ?? "Unknown pickup",
            destinationLocation: controller.orderModel.value.destinationLocationName ?? "Unknown destination",
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(BuildContext context, PaymentOrderController controller, DarkThemeProvider themeChange) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeChange.getThem() ? AppColors.darkContainerBackground : AppColors.containerBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeChange.getThem() ? AppColors.darkContainerBorder : AppColors.containerBorder,
          width: 0.5,
        ),
        boxShadow: themeChange.getThem()
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Booking summary".tr,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  controller.orderModel.value.paymentType ?? "Unknown",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const Divider(thickness: 1),
          
          // Ride Amount
          _buildSummaryRow(
            "Ride Amount".tr,
            Constant.amountShow(amount: controller.orderModel.value.finalRate ?? "0"),
          ),
          
          // Taxes
          if (controller.orderModel.value.taxList != null)
            ...controller.orderModel.value.taxList!.map((tax) => _buildSummaryRow(
              "${tax.title} (${tax.type == "fix" ? Constant.amountShow(amount: tax.tax) : "${tax.tax}%"})",
              Constant.amountShow(
                amount: Constant().calculateTax(
                  amount: (double.parse(controller.orderModel.value.finalRate ?? "0") - 
                          double.parse(controller.couponAmount.value)).toString(),
                  taxModel: tax,
                ).toString(),
              ),
              isSubItem: true,
            )),
          
          // Discount
          _buildSummaryRow(
            "Discount".tr,
            "(-${controller.couponAmount.value == "0.0" ? Constant.amountShow(amount: "0.0") : Constant.amountShow(amount: controller.couponAmount.value)})",
            valueColor: Colors.red,
          ),
          
          const Divider(thickness: 2),
          
          // Total
          _buildSummaryRow(
            "Total Amount".tr,
            Constant.amountShow(amount: controller.calculateAmount().toString()),
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isSubItem = false, bool isTotal = false, Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isTotal ? 8 : 4, horizontal: isSubItem ? 16 : 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
              fontSize: isTotal ? 16 : 14,
              color: isSubItem ? Colors.grey[600] : null,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
              fontSize: isTotal ? 16 : 14,
              color: valueColor ?? (isTotal ? AppColors.primary : null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection(BuildContext context, PaymentOrderController controller, DarkThemeProvider themeChange) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeChange.getThem() ? AppColors.darkContainerBackground : AppColors.containerBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeChange.getThem() ? AppColors.darkContainerBorder : AppColors.containerBorder,
          width: 0.5,
        ),
        boxShadow: themeChange.getThem()
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Payment Method".tr,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Obx(() => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.payment, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  controller.selectedPaymentMethod.value.isNotEmpty
                      ? controller.selectedPaymentMethod.value
                      : "Payment method not selected",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPaymentButton(BuildContext context, PaymentOrderController controller) {
    return Obx(() => SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: controller.isLoading.value ? null : () => _handlePayment(controller),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        child: controller.isLoading.value
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(
                "Complete Payment".tr,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    ));
  }

  void _handlePayment(PaymentOrderController controller) {
    final paymentMethod = controller.selectedPaymentMethod.value;
    final amount = controller.calculateAmount().toString();
    
    if (paymentMethod.isEmpty) {
      ShowToastDialog.showToast("Please select payment method");
      return;
    }
    
    switch (paymentMethod.toLowerCase()) {
      case 'cash':
        controller.completeCashOrder();
        break;
      case 'wallet':
        controller.processWalletPayment(amount: amount);
        break;
      case 'stripe':
        // For ride completion, capture the pre-authorized amount
        if (controller.orderModel.value.paymentIntentId != null) {
          controller.capturePreAuthorization(amount: amount);
        } else {
          controller.stripeMakePayment(amount: amount);
        }
        break;
      case 'razorpay':
        // Implement RazorPay payment
        break;
      default:
        ShowToastDialog.showToast("Payment method not supported");
    }
  }

}
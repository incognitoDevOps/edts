import 'package:customer/constant/constant.dart';
import 'package:customer/controller/wallet_controller.dart';
import 'package:customer/model/wallet_transaction_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/themes/text_field_them.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<WalletController>(
      init: WalletController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppColors.primary,
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
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              
                              // Wallet Balance Card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00C6A0), Color(0xFF007C91)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Total Balance".tr,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Obx(() => Text(
                                      Constant.amountShow(
                                        amount: controller.userModel.value.walletAmount ?? "0.0"
                                      ),
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _showTopUpDialog(context, controller),
                                        icon: const Icon(Icons.add, color: Colors.white),
                                        label: Text(
                                          "Topup Wallet".tr,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white.withOpacity(0.2),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Transaction History
                              Text(
                                "Transaction History",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              Expanded(
                                child: Obx(() {
                                  if (controller.transactionList.isEmpty) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.receipt_long_outlined,
                                            size: 64,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            "No transaction found".tr,
                                            style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "Your transactions will appear here",
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  
                                  return ListView.builder(
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: controller.transactionList.length,
                                    itemBuilder: (context, index) {
                                      WalletTransactionModel transaction = controller.transactionList[index];
                                      final isCredit = !transaction.amount!.startsWith('-');
                                      
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: themeChange.getThem() 
                                              ? AppColors.darkContainerBackground 
                                              : AppColors.containerBackground,
                                          borderRadius: BorderRadius.circular(12),
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
                                                    color: Colors.black.withOpacity(0.05),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: (isCredit ? Colors.green : Colors.red).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Icon(
                                                isCredit ? Icons.add : Icons.remove,
                                                color: isCredit ? Colors.green : Colors.red,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    transaction.note ?? "Transaction",
                                                    style: GoogleFonts.poppins(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    Constant.dateAndTimeFormatTimestamp(transaction.createdDate),
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  Text(
                                                    "Via ${transaction.paymentType ?? 'Unknown'}",
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              Constant.amountShow(amount: transaction.amount ?? "0"),
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: isCredit ? Colors.green : Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                }),
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

  void _showTopUpDialog(BuildContext context, WalletController controller) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Add Topup Amount".tr,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                TextFieldThem.buildTextFiled(
                  context,
                  hintText: 'Enter Amount'.tr,
                  controller: controller.amountController.value,
                  keyBoardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Text(
                  "Select Payment Option".tr,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                
                // Payment method selection
                Obx(() => Column(
                  children: _buildPaymentOptions(controller),
                )),
                
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        child: Text("Cancel".tr),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handleTopUp(context, controller),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "Topup".tr,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildPaymentOptions(WalletController controller) {
    final pm = controller.paymentModel.value;
    final List<Widget> options = [];
    
    if (pm.strip != null && pm.strip!.enable == true) {
      options.add(_buildPaymentOption(
        controller, 
        pm.strip!.name ?? "Stripe", 
        Icons.credit_card,
        "Stripe"
      ));
    }
    
    if (pm.razorpay != null && pm.razorpay!.enable == true) {
      options.add(_buildPaymentOption(
        controller, 
        pm.razorpay!.name ?? "RazorPay", 
        Icons.payment,
        "RazorPay"
      ));
    }
    
    return options;
  }

  Widget _buildPaymentOption(WalletController controller, String name, IconData icon, String value) {
    return RadioListTile<String>(
      value: value,
      groupValue: controller.selectedPaymentMethod.value,
      onChanged: (String? newValue) {
        controller.selectedPaymentMethod.value = newValue ?? "";
      },
      title: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            name,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
        ],
      ),
      activeColor: AppColors.primary,
    );
  }

  void _handleTopUp(BuildContext context, WalletController controller) {
    if (controller.amountController.value.text.isEmpty) {
      Get.back();
      controller.selectedPaymentMethod.value = "";
      return;
    }
    
    if (controller.selectedPaymentMethod.value.isEmpty) {
      return;
    }
    
    final amount = controller.amountController.value.text;
    final paymentMethod = controller.selectedPaymentMethod.value;
    
    Get.back();
    
    switch (paymentMethod.toLowerCase()) {
      case 'stripe':
        controller.stripeMakePayment(amount: amount);
        break;
      case 'razorpay':
        // Implement RazorPay if needed
        break;
      default:
        break;
    }
    
    // Clear form
    controller.amountController.value.clear();
    controller.selectedPaymentMethod.value = "";
  }
}
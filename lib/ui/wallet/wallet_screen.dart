import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/controller/wallet_controller.dart';
import 'package:driver/model/wallet_transaction_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/button_them.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/themes/text_field_them.dart';
import 'package:driver/ui/withdraw_history/withdraw_history_screen.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
            body: controller.isLoading.value
                ? Constant.loader(context)
                : Column(
                    children: [
                      SizedBox(
                        height: Responsive.width(10, context),
                        width: Responsive.width(100, context),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25))),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Column(
                              children: [
                                const SizedBox(
                                  height: 20,
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: themeChange.getThem() ? AppColors.darkContainerBackground : AppColors.containerBackground,
                                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                                    border: Border.all(color: themeChange.getThem() ? AppColors.darkContainerBorder : AppColors.containerBorder, width: 0.5),
                                    boxShadow: themeChange.getThem()
                                        ? null
                                        : [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(0.5),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2), // changes position of shadow
                                            ),
                                          ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      children: [
                                        Container(
                                            decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(50)),
                                            child: Padding(
                                              padding: const EdgeInsets.all(12.0),
                                              child: SvgPicture.asset(
                                                'assets/icons/ic_wallet.svg',
                                                width: 24,
                                                color: Colors.black,
                                              ),
                                            )),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text("Total Balance".tr, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                              Text(
                                                Constant.amountShow(amount: controller.driverUserModel.value.walletAmount.toString()),
                                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ButtonThem.buildButton(
                                        context,
                                        title: "Topup Wallet".tr,
                                        onPress: () {
                                          topUpWalletDialog(context, controller);
                                        },
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Expanded(
                                      child: ButtonThem.buildBorderButton(
                                        context,
                                        title: "withdraw".tr,
                                        onPress: () {
                                          withdrawDialog(context, controller);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ButtonThem.buildBorderButton(
                                        context,
                                        title: "Withdrawal history".tr,
                                        onPress: () {
                                          Get.to(const WithDrawHistoryScreen());
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                Expanded(
                                  child: controller.transactionList.isEmpty
                                      ? Center(
                                          child: Text("No transaction found".tr),
                                        )
                                      : ListView.builder(
                                          itemCount: controller.transactionList.length,
                                          itemBuilder: (context, index) {
                                            WalletTransactionModel walletTransactionModel = controller.transactionList[index];
                                            return Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Container(
                                                  decoration: BoxDecoration(
                                                    color: themeChange.getThem() ? AppColors.darkContainerBackground : AppColors.containerBackground,
                                                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                                                    border: Border.all(color: themeChange.getThem() ? AppColors.darkContainerBorder : AppColors.containerBorder, width: 0.5),
                                                    boxShadow: themeChange.getThem()
                                                        ? null
                                                        : [
                                                            BoxShadow(
                                                              color: Colors.grey.withOpacity(0.5),
                                                              blurRadius: 8,
                                                              offset: const Offset(0, 2), // changes position of shadow
                                                            ),
                                                          ],
                                                  ),
                                                  child: InkWell(
                                                    onTap: () {
                                                      transactionDialog(context, controller, walletTransactionModel);
                                                    },
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(8.0),
                                                      child: Row(
                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                        children: [
                                                          Container(
                                                              decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(50)),
                                                              child: Padding(
                                                                padding: const EdgeInsets.all(12.0),
                                                                child: SvgPicture.asset(
                                                                  'assets/icons/ic_wallet.svg',
                                                                  width: 24,
                                                                  color: Colors.black,
                                                                ),
                                                              )),
                                                          const SizedBox(
                                                            width: 10,
                                                          ),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Row(
                                                                  children: [
                                                                    Expanded(
                                                                      child: Text(
                                                                        DateFormat('KK:mm:ss a, dd MMM yyyy').format(walletTransactionModel.createdDate!.toDate()).toUpperCase(),
                                                                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      Constant.IsNegative(double.parse(walletTransactionModel.amount.toString()))
                                                                          ? "- ${Constant.amountShow(amount: walletTransactionModel.amount.toString().replaceAll("-", ""))}"
                                                                          : "+ ${Constant.amountShow(amount: walletTransactionModel.amount.toString())}",
                                                                      style: GoogleFonts.poppins(
                                                                          fontWeight: FontWeight.w600,
                                                                          color: Constant.IsNegative(double.parse(walletTransactionModel.amount.toString())) ? Colors.red : Colors.green),
                                                                    ),
                                                                  ],
                                                                ),
                                                                Text(
                                                                  walletTransactionModel.note.toString(),
                                                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w400),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  )),
                                            );
                                          },
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

  topUpWalletDialog(BuildContext context, WalletController controller) {
    return showModalBottomSheet(
        context: context,
        isDismissible: false,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.only(topRight: Radius.circular(15), topLeft: Radius.circular(15))),
            child: StatefulBuilder(builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
                child: Padding(
                  padding: MediaQuery.of(context).viewInsets,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Add Topup Amount".tr, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      const SizedBox(
                        height: 10,
                      ),
                      TextFieldThem.buildTextFiledWithPrefixIcon(
                        context,
                        hintText: 'Enter Amount'.tr,
                        controller: controller.amountController.value,
                        keyBoardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                        prefix: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Text(Constant.currencyModel!.symbol.toString()),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text("Select Payment Option".tr, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      const SizedBox(
                        height: 10,
                      ),
                      Obx(
                        () => Column(
                          children: [
                            controller.paymentModel.value.strip!.enable == true
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: InkWell(
                                      onTap: () {
                                        controller.selectedPaymentMethod.value = controller.paymentModel.value.strip!.name.toString();
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                            color: controller.selectedPaymentMethod.value == controller.paymentModel.value.strip!.name.toString()
                                                ? AppColors.lightGray
                                                : Colors.transparent,
                                            borderRadius: const BorderRadius.all(Radius.circular(5)),
                                            border: Border.all(color: AppColors.textFieldBorder, width: 0.5)),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                          child: Row(
                                            children: [
                                              Container(
                                                  decoration: const BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.all(Radius.circular(5))),
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(8.0),
                                                    child: SvgPicture.asset(
                                                      'assets/icons/ic_stripe.svg',
                                                      width: 30,
                                                      color: Colors.white,
                                                    ),
                                                  )),
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              Expanded(child: Text(controller.paymentModel.value.strip!.name.toString(), style: GoogleFonts.poppins())),
                                              Radio(
                                                value: controller.paymentModel.value.strip!.name.toString(),
                                                groupValue: controller.selectedPaymentMethod.value,
                                                onChanged: (value) {
                                                  controller.selectedPaymentMethod.value = value.toString();
                                                },
                                                activeColor: AppColors.primary,
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox(),
                            controller.paymentModel.value.razorpay!.enable == true
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: InkWell(
                                      onTap: () {
                                        controller.selectedPaymentMethod.value = controller.paymentModel.value.razorpay!.name.toString();
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                            color: controller.selectedPaymentMethod.value == controller.paymentModel.value.razorpay!.name.toString()
                                                ? AppColors.lightGray
                                                : Colors.transparent,
                                            borderRadius: const BorderRadius.all(Radius.circular(5)),
                                            border: Border.all(color: AppColors.textFieldBorder, width: 0.5)),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                          child: Row(
                                            children: [
                                              Container(
                                                  decoration: const BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.all(Radius.circular(5))),
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(8.0),
                                                    child: SvgPicture.asset(
                                                      'assets/icons/ic_razorpay.svg',
                                                      width: 30,
                                                      color: Colors.white,
                                                    ),
                                                  )),
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              Expanded(child: Text(controller.paymentModel.value.razorpay!.name.toString(), style: GoogleFonts.poppins())),
                                              Radio(
                                                value: controller.paymentModel.value.razorpay!.name.toString(),
                                                groupValue: controller.selectedPaymentMethod.value,
                                                onChanged: (value) {
                                                  controller.selectedPaymentMethod.value = value.toString();
                                                },
                                                activeColor: AppColors.primary,
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox(),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      ButtonThem.buildButton(
                        context,
                        title: "Topup".tr,
                        onPress: () {
                          if (controller.selectedPaymentMethod.value.isEmpty) {
                            ShowToastDialog.showToast("Please select payment method".tr);
                          } else if (controller.amountController.value.text.isEmpty) {
                            ShowToastDialog.showToast("Please enter amount".tr);
                          } else {
                            if (controller.selectedPaymentMethod.value == controller.paymentModel.value.strip!.name.toString()) {
                              controller.stripeMakePayment(amount: controller.amountController.value.text);
                            } else if (controller.selectedPaymentMethod.value == controller.paymentModel.value.razorpay!.name.toString()) {
                              controller.openCheckout(amount: double.parse(controller.amountController.value.text), orderId: "");
                            }
                          }
                        },
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                    ],
                  ),
                ),
              );
            }),
          );
        });
  }

  transactionDialog(BuildContext context, WalletController controller, WalletTransactionModel walletTransactionModel) {
    return showModalBottomSheet(
        context: context,
        isDismissible: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.only(topRight: Radius.circular(15), topLeft: Radius.circular(15))),
            child: StatefulBuilder(builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
                child: Padding(
                  padding: MediaQuery.of(context).viewInsets,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Transaction Details".tr, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Transaction ID".tr,
                              style: GoogleFonts.poppins(),
                            ),
                          ),
                          Text(
                            walletTransactionModel.transactionId.toString(),
                            style: GoogleFonts.poppins(),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Payment Details".tr,
                              style: GoogleFonts.poppins(),
                            ),
                          ),
                          Text(
                            Constant.amountShow(amount: walletTransactionModel.amount.toString().replaceAll("-", "")),
                            style: GoogleFonts.poppins(),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Pay Via".tr,
                              style: GoogleFonts.poppins(),
                            ),
                          ),
                          Text(
                            walletTransactionModel.paymentType.toString(),
                            style: GoogleFonts.poppins(),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Date in UTC Format".tr,
                              style: GoogleFonts.poppins(),
                            ),
                          ),
                          Text(
                            DateFormat('KK:mm:ss a, dd MMM yyyy').format(walletTransactionModel.createdDate!.toDate()).toUpperCase(),
                            style: GoogleFonts.poppins(),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ),
              );
            }),
          );
        });
  }

  withdrawDialog(BuildContext context, WalletController controller) {
    return showModalBottomSheet(
        context: context,
        isDismissible: false,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.only(topRight: Radius.circular(15), topLeft: Radius.circular(15))),
            child: StatefulBuilder(builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
                child: Padding(
                  padding: MediaQuery.of(context).viewInsets,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Withdraw".tr, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      const SizedBox(
                        height: 10,
                      ),
                      Text("Amount to Withdraw".tr, style: GoogleFonts.poppins()),
                      const SizedBox(
                        height: 5,
                      ),
                      TextFieldThem.buildTextFiledWithPrefixIcon(
                        context,
                        hintText: 'Enter Amount'.tr,
                        controller: controller.withdrawalAmountController.value,
                        keyBoardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                        prefix: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Text(Constant.currencyModel!.symbol.toString()),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text('Notes'.tr, style: GoogleFonts.poppins()),
                      const SizedBox(
                        height: 5,
                      ),
                      TextFieldThem.buildTextFiled(context, hintText: 'Notes'.tr, controller: controller.noteController.value, maxLine: 5),
                      const SizedBox(
                        height: 20,
                      ),
                      ButtonThem.buildButton(
                        context,
                        title: "Withdrawal".tr,
                        onPress: () async {
                          if (double.parse(controller.withdrawalAmountController.value.text) < double.parse(Constant.minimumAmountToWithdrawal)) {
                            ShowToastDialog.showToast("Withdraw amount must be greater or equal to ${Constant.amountShow(amount: Constant.minimumAmountToWithdrawal)}".tr);
                          } else if (double.parse(controller.withdrawalAmountController.value.text) > double.parse(controller.driverUserModel.value.walletAmount.toString())) {
                            ShowToastDialog.showToast("Insufficient balance".tr);
                          } else {
                            bool? isAvailable = await FireStoreUtils.bankDetailsIsAvailable();
                            if (isAvailable == true) {
                              ShowToastDialog.showLoader("Please wait".tr);
                              await FireStoreUtils.setWithdrawRequest(controller.withdrawModel.value!).then((value) {
                                if (value == true) {
                                  ShowToastDialog.closeLoader();
                                  ShowToastDialog.showToast("Request sent to admin".tr);
                                  Get.back();
                                }
                              });
                            } else {
                              ShowToastDialog.showToast("Your bank details is not available.Please add bank details".tr);
                            }
                          }
                        },
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                    ],
                  ),
                ),
              );
            }),
          );
        });
  }
}
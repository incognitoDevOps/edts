import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/model/payment_model.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/model/driver_user_model.dart';
import 'package:customer/services/payment_persistence_service.dart';
import 'package:customer/services/stripe_service.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

class PaymentOrderControllerEnhanced extends GetxController {
  RxBool isLoading = true.obs;
  Rx<OrderModel> orderModel = OrderModel().obs;
  Rx<PaymentModel> paymentModel = PaymentModel().obs;
  Rx<UserModel> userModel = UserModel().obs;
  Rx<DriverUserModel> driverUserModel = DriverUserModel().obs;

  RxBool isDriverLoading = true.obs;
  RxString driverError = "".obs;
  RxString selectedPaymentMethod = "".obs;
  RxBool isPaymentProcessing = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializePaymentScreen();
  }

  Future<void> _initializePaymentScreen() async {
    try {
      print("🚀 [PAYMENT INIT] Initializing payment screen...");

      await _loadArguments();

      await _loadPaymentConfiguration();

      await _loadUserProfile();

      await _loadDriverInformation();

      isLoading.value = false;
      update();
    } catch (e) {
      print("❌ [PAYMENT INIT] Error: $e");
      isLoading.value = false;
      ShowToastDialog.showToast("Failed to load payment information");
    }
  }

  Future<void> _loadArguments() async {
    dynamic argumentData = Get.arguments;
    if (argumentData == null || argumentData['orderModel'] == null) {
      print("❌ [PAYMENT INIT] No order model in arguments");
      throw Exception("Order model not provided");
    }

    OrderModel passedOrder = argumentData['orderModel'];
    print("📦 [PAYMENT INIT] Loading order: ${passedOrder.id}");

    final freshOrder = await PaymentPersistenceService.getOrderWithPaymentRecovery(
      passedOrder.id!,
    );

    if (freshOrder != null) {
      orderModel.value = freshOrder;
      print("✅ [PAYMENT INIT] Order loaded with payment data");
    } else {
      orderModel.value = passedOrder;
      print("⚠️  [PAYMENT INIT] Using passed order (fresh order load failed)");
    }
  }

  Future<void> _loadPaymentConfiguration() async {
    try {
      final payment = await FireStoreUtils().getPayment();
      if (payment != null) {
        paymentModel.value = payment;
        selectedPaymentMethod.value = orderModel.value.paymentType ?? "";
        print("✅ [PAYMENT CONFIG] Loaded: ${selectedPaymentMethod.value}");
      }
    } catch (e) {
      print("❌ [PAYMENT CONFIG] Error: $e");
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await FireStoreUtils.getUserProfile(
        FireStoreUtils.getCurrentUid(),
      );
      if (user != null) {
        userModel.value = user;
        print("✅ [USER PROFILE] Wallet: ${user.walletAmount}");
      }
    } catch (e) {
      print("❌ [USER PROFILE] Error: $e");
    }
  }

  Future<void> _loadDriverInformation() async {
    isDriverLoading.value = true;
    driverError.value = "";

    try {
      if (orderModel.value.driverId == null || orderModel.value.driverId!.isEmpty) {
        print("⚠️  [DRIVER LOAD] No driver assigned");

        final recovered = await FireStoreUtils.recoverDriverAssignment(
          orderModel.value.id!,
        );

        if (recovered) {
          final updatedOrder = await FireStoreUtils.getOrder(orderModel.value.id!);
          if (updatedOrder != null) {
            orderModel.value = updatedOrder;
          }
        }
      }

      if (orderModel.value.driverId != null && orderModel.value.driverId!.isNotEmpty) {
        final driver = await FireStoreUtils.getDriverWithRetry(
          orderModel.value.driverId!,
          maxRetries: 3, retryDelay: Duration(seconds: 2),
        );

        if (driver != null) {
          driverUserModel.value = driver;
          print("✅ [DRIVER LOAD] Loaded: ${driver.fullName}");
        } else {
          driverError.value = "Driver information not available";
        }
      } else {
        driverError.value = "No driver assigned";
      }
    } catch (e) {
      driverError.value = "Error loading driver information";
      print("❌ [DRIVER LOAD] Error: $e");
    } finally {
      isDriverLoading.value = false;
    }
  }

  Future<void> processStripePayment({required double amount}) async {
    if (isPaymentProcessing.value) {
      print("⚠️  [STRIPE] Payment already in progress");
      return;
    }

    isPaymentProcessing.value = true;

    try {
      if (orderModel.value.paymentIntentId == null ||
          orderModel.value.paymentIntentId!.isEmpty) {
        print("❌ [STRIPE] No payment intent found");
        ShowToastDialog.showToast(
          "Payment authorization not found. Please contact support.",
          duration: const Duration(seconds: 5),
        );
        return;
      }

      print("💳 [STRIPE] Processing payment...");
      print("   Payment Intent: ${orderModel.value.paymentIntentId}");
      print("   Amount: \$${amount.toStringAsFixed(2)}");

      ShowToastDialog.showLoader("Processing payment...");

      final stripeConfig = paymentModel.value.strip;
      if (stripeConfig == null || stripeConfig.stripeSecret == null) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Payment configuration error");
        return;
      }

      final stripeService = StripeService(
        stripeSecret: stripeConfig.stripeSecret!,
        publishableKey: stripeConfig.clientpublishableKey ?? '',
      );

      final success = await PaymentPersistenceService.capturePaymentWithRetry(
        order: orderModel.value,
        stripeService: stripeService,
        finalAmount: amount,
        maxRetries: 3,
      );

      ShowToastDialog.closeLoader();

      if (success) {
        print("✅ [STRIPE] Payment captured successfully");

        final authorizedAmount = orderModel.value.preAuthAmount != null
            ? double.parse(orderModel.value.preAuthAmount!)
            : amount;

        if (amount < authorizedAmount) {
          final difference = authorizedAmount - amount;
          ShowToastDialog.showToast(
            "Payment successful. ${Constant.amountShow(amount: difference.toStringAsFixed(2))} will be returned to your card.",
            position: EasyLoadingToastPosition.center,
            duration: const Duration(seconds: 5),
          );
        } else {
          ShowToastDialog.showToast(
            "Payment captured successfully",
            position: EasyLoadingToastPosition.center,
            duration: const Duration(seconds: 3),
          );
        }

        await _completeRide();
      } else {
        print("❌ [STRIPE] Payment capture failed");
        ShowToastDialog.showToast(
          "Payment capture failed. Please try again or contact support.",
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      log("❌ [STRIPE] Error: $e");
      ShowToastDialog.showToast("Payment processing error: ${e.toString()}");
    } finally {
      isPaymentProcessing.value = false;
    }
  }

  Future<void> cancelRide() async {
    try {
      print("🔄 [CANCEL RIDE] Starting cancellation...");
      ShowToastDialog.showLoader("Cancelling ride...");

      if (selectedPaymentMethod.value.toLowerCase().contains('stripe')) {
        if (orderModel.value.paymentIntentId != null &&
            orderModel.value.paymentIntentId!.isNotEmpty) {
          print("🔄 [CANCEL RIDE] Releasing Stripe pre-authorization...");

          final stripeConfig = paymentModel.value.strip;
          if (stripeConfig != null && stripeConfig.stripeSecret != null) {
            final stripeService = StripeService(
              stripeSecret: stripeConfig.stripeSecret!,
              publishableKey: stripeConfig.clientpublishableKey ?? '',
            );

            await PaymentPersistenceService.cancelPaymentWithRefund(
              order: orderModel.value,
              stripeService: stripeService,
            );

            ShowToastDialog.closeLoader();
            ShowToastDialog.showToast(
              "Ride cancelled. Your payment hold has been released.",
              position: EasyLoadingToastPosition.center,
              duration: const Duration(seconds: 4),
            );
          }
        }
      } else {
        orderModel.value.status = Constant.rideCanceled;
        orderModel.value.updateDate = Timestamp.now();
        await FireStoreUtils.setOrder(orderModel.value);

        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Ride cancelled successfully");
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      log("❌ [CANCEL RIDE] Error: $e");
      ShowToastDialog.showToast("Error cancelling ride");
    }
  }

  Future<void> _completeRide() async {
    print("✅ [COMPLETE RIDE] Finalizing ride completion...");
    ShowToastDialog.showLoader("Completing ride...");

    try {
      orderModel.value.paymentStatus = true;
      orderModel.value.status = Constant.rideComplete;
      orderModel.value.updateDate = Timestamp.now();

      await FireStoreUtils.setOrder(orderModel.value);

      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Ride completed successfully");

      Get.back();
    } catch (e) {
      ShowToastDialog.closeLoader();
      log("❌ [COMPLETE RIDE] Error: $e");
      ShowToastDialog.showToast("Error completing ride");
    }
  }

  double calculateFinalAmount() {
    double baseAmount = double.parse(orderModel.value.finalRate ?? "0");
    double taxAmount = 0.0;

    if (orderModel.value.taxList != null) {
      for (var tax in orderModel.value.taxList!) {
        taxAmount += Constant().calculateTax(
          amount: baseAmount.toString(),
          taxModel: tax,
        );
      }
    }

    return baseAmount + taxAmount;
  }
}

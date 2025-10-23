import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as maths;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/ui/orders/complete_order_screen.dart';
import 'package:customer/constant/send_notification.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/model/admin_commission.dart';
import 'package:customer/model/coupon_model.dart';
import 'package:customer/model/driver_user_model.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/model/payment_model.dart';
import 'package:customer/model/stripe_failed_model.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/model/wallet_transaction_model.dart';
import 'package:customer/payment/MercadoPagoScreen.dart';
import 'package:customer/payment/PayFastScreen.dart';
import 'package:customer/payment/paystack/pay_stack_screen.dart';
import 'package:customer/payment/paystack/pay_stack_url_model.dart';
import 'package:customer/payment/paystack/paystack_url_genrater.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/services/stripe_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentOrderController extends GetxController {
  RxBool isLoading = true.obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getArgument();
    getPaymentData();
    super.onInit();
  }

  Rx<OrderModel> orderModel = OrderModel().obs;

  getArgument() async {
    try {
      print("🔄 [PAYMENT LOAD] Loading payment screen...");

      dynamic argumentData = Get.arguments;
      if (argumentData == null) {
        print("❌ No order data provided");
        isLoading.value = false;
        return;
      }

      OrderModel passedOrder = argumentData['orderModel'];

      // 🔥 CRITICAL: Load FRESH from Firestore - NO RECOVERY
      final freshOrder = await FireStoreUtils.getOrder(passedOrder.id!);

      if (freshOrder == null) {
        print("❌ Order not found in database");
        isLoading.value = false;
        ShowToastDialog.showToast("Order data not found");
        return;
      }

      // Validate payment data exists for Stripe
      if (freshOrder.paymentType?.toLowerCase().contains("stripe") == true) {
        if (freshOrder.paymentIntentId == null ||
            freshOrder.paymentIntentId!.isEmpty) {
          print("❌ CRITICAL: Stripe payment missing payment intent");
          ShowToastDialog.showToast(
              "Payment authorization missing. Contact support with order ID: ${freshOrder.id}");
          isLoading.value = false;
          return;
        }
      }

      orderModel.value = freshOrder;
      selectedPaymentMethod.value = freshOrder.paymentType ?? '';

      print("✅ [PAYMENT LOAD] Order loaded:");
      freshOrder.debugPrint();

      // Load driver if assigned
      if (freshOrder.driverId != null && freshOrder.driverId!.isNotEmpty) {
        await _loadDriverInformation();
      }
    } catch (e) {
      print("❌ Error loading order: $e");
      isLoading.value = false;
      ShowToastDialog.showToast("Error loading order data");
    }
  }
  
  Rx<PaymentModel> paymentModel = PaymentModel().obs;
  Rx<UserModel> userModel = UserModel().obs;
  Rx<DriverUserModel> driverUserModel = DriverUserModel().obs;
  RxBool isDriverLoading = true.obs;
  RxString driverError = "".obs;

  RxString selectedPaymentMethod = "".obs;
  RxBool isPaymentProcessing = false.obs;

  // 🔥 ENHANCED: Payment data loading
  getPaymentData() async {
    print("💰 [PAYMENT DATA] Starting payment data loading...");
    
    try {
      // Load payment configuration
      await FireStoreUtils().getPayment().then((value) {
        if (value != null) {
          paymentModel.value = value;
          print("✅ [PAYMENT DATA] Payment configuration loaded");

          // Configure Stripe if available
          if (paymentModel.value.strip?.clientpublishableKey != null) {
            Stripe.publishableKey = paymentModel.value.strip!.clientpublishableKey.toString();
            Stripe.merchantIdentifier = 'BuzRyde';
            Stripe.instance.applySettings();
            print("✅ [PAYMENT DATA] Stripe configured");
          }
          
          setRef();
          print("✅ [PAYMENT DATA] Payment method: ${selectedPaymentMethod.value}");

          // Initialize RazorPay if needed
          if (paymentModel.value.razorpay != null) {
            razorPay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccess);
            razorPay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWaller);
            razorPay.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentError);
            print("✅ [PAYMENT DATA] RazorPay initialized");
          }
        } else {
          print("⚠️ [PAYMENT DATA] No payment configuration found");
        }
      });

      // Load user profile
      print("👤 [PAYMENT DATA] Loading user profile...");
      await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid()).then((value) {
        if (value != null) {
          userModel.value = value;
          print("✅ [PAYMENT DATA] User profile loaded - wallet: ${userModel.value.walletAmount}");
        } else {
          print("⚠️ [PAYMENT DATA] User profile not found");
        }
      });

      // 🔥 CRITICAL: Load driver information with enhanced recovery
      await _loadDriverInformationWithRecovery();

      print("✅ [PAYMENT DATA] All payment data loaded successfully");

    } catch (e, stack) {
      print("❌ [PAYMENT DATA] Error loading payment data: $e");
      print("📋 Stack trace: $stack");
      ShowToastDialog.showToast("Error loading payment information");
    } finally {
      isLoading.value = false;
      update();
      print("🏁 [PAYMENT DATA] Loading completed");
    }
  }

  // 🔥 ENHANCED: Driver loading with recovery mechanisms
  Future<void> _loadDriverInformationWithRecovery() async {
    isDriverLoading.value = true;
    driverError.value = "";

    try {
      // Check if driver ID exists
      if (orderModel.value.driverId == null || orderModel.value.driverId!.isEmpty) {
        print("⚠️ [DRIVER LOAD] No driver assigned to order ${orderModel.value.id}");
        
        // 🔥 CRITICAL: Attempt to recover driver ID from acceptedDriverId
        if (orderModel.value.acceptedDriverId != null && orderModel.value.acceptedDriverId!.isNotEmpty) {
          final recoveredDriverId = orderModel.value.acceptedDriverId!.first.toString();
          print("💡 [DRIVER RECOVERY] Found driver in acceptedDriverId: $recoveredDriverId");
          
          // Update the order with recovered driver ID
          orderModel.value.driverId = recoveredDriverId;
          await FireStoreUtils.setOrder(orderModel.value);
          print("✅ [DRIVER RECOVERY] Updated order with recovered driver ID");
        } else {
          driverError.value = "No driver assigned to this ride";
          isDriverLoading.value = false;
          update();
          return;
        }
      }

      print("🔍 [DRIVER LOAD] Loading driver: ${orderModel.value.driverId}");

      // Try to load driver with retry mechanism
      final driver = await FireStoreUtils.getDriverWithRetry(
        orderModel.value.driverId!,
        maxRetries: 3,
        retryDelay: Duration(seconds: 2)
      );

      if (driver != null) {
        driverUserModel.value = driver;
        driverError.value = "";
        print("✅ [DRIVER LOAD] Driver loaded successfully: ${driver.fullName}");
        
        // Debug driver payment settings
        _debugDriverPaymentSettings(driver);
      } else {
        driverError.value = "Driver information not available";
        print("❌ [DRIVER LOAD] Failed to load driver after retries");
        
        // 🔥 CRITICAL: Create emergency driver record to prevent crashes
        driverUserModel.value = DriverUserModel(
          id: orderModel.value.driverId!,
          fullName: "Driver (Unavailable)",
          email: "unknown@driver.com",
          phoneNumber: "000-000-0000",
          flatRateActive: false,
          paymentMethod: "percentage"
        );
        print("⚠️ [DRIVER LOAD] Created emergency driver record");
      }
    } catch (error, stack) {
      print("❌ [DRIVER LOAD] Error loading driver: $error");
      print("📋 Stack trace: $stack");
      
      driverError.value = "Error loading driver information";
      
      // 🔥 CRITICAL: Create emergency driver record
      driverUserModel.value = DriverUserModel(
        id: orderModel.value.driverId ?? "unknown",
        fullName: "Driver (Error)",
        email: "error@driver.com", 
        phoneNumber: "000-000-0000",
        flatRateActive: false,
        paymentMethod: "percentage"
      );
    } finally {
      isDriverLoading.value = false;
      update();
      print("🏁 [DRIVER LOAD] Driver loading completed");
    }
  }
  
  // The payment intent should be created during booking, not at payment screen
  Future<void> createPreAuthorization({required String amount}) async {
    print("⚠️  createPreAuthorization called - This should not happen!");
    print(
        "   Payment authorization should occur during booking, not at payment screen");
    ShowToastDialog.showToast(
        "Payment authorization error. Please try rebooking.");
  }

  Future<void> capturePreAuthorization({required String amount}) async {
    if (orderModel.value.paymentIntentId == null ||
        orderModel.value.paymentIntentId!.isEmpty) {
      print("❌ [CAPTURE] No payment intent found");
      ShowToastDialog.showToast(
          "No payment authorization found. Cannot process payment.");
      return;
    }

    if (isPaymentProcessing.value) {
      print("⚠️  [CAPTURE] Payment already in progress");
      return;
    }

    isPaymentProcessing.value = true;
    isLoading.value = true;

    try {
      print("💳 [CAPTURE] Starting capture with retry...");
      print("   Payment Intent ID: ${orderModel.value.paymentIntentId}");
      print("   Amount to capture: $amount");

      ShowToastDialog.showLoader("Processing payment...");

      final stripeConfig = paymentModel.value.strip;
      if (stripeConfig == null || stripeConfig.stripeSecret == null) {
        ShowToastDialog.closeLoader();
        isPaymentProcessing.value = false;
        isLoading.value = false;
        ShowToastDialog.showToast("Stripe not configured properly");
        return;
      }

      final stripeService = StripeService(
        stripeSecret: stripeConfig.stripeSecret!,
        publishableKey: stripeConfig.clientpublishableKey ?? '',
      );

      bool captureSuccess = false;
      int maxRetries = 3;

      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          print("   Capture attempt $attempt of $maxRetries...");

          final captureResult = await stripeService.capturePreAuthorization(
            paymentIntentId: orderModel.value.paymentIntentId!,
            finalAmount: amount,
          );

          if (captureResult['success'] == true) {
            print("✅ [CAPTURE] Successful on attempt $attempt");
            captureSuccess = true;
            break;
          } else {
            print(
                "❌ [CAPTURE] Attempt $attempt failed: ${captureResult['error']}");

            if (attempt < maxRetries) {
              final delay = Duration(seconds: attempt * 2);
              print("   Retrying in ${delay.inSeconds} seconds...");
              await Future.delayed(delay);
            }
          }
        } catch (e) {
          print("❌ [CAPTURE] Exception on attempt $attempt: $e");

          if (attempt < maxRetries) {
            await Future.delayed(Duration(seconds: attempt * 2));
          }
        }
      }

      ShowToastDialog.closeLoader();

      if (captureSuccess) {
        print("✅ [CAPTURE] Payment captured successfully");

        final authorizedAmount = orderModel.value.preAuthAmount != null
            ? double.parse(orderModel.value.preAuthAmount!)
            : double.parse(amount);
        final capturedAmount = double.parse(amount);

        WalletTransactionModel captureTransaction = WalletTransactionModel(
          id: Constant.getUuid(),
          amount: "-$amount",
          createdDate: Timestamp.now(),
          paymentType: "Stripe",
          transactionId: orderModel.value.id,
          userId: FireStoreUtils.getCurrentUid(),
          orderType: "city",
          userType: "customer",
          note: "Stripe payment captured for ride ${orderModel.value.id}",
        );

        await FireStoreUtils.setWalletTransaction(captureTransaction);

        orderModel.value.paymentIntentStatus = 'captured';
        orderModel.value.paymentStatus = true;
        orderModel.value.paymentCapturedAt = Timestamp.now();

        await FireStoreUtils.updateOrderPreservingPayment(orderModel.value);

        if (capturedAmount < authorizedAmount) {
          final difference = authorizedAmount - capturedAmount;

          WalletTransactionModel refundTransaction = WalletTransactionModel(
            id: Constant.getUuid(),
            amount: difference.toStringAsFixed(2),
            createdDate: Timestamp.now(),
            paymentType: "Stripe",
            transactionId: orderModel.value.id,
            userId: FireStoreUtils.getCurrentUid(),
            orderType: "city",
            userType: "customer",
            note:
                "Unused pre-authorization released for ride ${orderModel.value.id}",
          );

          await FireStoreUtils.setWalletTransaction(refundTransaction);

          ShowToastDialog.showToast(
            "Payment captured successfully. ${Constant.amountShow(amount: difference.toStringAsFixed(2))} will be returned to your card.",
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

        // 🔥 CRITICAL FIX: Reset payment processing flag BEFORE calling completeOrder
        // This prevents completeOrder from returning early due to the flag check
        isPaymentProcessing.value = false;
        isLoading.value = false;

        await completeOrder();
      } else {
        print("❌ [CAPTURE] All retry attempts failed");
        isPaymentProcessing.value = false;
        isLoading.value = false;
        ShowToastDialog.showToast(
          "Payment capture failed after multiple attempts. Please contact support with order ID: ${orderModel.value.id}",
          duration: const Duration(seconds: 7),
        );
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      isPaymentProcessing.value = false;
      isLoading.value = false;
      log("❌ [CAPTURE] Fatal error: $e");
      ShowToastDialog.showToast("Payment capture failed: $e");
    }
  }

  Future<void> cancelPreAuthorization() async {
    if (orderModel.value.paymentIntentId == null ||
        orderModel.value.paymentIntentId!.isEmpty) {
      print("ℹ️  [CANCEL] No payment intent to cancel");
      return;
    }

    try {
      print(
          "🔄 [CANCEL] Cancelling payment intent: ${orderModel.value.paymentIntentId}");

      final stripeConfig = paymentModel.value.strip;
      if (stripeConfig == null || stripeConfig.stripeSecret == null) {
        print("❌ [CANCEL] Stripe not configured");
        return;
      }

      final stripeService = StripeService(
        stripeSecret: stripeConfig.stripeSecret!,
        publishableKey: stripeConfig.clientpublishableKey ?? '',
      );

      final success = await stripeService.releasePreAuthorization(
        paymentIntentId: orderModel.value.paymentIntentId!,
      );

      if (success) {
        print("✅ [CANCEL] Payment intent cancelled successfully");

        WalletTransactionModel cancelTransaction = WalletTransactionModel(
          id: Constant.getUuid(),
          amount: "0",
          createdDate: Timestamp.now(),
          paymentType: "Stripe",
          transactionId: orderModel.value.id,
          userId: FireStoreUtils.getCurrentUid(),
          orderType: "city",
          userType: "customer",
          note:
              "Stripe pre-authorization released for ride ${orderModel.value.id}",
        );

        await FireStoreUtils.setWalletTransaction(cancelTransaction);

        orderModel.value.paymentIntentStatus = 'cancelled';
        orderModel.value.paymentCanceledAt = Timestamp.now();
        await FireStoreUtils.setOrder(orderModel.value);

        print("💾 [CANCEL] Cancellation data saved to Firestore");
      } else {
        print("❌ [CANCEL] Failed to cancel payment intent");
      }
    } catch (e) {
      log("❌ [CANCEL] Error: $e");
    }
  }

  // Enhanced wallet payment with balance check
  Future<void> processWalletPayment({required String amount}) async {
    try {
      final user =
          await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid());
      if (user == null) {
        ShowToastDialog.showToast("User information not available");
        return;
      }

      double walletBalance = double.parse(user.walletAmount ?? "0.0");
      double paymentAmount = double.parse(amount);

      if (walletBalance < paymentAmount) {
        ShowToastDialog.showToast(
            "Insufficient Funds. Please top up your wallet.");
        return;
      }

      // Deduct amount from wallet
      WalletTransactionModel debitTransaction = WalletTransactionModel(
          id: Constant.getUuid(),
          amount: "-$amount",
          createdDate: Timestamp.now(),
          paymentType: "wallet",
          transactionId: orderModel.value.id,
          userId: FireStoreUtils.getCurrentUid(),
          orderType: "city",
          userType: "customer",
          note: "Ride payment deducted");

      await FireStoreUtils.setWalletTransaction(debitTransaction);
      await FireStoreUtils.updateUserWallet(amount: "-$amount");

      completeOrder();
    } catch (e) {
      ShowToastDialog.showToast("Wallet payment failed: $e");
    }
  }

  // Method to handle ride cancellation and refunds
  Future<void> handleRideCancellation() async {
    try {
      print("🔄 [CANCELLATION] Processing ride cancellation...");
      print("   Order ID: ${orderModel.value.id}");
      print("   Payment Method: ${selectedPaymentMethod.value}");
      print("   Payment Intent ID: ${orderModel.value.paymentIntentId}");

      if ((selectedPaymentMethod.value.toLowerCase() == "stripe" ||
              selectedPaymentMethod.value.toLowerCase().contains("stripe")) &&
          orderModel.value.paymentIntentId != null &&
          orderModel.value.paymentIntentId!.isNotEmpty) {
        print("🔄 Cancelling Stripe pre-authorization...");

        final stripeConfig = paymentModel.value.strip;
        if (stripeConfig != null && stripeConfig.stripeSecret != null) {
          final stripeService = StripeService(
            stripeSecret: stripeConfig.stripeSecret!,
            publishableKey: stripeConfig.clientpublishableKey ?? '',
          );

          final success = await stripeService.releasePreAuthorization(
            paymentIntentId: orderModel.value.paymentIntentId!,
          );

          if (success) {
            print("✅ Pre-authorization released successfully");

            // Create transaction record for cancellation
            WalletTransactionModel cancellationTransaction =
                WalletTransactionModel(
              id: Constant.getUuid(),
              amount: "0",
              createdDate: Timestamp.now(),
              paymentType: "Stripe",
              transactionId: orderModel.value.id,
              userId: FireStoreUtils.getCurrentUid(),
              orderType: "city",
              userType: "customer",
              note:
                  "Ride cancelled - Stripe authorization released for ride #${orderModel.value.id}",
            );

            await FireStoreUtils.setWalletTransaction(cancellationTransaction);
            print(
                "💾 Cancellation transaction saved: ${cancellationTransaction.id}");

            orderModel.value.paymentIntentStatus = 'cancelled';
            orderModel.value.paymentCanceledAt = Timestamp.now();
            orderModel.value.status = Constant.rideCanceled;
            orderModel.value.updateDate = Timestamp.now();
            await FireStoreUtils.setOrder(orderModel.value);

            ShowToastDialog.showToast(
                "Ride canceled. Your payment hold has been released.",
                position: EasyLoadingToastPosition.center,
                duration: const Duration(seconds: 4));
          } else {
            print("❌ Failed to release pre-authorization");
            ShowToastDialog.showToast(
                "Failed to release payment. Please contact support.");
          }
        }
      } else if (selectedPaymentMethod.value.toLowerCase() == "wallet") {
        print("🔄 Processing wallet refund...");

        // Only refund if payment was already deducted
        if (orderModel.value.paymentStatus == true) {
          final amount = calculateAmount().toString();

          WalletTransactionModel refundTransaction = WalletTransactionModel(
              id: Constant.getUuid(),
              amount: amount,
              createdDate: Timestamp.now(),
              paymentType: "wallet",
              transactionId: orderModel.value.id,
              userId: FireStoreUtils.getCurrentUid(),
              orderType: "city",
              userType: "customer",
              note:
                  "Ride cancellation refund for ride #${orderModel.value.id}");

          await FireStoreUtils.setWalletTransaction(refundTransaction);
          await FireStoreUtils.updateUserWallet(amount: amount);

          print("✅ Wallet refund processed");
          ShowToastDialog.showToast("Amount refunded to your wallet");
        } else {
          print("ℹ️  No wallet refund needed - payment not yet deducted");
        }

        orderModel.value.status = Constant.rideCanceled;
        orderModel.value.updateDate = Timestamp.now();
        await FireStoreUtils.setOrder(orderModel.value);
      } else if (selectedPaymentMethod.value.toLowerCase() == "cash") {
        // For cash, just update status
        print("ℹ️  Cash payment - no refund needed");
        orderModel.value.status = Constant.rideCanceled;
        orderModel.value.updateDate = Timestamp.now();
        await FireStoreUtils.setOrder(orderModel.value);
        ShowToastDialog.showToast("Ride canceled successfully");
      }
    } catch (e) {
      log("Error handling ride cancellation: $e");
      ShowToastDialog.showToast("Error processing cancellation");
    }
  }

   // 🔥 ENHANCED: Complete order with comprehensive validation
  Future<void> completeOrder() async {
    print("💰 [COMPLETE ORDER] Starting complete order process...");

    // Prevent multiple simultaneous payments
    if (isPaymentProcessing.value) {
      print("⚠️ [COMPLETE ORDER] Payment already in progress");
      return;
    }

    isPaymentProcessing.value = true;
    isLoading.value = true;

    try {
      // DEBUG: Check order state before starting
      print("📋 [COMPLETE ORDER] Order validation:");
      print("   Order ID: ${orderModel.value.id}");
      print("   Driver ID: ${orderModel.value.driverId}");
      print("   Payment Type: ${orderModel.value.paymentType}");
      print("   Status: ${orderModel.value.status}");
      print("   Payment Intent: ${orderModel.value.paymentIntentId}");

      // 🔥 CRITICAL: Validate essential data
      if (!_validateOrderCompletion()) {
        isPaymentProcessing.value = false;
        isLoading.value = false;
        return;
      }

      ShowToastDialog.showLoader("Processing payment...");
      print("🔄 [COMPLETE ORDER] Step 1: Updating order status...");

      // Update order status
      orderModel.value.paymentStatus = true;
      orderModel.value.paymentType = selectedPaymentMethod.value;
      orderModel.value.status = Constant.rideComplete;
      orderModel.value.coupon = selectedCouponModel.value;
      orderModel.value.updateDate = Timestamp.now();

      print("✅ [COMPLETE ORDER] Step 1 Complete: Order status updated");

      // Calculate amount with debug
      final amount = calculateAmount();
      print("🧮 [COMPLETE ORDER] Calculated amount: $amount");

      // Create wallet transaction for driver
      print("🔄 [COMPLETE ORDER] Step 2: Creating wallet transaction...");
      WalletTransactionModel transactionModel = WalletTransactionModel(
          id: Constant.getUuid(),
          amount: amount.toString(),
          createdDate: Timestamp.now(),
          paymentType: selectedPaymentMethod.value,
          transactionId: orderModel.value.id,
          userId: orderModel.value.driverId.toString(),
          orderType: "city",
          userType: "driver",
          note: "Ride amount credited");

      await FireStoreUtils.setWalletTransaction(transactionModel);
      print("✅ [COMPLETE ORDER] Step 2 Complete: Wallet transaction created");

      // Update driver wallet
      print("🔄 [COMPLETE ORDER] Step 3: Updating driver wallet...");
      await FireStoreUtils.updateDriverWallet(
          amount: amount.toString(),
          driverId: orderModel.value.driverId.toString());
      print("✅ [COMPLETE ORDER] Step 3 Complete: Driver wallet updated");

      // Handle admin commission
      print("🔄 [COMPLETE ORDER] Step 4: Processing admin commission...");
      await _processAdminCommission(amount);

      // Send notification to driver
      print("🔄 [COMPLETE ORDER] Step 5: Sending notification...");
      await _sendCompletionNotification(amount);

      // Handle referral
      print("🔄 [COMPLETE ORDER] Step 6: Processing referral...");
      await _processReferral();

      // Final order save
      print("🔄 [COMPLETE ORDER] Step 7: Saving final order...");
      final success = await FireStoreUtils.updateOrderPreservingPayment(orderModel.value);

      if (success == true) {
        ShowToastDialog.closeLoader();
        print("🎉 [COMPLETE ORDER] PAYMENT COMPLETE SUCCESSFULLY!");
        ShowToastDialog.showToast("Payment completed successfully");

        // Navigate to complete order screen
        Get.off(() => const CompleteOrderScreen(), arguments: {
          'orderModel': orderModel.value,
        });
      } else {
        print("❌ [COMPLETE ORDER] Failed to save order");
        ShowToastDialog.closeLoader();
        isPaymentProcessing.value = false;
        isLoading.value = false;
        ShowToastDialog.showToast("Failed to complete ride");
      }

    } catch (e, stack) {
      ShowToastDialog.closeLoader();
      isPaymentProcessing.value = false;
      isLoading.value = false;
      print("❌ [COMPLETE ORDER] ERROR: $e");
      print("📋 Stack trace: $stack");
      ShowToastDialog.showToast("Error completing order: ${e.toString()}");
    } finally {
      isPaymentProcessing.value = false;
      isLoading.value = false;
    }
  }

  completeCashOrder() async {
    isPaymentProcessing.value = false;
    orderModel.value.paymentType = selectedPaymentMethod.value;
    orderModel.value.status = Constant.rideComplete;
    orderModel.value.coupon = selectedCouponModel.value;

    await SendNotification.sendOneNotification(
        token: driverUserModel.value.fcmToken.toString(),
        title: 'Payment changed.',
        body: '${userModel.value.fullName} has changed payment method.',
        payload: {});

    FireStoreUtils.setOrder(orderModel.value).then((value) {
      if (value == true) {
        ShowToastDialog.showToast("Payment method update successfully");
      }
    });
  }

   // 🔥 NEW: Comprehensive order validation
  bool _validateOrderCompletion() {
    // Check driver assignment
    if (orderModel.value.driverId == null || orderModel.value.driverId!.isEmpty) {
      print("❌ [VALIDATION] CRITICAL: No driver ID found!");
      
      // Attempt last-minute recovery
      if (orderModel.value.acceptedDriverId != null && orderModel.value.acceptedDriverId!.isNotEmpty) {
        final recoveredDriverId = orderModel.value.acceptedDriverId!.first.toString();
        print("💡 [VALIDATION] Recovering driver ID from acceptedDriverId: $recoveredDriverId");
        orderModel.value.driverId = recoveredDriverId;
      } else {
        ShowToastDialog.showToast("Cannot complete: No driver assigned to this ride");
        return false;
      }
    }

    // Check fare amount
    if (orderModel.value.finalRate == null || orderModel.value.finalRate!.isEmpty) {
      print("❌ [VALIDATION] CRITICAL: No final rate found!");
      ShowToastDialog.showToast("Cannot complete: Invalid fare amount");
      return false;
    }

    // Check payment method
    if (selectedPaymentMethod.value.isEmpty) {
      print("❌ [VALIDATION] CRITICAL: No payment method selected!");
      ShowToastDialog.showToast("Please select a payment method");
      return false;
    }

    // For Stripe payments, check if we have payment intent data
    if ((selectedPaymentMethod.value.toLowerCase() == "stripe" ||
            selectedPaymentMethod.value.toLowerCase().contains("stripe")) &&
        (orderModel.value.paymentIntentId == null || orderModel.value.paymentIntentId!.isEmpty)) {
      print("⚠️ [VALIDATION] Stripe payment but no payment intent data");
      // This might be okay if it's a new payment flow
    }

    print("✅ [VALIDATION] All checks passed");
    return true;
  }

  // 🔥 NEW: Process admin commission with better error handling
  Future<void> _processAdminCommission(double amount) async {
    try {
      if (orderModel.value.adminCommission != null &&
          orderModel.value.adminCommission!.isEnabled == true) {
        
        double baseAmount;
        try {
          baseAmount = double.parse(orderModel.value.finalRate.toString()) -
              double.parse(couponAmount.value.toString());
        } catch (e) {
          print("❌ [COMMISSION] Error calculating base amount, using finalRate only");
          baseAmount = double.tryParse(orderModel.value.finalRate.toString()) ?? 0.0;
        }

        // Ensure commission data is available
        if (orderModel.value.adminCommission == null) {
          print("⚠️ [COMMISSION] Order missing commission data, using global commission");
          if (Constant.adminCommission != null) {
            orderModel.value.adminCommission = Constant.adminCommission;
            await FirebaseFirestore.instance
                .collection(CollectionName.orders)
                .doc(orderModel.value.id)
                .update({'adminCommission': Constant.adminCommission!.toJson()});
            print("✅ [COMMISSION] Added missing commission data to order");
          } else {
            print("❌ [COMMISSION] No commission data available anywhere");
            orderModel.value.adminCommission = AdminCommission(
                isEnabled: false,
                type: "percentage", 
                amount: "0",
                flatRatePromotion: FlatRatePromotion(isEnabled: false, amount: 0.0));
          }
        }

        // Calculate commission
        double commissionAmount = _calculateDriverCommission(
            baseAmount, orderModel.value.adminCommission!, driverUserModel.value);

        print("📊 [COMMISSION] Final commission amount: $commissionAmount");

        // Only deduct commission if it's greater than 0
        if (commissionAmount > 0) {
          WalletTransactionModel adminCommissionWallet = WalletTransactionModel(
              id: Constant.getUuid(),
              amount: "-$commissionAmount",
              createdDate: Timestamp.now(),
              paymentType: selectedPaymentMethod.value,
              transactionId: orderModel.value.id,
              orderType: "city",
              userType: "driver",
              userId: orderModel.value.driverId.toString(),
              note: "Admin commission debited");

          await FireStoreUtils.setWalletTransaction(adminCommissionWallet);
          await FireStoreUtils.updateDriverWallet(
              amount: "-$commissionAmount",
              driverId: orderModel.value.driverId.toString());
          print("✅ [COMMISSION] Admin commission processed");
        } else {
          print("ℹ️ [COMMISSION] No commission to deduct (amount is 0)");
        }
      } else {
        print("ℹ️ [COMMISSION] No admin commission to process");
      }
    } catch (e) {
      print("❌ [COMMISSION] Error processing commission: $e");
      // Don't fail the entire payment if commission processing fails
    }
  }

  // 🔥 NEW: Send completion notification
  Future<void> _sendCompletionNotification(double amount) async {
    try {
      if (driverUserModel.value.fcmToken != null && driverUserModel.value.fcmToken!.isNotEmpty) {
        Map<String, dynamic> playLoad = <String, dynamic>{
          "type": "city_order_payment_complete",
          "orderId": orderModel.value.id
        };

        await SendNotification.sendOneNotification(
            token: driverUserModel.value.fcmToken.toString(),
            title: 'Payment Received',
            body: '${userModel.value.fullName} has paid ${Constant.amountShow(amount: amount.toString())} for the completed ride.',
            payload: playLoad);
        print("✅ [NOTIFICATION] Notification sent to driver");
      } else {
        print("ℹ️ [NOTIFICATION] No FCM token for driver, skipping notification");
      }
    } catch (e) {
      print("❌ [NOTIFICATION] Error sending notification: $e");
      // Don't fail payment if notification fails
    }
  }

  // 🔥 NEW: Process referral
  Future<void> _processReferral() async {
    try {
      await FireStoreUtils.getFirestOrderOrNOt(orderModel.value).then((value) async {
        if (value == true) {
          await FireStoreUtils.updateReferralAmount(orderModel.value);
          print("✅ [REFERRAL] Referral processed");
        } else {
          print("ℹ️ [REFERRAL] Not first order, no referral");
        }
      });
    } catch (e) {
      print("❌ [REFERRAL] Error processing referral: $e");
      // Don't fail payment if referral processing fails
    }
  }

  Rx<CouponModel> selectedCouponModel = CouponModel().obs;
  RxString couponAmount = "0.0".obs;

  double calculateAmount() {
    RxString taxAmount = "0.0".obs;
    if (orderModel.value.taxList != null) {
      for (var element in orderModel.value.taxList!) {
        taxAmount.value = (double.parse(taxAmount.value) +
                Constant().calculateTax(
                    amount: (double.parse(orderModel.value.finalRate.toString()) -
                            double.parse(couponAmount.value.toString()))
                        .toString(),
                    taxModel: element))
            .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
      }
    }
    return (double.parse(orderModel.value.finalRate.toString()) -
            double.parse(couponAmount.value.toString())) +
        double.parse(taxAmount.value);
  }

  // Capture Stripe pre-authorization when ride completes
  Future<void> _captureStripePreAuthorization() async {
    try {
      print("💳 [STRIPE] Starting pre-authorization capture...");

      if (orderModel.value.paymentIntentId == null ||
          orderModel.value.paymentIntentId!.isEmpty) {
        print("⚠️  No payment intent ID found - skipping automatic capture");
        return;
      }

      final stripeConfig = paymentModel.value.strip;
      if (stripeConfig == null || stripeConfig.stripeSecret == null) {
        print("⚠️  Stripe not configured - skipping capture");
        return;
      }

      final stripeService = StripeService(
        stripeSecret: stripeConfig.stripeSecret!,
        publishableKey: stripeConfig.clientpublishableKey ?? '',
      );

      // Calculate final amount
      final finalAmount = calculateAmount();
      print("💰 Final amount to capture: \$${finalAmount.toStringAsFixed(2)}");
      print(
          "💰 Originally authorized: \$${orderModel.value.preAuthAmount ?? 'Unknown'}");

      // Capture the pre-authorization
      final captureResult = await stripeService.capturePreAuthorization(
        paymentIntentId: orderModel.value.paymentIntentId!,
        finalAmount: finalAmount.toStringAsFixed(2),
      );

      if (captureResult['success'] == true) {
        print("✅ Pre-authorization captured successfully");
        orderModel.value.paymentIntentStatus = 'captured';
        orderModel.value.paymentStatus = true;

        // Get the originally authorized amount for comparison
        double authorizedAmount = orderModel.value.preAuthAmount != null
            ? double.parse(orderModel.value.preAuthAmount!)
            : finalAmount;

        // Create transaction record for customer (debit)
        WalletTransactionModel customerTransaction = WalletTransactionModel(
          id: Constant.getUuid(),
          amount: "-${finalAmount.toStringAsFixed(2)}",
          createdDate: Timestamp.now(),
          paymentType: "Stripe",
          transactionId: orderModel.value.id,
          userId: FireStoreUtils.getCurrentUid(),
          orderType: "city",
          userType: "customer",
          note: "Stripe payment for ride #${orderModel.value.id}",
        );

        await FireStoreUtils.setWalletTransaction(customerTransaction);
        print(
            "💾 Customer transaction history saved: ${customerTransaction.id}");

        // If there's a difference, create a refund transaction record
        if (finalAmount < authorizedAmount) {
          double difference = authorizedAmount - finalAmount;

          WalletTransactionModel refundTransaction = WalletTransactionModel(
            id: Constant.getUuid(),
            amount: difference.toStringAsFixed(2),
            createdDate: Timestamp.now(),
            paymentType: "Stripe",
            transactionId: orderModel.value.id,
            userId: FireStoreUtils.getCurrentUid(),
            orderType: "city",
            userType: "customer",
            note:
                "Stripe hold release - unused authorization for ride #${orderModel.value.id}",
          );

          await FireStoreUtils.setWalletTransaction(refundTransaction);
          print("💾 Refund transaction history saved: ${refundTransaction.id}");
        }

        await FireStoreUtils.setOrder(orderModel.value);
      } else {
        print(
            "❌ Failed to capture pre-authorization: ${captureResult['error']}");
      }
    } catch (e) {
      print("❌ Error capturing pre-authorization: $e");
    }
  }

  // Strip
  Future<void> stripeMakePayment({required String amount}) async {
    log(double.parse(amount).toStringAsFixed(0));
    try {
      Map<String, dynamic>? paymentIntentData =
          await createStripeIntent(amount: amount);
      if (paymentIntentData!.containsKey("error")) {
        Get.back();
        ShowToastDialog.showToast(
            "Something went wrong, please contact admin.");
      } else {
        await Stripe.instance.initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
                paymentIntentClientSecret: paymentIntentData['client_secret'],
                allowsDelayedPaymentMethods: false,
                googlePay: const PaymentSheetGooglePay(
                  merchantCountryCode: 'US',
                  testEnv: true,
                  currencyCode: "USD",
                ),
                style: ThemeMode.system,
                appearance: const PaymentSheetAppearance(
                  colors: PaymentSheetAppearanceColors(
                    primary: AppColors.primary,
                  ),
                ),
                merchantDisplayName: 'GoRide'));
        displayStripePaymentSheet(amount: amount);
      }
    } catch (e, s) {
      log("$e \n$s");
      ShowToastDialog.showToast("exception:$e \n$s");
    }
  }

  displayStripePaymentSheet({required String amount}) async {
    try {
      await Stripe.instance.presentPaymentSheet().then((value) {
        Get.back();
        ShowToastDialog.showToast("Payment successfully");
        completeOrder();
      });
    } on StripeException catch (e) {
      var lo1 = jsonEncode(e);
      var lo2 = jsonDecode(lo1);
      StripePayFailedModel lom = StripePayFailedModel.fromJson(lo2);
      ShowToastDialog.showToast(lom.error.message);
    } catch (e) {
      ShowToastDialog.showToast(e.toString());
    }
  }

  createStripeIntentWithCapture(
      {required String amount, required String captureMethod}) async {
    return createStripeIntent(amount: amount, captureMethod: captureMethod);
  }

  createStripeIntent(
      {required String amount, String captureMethod = 'automatic'}) async {
    try {
      Map<String, dynamic> body = {
        'amount': ((double.parse(amount) * 100).round()).toString(),
        'currency': "CAD",
        'payment_method_types[]': 'card',
        'capture_method': captureMethod,
        "description": "Strip Payment",
        "shipping[name]": userModel.value.fullName,
        "shipping[address][line1]": "510 Townsend St",
        "shipping[address][postal_code]": "98140",
        "shipping[address][city]": "San Francisco",
        "shipping[address][state]": "CA",
        "shipping[address][country]": "US",
      };
      log(paymentModel.value.strip!.stripeSecret.toString());
      var stripeSecret = paymentModel.value.strip!.stripeSecret;
      var response = await http.post(
          Uri.parse('https://api.stripe.com/v1/payment_intents'),
          body: body,
          headers: {
            'Authorization': 'Bearer $stripeSecret',
            'Content-Type': 'application/x-www-form-urlencoded'
          });

      return jsonDecode(response.body);
    } catch (e) {
      log(e.toString());
    }
  }

  //mercadoo
  mercadoPagoMakePayment(
      {required BuildContext context, required String amount}) async {
    final headers = {
      'Authorization': 'Bearer ${paymentModel.value.mercadoPago!.accessToken}',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      "items": [
        {
          "title": "Test",
          "description": "Test Payment",
          "quantity": 1,
          "currency_id": "USD", // or your preferred currency
          "unit_price": double.parse(amount),
        }
      ],
      "payer": {"email": userModel.value.email},
      "back_urls": {
        "failure": "${Constant.globalUrl}payment/failure",
        "pending": "${Constant.globalUrl}payment/pending",
        "success": "${Constant.globalUrl}payment/success",
      },
      "auto_return":
          "approved" // Automatically return after payment is approved
    });

    final response = await http.post(
      Uri.parse("https://api.mercadopago.com/checkout/preferences"),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      Get.to(MercadoPagoScreen(initialURl: data['init_point']))!.then((value) {
        if (value) {
          ShowToastDialog.showToast("Payment Successful!!");
          completeOrder();
        } else {
          ShowToastDialog.showToast("Payment UnSuccessful!!");
        }
      });
    } else {
      print('Error creating preference: ${response.body}');
      return null;
    }
  }

  ///PayStack Payment Method
  payStackPayment(String totalAmount) async {
    await PayStackURLGen.payStackURLGen(
            amount: (double.parse(totalAmount) * 100).toString(),
            currency: "NGN",
            secretKey: paymentModel.value.payStack!.secretKey.toString(),
            userModel: userModel.value)
        .then((value) async {
      if (value != null) {
        PayStackUrlModel payStackModel = value;
        Get.to(PayStackScreen(
          secretKey: paymentModel.value.payStack!.secretKey.toString(),
          callBackUrl: paymentModel.value.payStack!.callbackURL.toString(),
          initialURl: payStackModel.data.authorizationUrl,
          amount: totalAmount,
          reference: payStackModel.data.reference,
        ))!
            .then((value) {
          if (value) {
            ShowToastDialog.showToast("Payment Successful!!");
            completeOrder();
          } else {
            ShowToastDialog.showToast("Payment UnSuccessful!!");
          }
        });
      } else {
        ShowToastDialog.showToast(
            "Something went wrong, please contact admin.");
      }
    });
  }

  //flutter wave Payment Method
  flutterWaveInitiatePayment(
      {required BuildContext context, required String amount}) async {
    final url = Uri.parse('https://api.flutterwave.com/v3/payments');
    final headers = {
      'Authorization': 'Bearer ${paymentModel.value.flutterWave!.secretKey}',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      "tx_ref": _ref,
      "amount": amount,
      "currency": "NGN",
      "redirect_url": "${Constant.globalUrl}payment/success",
      "payment_options": "ussd, card, barter, payattitude",
      "customer": {
        "email": userModel.value.email.toString(),
        "phonenumber": userModel.value.phoneNumber, // Add a real phone number
        "name": userModel.value.fullName!, // Add a real customer name
      },
      "customizations": {
        "title": "Payment for Services",
        "description": "Payment for XYZ services",
      }
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      Get.to(MercadoPagoScreen(initialURl: data['data']['link']))!
          .then((value) {
        if (value) {
          ShowToastDialog.showToast("Payment Successful!!");
          completeOrder();
        } else {
          ShowToastDialog.showToast("Payment UnSuccessful!!");
        }
      });
    } else {
      print('Payment initialization failed: ${response.body}');
      return null;
    }
  }

  String? _ref;

  setRef() {
    maths.Random numRef = maths.Random();
    int year = DateTime.now().year;
    int refNumber = numRef.nextInt(20000);
    if (Platform.isAndroid) {
      _ref = "AndroidRef$year$refNumber";
    } else if (Platform.isIOS) {
      _ref = "IOSRef$year$refNumber";
    }
  }

  // payFast
  payFastPayment({required BuildContext context, required String amount}) {
    PayStackURLGen.getPayHTML(
            payFastSettingData: paymentModel.value.payfast!,
            amount: amount.toString(),
            userModel: userModel.value)
        .then((String? value) async {
      bool isDone = await Get.to(PayFastScreen(
          htmlData: value!, payFastSettingData: paymentModel.value.payfast!));
      if (isDone) {
        Get.back();
        ShowToastDialog.showToast("Payment successfully");
        completeOrder();
      } else {
        Get.back();
        ShowToastDialog.showToast("Payment Failed");
      }
    });
  }

  ///RazorPay payment function
  final Razorpay razorPay = Razorpay();

  void openCheckout({required amount, required orderId}) async {
    var options = {
      'key': paymentModel.value.razorpay!.razorpayKey,
      'amount': amount * 100,
      'name': 'GoRide',
      'order_id': orderId,
      "currency": "INR",
      'description': 'wallet Topup',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': userModel.value.phoneNumber,
        'email': userModel.value.email,
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      razorPay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void handlePaymentSuccess(PaymentSuccessResponse response) {
    isPaymentProcessing.value = false;
    Get.back();
    ShowToastDialog.showToast("Payment Successful!!");
    completeOrder();
  }

  void handleExternalWaller(ExternalWalletResponse response) {
    isPaymentProcessing.value = false;
    Get.back();
    ShowToastDialog.showToast("Payment Processing!! via");
  }

  void handlePaymentError(PaymentFailureResponse response) {
    isPaymentProcessing.value = false;
    Get.back();
    // RazorPayFailedModel lom = RazorPayFailedModel.fromJson(jsonDecode(response.message!.toString()));
    ShowToastDialog.showToast("Payment Failed!!");
  }

  /// FIX: Validate driver assignment before completing order
  static Future<bool> validateOrderCompletion(String orderId) async {
    /// Helper method to get order from FireStoreUtils
    Future<OrderModel?> getOrder(String orderId) async {
      return await FireStoreUtils.getOrder(orderId);
    }

    try {
      final order = await getOrder(orderId);
      if (order == null) {
        print("❌ Order not found: $orderId");
        return false;
      }

      // Critical validation: Must have a driver assigned
      if (order.driverId == null || order.driverId!.isEmpty) {
        print("❌ CRITICAL: Cannot complete order without driver assignment!");
        print("   Order: $orderId");
        print("   Status: ${order.status}");

        // Attempt automatic recovery
        final recoverySuccess =
            await FireStoreUtils.validateOrderCompletion(orderId);
        if (!recoverySuccess) {
          print("❌ Recovery failed, order cannot be completed");
          return false;
        }

        // Reload the order after recovery
        final recoveredOrder = await getOrder(orderId);
        if (recoveredOrder?.driverId == null) {
          print("❌ Recovery didn't assign a driver");
          return false;
        }

        return true;
      }

      print("✅ Order validation passed - Driver assigned: ${order.driverId}");
      return true;
    } catch (e) {
      print("❌ Order validation failed: $e");
      return false;
    }
  }

  /// FIX: Patch all orders with missing driver assignment
  static Future<void> patchBrokenOrders() async {
    print("🔧 Patching broken orders with missing driver assignment...");

    try {
      // Find all completed orders with null driverId
      final brokenOrders = await FirebaseFirestore.instance
          .collection(CollectionName.orders)
          .where('status', isEqualTo: 'Ride Completed')
          .where('driverId', isNull: true)
          .get();

      print("🔧 Found ${brokenOrders.size} broken orders to patch");

      for (var orderDoc in brokenOrders.docs) {
        final orderId = orderDoc.id;
        final orderData = orderDoc.data();

        print("🔧 Processing order: $orderId");

        // Check if this order has accepted drivers
        final acceptedDrivers = await FirebaseFirestore.instance
            .collection(CollectionName.orders)
            .doc(orderId)
            .collection("acceptedDriver")
            .get();

        if (acceptedDrivers.docs.isNotEmpty) {
          final driverId = acceptedDrivers.docs.first.id;
          print("🔧 Found accepted driver: $driverId for order: $orderId");

          // Apply the fix
          await assignDriverToOrder(orderId, driverId);
          print("✅ Order $orderId patched successfully");
        } else {
          print("⚠️  Order $orderId has no accepted drivers");
        }
      }

      print("🎉 Broken orders patch completed");
    } catch (e) {
      print("❌ Error patching broken orders: $e");
    }
  }

  /// FIX: Properly assign driver to order when they accept
  static Future<bool> assignDriverToOrder(
      String orderId, String driverId) async {
    try {
      print("🔧 FIX: Assigning driver $driverId to order $orderId");

      // Get the driver acceptance data
      final acceptanceDoc = await FirebaseFirestore.instance
          .collection(CollectionName.orders)
          .doc(orderId)
          .collection("acceptedDriver")
          .doc(driverId)
          .get();

      if (!acceptanceDoc.exists) {
        print("❌ Driver acceptance record not found");
        return false;
      }

      // Update the main order document with driver assignment
      await FirebaseFirestore.instance
          .collection(CollectionName.orders)
          .doc(orderId)
          .update({
        'driverId': driverId,
        'updateDate': FieldValue.serverTimestamp(),
        'acceptedDriverId': FieldValue.arrayUnion([driverId]),
        'status': 'Driver Accepted', // Or appropriate status
      });

      print("✅ Order successfully updated with driver assignment");
      return true;
    } catch (e) {
      print("❌ Error assigning driver to order: $e");
      return false;
    }
  }

  /// DEBUG: Check what's actually in the adminCommission document
  static Future<void> debugAdminCommissionSettings() async {
    try {
      print("🔍 DEBUG: Checking adminCommission settings in Firebase...");

      final commissionDoc = await FirebaseFirestore.instance
          .collection(CollectionName.settings)
          .doc('adminCommission')
          .get();

      if (!commissionDoc.exists) {
        print("❌ adminCommission document does NOT exist in Firebase!");
        return;
      }

      final data = commissionDoc.data();
      if (data == null) {
        print("❌ adminCommission document exists but data is null!");
        return;
      }

      print("📋 adminCommission document data:");
      data.forEach((key, value) {
        print("   $key: $value (type: ${value.runtimeType})");
      });

      // Check specifically for the required fields
      print("\n🔍 Field validation:");
      print(
          "   amount: '${data['amount']}' (exists: ${data.containsKey('amount')})");
      print("   type: '${data['type']}' (exists: ${data.containsKey('type')})");
      print(
          "   isEnabled: ${data['isEnabled']} (exists: ${data.containsKey('isEnabled')})");

      if (data['flatRatePromotion'] != null) {
        print("   flatRatePromotion: ${data['flatRatePromotion']}");
      }
    } catch (e) {
      print("❌ Error checking admin commission: $e");
    }
  }

  /// DEBUG: Check how adminCommission is being set in the order
  static Future<void> debugOrderAdminCommission(String orderId) async {
    try {
      print("🔍 DEBUG: Checking adminCommission in order $orderId");

      final orderDoc = await FirebaseFirestore.instance
          .collection(CollectionName.orders)
          .doc(orderId)
          .get();

      if (orderDoc.exists) {
        final orderData = orderDoc.data();
        print("📋 Order adminCommission field:");
        print("   adminCommission: ${orderData?['adminCommission']}");
        print(
            "   adminCommission type: ${orderData?['adminCommission']?.runtimeType}");

        if (orderData?['adminCommission'] != null) {
          final commission =
              orderData!['adminCommission'] as Map<String, dynamic>;
          commission.forEach((key, value) {
            print("     $key: $value (type: ${value.runtimeType})");
          });
        }
      }
    } catch (e) {
      print("❌ Error checking order admin commission: $e");
    }
  }

  /// Calculate commission based on driver's payment method (flat rate or percentage)
  double _calculateDriverCommission(double baseAmount,
      AdminCommission? orderCommission, DriverUserModel driver) {
    print("💰 [COMMISSION CALC] Calculating driver commission...");
    print("   Base amount: $baseAmount");
    print("   Driver flatRateActive: ${driver.flatRateActive}");
    print("   Driver paymentMethod: ${driver.paymentMethod}");

    AdminCommission? commissionToUse = orderCommission;

    // If no commission from order, use global
    if (commissionToUse == null) {
      print("⚠️ [COMMISSION CALC] No commission data in order, using global commission");
      commissionToUse = Constant.adminCommission;
    }

    if (commissionToUse == null) {
      print("❌ [COMMISSION CALC] No commission data available for calculation");
      return 0.0;
    }

    // SPECIAL CASE: If driver has flat rate active, deduct ZERO commission
    if (driver.flatRateActive == true) {
      print("🎯 [COMMISSION CALC] Driver has flatRateActive: true - deducting ZERO commission (already paid upfront)");
      return 0.0;
    }

    // Use the corrected Constant function
    double commissionAmount = Constant.calculateOrderAdminCommission(
        amount: baseAmount.toString(),
        adminCommission: commissionToUse,
        driver: driver);

    return commissionAmount;
  }

  /// Debug method to log driver's payment settings
  void _debugDriverPaymentSettings(DriverUserModel driver) {
    print("👤 [DRIVER DEBUG] Driver Payment Settings:");
    print("   Driver: ${driver.fullName} (${driver.id})");
    print("   flatRateActive: ${driver.flatRateActive}");
    print("   paymentMethod: ${driver.paymentMethod}");
    print("   flatRatePaidAt: ${driver.flatRatePaidAt}");
    print("   lastSwitched: ${driver.lastSwitched}");

    if (driver.flatRateActive == true) {
      print("   💰 FLAT RATE ACTIVE: Will deduct ZERO commission (already paid upfront)");
    }

    if (driver.flatRatePaidAt != null) {
      final paidAt = driver.flatRatePaidAt!.toDate();
      final now = DateTime.now();
      final difference = now.difference(paidAt);
      print("   Flat rate paid: ${difference.inDays} days ago");

      if (difference.inDays > 30) {
        print("   ⚠️ Flat rate may have expired (more than 30 days)");
      } else {
        print("   ✅ Flat rate is within validity period");
      }
    } else if (driver.flatRateActive == true) {
      print("   ⚠️ flatRateActive is true but flatRatePaidAt is null - inconsistent data");
    }
  }

  Future<void> _loadDriverInformation() async {
    isDriverLoading.value = true;
    driverError.value = "";

    try {
      if (orderModel.value.driverId == null ||
          orderModel.value.driverId!.isEmpty) {
        print("⚠️ No driver assigned to order ${orderModel.value.id}");
        driverError.value = "No driver assigned";
        return;
      }

      print("🔍 Loading driver: ${orderModel.value.driverId}");

      // Try to load driver with retry mechanism
      final driver = await FireStoreUtils.getDriverWithRetry(
          orderModel.value.driverId.toString(),
          maxRetries: 3, retryDelay: Duration(seconds: 2));

      if (driver != null) {
        driverUserModel.value = driver;
        driverError.value = "";
        print("✅ Driver loaded successfully: ${driver.fullName}");

        // Debug driver payment settings
        _debugDriverPaymentSettings(driver);
      } else {
        driverError.value = "Driver information not available";
        print("❌ Failed to load driver after retries");
      }
    } catch (error) {
      driverError.value = "Error loading driver information";
      print("❌ Error loading driver: $error");
    } finally {
      isDriverLoading.value = false;
    }
  }

  @override
  void onClose() {
    // Clean up RazorPay listeners
    razorPay.clear();
    super.onClose();
  }
}

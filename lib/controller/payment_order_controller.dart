import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as maths;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
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
import 'package:customer/payment/getPaytmTxtToken.dart';
import 'package:customer/payment/paystack/pay_stack_screen.dart';
import 'package:customer/payment/paystack/pay_stack_url_model.dart';
import 'package:customer/payment/paystack/paystack_url_genrater.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      orderModel.value = argumentData['orderModel'];
    }
    update();
  }

  Rx<PaymentModel> paymentModel = PaymentModel().obs;
  Rx<UserModel> userModel = UserModel().obs;
  Rx<DriverUserModel> driverUserModel = DriverUserModel().obs;
  RxBool isDriverLoading = true.obs;
  RxString driverError = "".obs;

  RxString selectedPaymentMethod = "".obs;
  RxBool isPaymentProcessing = false.obs;

  getPaymentData() async {
    // In getPaymentData method, add:
    await debugAdminCommissionSettings();

    await debugOrderAdminCommission(orderModel.value.id!);
    try {
      // Load payment configuration
      await FireStoreUtils().getPayment().then((value) {
        if (value != null) {
          paymentModel.value = value;

          if (paymentModel.value.strip?.clientpublishableKey != null) {
            Stripe.publishableKey =
                paymentModel.value.strip!.clientpublishableKey.toString();
            Stripe.merchantIdentifier = 'BuzRyde';
            Stripe.instance.applySettings();
          }
          setRef();
          selectedPaymentMethod.value = orderModel.value.paymentType.toString();

          razorPay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccess);
          razorPay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWaller);
          razorPay.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentError);
        }
      });

      // Load user profile
      await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid())
          .then((value) {
        if (value != null) {
          userModel.value = value;
          print(
              "💰 User wallet amount loaded: ${userModel.value.walletAmount}");
        }
      });

      // DEBUG: Comprehensive driver assignment analysis
      print("🔍 ANALYZING DRIVER ASSIGNMENT ISSUE");

      final firestoreUtils = FireStoreUtils();
      await firestoreUtils.debugDriverAssignmentIssue(orderModel.value.id!);

      // Attempt to recover the driver assignment
      if (orderModel.value.driverId == null) {
        print("🔄 No driver ID found, attempting recovery...");
        final recoverySuccess =
            await FireStoreUtils.recoverDriverAssignment(orderModel.value.id!);

        if (recoverySuccess) {
          // Reload the order with the recovered driver ID
          final updatedOrder =
              await FireStoreUtils.getOrder(orderModel.value.id!);
          if (updatedOrder != null && updatedOrder.driverId != null) {
            orderModel.value = updatedOrder;
            print("✅ Driver assignment recovered successfully!");
          }
        }
      }

      // Load driver information with proper error handling
      await _loadDriverInformation();
    } catch (e) {
      log("Error in getPaymentData: $e");
    }

    isLoading.value = false;
    update();
  }

  // Stripe pre-authorization methods
  Future<void> createPreAuthorization({required String amount}) async {
    if (paymentModel.value.strip?.stripeSecret == null) {
      ShowToastDialog.showToast("Stripe not configured");
      return;
    }

    try {
      ShowToastDialog.showLoader("Authorizing payment...");
      Map<String, dynamic>? paymentIntentData = await createStripeIntent(
        amount: amount,
        captureMethod: 'manual', // This creates a pre-authorization
      );

      if (paymentIntentData!.containsKey("error")) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Failed to create pre-authorization");
      } else {
        // Store the payment intent ID for later capture
        orderModel.value.paymentIntentId = paymentIntentData['id'];
        await FireStoreUtils.setOrder(orderModel.value);
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Payment pre-authorized successfully");
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      log("Pre-authorization error: $e");
      ShowToastDialog.showToast("Pre-authorization failed: $e");
    }
  }

  Future<void> capturePreAuthorization({required String amount}) async {
    if (orderModel.value.paymentIntentId == null) {
      ShowToastDialog.showToast("No pre-authorization found");
      return;
    }

    try {
      ShowToastDialog.showLoader("Processing payment...");
      final response = await http.post(
        Uri.parse(
            'https://api.stripe.com/v1/payment_intents/${orderModel.value.paymentIntentId}/capture'),
        headers: {
          'Authorization': 'Bearer ${paymentModel.value.strip!.stripeSecret}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount_to_capture':
              ((double.parse(amount) * 100).round()).toString(),
        },
      );

      if (response.statusCode == 200) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Payment captured successfully");
        completeOrder();
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Failed to capture payment");
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      log("Capture error: $e");
      ShowToastDialog.showToast("Payment capture failed: $e");
    }
  }

  Future<void> cancelPreAuthorization() async {
    if (orderModel.value.paymentIntentId == null) {
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(
            'https://api.stripe.com/v1/payment_intents/${orderModel.value.paymentIntentId}/cancel'),
        headers: {
          'Authorization': 'Bearer ${paymentModel.value.strip!.stripeSecret}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      if (response.statusCode == 200) {
        log("Pre-authorization cancelled successfully");
      } else {
        log("Failed to cancel pre-authorization");
      }
    } catch (e) {
      log("Cancel pre-authorization error: $e");
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
      if (selectedPaymentMethod.value.toLowerCase() == "stripe" &&
          orderModel.value.paymentIntentId != null) {
        // Cancel Stripe pre-authorization
        await cancelPreAuthorization();
      } else if (selectedPaymentMethod.value.toLowerCase() == "wallet") {
        // Refund wallet amount
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
            note: "Ride cancellation refund");

        await FireStoreUtils.setWalletTransaction(refundTransaction);
        await FireStoreUtils.updateUserWallet(amount: amount);
        ShowToastDialog.showToast("Amount refunded to your wallet");
      }
    } catch (e) {
      log("Error handling ride cancellation: $e");
    }
  }

  completeOrder() async {
    print("💰 [PAYMENT DEBUG] Starting completeOrder process...");

    try {
      // Reset payment processing flag at the end
      isPaymentProcessing.value = false;

      // DEBUG: Check order state before starting
      print("📋 Order ID: ${orderModel.value.id}");
      print("🚗 Driver ID: ${orderModel.value.driverId}");
      print("💳 Payment Type: ${orderModel.value.paymentType}");
      print("📊 Current Status: ${orderModel.value.status}");

      // Validate critical data
      if (orderModel.value.driverId == null ||
          orderModel.value.driverId!.isEmpty) {
        print("❌ CRITICAL: No driver ID found!");
        ShowToastDialog.showToast("Cannot complete: No driver assigned");
        ShowToastDialog.closeLoader();
        isPaymentProcessing.value = false;
        return;
      }

      if (orderModel.value.finalRate == null ||
          orderModel.value.finalRate!.isEmpty) {
        print("❌ CRITICAL: No final rate found!");
        ShowToastDialog.showToast("Cannot complete: Invalid fare amount");
        ShowToastDialog.closeLoader();
        isPaymentProcessing.value = false;
        return;
      }

      ShowToastDialog.showLoader("Processing payment...");
      print("🔄 Step 1: Updating order status...");

      // Update order status
      orderModel.value.paymentStatus = true;
      orderModel.value.paymentType = selectedPaymentMethod.value;
      orderModel.value.status = Constant.rideComplete;
      orderModel.value.coupon = selectedCouponModel.value;
      orderModel.value.updateDate = Timestamp.now();

      print("✅ Step 1 Complete: Order status updated");

      // Calculate amount with debug
      final amount = calculateAmount();
      print("🧮 Calculated amount: $amount");

      // Create wallet transaction
      print("🔄 Step 2: Creating wallet transaction...");
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
      print("✅ Step 2 Complete: Wallet transaction created");

      // Update driver wallet
      print("🔄 Step 3: Updating driver wallet...");
      await FireStoreUtils.updateDriverWallet(
          amount: amount.toString(),
          driverId: orderModel.value.driverId.toString());
      print("✅ Step 3 Complete: Driver wallet updated");

      // Handle admin commission with debug
      print("🔄 Step 4: Processing admin commission...");
      if (orderModel.value.adminCommission != null &&
          orderModel.value.adminCommission!.isEnabled == true) {
        double baseAmount;
        try {
          baseAmount = double.parse(orderModel.value.finalRate.toString()) -
              double.parse(couponAmount.value.toString());
        } catch (e) {
          print("❌ Error calculating base amount, using finalRate only");
          baseAmount =
              double.tryParse(orderModel.value.finalRate.toString()) ?? 0.0;
        }

        // Safety check: Ensure commission data is available
        if (orderModel.value.adminCommission == null) {
          print("⚠️  Order missing commission data, using global commission");
          if (Constant.adminCommission != null) {
            orderModel.value.adminCommission = Constant.adminCommission;
            // Update the order in Firestore with the commission data
            await FirebaseFirestore.instance
                .collection(CollectionName.orders)
                .doc(orderModel.value.id)
                .update(
                    {'adminCommission': Constant.adminCommission!.toJson()});
            print("✅ Added missing commission data to order");
          } else {
            print("❌ No commission data available anywhere");
            // Create emergency default commission
            orderModel.value.adminCommission = AdminCommission(
                isEnabled: false,
                type: "percentage",
                amount: "0",
                flatRatePromotion:
                    FlatRatePromotion(isEnabled: false, amount: 0.0));
          }
        }

        // Use the new helper method to calculate commission based on driver's payment method
        double commissionAmount = _calculateDriverCommission(baseAmount,
            orderModel.value.adminCommission!, driverUserModel.value);

        print("📊 Final commission amount: $commissionAmount");

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
          print("✅ Step 4 Complete: Admin commission processed");
        } else {
          print("ℹ️  No commission to deduct (amount is 0)");
        }
      } else {
        print("ℹ️  No admin commission to process");
      }

      // Send notification with debug
      print("🔄 Step 5: Sending notification...");
      if (driverUserModel.value.fcmToken != null) {
        Map<String, dynamic> playLoad = <String, dynamic>{
          "type": "city_order_payment_complete",
          "orderId": orderModel.value.id
        };

        await SendNotification.sendOneNotification(
            token: driverUserModel.value.fcmToken.toString(),
            title: 'Payment Received',
            body:
                '${userModel.value.fullName} has paid ${Constant.amountShow(amount: amount.toString())} for the completed ride.',
            payload: playLoad);
        print("✅ Step 5 Complete: Notification sent");
      } else {
        print("ℹ️  No FCM token for driver");
      }

      // Handle referral with debug
      print("🔄 Step 6: Processing referral...");
      await FireStoreUtils.getFirestOrderOrNOt(orderModel.value)
          .then((value) async {
        if (value == true) {
          await FireStoreUtils.updateReferralAmount(orderModel.value);
          print("✅ Referral processed");
        } else {
          print("ℹ️  Not first order, no referral");
        }
      });

      // Final order save with debug
      print("🔄 Step 7: Saving final order...");
      await FireStoreUtils.setOrder(orderModel.value).then((value) {
        if (value == true) {
          ShowToastDialog.closeLoader();
          print("🎉 PAYMENT COMPLETE SUCCESSFULLY!");
          ShowToastDialog.showToast("Ride Complete successfully");

          // Navigate away or reset state
          Get.back(); // Or whatever navigation you need
        } else {
          print("❌ Failed to save order");
          ShowToastDialog.closeLoader();
          ShowToastDialog.showToast("Failed to complete ride");
        }
      });
    } catch (e, stack) {
      ShowToastDialog.closeLoader();
      isPaymentProcessing.value = false;
      print("❌ ERROR in completeOrder: $e");
      print("📋 Stack trace: $stack");
      ShowToastDialog.showToast("Error completing order: ${e.toString()}");
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

  Rx<CouponModel> selectedCouponModel = CouponModel().obs;
  RxString couponAmount = "0.0".obs;

  double calculateAmount() {
    RxString taxAmount = "0.0".obs;
    if (orderModel.value.taxList != null) {
      for (var element in orderModel.value.taxList!) {
        taxAmount.value = (double.parse(taxAmount.value) +
                Constant().calculateTax(
                    amount:
                        (double.parse(orderModel.value.finalRate.toString()) -
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
    print("💰 Calculating driver commission...");
    print("   Base amount: $baseAmount");
    print("   Driver flatRateActive: ${driver.flatRateActive}");
    print("   Driver paymentMethod: ${driver.paymentMethod}");

    AdminCommission? commissionToUse = orderCommission;

    // If no commission from order, use global
    if (commissionToUse == null) {
      print("⚠️  No commission data in order, using global commission");
      commissionToUse = Constant.adminCommission;
    }

    if (commissionToUse == null) {
      print("❌ No commission data available for calculation");
      return 0.0;
    }

    // SPECIAL CASE: If driver has flat rate active, deduct ZERO commission
    if (driver.flatRateActive == true) {
      print(
          "🎯 Driver has flatRateActive: true - deducting ZERO commission (already paid upfront)");
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
    print("👤 Driver Payment Settings Debug:");
    print("   Driver: ${driver.fullName} (${driver.id})");
    print("   flatRateActive: ${driver.flatRateActive}");
    print("   paymentMethod: ${driver.paymentMethod}");
    print("   flatRatePaidAt: ${driver.flatRatePaidAt}");
    print("   lastSwitched: ${driver.lastSwitched}");

    // Special note about flat rate commission
    if (driver.flatRateActive == true) {
      print(
          "   💰 FLAT RATE ACTIVE: Will deduct ZERO commission (already paid upfront)");
    }

    // Check if flat rate should be active based on timing
    if (driver.flatRatePaidAt != null) {
      final paidAt = driver.flatRatePaidAt!.toDate();
      final now = DateTime.now();
      final difference = now.difference(paidAt);

      print("   Flat rate paid: ${difference.inDays} days ago");

      // Typically flat rate is valid for 30 days
      if (difference.inDays > 30) {
        print("   ⚠️ Flat rate may have expired (more than 30 days)");
        print("   💡 Consider updating flatRateActive to false");
      } else {
        print("   ✅ Flat rate is within validity period");
      }
    } else if (driver.flatRateActive == true) {
      print("   ⚠️ flatRateActive is true but flatRatePaidAt is null");
      print("   💡 This might indicate inconsistent data");
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
          maxRetries: 3);

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
}
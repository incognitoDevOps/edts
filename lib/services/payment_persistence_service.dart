import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/model/wallet_transaction_model.dart';
import 'package:customer/services/stripe_service.dart';
import 'package:customer/utils/fire_store_utils.dart';

class PaymentPersistenceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<bool> saveOrderWithPaymentData(OrderModel order) async {
    try {
      print("💾 [PAYMENT PERSISTENCE] Saving order with payment data...");
      print("   Order ID: ${order.id}");
      print("   Payment Intent ID: ${order.paymentIntentId}");
      print("   Pre-auth Amount: ${order.preAuthAmount}");
      print("   Status: ${order.paymentIntentStatus}");

      final orderData = order.toJson();

      await _firestore
          .collection(CollectionName.orders)
          .doc(order.id)
          .set(orderData, SetDocumentOptions(merge: true));

      await _verifyPaymentDataSaved(order.id!);

      print("✅ [PAYMENT PERSISTENCE] Order saved successfully");
      return true;
    } catch (e) {
      print("❌ [PAYMENT PERSISTENCE] Failed to save order: $e");
      return false;
    }
  }

  static Future<void> _verifyPaymentDataSaved(String orderId) async {
    try {
      final doc = await _firestore
          .collection(CollectionName.orders)
          .doc(orderId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        print("   ✓ Verification - Payment Intent ID: ${data?['paymentIntentId']}");
        print("   ✓ Verification - Pre-auth Amount: ${data?['preAuthAmount']}");
        print("   ✓ Verification - Status: ${data?['paymentIntentStatus']}");
      }
    } catch (e) {
      print("   ⚠️  Verification failed: $e");
    }
  }

  static Future<OrderModel?> getOrderWithPaymentRecovery(String orderId) async {
    try {
      print("🔄 [PAYMENT RECOVERY] Loading order with payment data...");
      print("   Order ID: $orderId");

      final doc = await _firestore
          .collection(CollectionName.orders)
          .doc(orderId)
          .get();

      if (!doc.exists || doc.data() == null) {
        print("❌ [PAYMENT RECOVERY] Order not found");
        return null;
      }

      final order = OrderModel.fromJson(doc.data()!);

      if (order.paymentIntentId != null && order.paymentIntentId!.isNotEmpty) {
        print("✅ [PAYMENT RECOVERY] Payment data found:");
        print("   Payment Intent ID: ${order.paymentIntentId}");
        print("   Pre-auth Amount: ${order.preAuthAmount}");
        print("   Status: ${order.paymentIntentStatus}");
      } else {
        print("⚠️  [PAYMENT RECOVERY] No payment intent data in order");
      }

      return order;
    } catch (e) {
      print("❌ [PAYMENT RECOVERY] Error loading order: $e");
      return null;
    }
  }

  static Future<bool> capturePaymentWithRetry({
    required OrderModel order,
    required StripeService stripeService,
    required double finalAmount,
    int maxRetries = 3,
  }) async {
    if (order.paymentIntentId == null || order.paymentIntentId!.isEmpty) {
      print("❌ [PAYMENT CAPTURE] No payment intent ID");
      return false;
    }

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print("💳 [PAYMENT CAPTURE] Attempt $attempt of $maxRetries");
        print("   Payment Intent: ${order.paymentIntentId}");
        print("   Amount: \$${finalAmount.toStringAsFixed(2)}");

        final result = await stripeService.capturePreAuthorization(
          paymentIntentId: order.paymentIntentId!,
          finalAmount: finalAmount.toStringAsFixed(2),
        );

        if (result['success'] == true) {
          print("✅ [PAYMENT CAPTURE] Capture successful on attempt $attempt");

          order.paymentIntentStatus = 'captured';
          order.paymentStatus = true;
          order.paymentCapturedAt = Timestamp.now();

          await saveOrderWithPaymentData(order);

          await _logCaptureTransaction(
            order: order,
            capturedAmount: finalAmount,
            userId: FireStoreUtils.getCurrentUid(),
          );

          return true;
        } else {
          print("❌ [PAYMENT CAPTURE] Attempt $attempt failed: ${result['error']}");

          if (attempt < maxRetries) {
            final delay = Duration(seconds: attempt * 2);
            print("   Retrying in ${delay.inSeconds} seconds...");
            await Future.delayed(delay);
          }
        }
      } catch (e) {
        print("❌ [PAYMENT CAPTURE] Exception on attempt $attempt: $e");

        if (attempt == maxRetries) {
          print("❌ [PAYMENT CAPTURE] All retry attempts exhausted");
          return false;
        }

        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }

    return false;
  }

  static Future<void> _logCaptureTransaction({
    required OrderModel order,
    required double capturedAmount,
    required String userId,
  }) async {
    try {
      final transaction = WalletTransactionModel(
        id: Constant.getUuid(),
        amount: "-${capturedAmount.toStringAsFixed(2)}",
        createdDate: Timestamp.now(),
        paymentType: "Stripe",
        transactionId: order.id,
        userId: userId,
        orderType: "city",
        userType: "customer",
        note: "Payment captured for ride ${order.id}",
      );

      await FireStoreUtils.setWalletTransaction(transaction);
      print("💾 [TRANSACTION LOG] Capture transaction saved: ${transaction.id}");

      final authorizedAmount = order.preAuthAmount != null
          ? double.parse(order.preAuthAmount!)
          : capturedAmount;

      if (capturedAmount < authorizedAmount) {
        final difference = authorizedAmount - capturedAmount;

        final refundTransaction = WalletTransactionModel(
          id: Constant.getUuid(),
          amount: difference.toStringAsFixed(2),
          createdDate: Timestamp.now(),
          paymentType: "Stripe",
          transactionId: order.id,
          userId: userId,
          orderType: "city",
          userType: "customer",
          note: "Unused pre-authorization released for ride ${order.id}",
        );

        await FireStoreUtils.setWalletTransaction(refundTransaction);
        print("💾 [TRANSACTION LOG] Refund transaction saved: ${refundTransaction.id}");
      }
    } catch (e) {
      print("❌ [TRANSACTION LOG] Failed to log transaction: $e");
    }
  }

  static Future<bool> cancelPaymentWithRefund({
    required OrderModel order,
    required StripeService stripeService,
  }) async {
    if (order.paymentIntentId == null || order.paymentIntentId!.isEmpty) {
      print("ℹ️  [PAYMENT CANCEL] No payment intent to cancel");
      return true;
    }

    try {
      print("🔄 [PAYMENT CANCEL] Cancelling payment intent...");
      print("   Payment Intent: ${order.paymentIntentId}");

      final success = await stripeService.releasePreAuthorization(
        paymentIntentId: order.paymentIntentId!,
      );

      if (success) {
        print("✅ [PAYMENT CANCEL] Payment intent cancelled successfully");

        order.paymentIntentStatus = 'cancelled';
        order.paymentCanceledAt = Timestamp.now();
        order.status = Constant.rideCanceled;
        order.updateDate = Timestamp.now();

        await saveOrderWithPaymentData(order);

        final transaction = WalletTransactionModel(
          id: Constant.getUuid(),
          amount: "0",
          createdDate: Timestamp.now(),
          paymentType: "Stripe",
          transactionId: order.id,
          userId: FireStoreUtils.getCurrentUid(),
          orderType: "city",
          userType: "customer",
          note: "Pre-authorization released for cancelled ride ${order.id}",
        );

        await FireStoreUtils.setWalletTransaction(transaction);
        print("💾 [TRANSACTION LOG] Cancellation logged: ${transaction.id}");

        return true;
      } else {
        print("❌ [PAYMENT CANCEL] Failed to cancel payment intent");
        return false;
      }
    } catch (e) {
      print("❌ [PAYMENT CANCEL] Error: $e");
      return false;
    }
  }

  static Future<List<String>> findStuckPaymentIntents() async {
    try {
      print("🔍 [STUCK PAYMENTS] Searching for uncaptured payment intents...");

      final cutoffTime = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(hours: 2)),
      );

      final snapshot = await _firestore
          .collection(CollectionName.orders)
          .where('paymentIntentStatus', whereIn: ['requires_capture', 'processing'])
          .where('preAuthCreatedAt', isLessThan: cutoffTime)
          .get();

      final stuckPaymentIntents = <String>[];

      for (var doc in snapshot.docs) {
        final order = OrderModel.fromJson(doc.data());
        if (order.paymentIntentId != null && order.paymentIntentId!.isNotEmpty) {
          stuckPaymentIntents.add(order.paymentIntentId!);
          print("   Found stuck payment: ${order.paymentIntentId}");
          print("     Order: ${order.id}");
          print("     Amount: ${order.preAuthAmount}");
          print("     Created: ${order.preAuthCreatedAt}");
        }
      }

      print("✅ [STUCK PAYMENTS] Found ${stuckPaymentIntents.length} stuck payments");
      return stuckPaymentIntents;
    } catch (e) {
      print("❌ [STUCK PAYMENTS] Error searching: $e");
      return [];
    }
  }

  static Future<int> captureAllStuckPayments({
    required StripeService stripeService,
  }) async {
    try {
      print("🚀 [EMERGENCY CAPTURE] Starting emergency capture process...");

      final cutoffTime = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(hours: 2)),
      );

      final snapshot = await _firestore
          .collection(CollectionName.orders)
          .where('paymentIntentStatus', whereIn: ['requires_capture', 'processing'])
          .where('preAuthCreatedAt', isLessThan: cutoffTime)
          .get();

      int successCount = 0;
      int failCount = 0;

      for (var doc in snapshot.docs) {
        try {
          final order = OrderModel.fromJson(doc.data());

          if (order.paymentIntentId == null || order.paymentIntentId!.isEmpty) {
            print("   ⚠️  Order ${order.id} has no payment intent ID");
            continue;
          }

          print("   Processing order: ${order.id}");
          print("   Payment Intent: ${order.paymentIntentId}");

          final captureAmount = order.preAuthAmount != null
              ? double.parse(order.preAuthAmount!)
              : (order.finalRate != null ? double.parse(order.finalRate!) : 0.0);

          if (captureAmount <= 0) {
            print("   ⚠️  Invalid capture amount: $captureAmount");
            continue;
          }

          final success = await capturePaymentWithRetry(
            order: order,
            stripeService: stripeService,
            finalAmount: captureAmount,
            maxRetries: 3,
          );

          if (success) {
            successCount++;
            print("   ✅ Successfully captured: ${order.paymentIntentId}");
          } else {
            failCount++;
            print("   ❌ Failed to capture: ${order.paymentIntentId}");
          }

          await Future.delayed(const Duration(seconds: 1));

        } catch (e) {
          failCount++;
          print("   ❌ Error processing order: $e");
        }
      }

      print("🎉 [EMERGENCY CAPTURE] Complete!");
      print("   Successful: $successCount");
      print("   Failed: $failCount");
      print("   Total: ${successCount + failCount}");

      return successCount;
    } catch (e) {
      print("❌ [EMERGENCY CAPTURE] Fatal error: $e");
      return 0;
    }
  }

  static Future<Map<String, dynamic>> getPaymentHealthReport() async {
    try {
      print("📊 [PAYMENT HEALTH] Generating report...");

      final now = DateTime.now();
      final last24Hours = Timestamp.fromDate(now.subtract(const Duration(hours: 24)));

      final allOrders = await _firestore
          .collection(CollectionName.orders)
          .where('createdDate', isGreaterThan: last24Hours)
          .get();

      int totalWithStripe = 0;
      int captured = 0;
      int uncaptured = 0;
      int cancelled = 0;
      int missing = 0;

      for (var doc in allOrders.docs) {
        final order = OrderModel.fromJson(doc.data());

        if (order.paymentType?.toLowerCase().contains('stripe') == true) {
          totalWithStripe++;

          if (order.paymentIntentId == null || order.paymentIntentId!.isEmpty) {
            missing++;
          } else if (order.paymentIntentStatus == 'captured') {
            captured++;
          } else if (order.paymentIntentStatus == 'cancelled') {
            cancelled++;
          } else {
            uncaptured++;
          }
        }
      }

      final report = {
        'timestamp': DateTime.now().toIso8601String(),
        'period': 'Last 24 hours',
        'total_stripe_orders': totalWithStripe,
        'captured': captured,
        'uncaptured': uncaptured,
        'cancelled': cancelled,
        'missing_payment_intent': missing,
        'health_score': totalWithStripe > 0
            ? ((captured + cancelled) / totalWithStripe * 100).toStringAsFixed(1)
            : '100.0',
      };

      print("📊 [PAYMENT HEALTH] Report:");
      report.forEach((key, value) {
        print("   $key: $value");
      });

      return report;
    } catch (e) {
      print("❌ [PAYMENT HEALTH] Error generating report: $e");
      return {'error': e.toString()};
    }
  }
}

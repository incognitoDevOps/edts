import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/services/stripe_service.dart';
import 'package:customer/utils/fire_store_utils.dart';

class AutoCaptureService {
  static Timer? _retryTimer;
  static bool _isRunning = false;

  static void startAutoCapture({Duration interval = const Duration(minutes: 15)}) {
    if (_isRunning) {
      print("⚠️  Auto-capture service already running");
      return;
    }

    _isRunning = true;
    print("🚀 Starting auto-capture service (interval: ${interval.inMinutes} minutes)");

    _retryTimer = Timer.periodic(interval, (timer) {
      _processUncapturedPayments();
    });

    _processUncapturedPayments();
  }

  static void stopAutoCapture() {
    if (_retryTimer != null) {
      _retryTimer!.cancel();
      _retryTimer = null;
      _isRunning = false;
      print("🛑 Auto-capture service stopped");
    }
  }

  static Future<void> _processUncapturedPayments() async {
    print("🔄 [AUTO-CAPTURE] Running scheduled capture check...");

    try {
      final cutoffTime = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(hours: 24)),
      );

      final ordersSnapshot = await FirebaseFirestore.instance
          .collection(CollectionName.orders)
          .where('paymentIntentStatus', isEqualTo: 'requires_capture')
          .where('createdDate', isGreaterThan: cutoffTime)
          .limit(20)
          .get();

      print("📊 Found ${ordersSnapshot.docs.length} orders requiring capture");

      if (ordersSnapshot.docs.isEmpty) {
        print("✅ No pending captures");
        return;
      }

      final paymentConfig = await FireStoreUtils().getPayment();
      if (paymentConfig?.strip == null) {
        print("❌ Stripe not configured");
        return;
      }

      final stripeService = StripeService(
        stripeSecret: paymentConfig.strip!.stripeSecret!,
        publishableKey: paymentConfig.strip!.clientpublishableKey ?? '',
      );

      int successCount = 0;
      int failCount = 0;

      for (final doc in ordersSnapshot.docs) {
        try {
          final order = OrderModel.fromJson(doc.data());

          if (order.paymentIntentId == null || order.paymentIntentId!.isEmpty) {
            print("⚠️  Skipping order ${order.id} - no payment intent");
            continue;
          }

          print("💳 Processing order ${order.id}...");

          final captureResult = await stripeService.capturePreAuthorization(
            paymentIntentId: order.paymentIntentId!,
            finalAmount: order.finalRate ?? '0',
          );

          if (captureResult['success'] == true) {
            order.paymentIntentStatus = 'succeeded';
            order.paymentStatus = true;
            await FireStoreUtils.setOrder(order);

            successCount++;
            print("✅ Captured: ${order.id}");

            await _logCaptureSuccess(order);
          } else {
            failCount++;
            print("❌ Failed: ${order.id} - ${captureResult['error']}");

            await _logCaptureFailure(order, captureResult['error'].toString());
          }

          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          failCount++;
          print("❌ Error processing order: $e");
        }
      }

      print("📊 Auto-capture complete: $successCount succeeded, $failCount failed");

      await _recordBatchResult(
        totalProcessed: ordersSnapshot.docs.length,
        successCount: successCount,
        failCount: failCount,
      );
    } catch (e) {
      print("❌ Error in auto-capture service: $e");
    }
  }

  static Future<void> _logCaptureSuccess(OrderModel order) async {
    try {
      await FirebaseFirestore.instance
          .collection('auto_capture_log')
          .add({
        'orderId': order.id,
        'paymentIntentId': order.paymentIntentId,
        'amount': order.finalRate,
        'status': 'success',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("❌ Failed to log capture success: $e");
    }
  }

  static Future<void> _logCaptureFailure(OrderModel order, String error) async {
    try {
      await FirebaseFirestore.instance
          .collection('capture_failures')
          .add({
        'orderId': order.id,
        'paymentIntentId': order.paymentIntentId,
        'amount': order.finalRate,
        'error': error,
        'source': 'auto_capture_service',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("❌ Failed to log capture failure: $e");
    }
  }

  static Future<void> _recordBatchResult({
    required int totalProcessed,
    required int successCount,
    required int failCount,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('auto_capture_batches')
          .add({
        'totalProcessed': totalProcessed,
        'successCount': successCount,
        'failCount': failCount,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("❌ Failed to record batch result: $e");
    }
  }

  static Future<void> retryFailedOrder(String orderId) async {
    print("🔄 Manually retrying order: $orderId");

    try {
      final orderDoc = await FirebaseFirestore.instance
          .collection(CollectionName.orders)
          .doc(orderId)
          .get();

      if (!orderDoc.exists) {
        print("❌ Order not found");
        return;
      }

      final order = OrderModel.fromJson(orderDoc.data()!);

      if (order.paymentIntentStatus == 'succeeded' ||
          order.paymentIntentStatus == 'captured') {
        print("ℹ️  Payment already captured");
        return;
      }

      final paymentConfig = await FireStoreUtils().getPayment();
      if (paymentConfig?.strip == null) {
        print("❌ Stripe not configured");
        return;
      }

      final stripeService = StripeService(
        stripeSecret: paymentConfig.strip!.stripeSecret!,
        publishableKey: paymentConfig.strip!.clientpublishableKey ?? '',
      );

      final captureResult = await stripeService.capturePreAuthorization(
        paymentIntentId: order.paymentIntentId!,
        finalAmount: order.finalRate ?? '0',
      );

      if (captureResult['success'] == true) {
        order.paymentIntentStatus = 'succeeded';
        order.paymentStatus = true;
        await FireStoreUtils.setOrder(order);

        print("✅ Manual retry successful");
        await _logCaptureSuccess(order);
      } else {
        print("❌ Manual retry failed: ${captureResult['error']}");
        await _logCaptureFailure(order, captureResult['error'].toString());
      }
    } catch (e) {
      print("❌ Error in manual retry: $e");
    }
  }

  static Future<Map<String, dynamic>> getServiceStatus() async {
    try {
      final uncapturedSnapshot = await FirebaseFirestore.instance
          .collection(CollectionName.orders)
          .where('paymentIntentStatus', isEqualTo: 'requires_capture')
          .get();

      final recentBatchesSnapshot = await FirebaseFirestore.instance
          .collection('auto_capture_batches')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      int totalSuccess = 0;
      int totalFail = 0;

      for (final doc in recentBatchesSnapshot.docs) {
        totalSuccess += (doc.data()['successCount'] as int?) ?? 0;
        totalFail += (doc.data()['failCount'] as int?) ?? 0;
      }

      return {
        'isRunning': _isRunning,
        'pendingCapturesCount': uncapturedSnapshot.docs.length,
        'recentSuccessCount': totalSuccess,
        'recentFailCount': totalFail,
        'successRate': (totalSuccess + totalFail) > 0
            ? (totalSuccess / (totalSuccess + totalFail) * 100)
            : 0.0,
      };
    } catch (e) {
      print("❌ Error getting service status: $e");
      return {
        'error': e.toString(),
      };
    }
  }
}

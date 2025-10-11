import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/collection_name.dart';

class PaymentCaptureMonitor {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<Map<String, dynamic>> getCaptureMetrics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();

    try {
      final ordersSnapshot = await _firestore
          .collection(CollectionName.orders)
          .where('createdDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdDate', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      int totalStripeOrders = 0;
      int capturedOrders = 0;
      int uncapturedOrders = 0;
      int failedCaptures = 0;
      double totalCapturedAmount = 0;
      double totalUncapturedAmount = 0;

      for (final doc in ordersSnapshot.docs) {
        final data = doc.data();
        final paymentType = data['paymentType'] as String?;
        final paymentIntentId = data['paymentIntentId'] as String?;
        final paymentIntentStatus = data['paymentIntentStatus'] as String?;
        final finalRate = data['finalRate'] as String?;

        if (paymentType?.toLowerCase().contains('stripe') == true &&
            paymentIntentId != null) {
          totalStripeOrders++;

          final amount = double.tryParse(finalRate ?? '0') ?? 0;

          if (paymentIntentStatus == 'succeeded' || paymentIntentStatus == 'captured') {
            capturedOrders++;
            totalCapturedAmount += amount;
          } else if (paymentIntentStatus == 'requires_capture') {
            uncapturedOrders++;
            totalUncapturedAmount += amount;
          } else if (paymentIntentStatus == 'canceled' ||
                     paymentIntentStatus == 'failed') {
            failedCaptures++;
          }
        }
      }

      final captureRate = totalStripeOrders > 0
          ? (capturedOrders / totalStripeOrders * 100)
          : 0.0;

      return {
        'totalStripeOrders': totalStripeOrders,
        'capturedOrders': capturedOrders,
        'uncapturedOrders': uncapturedOrders,
        'failedCaptures': failedCaptures,
        'captureRate': captureRate,
        'totalCapturedAmount': totalCapturedAmount,
        'totalUncapturedAmount': totalUncapturedAmount,
        'dateRange': {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
      };
    } catch (e) {
      print("❌ Error getting capture metrics: $e");
      return {
        'error': e.toString(),
      };
    }
  }

  static Future<List<Map<String, dynamic>>> getCaptureFailures({
    int limit = 50,
  }) async {
    try {
      final failuresSnapshot = await _firestore
          .collection('capture_failures')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return failuresSnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      print("❌ Error getting capture failures: $e");
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getUncapturedOrders({
    int limit = 100,
  }) async {
    try {
      final ordersSnapshot = await _firestore
          .collection(CollectionName.orders)
          .where('paymentIntentStatus', whereIn: ['requires_capture', 'requires_payment_method'])
          .orderBy('createdDate', descending: true)
          .limit(limit)
          .get();

      return ordersSnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      print("❌ Error getting uncaptured orders: $e");
      return [];
    }
  }

  static Future<void> recordCaptureAttempt({
    required String orderId,
    required String paymentIntentId,
    required bool success,
    String? error,
    String? amount,
  }) async {
    try {
      await _firestore.collection('capture_attempts').add({
        'orderId': orderId,
        'paymentIntentId': paymentIntentId,
        'success': success,
        'error': error,
        'amount': amount,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("❌ Error recording capture attempt: $e");
    }
  }

  static Stream<List<Map<String, dynamic>>> streamUncapturedPayments() {
    return _firestore
        .collection(CollectionName.orders)
        .where('paymentIntentStatus', whereIn: ['requires_capture'])
        .orderBy('createdDate', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  static Future<bool> checkOrderCaptureStatus(String orderId) async {
    try {
      final orderDoc = await _firestore
          .collection(CollectionName.orders)
          .doc(orderId)
          .get();

      if (!orderDoc.exists) return false;

      final data = orderDoc.data();
      final status = data?['paymentIntentStatus'] as String?;

      return status == 'succeeded' || status == 'captured';
    } catch (e) {
      print("❌ Error checking capture status: $e");
      return false;
    }
  }

  static Future<void> alertUncapturedThreshold({
    required int threshold,
    required Function(int count, double amount) onThresholdExceeded,
  }) async {
    try {
      final uncapturedOrders = await getUncapturedOrders();

      if (uncapturedOrders.length >= threshold) {
        double totalAmount = 0;
        for (final order in uncapturedOrders) {
          final amount = double.tryParse(order['finalRate']?.toString() ?? '0') ?? 0;
          totalAmount += amount;
        }

        await onThresholdExceeded(uncapturedOrders.length, totalAmount);
      }
    } catch (e) {
      print("❌ Error checking threshold: $e");
    }
  }

  static Future<Map<String, dynamic>> getDailyReport() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return await getCaptureMetrics(
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }
}

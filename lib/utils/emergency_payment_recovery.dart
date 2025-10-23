import 'dart:developer';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/model/payment_model.dart';
import 'package:customer/services/payment_persistence_service.dart';
import 'package:customer/services/stripe_service.dart';
import 'package:customer/utils/fire_store_utils.dart';

class EmergencyPaymentRecovery {
  static Future<Map<String, dynamic>> captureAllStuckPayments() async {
    try {
      print("🚨 [EMERGENCY RECOVERY] Starting emergency payment capture...");
      print("   This will capture ALL stuck pre-authorized payments");
      print("   Payments stuck for more than 2 hours will be processed");

      ShowToastDialog.showLoader("Processing stuck payments...");

      final paymentConfig = await FireStoreUtils().getPayment();
      if (paymentConfig == null) {
        ShowToastDialog.closeLoader();
        return {
          'success': false,
          'error': 'Payment configuration not available',
        };
      }

      final stripeConfig = paymentConfig.strip;
      if (stripeConfig == null || stripeConfig.stripeSecret == null) {
        ShowToastDialog.closeLoader();
        return {
          'success': false,
          'error': 'Stripe configuration not available',
        };
      }

      final stripeService = StripeService(
        stripeSecret: stripeConfig.stripeSecret!,
        publishableKey: stripeConfig.clientpublishableKey ?? '',
      );

      final capturedCount = await PaymentPersistenceService.captureAllStuckPayments(
        stripeService: stripeService,
      );

      ShowToastDialog.closeLoader();

      final result = {
        'success': true,
        'captured_count': capturedCount,
        'message': 'Successfully captured $capturedCount stuck payment${capturedCount != 1 ? 's' : ''}',
      };

      print("🎉 [EMERGENCY RECOVERY] Complete: $result");
      return result;
    } catch (e) {
      ShowToastDialog.closeLoader();
      log("❌ [EMERGENCY RECOVERY] Error: $e");
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<List<String>> findStuckPayments() async {
    try {
      print("🔍 [EMERGENCY RECOVERY] Searching for stuck payments...");

      final stuckPayments = await PaymentPersistenceService.findStuckPaymentIntents();

      print("📊 [EMERGENCY RECOVERY] Found ${stuckPayments.length} stuck payments");
      return stuckPayments;
    } catch (e) {
      log("❌ [EMERGENCY RECOVERY] Search error: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>> generatePaymentHealthReport() async {
    try {
      print("📊 [HEALTH REPORT] Generating payment health report...");

      final report = await PaymentPersistenceService.getPaymentHealthReport();

      print("✅ [HEALTH REPORT] Report generated successfully");
      return report;
    } catch (e) {
      log("❌ [HEALTH REPORT] Error: $e");
      return {
        'error': e.toString(),
      };
    }
  }

  static Future<void> runFullRecoveryProcess() async {
    try {
      print("\n════════════════════════════════════════════");
      print("🚨 STARTING FULL PAYMENT RECOVERY PROCESS 🚨");
      print("════════════════════════════════════════════\n");

      print("STEP 1: Generating health report...");
      final healthReport = await generatePaymentHealthReport();
      print("\n📊 HEALTH REPORT:");
      healthReport.forEach((key, value) {
        print("   $key: $value");
      });

      print("\n" + "─" * 48 + "\n");

      print("STEP 2: Finding stuck payments...");
      final stuckPayments = await findStuckPayments();
      print("   Found: ${stuckPayments.length} stuck payments");

      if (stuckPayments.isEmpty) {
        print("\n✅ NO STUCK PAYMENTS FOUND - System is healthy!\n");
        print("════════════════════════════════════════════\n");
        return;
      }

      print("\n" + "─" * 48 + "\n");

      print("STEP 3: Capturing stuck payments...");
      final captureResult = await captureAllStuckPayments();

      print("\n📊 CAPTURE RESULTS:");
      captureResult.forEach((key, value) {
        print("   $key: $value");
      });

      print("\n" + "─" * 48 + "\n");

      print("STEP 4: Generating post-recovery health report...");
      final postHealthReport = await generatePaymentHealthReport();
      print("\n📊 POST-RECOVERY HEALTH REPORT:");
      postHealthReport.forEach((key, value) {
        print("   $key: $value");
      });

      print("\n════════════════════════════════════════════");
      print("🎉 RECOVERY PROCESS COMPLETE 🎉");
      print("════════════════════════════════════════════\n");
    } catch (e) {
      log("❌ [FULL RECOVERY] Fatal error: $e");
      print("\n════════════════════════════════════════════");
      print("❌ RECOVERY PROCESS FAILED ❌");
      print("Error: $e");
      print("════════════════════════════════════════════\n");
    }
  }

  static void runRecoveryInBackground() {
    Future.microtask(() async {
      try {
        print("🔄 [BACKGROUND RECOVERY] Starting background payment recovery...");

        final stuckPayments = await findStuckPayments();

        if (stuckPayments.isNotEmpty) {
          print("⚠️  [BACKGROUND RECOVERY] Found ${stuckPayments.length} stuck payments");
          print("   Running automatic capture...");

          await captureAllStuckPayments();

          print("✅ [BACKGROUND RECOVERY] Background recovery complete");
        } else {
          print("✅ [BACKGROUND RECOVERY] No stuck payments found");
        }
      } catch (e) {
        log("❌ [BACKGROUND RECOVERY] Error: $e");
      }
    });
  }

  static Future<bool> verifyPaymentDataIntegrity(String orderId) async {
    try {
      print("🔍 [INTEGRITY CHECK] Verifying payment data for order: $orderId");

      final order = await PaymentPersistenceService.getOrderWithPaymentRecovery(orderId);

      if (order == null) {
        print("❌ [INTEGRITY CHECK] Order not found");
        return false;
      }

      print("📋 [INTEGRITY CHECK] Order data:");
      print("   Order ID: ${order.id}");
      print("   Payment Type: ${order.paymentType}");
      print("   Payment Intent ID: ${order.paymentIntentId}");
      print("   Pre-auth Amount: ${order.preAuthAmount}");
      print("   Status: ${order.paymentIntentStatus}");
      print("   Created: ${order.preAuthCreatedAt}");
      print("   Captured: ${order.paymentCapturedAt}");
      print("   Cancelled: ${order.paymentCanceledAt}");

      bool isValid = true;

      if (order.paymentType?.toLowerCase().contains('stripe') == true) {
        if (order.paymentIntentId == null || order.paymentIntentId!.isEmpty) {
          print("❌ [INTEGRITY CHECK] Missing payment intent ID for Stripe payment");
          isValid = false;
        }

        if (order.preAuthAmount == null || order.preAuthAmount!.isEmpty) {
          print("⚠️  [INTEGRITY CHECK] Missing pre-auth amount");
        }

        if (order.paymentIntentStatus == null || order.paymentIntentStatus!.isEmpty) {
          print("⚠️  [INTEGRITY CHECK] Missing payment intent status");
        }
      }

      if (isValid) {
        print("✅ [INTEGRITY CHECK] Payment data is valid");
      } else {
        print("❌ [INTEGRITY CHECK] Payment data has issues");
      }

      return isValid;
    } catch (e) {
      log("❌ [INTEGRITY CHECK] Error: $e");
      return false;
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/model/payment_model.dart';
import 'package:customer/services/stripe_service.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmergencyCaptureToolScreen extends StatefulWidget {
  const EmergencyCaptureToolScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyCaptureToolScreen> createState() =>
      _EmergencyCaptureToolScreenState();
}

class _EmergencyCaptureToolScreenState
    extends State<EmergencyCaptureToolScreen> {
  List<OrderModel> uncapturedOrders = [];
  bool isLoading = true;
  Map<String, String> captureStatus = {};
  Map<String, double> captureProgress = {};

  @override
  void initState() {
    super.initState();
    _loadUncapturedOrders();
  }

  Future<void> _loadUncapturedOrders() async {
    try {
      setState(() => isLoading = true);

      final ordersSnapshot = await FirebaseFirestore.instance
          .collection(CollectionName.orders)
          .where('paymentIntentStatus', isEqualTo: 'requires_capture')
          .where('paymentStatus', isEqualTo: false)
          .get();

      uncapturedOrders = ordersSnapshot.docs
          .map((doc) => OrderModel.fromJson(doc.data()))
          .where((order) =>
              order.paymentIntentId != null &&
              order.paymentIntentId!.isNotEmpty)
          .toList();

      print("🔍 Found ${uncapturedOrders.length} uncaptured orders");

      setState(() => isLoading = false);
    } catch (e) {
      print("❌ Error loading uncaptured orders: $e");
      setState(() => isLoading = false);
      ShowToastDialog.showToast("Failed to load uncaptured orders: $e");
    }
  }

  Future<void> _captureAllPayments() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Capture All Payments"),
        content: Text(
            "This will attempt to capture ${uncapturedOrders.length} uncaptured payments. Continue?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _executeBatchCapture();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text("Capture All"),
          ),
        ],
      ),
    );
  }

  Future<void> _executeBatchCapture() async {
    try {
      final paymentModel = await FireStoreUtils().getPayment();
      if (paymentModel == null || paymentModel.strip?.stripeSecret == null) {
        ShowToastDialog.showToast("Stripe configuration not found");
        return;
      }

      final stripeService = StripeService(
        stripeSecret: paymentModel.strip!.stripeSecret!,
        publishableKey: paymentModel.strip!.clientpublishableKey ?? '',
      );

      int successCount = 0;
      int failCount = 0;

      for (int i = 0; i < uncapturedOrders.length; i++) {
        final order = uncapturedOrders[i];

        setState(() {
          captureProgress[order.id!] = (i + 1) / uncapturedOrders.length;
          captureStatus[order.id!] = "Processing...";
        });

        try {
          final result = await _captureOrderPayment(order, stripeService);

          setState(() {
            if (result) {
              captureStatus[order.id!] = "✅ Captured";
              successCount++;
            } else {
              captureStatus[order.id!] = "❌ Failed";
              failCount++;
            }
          });

          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          setState(() {
            captureStatus[order.id!] = "❌ Error: $e";
            failCount++;
          });
        }
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Batch Capture Complete"),
          content: Text(
              "Success: $successCount\nFailed: $failCount\n\nTotal: ${uncapturedOrders.length}"),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _loadUncapturedOrders();
              },
              child: Text("Refresh"),
            ),
          ],
        ),
      );
    } catch (e) {
      print("❌ Batch capture error: $e");
      ShowToastDialog.showToast("Batch capture failed: $e");
    }
  }

  Future<bool> _captureOrderPayment(
      OrderModel order, StripeService stripeService) async {
    try {
      print("💳 Capturing payment for order: ${order.id}");
      print("   PaymentIntent: ${order.paymentIntentId}");
      print("   Amount: ${order.finalRate}");

      final captureResult = await stripeService.capturePreAuthorization(
        paymentIntentId: order.paymentIntentId!,
        finalAmount: order.finalRate!,
      );

      if (captureResult['success'] == true) {
        await FirebaseFirestore.instance
            .collection(CollectionName.orders)
            .doc(order.id)
            .update({
          'paymentIntentStatus': 'succeeded',
          'paymentStatus': true,
          'paymentCapturedAt': FieldValue.serverTimestamp(),
        });

        print("✅ Order ${order.id} payment captured successfully");
        return true;
      } else {
        print(
            "❌ Failed to capture order ${order.id}: ${captureResult['error']}");
        return false;
      }
    } catch (e) {
      print("❌ Exception capturing order ${order.id}: $e");
      return false;
    }
  }

  Future<void> _captureSinglePayment(OrderModel order) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Capture Payment"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Order ID: ${order.id}"),
            Text("Payment Intent: ${order.paymentIntentId}"),
            Text("Amount: \$${order.finalRate}"),
            const SizedBox(height: 16),
            Text("Capture this payment?"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _executeSingleCapture(order);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text("Capture"),
          ),
        ],
      ),
    );
  }

  Future<void> _executeSingleCapture(OrderModel order) async {
    try {
      ShowToastDialog.showLoader("Capturing payment...");

      final paymentModel = await FireStoreUtils().getPayment();
      if (paymentModel == null || paymentModel.strip?.stripeSecret == null) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Stripe configuration not found");
        return;
      }

      final stripeService = StripeService(
        stripeSecret: paymentModel.strip!.stripeSecret!,
        publishableKey: paymentModel.strip!.clientpublishableKey ?? '',
      );

      final success = await _captureOrderPayment(order, stripeService);

      ShowToastDialog.closeLoader();

      if (success) {
        ShowToastDialog.showToast("Payment captured successfully!");
        await _loadUncapturedOrders();
      } else {
        ShowToastDialog.showToast("Failed to capture payment");
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Emergency Capture Tool"),
        backgroundColor: Colors.red,
        actions: [
          if (uncapturedOrders.isNotEmpty)
            IconButton(
              onPressed: _captureAllPayments,
              icon: Icon(Icons.download_done),
              tooltip: "Capture All",
            ),
          IconButton(
            onPressed: _loadUncapturedOrders,
            icon: Icon(Icons.refresh),
            tooltip: "Refresh",
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : uncapturedOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle,
                          size: 64, color: Colors.green),
                      SizedBox(height: 16),
                      Text(
                        "No uncaptured payments found!",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "All payments have been successfully captured.",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      color: Colors.red.shade50,
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "${uncapturedOrders.length} uncaptured payment(s) found",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: uncapturedOrders.length,
                        itemBuilder: (context, index) {
                          final order = uncapturedOrders[index];
                          final status = captureStatus[order.id] ?? "";
                          final progress = captureProgress[order.id] ?? 0.0;

                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(
                                "Order: ${order.id}",
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Text(
                                      "Payment Intent: ${order.paymentIntentId}"),
                                  Text("Amount: \$${order.finalRate}"),
                                  Text(
                                      "From: ${order.sourceLocationName ?? 'Unknown'}"),
                                  Text(
                                      "To: ${order.destinationLocationName ?? 'Unknown'}"),
                                  if (status.isNotEmpty) ...[
                                    SizedBox(height: 4),
                                    Text(
                                      status,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: status.contains("✅")
                                            ? Colors.green
                                            : status.contains("❌")
                                                ? Colors.red
                                                : Colors.orange,
                                      ),
                                    ),
                                  ],
                                  if (progress > 0 && progress < 1.0) ...[
                                    SizedBox(height: 4),
                                    LinearProgressIndicator(value: progress),
                                  ],
                                ],
                              ),
                              trailing: status.contains("✅")
                                  ? Icon(Icons.check_circle,
                                      color: Colors.green)
                                  : IconButton(
                                      icon: Icon(Icons.download,
                                          color: Colors.green),
                                      onPressed: () =>
                                          _captureSinglePayment(order),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

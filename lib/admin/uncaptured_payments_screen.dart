import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/services/stripe_service.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UncapturedPaymentsScreen extends StatefulWidget {
  const UncapturedPaymentsScreen({Key? key}) : super(key: key);

  @override
  State<UncapturedPaymentsScreen> createState() => _UncapturedPaymentsScreenState();
}

class _UncapturedPaymentsScreenState extends State<UncapturedPaymentsScreen> {
  bool isLoading = true;
  List<OrderModel> uncapturedOrders = [];
  Map<String, bool> processingOrders = {};

  @override
  void initState() {
    super.initState();
    _loadUncapturedPayments();
  }

  Future<void> _loadUncapturedPayments() async {
    setState(() => isLoading = true);

    try {
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection(CollectionName.orders)
          .where('paymentIntentStatus', whereIn: ['requires_capture', 'requires_payment_method'])
          .get();

      final orders = ordersSnapshot.docs
          .map((doc) => OrderModel.fromJson(doc.data()))
          .where((order) => order.paymentIntentId != null)
          .toList();

      orders.sort((a, b) => (b.createdDate?.millisecondsSinceEpoch ?? 0)
          .compareTo(a.createdDate?.millisecondsSinceEpoch ?? 0));

      setState(() {
        uncapturedOrders = orders;
        isLoading = false;
      });

      print("📊 Found ${orders.length} orders with uncaptured payments");
    } catch (e) {
      print("❌ Error loading uncaptured payments: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _capturePayment(OrderModel order) async {
    if (processingOrders[order.id] == true) return;

    setState(() => processingOrders[order.id!] = true);
    ShowToastDialog.showLoader("Capturing payment...");

    try {
      final paymentConfig = await FireStoreUtils().getPayment();
      if (paymentConfig?.strip == null) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Stripe not configured");
        setState(() => processingOrders[order.id!] = false);
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

      ShowToastDialog.closeLoader();

      if (captureResult['success'] == true) {
        order.paymentIntentStatus = 'succeeded';
        order.paymentStatus = true;
        await FireStoreUtils.setOrder(order);

        ShowToastDialog.showToast("Payment captured successfully!");

        setState(() {
          uncapturedOrders.remove(order);
          processingOrders.remove(order.id);
        });
      } else {
        ShowToastDialog.showToast("Capture failed: ${captureResult['error']}");
        setState(() => processingOrders[order.id!] = false);
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Error: $e");
      setState(() => processingOrders[order.id!] = false);
    }
  }

  Future<void> _bulkCapture() async {
    if (uncapturedOrders.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Bulk Capture"),
        content: Text(
          "Capture ${uncapturedOrders.length} pending payments?\n\n"
          "This will attempt to capture all uncaptured Stripe payments."
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Capture All"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    ShowToastDialog.showLoader("Processing bulk capture...");

    int successCount = 0;
    int failCount = 0;

    for (final order in List.from(uncapturedOrders)) {
      try {
        final paymentConfig = await FireStoreUtils().getPayment();
        if (paymentConfig?.strip == null) continue;

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
          successCount++;
        } else {
          failCount++;
        }

        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        failCount++;
      }
    }

    ShowToastDialog.closeLoader();
    ShowToastDialog.showToast(
      "Bulk capture complete: $successCount succeeded, $failCount failed"
    );

    _loadUncapturedPayments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Uncaptured Payments"),
        actions: [
          if (uncapturedOrders.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadUncapturedPayments,
            ),
          if (uncapturedOrders.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.check_circle),
              onPressed: _bulkCapture,
              tooltip: "Bulk Capture",
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : uncapturedOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, size: 80, color: Colors.green),
                      const SizedBox(height: 16),
                      const Text(
                        "No Uncaptured Payments",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text("All Stripe payments have been captured"),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUncapturedPayments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: uncapturedOrders.length,
                    itemBuilder: (context, index) {
                      final order = uncapturedOrders[index];
                      final isProcessing = processingOrders[order.id] ?? false;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Order #${order.id?.substring(0, 8)}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    Constant.amountShow(
                                      amount: order.finalRate ?? '0'
                                    ),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow("From", order.sourceLocationName ?? "Unknown"),
                              _buildInfoRow("To", order.destinationLocationName ?? "Unknown"),
                              _buildInfoRow(
                                "Created",
                                order.createdDate != null
                                    ? _formatDate(order.createdDate!)
                                    : "Unknown",
                              ),
                              _buildInfoRow("Status", order.paymentIntentStatus ?? "Unknown"),
                              _buildInfoRow(
                                "Payment Intent",
                                order.paymentIntentId?.substring(0, 20) ?? "Unknown",
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: isProcessing
                                      ? null
                                      : () => _capturePayment(order),
                                  icon: isProcessing
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.payment),
                                  label: Text(
                                    isProcessing ? "Processing..." : "Capture Payment"
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}

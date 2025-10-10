import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class PaymentMonitoringDashboard extends StatefulWidget {
  const PaymentMonitoringDashboard({Key? key}) : super(key: key);

  @override
  State<PaymentMonitoringDashboard> createState() =>
      _PaymentMonitoringDashboardState();
}

class _PaymentMonitoringDashboardState
    extends State<PaymentMonitoringDashboard> {
  int totalOrders = 0;
  int uncapturedPayments = 0;
  int capturedPayments = 0;
  int canceledPayments = 0;
  double totalUncapturedAmount = 0.0;
  double totalCapturedAmount = 0.0;
  bool isLoading = true;

  List<OrderModel> recentUncaptured = [];

  @override
  void initState() {
    super.initState();
    _loadPaymentStats();
  }

  Future<void> _loadPaymentStats() async {
    try {
      setState(() => isLoading = true);

      final now = DateTime.now();
      final last30Days = now.subtract(const Duration(days: 30));

      // Get all Stripe orders from last 30 days
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection(CollectionName.orders)
          .where('paymentType', isEqualTo: 'Stripe')
          .where('createdDate', isGreaterThanOrEqualTo: Timestamp.fromDate(last30Days))
          .get();

      totalOrders = ordersSnapshot.size;
      uncapturedPayments = 0;
      capturedPayments = 0;
      canceledPayments = 0;
      totalUncapturedAmount = 0.0;
      totalCapturedAmount = 0.0;
      recentUncaptured = [];

      for (var doc in ordersSnapshot.docs) {
        final order = OrderModel.fromJson(doc.data());

        if (order.paymentIntentId != null && order.paymentIntentId!.isNotEmpty) {
          final status = order.paymentIntentStatus ?? 'unknown';
          final amount = double.tryParse(order.finalRate ?? '0') ?? 0.0;

          if (status == 'requires_capture') {
            uncapturedPayments++;
            totalUncapturedAmount += amount;
            recentUncaptured.add(order);
          } else if (status == 'succeeded' || status == 'captured') {
            capturedPayments++;
            totalCapturedAmount += amount;
          } else if (status == 'canceled') {
            canceledPayments++;
          }
        }
      }

      // Sort uncaptured by date (most recent first)
      recentUncaptured.sort((a, b) {
        final aDate = a.createdDate?.toDate() ?? DateTime(2000);
        final bDate = b.createdDate?.toDate() ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });

      // Keep only last 10
      if (recentUncaptured.length > 10) {
        recentUncaptured = recentUncaptured.sublist(0, 10);
      }

      setState(() => isLoading = false);
    } catch (e) {
      print("❌ Error loading payment stats: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Payment Monitoring"),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            onPressed: _loadPaymentStats,
            icon: Icon(Icons.refresh),
            tooltip: "Refresh",
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPaymentStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      "Last 30 Days Overview",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Real-time payment status tracking",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 20),

                    // Stats Cards
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        _buildStatCard(
                          "Total Orders",
                          totalOrders.toString(),
                          Icons.receipt_long,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          "Uncaptured",
                          uncapturedPayments.toString(),
                          Icons.warning,
                          Colors.red,
                          subtitle: Constant.amountShow(
                              amount: totalUncapturedAmount.toStringAsFixed(2)),
                        ),
                        _buildStatCard(
                          "Captured",
                          capturedPayments.toString(),
                          Icons.check_circle,
                          Colors.green,
                          subtitle: Constant.amountShow(
                              amount: totalCapturedAmount.toStringAsFixed(2)),
                        ),
                        _buildStatCard(
                          "Canceled",
                          canceledPayments.toString(),
                          Icons.cancel,
                          Colors.orange,
                        ),
                      ],
                    ),
                    SizedBox(height: 24),

                    // Critical Alert
                    if (uncapturedPayments > 0)
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: Colors.red, size: 28),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Action Required",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: Colors.red,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "$uncapturedPayments payment(s) need immediate capture",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 24),

                    // Recent Uncaptured List
                    if (recentUncaptured.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Recent Uncaptured Payments",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            "${recentUncaptured.length}",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      ...recentUncaptured.map((order) => _buildUncapturedCard(order)),
                    ],

                    // Success Message
                    if (uncapturedPayments == 0)
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green, size: 32),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "All Clear!",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: Colors.green.shade900,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "No uncaptured payments requiring attention",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color,
      {String? subtitle}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUncapturedCard(OrderModel order) {
    final date = order.createdDate?.toDate() ?? DateTime.now();
    final formattedDate = DateFormat('MMM dd, yyyy HH:mm').format(date);
    final amount = Constant.amountShow(amount: order.finalRate ?? '0');

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.warning, color: Colors.red),
        ),
        title: Text(
          "Order: ${order.id?.substring(0, 12)}...",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text("Amount: $amount"),
            Text("Date: $formattedDate"),
            Text("PI: ${order.paymentIntentId?.substring(0, 20)}..."),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}

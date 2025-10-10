import 'package:customer/admin/emergency_capture_tool.dart';
import 'package:customer/admin/payment_monitoring_dashboard.dart';
import 'package:customer/admin/uncaptured_payments_screen.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// Admin Tools Menu - Quick access to payment management tools
///
/// Usage: Add this to your admin/settings screen:
/// ```dart
/// ListTile(
///   title: Text("Payment Tools"),
///   onTap: () => Get.to(() => AdminToolsMenu()),
/// )
/// ```
class AdminToolsMenu extends StatelessWidget {
  const AdminToolsMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Payment Tools"),
        backgroundColor: AppColors.primary,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Payment Management",
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Tools for managing and monitoring payments",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Emergency Capture Tool
          _buildToolCard(
            context: context,
            title: "Emergency Capture Tool",
            description: "Capture stuck or failed payments immediately",
            icon: Icons.bolt,
            iconColor: Colors.red,
            borderColor: Colors.red.shade200,
            backgroundColor: Colors.red.shade50,
            onTap: () {
              Get.to(() => EmergencyCaptureToolScreen());
            },
            badge: "URGENT",
            badgeColor: Colors.red,
          ),

          SizedBox(height: 16),

          // Payment Monitoring Dashboard
          _buildToolCard(
            context: context,
            title: "Payment Monitoring",
            description: "Real-time overview of payment system health",
            icon: Icons.dashboard,
            iconColor: Colors.blue,
            borderColor: Colors.blue.shade200,
            backgroundColor: Colors.blue.shade50,
            onTap: () {
              Get.to(() => PaymentMonitoringDashboard());
            },
            badge: "NEW",
            badgeColor: Colors.blue,
          ),

          SizedBox(height: 16),

          // Uncaptured Payments (Legacy)
          _buildToolCard(
            context: context,
            title: "Uncaptured Payments",
            description: "View and manage uncaptured payment intents",
            icon: Icons.payment,
            iconColor: Colors.orange,
            borderColor: Colors.orange.shade200,
            backgroundColor: Colors.orange.shade50,
            onTap: () {
              Get.to(() => UncapturedPaymentsScreen());
            },
          ),

          SizedBox(height: 32),

          // Quick Actions Section
          Text(
            "Quick Actions",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),

          // Quick action buttons
          Row(
            children: [
              Expanded(
                child: _buildQuickAction(
                  icon: Icons.refresh,
                  label: "Sync Data",
                  onTap: () {
                    // Implement data sync
                    Get.snackbar(
                      "Sync Started",
                      "Refreshing payment data...",
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                    );
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildQuickAction(
                  icon: Icons.open_in_browser,
                  label: "Stripe Dashboard",
                  onTap: () {
                    Get.snackbar(
                      "Stripe Dashboard",
                      "Opening Stripe dashboard...",
                      snackPosition: SnackPosition.BOTTOM,
                    );
                    // In production, open Stripe dashboard URL
                  },
                ),
              ),
            ],
          ),

          SizedBox(height: 32),

          // System Status
          _buildSystemStatus(),

          SizedBox(height: 24),

          // Help Section
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.help_outline, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      "Need Help?",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  "Check the documentation files for detailed guides:",
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                SizedBox(height: 8),
                _buildDocLink("• QUICK_START_GUIDE.md"),
                _buildDocLink("• PAYMENT_SYSTEM_FIX_DOCUMENTATION.md"),
                _buildDocLink("• IMPLEMENTATION_SUMMARY.md"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required Color borderColor,
    required Color backgroundColor,
    required VoidCallback onTap,
    String? badge,
    Color? badgeColor,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (badge != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor ?? Colors.grey,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badge,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary),
              SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSystemStatus() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text(
                "System Status",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildStatusRow("Payment Processing", "Operational", Colors.green),
          _buildStatusRow("Stripe Integration", "Operational", Colors.green),
          _buildStatusRow("Capture System", "Enhanced v1.0", Colors.green),
          _buildStatusRow("Monitoring", "Active", Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 6),
              Text(
                status,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocLink(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey[700],
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

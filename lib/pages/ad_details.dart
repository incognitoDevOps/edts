// ignore_for_file: unused_element, library_private_types_in_public_api

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:moderntr/constants.dart';

class AdDetailsPage extends StatefulWidget {
  final String adId; // ad ID passed from the ads page

  const AdDetailsPage({super.key, required this.adId});

  @override
  _AdDetailsPageState createState() => _AdDetailsPageState();
}

class _AdDetailsPageState extends State<AdDetailsPage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> fetchAdDetails() async {
    final token = await _storage.read(key: "token");
    final response = await http.get(
      Uri.parse("$BASE_URL/ads/${widget.adId}/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 401) {
      // If unauthorized, schedule a redirect to the login page.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      throw Exception("Unauthorized. Redirecting to login...");
    } else {
      throw Exception("Failed to load ad details");
    }
  }

  // Helper to truncate description text.
  String _truncateDescription(String? description, {int cutoff = 120}) {
    if (description == null) return "";
    return description.length > cutoff
        ? "${description.substring(0, cutoff)}..."
        : description;
  }

  // Build status badge widget.
  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child:
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  // Build the top header with image, truncated description, and dynamic metrics.
  Widget _buildAdHeader(Map<String, dynamic> ad) {
    final truncatedDesc = _truncateDescription(ad["description"]);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row with image and title/description.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    ad["image"],
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                // Title and description.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ad["product_name"] ?? "No Title",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        truncatedDesc,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Dynamic metrics.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetric("Tot Spent", "Ksh ${ad["total_spent"] ?? ''}"),
                _buildMetric("Days Run", ad["days_run"]?.toString() ?? ""),
                _buildMetric("Paid Views", ad["paid_views"]?.toString() ?? ""),
              ],
            ),
            const SizedBox(height: 12),
            // Status badges.
            Row(
              children: [
                _buildStatusBadge(
                  ad["status"] ?? "Unknown",
                  ad["status"]?.toLowerCase() == "active"
                      ? Colors.green
                      : Colors.red,
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(
                  ad["paid_status"] ?? "Not Paid",
                  ad["paid_status"]?.toLowerCase() == "paid"
                      ? Colors.green
                      : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build individual metric widget.
  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  // Returns an icon for a given button text.
  IconData _getButtonIcon(String text) {
    switch (text.toLowerCase()) {
      case "renew":
        return Icons.autorenew;
      case "pause":
        return Icons.pause;
      case "pay":
        return Icons.payment;
      case "start":
        return Icons.play_arrow;
      default:
        return Icons.info;
    }
  }

  // Build action buttons with equal width based on ad status.
  Widget _buildActionButtons(Map<String, dynamic> ad) {
    List<Widget> buttons = [];
    final String status = (ad["status"] ?? "").toString().toLowerCase();
    final String paidStatus =
        (ad["paid_status"] ?? "").toString().toLowerCase();

    // Always show Pay button if not paid.
    if (paidStatus == "not paid") {
      buttons.add(_buildActionButton("Pay", Colors.deepPurple));
    }
    // Show different buttons based on ad status.
    if (status == "active") {
      buttons.add(_buildActionButton("Pause", Colors.red));
    } else if (status == "scheduled") {
      buttons.add(_buildActionButton("Start", Colors.orange));
    } else if (status == "inactive" ||
        status == "complete" ||
        status == "compelete") {
      buttons.add(_buildActionButton("Renew", Colors.green));
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: buttons
            .map((button) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: button,
                  ),
                ))
            .toList(),
      ),
    );
  }

  // Build a single action button with an icon.
  Widget _buildActionButton(String text, Color color) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () {
        // Add your action logic here.
      },
      icon: Icon(
        _getButtonIcon(text),
        color: Colors.white,
        size: 18,
      ),
      label:
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
    );
  }

  // Build ad renewals section.
  Widget _buildAdRenewals(Map<String, dynamic> ad) {
    final renewals = ad["payments"] as List<dynamic>? ?? [];
    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Ad Renewals",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text("All your Ad renewals",
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text("Renewed On",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("Expiry Date",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("Amount Paid",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("Views",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: renewals.length,
                  itemBuilder: (context, index) {
                    final renewal = renewals[index] as Map<String, dynamic>;
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            index.isEven ? Colors.white : Colors.grey.shade100,
                        border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(renewal["transaction_date"] ?? ""),
                          Text(renewal["expiry_date"] ?? ""),
                          Text("Ksh ${renewal["amount"] ?? ""}"),
                          Text(renewal["views"]?.toString() ?? ""),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Optionally add an AppBar.
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchAdDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData) {
            return const Center(child: Text("No details found."));
          } else {
            final ad = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAdHeader(ad),
                  const SizedBox(height: 16),
                  // Uncomment if you wish to show action buttons.
                  // _buildActionButtons(ad),
                  // const SizedBox(height: 16),
                  _buildAdRenewals(ad),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

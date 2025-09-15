// ignore_for_file: unused_import, library_private_types_in_public_api

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moderntr/constants.dart';
import 'package:intl/intl.dart';
import 'package:moderntr/widgets/back_button_handler.dart';

final String baseUrl = BASE_URL;
final storage = FlutterSecureStorage();

class MyAdsPage extends StatefulWidget {
  const MyAdsPage({super.key});

  @override
  _MyAdsPageState createState() => _MyAdsPageState();
}

class _MyAdsPageState extends State<MyAdsPage> {
  // Helper method to handle unauthorized responses.
  void _handleUnauthorized(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/login');
    });
  }

  Future<List<Map<String, dynamic>>> fetchAds() async {
    final token = await storage.read(key: 'token');

    if (token == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Token expired. Please log in."),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/login');
      });
      return [];
    }

    final url = Uri.parse("$BASE_URL/ads");
    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      final List<dynamic> adsJson = jsonDecode(decoded);
      return adsJson.cast<Map<String, dynamic>>();
    } else if (response.statusCode == 401) {
      _handleUnauthorized("Token expired. Please log in.");
      return [];
    } else {
      throw Exception("Failed to load ads: ${response.body}");
    }
  }

  Future<void> _refreshAds() async {
    setState(() {}); // Refresh ads by rebuilding widget.
  }

  // Helper method to truncate description text with a longer cutoff.
  String _truncateDescription(String? description, {int cutoff = 120}) {
    if (description == null) return "";
    return description.length > cutoff
        ? "${description.substring(0, cutoff)}..."
        : description;
  }

  // Helper method to get the circle indicator color based on ad status.
  Color _getStatusColor(String? status) {
    if (status == "active") {
      return Colors.green;
    } else if (status == "scheduled" || status == "inactive") {
      return Colors.red;
    } else if (status == "complete" || status == "compelete") {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }

  // Helper method to build conditional action buttons.
  Widget _buildActionButtons(Map<String, dynamic> ad) {
    List<Widget> buttons = [];
    final paidStatus = ad["paid_status"]?.toString().toLowerCase() ?? "";
    final adStatus = ad["status"]?.toString().toLowerCase() ?? "";

    // Add Edit and Delete buttons for all ads
    buttons.add(
      ElevatedButton.icon(
        onPressed: () => _editAd(ad),
        icon: const Icon(Icons.edit, size: 18, color: Colors.white),
        label: const Text("Edit"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );

    buttons.add(
      ElevatedButton.icon(
        onPressed: () => _deleteAd(ad),
        icon: const Icon(Icons.delete, size: 18, color: Colors.white),
        label: const Text("Delete"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );

    if (paidStatus == "not paid") {
      buttons.add(
        ElevatedButton.icon(
          onPressed: () {
            // Navigate to payment screen.
            context.push('/pay-ad', extra: {"ad_id": ad["ad_id"].toString()});
          },
          icon: const Icon(Icons.credit_card, size: 18, color: Colors.white),
          label: const Text("Pay"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }
    if (adStatus == "scheduled") {
      buttons.add(
        ElevatedButton(
          onPressed: () {
            // Add your start ad logic here.
          },
          child: const Text("Start"),
        ),
      );
    }
    if (adStatus == "complete" || adStatus == "compelete") {
      buttons.add(
        ElevatedButton(
          onPressed: () {
            // Add your renew ad logic here.
          },
          child: const Text("Renew"),
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: buttons,
      ),
    );
  }

  void _editAd(Map<String, dynamic> ad) {
    // Navigate to edit ad page (you'll need to create this)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Ad"),
        content: const Text("Edit ad functionality will be implemented here."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAd(Map<String, dynamic> ad) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Ad"),
        content: const Text("Are you sure you want to delete this ad? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final token = await storage.read(key: 'token');
        final response = await http.delete(
          Uri.parse("$BASE_URL/ads/${ad['ad_id']}/delete/"),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Ad deleted successfully!")),
          );
          setState(() {}); // Refresh the ads list
        } else {
          final error = jsonDecode(response.body)["error"] ?? "Failed to delete ad";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting ad: $e")),
        );
      }
    }
  }

  Widget _buildAdCard(BuildContext context, Map<String, dynamic> ad) {
    final String truncatedDesc = _truncateDescription(ad["description"]);
    final Color statusColor = _getStatusColor(ad["status"]);

    return GestureDetector(
      onTap: () {
        context.push('/ad-details', extra: ad);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display ad image (network or placeholder).
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child:
                        ad["image"] != null && ad["image"].toString().isNotEmpty
                            ? Image.network(
                                ad["image"],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                "assets/images/placeholder.png",
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ad["product_name"] ?? "No Title",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          truncatedDesc,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Ksh ${ad["price"]}",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Duration: ${ad["start_date"]} to ${ad["end_date"]}",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // Circle indicator based on status.
                  Icon(Icons.circle, color: statusColor, size: 14),
                ],
              ),
              // Display action buttons conditionally.
              _buildActionButtons(ad),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackButtonHandler(
      parentRoute: '/account',
      child: Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchAds(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No ads found."));
          } else {
            final ads = snapshot.data!;
            return RefreshIndicator(
              onRefresh: _refreshAds,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "My Ads",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text("All your product promotions.",
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: ads.length,
                        itemBuilder: (context, index) {
                          return _buildAdCard(context, ads[index]);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
      ),
    );
  }
}

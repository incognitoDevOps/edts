// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:moderntr/constants.dart';
import 'package:moderntr/widgets/back_button_handler.dart';

class PayAd extends StatefulWidget {
  final String adId; // Receive the ad id.

  const PayAd({super.key, required this.adId});

  @override
  _PayAdState createState() => _PayAdState();
}

class _PayAdState extends State<PayAd> {
  final TextEditingController _mobileController = TextEditingController();
  bool _isPaying = false;

  Future<void> _submitPayment() async {
    setState(() => _isPaying = true);

    final paymentData = {
      "ad_id": widget.adId,
      "mobile_no": _mobileController.text,
    };
    print(paymentData);

    try {
      final token = await FlutterSecureStorage().read(key: "token");
      final response = await http.post(
        Uri.parse("$BASE_URL/ads/pay/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(paymentData),
      );

      // Handle token expiration
      if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Token expired, please log in")),
        );
        setState(() => _isPaying = false);
        context.go('/'); // Redirect to login
        return;
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final receipt = responseData["receipt_number"];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment initiated. Receipt: $receipt")),
        );
        // Start polling the backend for payment confirmation.
        _pollPaymentStatus();
      } else {
        final error = jsonDecode(response.body)["error"].toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
        setState(() => _isPaying = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $e")),
      );
      setState(() => _isPaying = false);
    }
  }

  Future<void> _pollPaymentStatus() async {
    final token = await FlutterSecureStorage().read(key: "token");
    int elapsed = 0;
    const int timeout = 60; // seconds
    const int interval = 5; // seconds

    while (elapsed < timeout) {
      await Future.delayed(const Duration(seconds: interval));
      elapsed += interval;
      try {
        // Check the ad details to see if payment status changed
        final response = await http.get(
          Uri.parse("$BASE_URL/ads/${widget.adId}/"),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        );

        // Handle token expiration during polling as well
        if (response.statusCode == 401) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Token expired, please log in")),
          );
          setState(() => _isPaying = false);
          context.go('/'); // Redirect to login
          return;
        }

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data["paid_status"] == "paid") {
            setState(() => _isPaying = false);
            // Navigate to payment success page first, then to ads
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Payment successful!")),
            );
            context.go('/payment-success');
            return;
          } else if (data["paid_status"] == "failed") {
            setState(() => _isPaying = false);
            context.go('/payment-failed');
            return;
          }
        }
      } catch (e) {
        // Optionally log or handle errors from polling.
      }
    }
    // If timeout reached, assume payment failed.
    setState(() => _isPaying = false);
    context.go('/payment-failed');
  }

  @override
  Widget build(BuildContext context) {
    final Color maroon = const Color(0xFF6C1910);

    return BackButtonHandler(
      parentRoute: '/my-ads',
      child: Scaffold(
      appBar: AppBar(title: const Text("Complete Payment")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Complete Payment",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text("Pay for ad.", style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            TextField(
              controller: _mobileController,
              decoration: InputDecoration(
                hintText: "Enter Mpesa number",
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: maroon),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Redirect to ads page after clicking "Pay later"
                      context.go('/my-ads');
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: const BorderSide(color: Colors.black),
                    ),
                    child: Text(
                      "Pay later",
                      style: TextStyle(
                          color: maroon,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isPaying ? null : _submitPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: maroon,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isPaying
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Pay Ad",
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}

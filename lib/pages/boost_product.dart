// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:moderntr/constants.dart';
import 'package:intl/intl.dart';

class PromoteProductWidget extends StatefulWidget {
  final String productId;
  final String productName;

  const PromoteProductWidget({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  _PromoteProductWidgetState createState() => _PromoteProductWidgetState();
}

class _PromoteProductWidgetState extends State<PromoteProductWidget> {
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _isSubmitting = false;

  // Helper function to show the date picker.
  Future<void> _selectDate(TextEditingController controller) async {
    DateTime now = DateTime.now();
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now, // Prevent past dates.
      lastDate: DateTime(now.year + 5),
    );

    if (pickedDate != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  Future<void> _submitAd() async {
    setState(() => _isSubmitting = true);

    // Create the ad data payload.
    final adData = {
      "product_id": widget.productId,
      "start_date": _startDateController.text,
      "end_date": _endDateController.text,
      "cost_per_day": _amountController.text,
    };

    final token = await FlutterSecureStorage().read(key: "token");

    final response = await http.post(
      Uri.parse("$BASE_URL/ads/create/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(adData),
    );

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      final adId = responseData["ad_id"]; // Extract ad id
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ad created successfully!")),
      );
      // Convert adId to String before passing it.
      context.push("/pay-ad", extra: {"ad_id": adId.toString()});
    } else if (response.statusCode == 401) {
      // Handle unauthorized response
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session expired. Please log in again.")),
      );
    } else {
      final error = jsonDecode(response.body)["error"] ?? "Failed to create ad";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }

    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text("Promote Product")),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              const Text(
                "Promote Product.",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              const Text(
                "Create an ad.",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 15),

              // Product Name (Read-only)
              TextFormField(
                readOnly: true,
                initialValue: widget.productName,
                decoration: _inputDecoration(),
              ),
              const SizedBox(height: 15),

              // Start Date & End Date Fields with date picker
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startDateController,
                      readOnly: true,
                      onTap: () async {
                        await _selectDate(_startDateController);
                      },
                      decoration: _inputDecoration(hint: "Start date"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _endDateController,
                      readOnly: true,
                      onTap: () async {
                        await _selectDate(_endDateController);
                      },
                      decoration: _inputDecoration(hint: "End date"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Amount Per Day Field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(hint: "Amount per day"),
              ),
              const SizedBox(height: 25),

              // Buttons Row
              Row(
                children: [
                  // Skip Button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Skip",
                          style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Create Ad Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitAd,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C1910),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text("Create Ad"),
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

  // Custom Input Decoration helper.
  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF6C1910)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF6C1910), width: 2),
      ),
    );
  }
}

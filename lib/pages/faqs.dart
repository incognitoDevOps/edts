// ignore_for_file: library_private_types_in_public_api

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:moderntr/constants.dart'; // Contains base URL

final String baseUrl = BASE_URL;

class FAQsPage extends StatefulWidget {
  const FAQsPage({super.key});

  @override
  _FAQsPageState createState() => _FAQsPageState();
}

class _FAQsPageState extends State<FAQsPage> {
  List faqs = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchFAQs();
  }

  Future<void> fetchFAQs() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/faqs/'));
      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decoded);
        setState(() {
          if (data is List) {
            faqs = data;
          } else if (data['faqs'] != null) {
            faqs = data['faqs'];
          }
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Error: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Exception: $e";
        isLoading = false;
      });
    }
  }

  void _showFAQDialog(Map faq) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(faq['question'] ?? "FAQ"),
        content: SingleChildScrollView(
          child: Text(faq['answer'] ?? "No answer provided."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQCard(Map faq) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: ListTile(
        title: Text(
          faq['question'] ?? "No question",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showFAQDialog(faq),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Frequently asked questions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text("what do you want to know?",
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),
            if (isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (errorMessage != null)
              Expanded(
                child: Center(
                  child: Text(errorMessage!,
                      style: const TextStyle(color: Colors.red)),
                ),
              )
            else if (faqs.isEmpty)
              const Expanded(child: Center(child: Text("No FAQs available.")))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: faqs.length,
                  itemBuilder: (context, index) {
                    return _buildFAQCard(faqs[index]);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ignore_for_file: library_private_types_in_public_api

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moderntr/constants.dart'; // Import for formatting numbers
import 'package:moderntr/widgets/back_button_handler.dart';

final String baseUrl = BASE_URL;
final storage = FlutterSecureStorage();

class MyReviewsPage extends StatefulWidget {
  const MyReviewsPage({super.key});

  @override
  _MyReviewsPageState createState() => _MyReviewsPageState();
}

class _MyReviewsPageState extends State<MyReviewsPage> {
  late Future<List<Map<String, dynamic>>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = fetchReviews();
  }

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

  Future<List<Map<String, dynamic>>> fetchReviews() async {
    final token = await storage.read(key: "token");

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

    final uri = Uri.parse("$baseUrl/reviews/store/");
    final response = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes); // ✅ decode correctly
      final List<dynamic> reviewsJson = jsonDecode(decoded);
      return reviewsJson.cast<Map<String, dynamic>>();
    } else if (response.statusCode == 401) {
      _handleUnauthorized("Token expired. Please log in.");
      return [];
    } else if (response.statusCode == 404) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No store found. Please create a store."),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/create-store');
      });
      return [];
    } else {
      throw Exception("Failed to load reviews: ${response.body}");
    }
  }

  /// Build a custom header similar to your listings header.
  Widget _buildCustomHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          "My Reviews",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 4),
        Text(
          "Your product reviews.",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  /// Build a review card with "read more" functionality.
  Widget _buildReviewCard(Map<String, dynamic> review) {
    return ReviewCard(review: review);
  }

  @override
  Widget build(BuildContext context) {
    return BackButtonHandler(
      parentRoute: '/account',
      child: Scaffold(
        // Remove the AppBar by setting it to null.
        appBar: null,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _reviewsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No reviews found."));
              } else {
                final reviews = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Custom header at the top.
                    _buildCustomHeader(),
                    Expanded(
                      child: ListView.separated(
                        itemCount: reviews.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildReviewCard(reviews[index]);
                        },
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

/// A stateful widget for a single review card, with "read more" logic.
class ReviewCard extends StatefulWidget {
  final Map<String, dynamic> review;
  final int truncateThreshold;

  const ReviewCard(
      {super.key, required this.review, this.truncateThreshold = 100});

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final String reviewText = widget.review["review"] ?? "";
    final bool shouldTruncate = reviewText.length > widget.truncateThreshold;
    final String displayedText = _isExpanded || !shouldTruncate
        ? reviewText
        : "${reviewText.substring(0, widget.truncateThreshold)}...";

    // Determine thumbs icon based on rating.
    int rating = int.tryParse(widget.review["rating"].toString()) ?? 0;
    final IconData thumbIcon = rating >= 3 ? Icons.thumb_up : Icons.thumb_down;
    final Color thumbColor = rating >= 3 ? Colors.green : Colors.red;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Reviewer and thumbs.
            Row(
              children: [
                const Icon(Icons.person, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.review["reviewer_name"] ?? "Anonymous",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Icon(thumbIcon, color: thumbColor, size: 18),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              displayedText,
              style: const TextStyle(fontSize: 14),
            ),
            if (shouldTruncate)
              TextButton(
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Text(_isExpanded ? "Read less" : "Read more"),
              ),
            const SizedBox(height: 6),
            Text(
              widget.review["date"] ?? "",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
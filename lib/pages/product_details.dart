// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:moderntr/constants.dart';
import 'package:intl/intl.dart'; // For number formatting
import 'package:url_launcher/url_launcher.dart'; // For launching WhatsApp
import 'package:go_router/go_router.dart'; // For navigation
// Import flutter_html for rendering rich HTML with emojis.
import 'package:flutter_html/flutter_html.dart';
import 'package:moderntr/widgets/back_button_handler.dart';

const String baseUrl = BASE_URL;

class ProductDetailsPage extends StatefulWidget {
  // The product passed from the category listings page should include at least an "id".
  final Map<String, dynamic> product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  Map<String, dynamic>? productData;
  bool _isLoading = true;
  String? _errorMessage;
  String? currentUserId; // Current logged in user's ID

  bool _isDescriptionExpanded = false;
  final int _descriptionWordLimit = 45;

  int _currentImageIndex = 0; // Tracks the currently displayed image index

  // Review form controllers and variables.
  final TextEditingController _reviewController = TextEditingController();
  int _selectedRating = 5; // Default rating (1 to 5)
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Controllers for complaint (report) form.
  final TextEditingController _complaintReasonController =
      TextEditingController();
  final TextEditingController _complaintDescriptionController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    fetchProductDetails();
  }

  Future<void> _loadCurrentUserId() async {
    final id = await _storage.read(key: "user_id");
    setState(() {
      currentUserId = id;
    });
  }

  Future<void> fetchProductDetails() async {
    final productId = widget.product["id"].toString();
    // Construct the URL properly.
    final uri = Uri.parse("$baseUrl/products/fetch/")
        .replace(queryParameters: {"product_id": productId});

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        // Decode response.bodyBytes with utf8 before jsonDecode:
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decodedBody);

        if (data["product"] != null) {
          setState(() {
            productData = data["product"];
            _isLoading = false;
            _currentImageIndex = 0;
          });
        } else {
          setState(() {
            _errorMessage = "Product not found";
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = "Error: ${response.body}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error fetching product: $e";
        _isLoading = false;
      });
    }
  }

  /// **Main Product Image with Navigation Buttons**
  Widget _buildMainImage() {
    final List images = productData?["images"] ?? [];
    final String? imageUrl =
        images.isNotEmpty ? images[_currentImageIndex] : null;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Center(
        child: Stack(
          children: [
            Hero(
              tag: "product_${widget.product["id"]}",
              child: imageUrl != null
                  ? FadeInImage.assetNetwork(
                      placeholder: 'assets/images/placeholder.png',
                      image: imageUrl,
                      height: 450,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 450,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported, size: 100),
                    ),
            ),
            // Left arrow button.
            if (images.length > 1)
              Positioned(
                left: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon:
                        const Icon(Icons.arrow_back_ios, color: Colors.white70),
                    onPressed: () {
                      setState(() {
                        _currentImageIndex =
                            (_currentImageIndex - 1) % images.length;
                        if (_currentImageIndex < 0) {
                          _currentImageIndex = images.length - 1;
                        }
                      });
                    },
                  ),
                ),
              ),
            // Right arrow button.
            if (images.length > 1)
              Positioned(
                right: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios,
                        color: Colors.white70),
                    onPressed: () {
                      setState(() {
                        _currentImageIndex =
                            (_currentImageIndex + 1) % images.length;
                      });
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// **Horizontally Scrollable Thumbnails Section**
  Widget _buildImageThumbnails() {
    final List images = productData?["images"] ?? [];
    if (images.isEmpty) {
      return const SizedBox();
    }
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _thumbnailImage(images[index]),
      ),
    );
  }

  Widget _thumbnailImage(String imageUrl) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentImageIndex = productData!["images"].indexOf(imageUrl);
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          imageUrl,
          height: 70,
          width: 70,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  /// **Location & Title**
  Widget _buildLocationAndTitle() {
    final String town = productData?["town"] ?? "";
    final String county = productData?["county"] ?? "";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on, size: 18, color: Colors.black54),
            const SizedBox(width: 5),
            Text(
              "$town, $county",
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          productData?["name"] ?? "",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
          ),
        ),
      ],
    );
  }

  /// **Price Section**
  Widget _buildPrice() {
    final formattedPrice =
        NumberFormat("#,##0", "en_US").format(productData?["price"] ?? 0);
    return Text(
      "Ksh $formattedPrice",
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }

  /// **Product Description** (Using flutter_html to render emojis / HTML)
  Widget _buildDescription() {
    final description =
        productData?["description"] ?? "No description available.";
    final wordList = description.split(RegExp(r'\s+'));

    final bool shouldTruncate = wordList.length > _descriptionWordLimit;
    final String shortenedDescription = shouldTruncate
        ? wordList.take(_descriptionWordLimit).join(' ') + '...'
        : description;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Html(
          data: _isDescriptionExpanded || !shouldTruncate
              ? description
              : shortenedDescription,
          style: {
            "body": Style(
              fontSize: FontSize(14),
              color: Colors.black54,
              fontFamily: "Segoe UI Emoji",
            ),
          },
        ),
        if (shouldTruncate)
          TextButton(
            onPressed: () {
              setState(() {
                _isDescriptionExpanded = !_isDescriptionExpanded;
              });
            },
            child: Text(
              _isDescriptionExpanded ? 'Read less' : 'Read more',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
          ),
      ],
    );
  }

  /// **Contact Buttons**
  Widget _buildContactButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.chat, color: Colors.white),
            label: const Text(
              "Contact Seller",
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C1910),
            ),
            onPressed: _initiateChat,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white),
            label: const Text(
              "WhatsApp",
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: _launchWhatsApp,
          ),
        ),
      ],
    );
  }

  /// **Seller Info**
  Widget _buildSellerInfo() {
    final store = productData?["store"];
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: store != null && store["image"] != null
              ? NetworkImage(store["image"])
              : const AssetImage('assets/images/profile.jpg') as ImageProvider,
          radius: 28,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                store?["name"] ?? "Store Name",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              const Text(
                "Member since: 12 January 2025",
                style: TextStyle(color: Colors.black54, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        TextButton.icon(
          icon: const Icon(Icons.report, color: Colors.red),
          label: const Text("Report",
              style: TextStyle(color: Colors.red, fontSize: 14)),
          onPressed: _showReportDialog,
        ),
      ],
    );
  }

  /// **Comments/Reviews Section**
  Widget _buildCommentsSection() {
    final List reviews = productData?["reviews"] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(thickness: 1.2),
        const SizedBox(height: 16),
        const Text(
          "Customer Reviews",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        reviews.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  children: const [
                    Icon(Icons.comment_bank_outlined, color: Colors.grey),
                    SizedBox(width: 10),
                    Text(
                      "No comments yet. Be the first to review!",
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: reviews.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final review = reviews[index] as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ReviewCard(review: review),
                  );
                },
              ),
      ],
    );
  }

  /// **Review Form**
  Widget _buildReviewForm() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Add Your Review",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          /// Rating Stars
          Row(
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _selectedRating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 28,
                ),
                onPressed: () {
                  setState(() {
                    _selectedRating = index + 1;
                  });
                },
              );
            }),
          ),

          const SizedBox(height: 10),

          /// Comment TextField
          TextField(
            controller: _reviewController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Write your review...",
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Colors.redAccent, width: 1.4),
              ),
            ),
          ),

          const SizedBox(height: 16),

          /// Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send, color: Colors.white),
              label:
                  const Text("Submit Review", style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C1910),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _submitReview,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReview() async {
    final productId = widget.product["id"].toString();
    final reviewText = _reviewController.text.trim();

    if (reviewText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Review cannot be blank.")),
      );
      return;
    }

    final reviewData = {
      "product_id": productId,
      "rating": _selectedRating,
      "review": reviewText,
    };

    try {
      final token = await _storage.read(key: "token");
      final response = await http.post(
        Uri.parse("$baseUrl/reviews/create/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(reviewData),
      );

      if (response.statusCode == 201) {
        _reviewController.clear();
        setState(() {
          fetchProductDetails();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add comment: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding comment: $e")),
      );
    }
  }

  // Initiates a chat with the store owner.
  Future<void> _initiateChat() async {
    final store = productData?["store"];
    if (store == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Store info not available")),
      );
      return;
    }
    final ownerId = store["owner"]["id"];
    final ownerName = store["name"];
    final ownerProfileImage = store["image"] ?? "assets/images/profile.jpg";

    try {
      final token = await _storage.read(key: "token");
      final response = await http.post(
        Uri.parse("$baseUrl/rooms/initiate/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "other_user_id": ownerId,
          "product_id": widget.product["id"],
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final roomId = data["room"]["id"];
        context.push('/chat-details', extra: {
          "roomId": roomId,
          "name": ownerName,
          "profileImage": ownerProfileImage,
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error initiating chat: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // Launches WhatsApp chat with the seller's phone number.

  Future<void> _launchWhatsApp() async {
    final store = productData?["store"];
    if (store == null || store["phone"] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seller phone number not available")),
      );
      return;
    }

    // Clean and format the phone number
    String phone = store["phone"].toString().replaceAll(RegExp(r'[^0-9]'), '');

    // Ensure proper Kenyan country code format
    if (phone.startsWith('0')) {
      phone = '254${phone.substring(1)}'; // Convert 07... to 2547...
    } else if (!phone.startsWith('254')) {
      phone = '254$phone'; // Add country code if missing
    }

    // Create both direct and web URLs
    final directUrl =
        "https://wa.me/$phone?text=${Uri.encodeComponent('Hi, I am interested in your product ${productData?["name"] ?? ''}')}";
    final webUrl =
        "https://web.whatsapp.com/send?phone=$phone&text=${Uri.encodeComponent('Hi, I am interested in your product ${productData?["name"] ?? ''}')}";

    try {
      // Try direct WhatsApp app first
      if (await canLaunchUrl(Uri.parse(directUrl))) {
        await launchUrl(Uri.parse(directUrl));
      }
      // Fallback to WhatsApp Web
      else if (await canLaunchUrl(Uri.parse(webUrl))) {
        await launchUrl(Uri.parse(webUrl));
      }
      // Ultimate fallback
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Could not launch WhatsApp. Please install WhatsApp first."),
            duration: Duration(seconds: 3),
          ),
        );
        // Optionally open Play Store to install WhatsApp
        final playStoreUrl =
            "https://play.google.com/store/apps/details?id=com.whatsapp";
        if (await canLaunchUrl(Uri.parse(playStoreUrl))) {
          await launchUrl(Uri.parse(playStoreUrl));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Shows the report complaint form in a popup dialog.
  Future<void> _showReportDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white,
              title: const Text(
                'Report Vendor',
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _complaintReasonController,
                      decoration: InputDecoration(
                        labelText: 'Reason',
                        labelStyle: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.redAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _complaintDescriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.redAccent),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                        fontFamily: 'Roboto', color: Colors.grey, fontSize: 16),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setState(() {
                            isSubmitting = true;
                          });
                          await _submitComplaint();
                          setState(() {
                            isSubmitting = false;
                          });
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Submit',
                          style: TextStyle(fontFamily: 'Roboto', fontSize: 16)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Submits the complaint to the backend.
  Future<void> _submitComplaint() async {
    final store = productData?["store"];
    if (store == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Store info not available")),
      );
      return;
    }
    final storeId = store["id"];
    final reason = _complaintReasonController.text.trim();
    final description = _complaintDescriptionController.text.trim();

    if (reason.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    try {
      final token = await _storage.read(key: "token");
      final response = await http.post(
        Uri.parse("$baseUrl/stores/$storeId/complaint/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "reason": reason,
          "description": description,
        }),
      );

      if (response.statusCode == 201) {
        Navigator.of(context).pop(); // Close the dialog.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Complaint submitted successfully")),
        );
        _complaintReasonController.clear();
        _complaintDescriptionController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Failed to submit complaint: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error submitting complaint: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const BackButtonHandler(
        child: Scaffold(
        body: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_errorMessage != null) {
      return BackButtonHandler(
        child: Scaffold(
        body: Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
          ),
        ),
        ),
      );
    }
    return BackButtonHandler(
      child: Scaffold(
      backgroundColor: Colors.white,
      // appBar: AppBar(
      //   title: Text(
      //     productData?["name"] ?? "",
      //     style: const TextStyle(
      //         fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
      //   ),
      //   backgroundColor: Colors.redAccent,
      //   iconTheme: const IconThemeData(color: Colors.white),
      //   elevation: 0,
      // ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMainImage(),
              const SizedBox(height: 15),
              _buildImageThumbnails(),
              const SizedBox(height: 20),
              _buildLocationAndTitle(),
              const SizedBox(height: 8),
              _buildPrice(),
              const SizedBox(height: 12),
              _buildDescription(),
              const SizedBox(height: 20),
              _buildContactButtons(),
              const SizedBox(height: 25),
              _buildSellerInfo(),
              const SizedBox(height: 30),
              // Comments Section
              _buildCommentsSection(),
              const SizedBox(height: 20),
              _buildReviewForm(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

/// A separate stateful widget for each review card, which handles "read more" logic.
class ReviewCard extends StatefulWidget {
  final Map<String, dynamic> review;
  final int truncateThreshold;

  const ReviewCard({
    super.key,
    required this.review,
    this.truncateThreshold = 100,
  });

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
    final int rating = int.tryParse(widget.review["rating"].toString()) ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.review["name"] ?? "Anonymous",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Row(
                  children: List.generate(5, (i) {
                    return Icon(
                      i < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(displayedText, style: const TextStyle(fontSize: 14)),
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
              widget.review["date"] != null
                  ? widget.review["date"].toString()
                  : "",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

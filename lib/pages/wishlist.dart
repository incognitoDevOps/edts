import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:moderntr/services/wishlist_service.dart';
import 'package:moderntr/widgets/back_button_handler.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  List<dynamic> wishlist = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchWishlist();
  }

  Future<void> _fetchWishlist() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final result = await WishlistService.getWishlist(
      // Updated callback: Show a token expiration message before redirecting.
      showSnackbar: (message) => _showOverlaySnackBar(context, message),
      redirectToLogin: () {
        _showOverlaySnackBar(context, "Token expired, please log in");
        context.go('/login');
      },
    );

    if (result.containsKey("wishlist")) {
      setState(() {
        wishlist = result["wishlist"];
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = result["error"] ?? "Failed to load wishlist.";
        isLoading = false;
      });
    }
  }

  void _removeFromWishlist(int productId, int index) async {
    await WishlistService.removeFromWishlist(
      showSnackbar: (message) => _showOverlaySnackBar(context, message),
      redirectToLogin: () {
        _showOverlaySnackBar(context, "Token expired, please log in");
        context.go('/login');
      },
      productId: productId,
    );

    setState(() {
      wishlist.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BackButtonHandler(
      parentRoute: '/',
      child: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("My Wishlist",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("Your saved favorite items.",
                style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage.isNotEmpty
                      ? Center(
                          child: Text(
                            errorMessage,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.red),
                          ),
                        )
                      : wishlist.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              itemCount: wishlist.length,
                              itemBuilder: (context, index) {
                                final item = wishlist[index];
                                return Dismissible(
                                  key: Key(item["id"].toString()),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    padding: const EdgeInsets.only(right: 20),
                                    alignment: Alignment.centerRight,
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.delete,
                                        color: Colors.white, size: 24),
                                  ),
                                  onDismissed: (direction) {
                                    _removeFromWishlist(
                                        item["product"]["id"], index);
                                  },
                                  child: _buildWishlistItem(item),
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

  Widget _buildWishlistItem(Map<String, dynamic> item) {
    String description =
        item["product"]["description"] ?? "No description available";
    String shortDescription = description.length > 50
        ? "${description.substring(0, 50)}..."
        : description;

    // Format price with commas.
    String formattedPrice =
        "Ksh ${NumberFormat("#,##0", "en_US").format(item["product"]["price"])}";

    return InkWell(
      onTap: () {
        // Redirect to product details with the product data.
        context.push('/product-details', extra: item["product"]);
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item["product"]["image"] ?? "",
                  height: 70,
                  width: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.image,
                    size: 70,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item["product"]["name"],
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shortDescription,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedPrice,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.trash,
                    color: Colors.red, size: 16),
                onPressed: () => _removeFromWishlist(
                    item["product"]["id"],
                    wishlist.indexOf(item)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 10),
          const Text(
            "Your wishlist is empty!",
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54),
          ),
          const SizedBox(height: 5),
          const Text(
            "Browse products and save your favorites.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showOverlaySnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:moderntr/constants.dart';
import 'package:moderntr/widgets/back_button_handler.dart';

final String baseUrl = BASE_URL;
final storage = FlutterSecureStorage();

class MyListingsPage extends StatefulWidget {
  const MyListingsPage({super.key});

  @override
  _MyListingsPageState createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage> {
  List<Map<String, dynamic>> listings = [];
  bool isLoading = true;
  String? errorMessage;
  bool storeNotFound = false;

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

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

  Future<void> _loadListings() async {
    try {
      String? token = await storage.read(key: "token");

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
        setState(() {
          isLoading = false;
        });
        return;
      }

      final response = await fetchProducts(token: token);

      // Handle different response scenarios
      if (response == null) {
        setState(() {
          errorMessage = "No response from server";
          isLoading = false;
        });
        return;
      }

      if (response is Map<String, dynamic>) {
        if (response.containsKey("detail")) {
          if (response["detail"] == "Store not found") {
            setState(() {
              storeNotFound = true;
              isLoading = false;
              errorMessage = null;
              listings = [];
            });
            return;
          } else {
            setState(() {
              errorMessage = response["detail"].toString();
              isLoading = false;
            });
            return;
          }
        }

        if (response.containsKey("products")) {
          try {
            final products = response["products"];
            if (products is List) {
              final validListings = _validateAndSanitizeProducts(products);
              setState(() {
                listings = validListings;
                isLoading = false;
                errorMessage = null;
                storeNotFound = false;
              });
              return;
            }
          } catch (e) {
            // Fall through to error handling
          }
        }
      }

      setState(() {
        errorMessage = "No Listings Found";
        // errorMessage = "Invalid data format from API";
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load listings: ${e.toString()}";
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _validateAndSanitizeProducts(List<dynamic> products) {
    final List<Map<String, dynamic>> validProducts = [];

    for (var product in products) {
      try {
        if (product is Map<String, dynamic>) {
          final sanitizedProduct = {
            "id": product["id"] is int ? product["id"] : 0,
            "name": product["name"] is String ? product["name"] : "Unnamed Product",
            "price": product["price"] is num ? product["price"] : 0,
            // "description": product["description"] is String 
            //     ? product["description"] 
            //     : "No description available",
            "image": product["image"] is String ? product["image"] : null,
          };
          validProducts.add(sanitizedProduct);
        }
      } catch (e) {
        // Skip invalid products
        debugPrint("Skipping invalid product: $e");
      }
    }

    return validProducts;
  }

  Future<dynamic> fetchProducts({required String token}) async {
    try {
      final uri = Uri.parse('$baseUrl/products/store/all/').replace(queryParameters: {
        'page': '1',
        'per_page': '10',
      });

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        try {
          final decoded = utf8.decode(response.bodyBytes);
          return jsonDecode(decoded);
        } catch (e) {
          throw Exception("Failed to decode response: $e");
        }
      } else if (response.statusCode == 401) {
        _handleUnauthorized("Token expired. Please log in.");
        return null;
      } else if (response.statusCode == 404) {
        try {
          final decoded = utf8.decode(response.bodyBytes);
          return jsonDecode(decoded);
        } catch (e) {
          return {"detail": "Store not found"};
        }
      } else {
        try {
          final decoded = utf8.decode(response.bodyBytes);
          return jsonDecode(decoded);
        } catch (e) {
          return {"detail": "Server error: ${response.statusCode}"};
        }
      }
    } catch (e) {
      throw Exception("Network error: $e");
    }
  }

  Future<void> _deleteProduct(int productId) async {
    try {
      String? token = await storage.read(key: "token");
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please log in to delete products.")),
        );
        return;
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/products/$productId/delete/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          listings.removeWhere((item) => item["id"] == productId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product deleted successfully.")),
        );
      } else if (response.statusCode == 401) {
        _handleUnauthorized("Token expired. Please log in.");
      } else {
        final error = jsonDecode(response.body)["error"] ?? "Failed to delete product";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting product: ${e.toString()}")),
      );
    }
  }

  String formatPrice(dynamic price) {
    try {
      if (price is num) {
        final formatter = NumberFormat("#,##0", "en_US");
        return formatter.format(price);
      }
      return "0";
    } catch (e) {
      return "0";
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackButtonHandler(
      parentRoute: '/account',
      child: Scaffold(
      appBar: AppBar(
        title: const Text("My Listings"),
        actions: [
          if (!isLoading && !storeNotFound && errorMessage == null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadListings,
            ),
        ],
      ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isLoading && !storeNotFound && errorMessage == null && listings.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 12.0),
                child: Text("Your active and inactive listings.",
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            
            if (isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (errorMessage != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadListings,
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                ),
              )
            else if (storeNotFound)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.store_mall_directory_outlined, 
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text("Store Not Found",
                          style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      const Text(
                          "You need to create a store before you can add listings.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[800],
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                        ),
                        onPressed: () {
                          context.push('/create-store');
                        },
                        child: const Text("Create Store",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              )
            else if (listings.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.list_alt, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text("No listings available",
                          style: TextStyle(fontSize: 16)),
                      SizedBox(height: 8),
                      Text("Add your first product to get started",
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadListings,
                  child: ListView.builder(
                    itemCount: listings.length,
                    itemBuilder: (context, index) {
                      return _buildListingCard(listings[index]);
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: !isLoading && !storeNotFound && errorMessage == null
          ? FloatingActionButton(
              onPressed: () {
                context.push('/add-product');
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildListingCard(Map<String, dynamic> listing) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: listing["image"] != null
                      ? Image.network(
                          listing["image"],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                              Image.asset(
                                "assets/images/placeholder.png",
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                        )
                      : Image.asset(
                          "assets/images/placeholder.png",
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing["name"],
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Ksh ${formatPrice(listing["price"])}",
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red),
                      ),
                      const SizedBox(height: 2),
                      // Text(
                      //   listing["description"],
                      //   style: const TextStyle(fontSize: 12, color: Colors.grey),
                      //   maxLines: 2,
                      //   overflow: TextOverflow.ellipsis,
                      // ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == "Edit") {
                      context.push('/edit-product', extra: listing);
                    } else if (value == "Delete") {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Delete Listing"),
                          content: const Text(
                              "Are you sure you want to delete this product?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _deleteProduct(listing["id"]);
                              },
                              child: const Text("Delete",
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: "Edit", child: Text("Edit")),
                    const PopupMenuItem(value: "Delete", child: Text("Delete")),
                  ],
                  iconSize: 18,
                ),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                context.push('/promote', extra: {
                  "productId": listing["id"].toString(),
                  "productName": listing["name"]
                });
              },
              child: Container(
                width: double.infinity,
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF800000),
                      Color(0xFFA52A2A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.campaign,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Promote",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:moderntr/constants.dart';

class WishlistService {
  static const String baseUrl = BASE_URL;
  static final FlutterSecureStorage storage = FlutterSecureStorage();

  // Get the auth token.
  static Future<String?> _getToken() async {
    return await storage.read(key: "token");
  }

  // Fetch Wishlist.
  static Future<Map<String, dynamic>> getWishlist({
    required Function(String) showSnackbar,
    required Function() redirectToLogin,
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        showSnackbar("Authentication required!");
        redirectToLogin();
        return {"error": "Authentication required!"};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/wishlist/?page=$page&per_page=$perPage'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {"wishlist": data["wishlist"] ?? []};
      } else if (response.statusCode == 401) {
        showSnackbar("Unauthorized. Please log in.");
        redirectToLogin();
        return {"error": "Unauthorized"};
      } else {
        showSnackbar("Failed to load wishlist");
        return {"error": "Failed to load wishlist"};
      }
    } catch (e) {
      showSnackbar("Error fetching wishlist: ${e.toString()}");
      return {"error": e.toString()};
    }
  }

  // Add to Wishlist.
  static Future<void> addToWishlist({
    required Function(String) showSnackbar,
    required Function() redirectToLogin,
    required int productId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        showSnackbar("Authentication required!");
        redirectToLogin();
        return;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/wishlist/'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"product_id": productId}),
      );

      if (response.statusCode == 201) {
        showSnackbar("Product added to wishlist!");
      } else if (response.statusCode == 200) {
        showSnackbar("Product is already in your wishlist.");
      } else if (response.statusCode == 401) {
        showSnackbar("Unauthorized. Please log in.");
        redirectToLogin();
      } else {
        showSnackbar("Failed to add product to wishlist.");
      }
    } catch (e) {
      showSnackbar("Error adding product: ${e.toString()}");
    }
  }

  // Remove from Wishlist.
  static Future<void> removeFromWishlist({
    required Function(String) showSnackbar,
    required Function() redirectToLogin,
    required int productId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        showSnackbar("Authentication required!");
        redirectToLogin();
        return;
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/wishlist/?product_id=$productId'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        showSnackbar("Product removed from wishlist!");
      } else if (response.statusCode == 401) {
        showSnackbar("Unauthorized. Please log in.");
        redirectToLogin();
      } else {
        showSnackbar("Failed to remove product from wishlist.");
      }
    } catch (e) {
      showSnackbar("Error removing product: ${e.toString()}");
    }
  }
}

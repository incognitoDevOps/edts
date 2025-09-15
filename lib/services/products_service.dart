// ignore_for_file: use_build_context_synchronously, deprecated_member_use, avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:moderntr/constants.dart';
import 'package:html_unescape/html_unescape.dart';
// import '../models/product.dart';

class ProductService {
  final String baseUrl = BASE_URL;
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final HtmlUnescape unescape = HtmlUnescape();

  String decodeEmoji(String? text) {
    return text != null ? unescape.convert(text) : '';
  }

  void _showOverlaySnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50.0,
        left: MediaQuery.of(context).size.width * 0.2,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    try {
      final response =
          await http.get(Uri.parse("$baseUrl/products/categories/"));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['categories'] as List<dynamic>;

        return data.map((category) {
          String imageUrl = category['background'] ?? '';
          if (imageUrl.startsWith('http://localhost')) {
            imageUrl =
                imageUrl.replaceFirst('http://localhost', 'http://127.0.0.1');
          }

          return {
            'id': category['id'],
            'name': decodeEmoji(category['name']),
            'background': imageUrl,
          };
        }).toList();
      } else {
        throw Exception(
            "Failed to load categories. Status code: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching categories: $e");
    }
  }

  Future<List<Map<String, dynamic>>> fetchCountiesWithSubcounties() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/products/counties/"));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['counties'] as List<dynamic>;

        return data.map((county) {
          return {
            'id': county['id'],
            'name': decodeEmoji(county['name']),
            'subcounties':
                List<Map<String, dynamic>>.from(county['subcounties']),
          };
        }).toList();
      } else {
        throw Exception(
            "Failed to load counties. Status code: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching counties: $e");
    }
  }

  Future<List<Product>> fetchAllProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/products/all/'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final products =
            List<Product>.from(data['items'].map((x) => Product.fromJson(x)));
        return products;
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  Future<List<Product>> fetchStructuredProducts() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/products/structured/'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final products =
            List<Product>.from(data['items'].map((x) => Product.fromJson(x)));
        return products;
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  Future<void> checkUserStore(BuildContext context) async {
    try {
      final String? token = await storage.read(key: 'token');

      if (token == null) {
        if (context.mounted) {
          context.go('/login');
        }
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/products/user/store/check/'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['has_store'] == false) {
          _showOverlaySnackBar(context, "You need a store to start selling");
          await Future.delayed(const Duration(seconds: 1));

          if (context.mounted) {
            context.go('/create-store');
          }
        }
      } else {
        _showOverlaySnackBar(
            context, "Error checking store. Please try again.");
      }
    } catch (e) {
      _showOverlaySnackBar(context, "An error occurred: $e");
    }
  }

  Future<void> createStore(
    BuildContext context,
    String name,
    String email,
    String address,
    String phone,
    String product,
    String description,
    File? logo,
  ) async {
    try {
      final String? token = await storage.read(key: 'token');
      if (token == null) {
        if (context.mounted) {
          _showOverlaySnackBar(context, "You need to log in first!");
        }
        return;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/products/create/store/'),
      );
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['address'] = address;
      request.fields['phone_number'] = phone;
      request.fields['product'] = product;
      request.fields['description'] = description;

      if (logo != null) {
        request.files.add(await http.MultipartFile.fromPath('logo', logo.path));
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode == 201) {
        if (context.mounted) {
          _showOverlaySnackBar(context, "Store Created Successfully!");
          await Future.delayed(const Duration(seconds: 2));
          if (context.mounted) {
            context.go('/create-product');
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Error: ${jsonResponse['error'] ?? 'Something went wrong'}"),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred: $e")),
        );
      }
    }
  }

  Future<bool> hasStore() async {
    try {
      final String? token = await storage.read(key: 'token');
      if (token == null) return false;

      final response = await http.get(
        Uri.parse('$baseUrl/products/user/store/check/'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['has_store'] == true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint("Error in hasStore: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>> fetchProducts({
    int page = 1,
    int perPage = 100000,
    String? county,
    String? subcounty,
    String? category,
    String? subcategory,
    String? variant,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/products/all/').replace(queryParameters: {
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (county != null) 'county': county,
        if (subcounty != null) 'subcounty': subcounty,
        if (category != null) 'category': category,
        if (subcategory != null) 'subcategory': subcategory,
        if (variant != null) 'variant': variant,
      });

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        // Optionally decode emojis in top-level product list
        if (body['items'] != null && body['items'] is List) {
          body['items'] = (body['items'] as List).map((product) {
            return {
              ...product,
              'name': decodeEmoji(product['name']),
              'description': decodeEmoji(product['description']),
            };
          }).toList();
        }

        return body;
      } else {
        throw Exception("Failed to fetch products: ${response.body}");
      }
    } catch (e) {
      print(e);
      throw Exception("Error fetching products: $e");
    }
  }
}

class Product {
  final int id;
  final String name;
  final String description;
  // Add other fields as needed

  Product({
    required this.id,
    required this.name,
    required this.description,
    // Add other fields as needed
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      // Map other fields as needed
    );
  }
}

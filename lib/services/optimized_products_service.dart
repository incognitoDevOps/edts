import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:moderntr/constants.dart';
import 'package:moderntr/services/cache_service.dart';
import 'package:moderntr/services/image_service.dart';
import 'package:html_unescape/html_unescape.dart';

class OptimizedProductService {
  static const String baseUrl = BASE_URL;
  static const FlutterSecureStorage storage = FlutterSecureStorage();
  static final HtmlUnescape unescape = HtmlUnescape();

  // Cache keys
  static const String _categoriesCacheKey = 'categories';
  static const String _countiesCacheKey = 'counties';
  static const String _productsCacheKey = 'products';
  static const String _myListingsCacheKey = 'my_listings';
  static const String _structuredProductsCacheKey = 'structured_products';

  static String decodeEmoji(String? text) {
    return text != null ? unescape.convert(text) : '';
  }

  static Future<String?> _getToken() async {
    return await storage.read(key: 'token');
  }

  static Future<List<Map<String, dynamic>>> fetchCategories({bool forceRefresh = false}) async {
    return await CacheService.fetchWithCache(
      _categoriesCacheKey,
      () async {
        final response = await http.get(Uri.parse("$baseUrl/products/categories/"));
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body)['categories'] as List<dynamic>;
          
          return data.map((category) {
            String imageUrl = category['background'] ?? '';
            if (imageUrl.startsWith('http://localhost')) {
              imageUrl = imageUrl.replaceFirst('http://localhost', 'http://127.0.0.1');
            }

            return {
              'id': category['id'],
              'name': decodeEmoji(category['name']),
              'background': imageUrl,
              'subcategories': category['subcategories'] ?? [],
            };
          }).toList();
        } else {
          throw Exception("Failed to load categories. Status code: ${response.statusCode}");
        }
      },
      expiry: const Duration(hours: 6),
      forceRefresh: forceRefresh,
    ) ?? [];
  }

  static Future<List<Map<String, dynamic>>> fetchCounties({bool forceRefresh = false}) async {
    return await CacheService.fetchWithCache(
      _countiesCacheKey,
      () async {
        final response = await http.get(Uri.parse("$baseUrl/products/counties/"));
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body)['counties'] as List<dynamic>;
          
          return data.map((county) {
            return {
              'id': county['id'],
              'name': decodeEmoji(county['name']),
              'subcounties': county['subcounties'] ?? [],
            };
          }).toList();
        } else {
          throw Exception("Failed to load counties. Status code: ${response.statusCode}");
        }
      },
      expiry: const Duration(hours: 12),
      forceRefresh: forceRefresh,
    ) ?? [];
  }

  static Future<Map<String, dynamic>> fetchStructuredProducts({
    int page = 1,
    int perPage = 10,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '${_structuredProductsCacheKey}_${page}_$perPage';
    
    return await CacheService.fetchWithCache(
      cacheKey,
      () async {
        final response = await http.get(
          Uri.parse('$baseUrl/products/structured/?page=$page&per_page=$perPage'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes))['data'];
          return data as Map<String, dynamic>;
        } else {
          throw Exception('Failed to load products');
        }
      },
      expiry: const Duration(minutes: 30),
      forceRefresh: forceRefresh,
    ) ?? {'items': []};
  }

  static Future<Map<String, dynamic>> fetchProductDetails(String productId, {bool forceRefresh = false}) async {
    final cacheKey = 'product_details_$productId';
    
    return await CacheService.fetchWithCache(
      cacheKey,
      () async {
        final uri = Uri.parse("$baseUrl/products/fetch/")
            .replace(queryParameters: {"product_id": productId});

        final response = await http.get(uri);
        if (response.statusCode == 200) {
          final decodedBody = utf8.decode(response.bodyBytes);
          final data = jsonDecode(decodedBody);
          return data as Map<String, dynamic>;
        } else {
          throw Exception("Failed to load product details");
        }
      },
      expiry: const Duration(minutes: 30),
      forceRefresh: forceRefresh,
    ) ?? {};
  }

  static Future<List<Map<String, dynamic>>> searchProducts({
    required String query,
    String? category,
    String? subcategory,
    String? variant,
    String? county,
    String? subcounty,
    int page = 1,
    int perPage = 10,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'search_${query}_${category}_${subcategory}_${variant}_${county}_${subcounty}_${page}_$perPage';
    
    return await CacheService.fetchWithCache(
      cacheKey,
      () async {
        final queryParameters = {
          'q': query,
          'page': page.toString(),
          'per_page': perPage.toString(),
          if (category != null) 'category': category,
          if (subcategory != null) 'subcategory': subcategory,
          if (variant != null) 'variant': variant,
          if (county != null) 'county': county,
          if (subcounty != null) 'subcounty': subcounty,
        };

        final uri = Uri.parse('$baseUrl/products/all/').replace(queryParameters: queryParameters);
        final response = await http.get(uri);
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return List<Map<String, dynamic>>.from(data['products'] ?? []);
        } else {
          throw Exception('Failed to search products');
        }
      },
      expiry: const Duration(minutes: 15),
      forceRefresh: forceRefresh,
    ) ?? [];
  }

  static Future<List<Map<String, dynamic>>> fetchMyListings({bool forceRefresh = false}) async {
    final token = await _getToken();
    if (token == null) throw Exception('No authentication token');

    return await CacheService.fetchWithCache(
      _myListingsCacheKey,
      () async {
        final uri = Uri.parse('$baseUrl/products/store/all/').replace(queryParameters: {
          'page': '1',
          'per_page': '100',
        });

        final response = await http.get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final decoded = utf8.decode(response.bodyBytes);
          final data = jsonDecode(decoded);
          return List<Map<String, dynamic>>.from(data['products'] ?? []);
        } else if (response.statusCode == 401) {
          throw Exception('Unauthorized');
        } else if (response.statusCode == 404) {
          throw Exception('Store not found');
        } else {
          throw Exception('Failed to load listings');
        }
      },
      expiry: const Duration(minutes: 15),
      forceRefresh: forceRefresh,
    ) ?? [];
  }

  static Future<Map<String, dynamic>> createProduct({
    required BuildContext context,
    required String name,
    required String category,
    required String subCategory,
    required String unit,
    required String price,
    required String description,
    required String county,
    required String subCounty,
    required String variant,
    required String town,
    required List<File> images,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token');

      // Add watermarks to images
      final watermarkedImages = await ImageService.addWatermarkToMultiple(images);

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/products/create/'),
      );
      request.headers['Authorization'] = 'Bearer $token';

      // Attach product details
      request.fields['name'] = name;
      request.fields['category'] = category;
      request.fields['sub_category'] = subCategory;
      request.fields['unit'] = unit;
      request.fields['price'] = price;
      request.fields['description'] = description;
      request.fields['county'] = county;
      request.fields['sub_county'] = subCounty;
      request.fields['variant'] = variant;
      request.fields['town'] = town;

      // Attach watermarked images
      for (var image in watermarkedImages) {
        request.files.add(await http.MultipartFile.fromPath('images', image.path));
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseData);

      if (response.statusCode == 201) {
        // Clear cache to force refresh
        await CacheService.clearCache(_myListingsCacheKey);
        await CacheService.clearCache(_structuredProductsCacheKey);
        return {'success': true, 'message': 'Product created successfully!'};
      } else {
        return {'success': false, 'message': jsonResponse['error'] ?? 'Failed to create product'};
      }
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  static Future<bool> hasStore() async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      // Try to get from cache first
      final cachedResult = await CacheService.getCachedData<bool>('has_store');
      if (cachedResult != null) return cachedResult;

      final response = await http.get(
        Uri.parse('$baseUrl/products/user/store/check/'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final hasStore = data['has_store'] == true;
        
        // Cache the result
        await CacheService.cacheData('has_store', hasStore, expiry: const Duration(minutes: 30));
        return hasStore;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  static Future<void> invalidateCache() async {
    await CacheService.clearCache(_categoriesCacheKey);
    await CacheService.clearCache(_countiesCacheKey);
    await CacheService.clearCache(_productsCacheKey);
    await CacheService.clearCache(_myListingsCacheKey);
    await CacheService.clearCache(_structuredProductsCacheKey);
    await CacheService.clearCache('has_store');
  }
}
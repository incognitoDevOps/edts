// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moderntr/services/products_service.dart';
import 'package:http/http.dart' as http;
import 'package:moderntr/constants.dart';
import 'package:intl/intl.dart';
import 'package:moderntr/services/wishlist_service.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();
  final PageController _pageController = PageController();

  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> topViewedProducts = [];
  Set<int> wishedIds = {};

  bool isLoading = true;
  bool isLoadingTopViewed = true;

  @override
  void initState() {
    super.initState();
    print("Initializing HomeScreen...");
    _fetchCategories();
    _fetchTopViewedProducts();
    _loadWishlistIds();
  }

  Future<void> _fetchCategories() async {
    print("🟡 Fetching categories from server...");
    try {
      List<Map<String, dynamic>> data = await _productService.fetchCategories();
      print("🚀 Raw categories data received: ${data.length} items");

      final coreOrder = [
        'vehicles',
        'vehicle parts',
        'Appliances and furniture',
        'fashion',
        'electronics',
        'Phones & Tablets',
      ];

      String normalize(String input) {
        return input
            .toLowerCase()
            .replaceAll(RegExp(r'\s*&\s*'), ' and ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
      }

      final normalizedCoreOrder = coreOrder.map(normalize).toList();
      List<Map<String, dynamic>> coreCategories = [];
      List<Map<String, dynamic>> otherCategories = [];

      print("🔍 Processing categories:");
      for (var category in data) {
        final rawName = (category['name'] ?? '').toString();
        String displayName;
        try {
          displayName = utf8.decode(rawName.runes.toList());
        } catch (_) {
          displayName = rawName;
        }

        final normalizedName = normalize(displayName);
        final sortIndex = normalizedCoreOrder.indexOf(normalizedName);

        if (sortIndex != -1) {
          print("✅ Matched core category: '$displayName' (index: $sortIndex)");
          coreCategories.add({
            ...category,
            'name': displayName,
            'sortKey': sortIndex,
          });
        } else {
          print("➖ Other category: '$displayName'");
          otherCategories.add({
            ...category,
            'name': displayName,
          });
        }
      }

      coreCategories
          .sort((a, b) => (a['sortKey'] as int).compareTo(b['sortKey'] as int));
      otherCategories
          .sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));

      setState(() {
        categories = [...coreCategories, ...otherCategories];
        isLoading = false;
      });

      print(
          "\n📦 Final categories to be displayed (${categories.length} total):");
      for (int i = 0; i < categories.length; i++) {
        print("${i + 1}. ${categories[i]['name']}");
      }

      print("\n🎯 Matched core categories order:");
      for (var cat in coreCategories) {
        print("- ${cat['name']} (index: ${cat['sortKey']})");
      }
    } catch (e, st) {
      print("❗ Error fetching categories: $e");
      print("📄 Stack trace: $st");
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchTopViewedProducts() async {
    print("Fetching top viewed products...");
    try {
      final response =
          await http.get(Uri.parse('$BASE_URL/products/top-viewed/'));
      print("Top viewed products response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decodedBody);
        print("Raw top viewed products data: $data");

        final rawProducts =
            List<Map<String, dynamic>>.from(data["items"] ?? []);
        final uniqueProducts = _removeDuplicateProducts(rawProducts);

        print("Unique top viewed products (${uniqueProducts.length} items):");
        for (var product in uniqueProducts) {
          print("- ${product['name']} (ID: ${product['id']})");
        }

        setState(() {
          topViewedProducts = uniqueProducts;
          isLoadingTopViewed = false;
        });
      } else {
        print("Failed to load top viewed products: ${response.statusCode}");
        print("Response body: ${response.body}");
        setState(() => isLoadingTopViewed = false);
      }
    } catch (e, stackTrace) {
      print("Error fetching top viewed products: $e");
      print("Stack trace: $stackTrace");
      setState(() => isLoadingTopViewed = false);
    }
  }

  Future<void> _loadWishlistIds() async {
    print("Loading wishlist IDs...");
    try {
      final result = await WishlistService.getWishlist(
        showSnackbar: (_) {},
        redirectToLogin: () {},
      );
      print("Wishlist result: $result");

      final List<dynamic> list = result["wishlist"] ?? [];
      final ids = list.map((e) => e["product"]["id"] as int).toSet();

      print("Loaded ${ids.length} wishlist IDs: $ids");
      setState(() {
        wishedIds = ids;
      });
    } catch (e, stackTrace) {
      print("Error loading wishlist: $e");
      print("Stack trace: $stackTrace");
    }
  }

  void _toggleWishlist(int productId) async {
    final isWished = wishedIds.contains(productId);

    if (isWished) {
      await WishlistService.removeFromWishlist(
        productId: productId,
        showSnackbar: (msg) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg))),
        redirectToLogin: () => context.push('/login'),
      );
      setState(() {
        wishedIds.remove(productId);
      });
    } else {
      await WishlistService.addToWishlist(
        productId: productId,
        showSnackbar: (msg) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg))),
        redirectToLogin: () => context.push('/login'),
      );
      setState(() {
        wishedIds.add(productId);
      });
    }
  }

  String _decodeEmojiSafe(dynamic text) {
    try {
      if (text == null) return '';
      if (text is! String) return text.toString();

      // Properly decode \uXXXX or \\ud83d\\ude80 → 🚀
      return jsonDecode('"$text"');
    } catch (_) {
      return text.toString();
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  List<Map<String, dynamic>> _removeDuplicateProducts(
      List<Map<String, dynamic>> products) {
    final seen = <String>{};
    final uniqueList = <Map<String, dynamic>>[];

    for (var product in products) {
      final key =
          "${product['name']}-${product['price']}-${product['store_id'] ?? ''}";
      if (!seen.contains(key)) {
        seen.add(key);
        uniqueList.add(product);
      }
    }
    return uniqueList;
  }

  String _truncateDescription(String description, int maxLength) {
    return description.length > maxLength
        ? '${description.substring(0, maxLength)}...'
        : description;
  }

  List<List<Map<String, dynamic>>> _chunkedCategories(
      List<Map<String, dynamic>> list, int size) {
    List<List<Map<String, dynamic>>> chunks = [];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(
          list.sublist(i, i + size > list.length ? list.length : i + size));
    }
    return chunks;
  }

  @override
  Widget build(BuildContext context) {
    final pages = _chunkedCategories(categories, 6);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Center(
          child: Container(
            margin: const EdgeInsets.all(18.0),
            child: Image.asset('assets/images/logo.png', height: 50),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // CATEGORIES SECTION
                    SizedBox(
                      height: 250,
                      child: categories.isEmpty
                          ? const Center(child: Text("No categories available"))
                          : PageView.builder(
                              controller: _pageController,
                              itemCount: pages.length,
                              itemBuilder: (context, pageIndex) {
                                final items = pages[pageIndex];
                                return GridView.count(
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 3,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 2),
                                  childAspectRatio: 0.85,
                                  mainAxisSpacing: 2,
                                  crossAxisSpacing: 8,
                                  children: items.map((category) {
                                    return GestureDetector(
                                      onTap: () {
                                        context.go(
                                            '/category-listing?category=${category['id']}');
                                      },
                                      child: SizedBox(
                                        height: 120,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Container(
                                              height: 90,
                                              width: 120,
                                              padding:
                                                  const EdgeInsets.all(5.0),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: category['background'] !=
                                                      null
                                                  ? ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                      child: Image.network(
                                                        category['background'],
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context,
                                                            error, stackTrace) {
                                                          return const Icon(Icons
                                                              .image_not_supported);
                                                        },
                                                      ),
                                                    )
                                                  : const Icon(Icons
                                                      .image_not_supported),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              category['name'] ?? 'Unnamed',
                                              style: const TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.brown,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                    ),

                    if (pages.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SmoothPageIndicator(
                        controller: _pageController,
                        count: pages.length,
                        effect: WormEffect(
                          activeDotColor: Colors.brown,
                          dotColor: Colors.grey.shade300,
                          dotHeight: 5,
                          dotWidth: 28,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // TOP VIEWED PRODUCTS SECTION
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Top Viewed Products",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    isLoadingTopViewed
                        ? const Center(child: CircularProgressIndicator())
                        : topViewedProducts.isEmpty
                            ? const Text("No top viewed products available.")
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: topViewedProducts.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 12,
                                  childAspectRatio:
                                      0.69, // Adjusted to prevent overflow
                                ),
                                itemBuilder: (context, index) {
                                  final product = topViewedProducts[index];
                                  return _buildTopViewedProductCard(product);
                                },
                              ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTopViewedProductCard(Map<String, dynamic> product) {
    final formattedPrice =
        NumberFormat("#,##0", "en_US").format(product['price']);
    final String town = product['town']?.toString().trim() ?? '';
    final String county = product['county']?.toString().trim() ?? '';

    final String location = [
      if (town.isNotEmpty) town,
      if (county.isNotEmpty) county,
    ].join(', '); // This avoids trailing or leading commas

    final bool isWished = wishedIds.contains(product['id']);

    return GestureDetector(
      onTap: () =>
          context.push('/product-details', extra: {"id": product["id"]}),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 290, // Constrain height to prevent overflow
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  product['image'] != null
                      ? Image.network(
                          product['image'],
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 160,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, size: 40),
                        ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: IconButton(
                      icon: Icon(
                        isWished ? Icons.favorite : Icons.favorite_border,
                        color: isWished ? Colors.red : Colors.grey,
                        size: 22,
                      ),
                      onPressed: () => _toggleWishlist(product['id']),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(6.0),
                child: Text(
                  _decodeEmojiSafe(product['name']),
                  style: const TextStyle(
                    color: Colors.brown,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: Text(
                  "Ksh $formattedPrice",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 6.0),
              //   child: Text(
              //     _truncateDescription(
              //         _decodeEmojiSafe(product['description']), 50),
              //     style: const TextStyle(fontSize: 10, color: Colors.grey),
              //     maxLines: 2,
              //     overflow: TextOverflow.ellipsis,
              //   ),
              // ),
              const Spacer(), // Pushes location to the bottom

              // Conditionally show location if it exists
              if (location.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6.0, vertical: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: Colors.black54),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(
                              fontSize: 10, color: Colors.black54),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

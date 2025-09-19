import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moderntr/services/products_service.dart';
import 'package:http/http.dart' as http;
import 'package:moderntr/constants.dart';
import 'package:intl/intl.dart';
import 'package:moderntr/services/wishlist_service.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shimmer/shimmer.dart';
import 'package:moderntr/widgets/back_button_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();
  final int _productsPerPage = 20;

  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> boostedProducts = [];
  List<Map<String, dynamic>> mostViewedProducts = [];
  Set<int> wishedIds = {};

  bool isLoadingCategories = true;
  bool isLoadingProducts = true;
  bool hasError = false;
  bool isRefreshing = false;
  
  // Most viewed products pagination
  int _mostViewedPage = 1;
  bool _hasMoreMostViewed = true;
  bool _isLoadingMoreMostViewed = false;
  final int _mostViewedPerPage = 20;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadWishlistIds() async {
    try {
      final result = await WishlistService.getWishlist(
        showSnackbar: (_) {},
        redirectToLogin: () {},
      );
      final List<dynamic> list = result["wishlist"] ?? [];
      final ids = list.map((e) => e["product"]["id"] as int).toSet();
      setState(() => wishedIds = ids);
    } catch (e) {
      // Silently fail - wishlist is non-critical
    }
  }

  Future<void> _fetchInitialData() async {
    await Future.wait([
      _fetchCategories(),
      _fetchStructuredProducts(),
      _loadWishlistIds(),
    ]);
  }

  Future<void> _fetchCategories() async {
    try {
      List<Map<String, dynamic>> data = await _productService.fetchCategories();
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
          coreCategories.add({
            ...category,
            'name': displayName,
            'sortKey': sortIndex,
          });
        } else {
          otherCategories.add({
            ...category,
            'name': displayName,
          });
        }

        coreCategories.sort(
            (a, b) => (a['sortKey'] as int).compareTo(b['sortKey'] as int));
        otherCategories
            .sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));

        setState(() {
          categories = [...coreCategories, ...otherCategories];
          isLoadingCategories = false;
        });
        setState(() => isLoadingCategories = false);
      }
    } catch (e) {
      setState(() {
        isLoadingCategories = false;
        hasError = true;
      });
    }
  }

  List<Map<String, dynamic>> _removeDuplicateProducts(
    List<Map<String, dynamic>> products,
  ) {
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

  Future<void> _fetchStructuredProducts({bool refresh = false}) async {
    try {
      if (refresh) {
        setState(() {
          isRefreshing = true;
          _mostViewedPage = 1;
          _hasMoreMostViewed = true;
          boostedProducts.clear();
          mostViewedProducts.clear();
        });
      }

      final response = await http.get(
        Uri.parse(
            '$BASE_URL/products/structured/?page=$_mostViewedPage&per_page=$_mostViewedPerPage'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes))['data'];
        final newProducts =
            List<Map<String, dynamic>>.from(data['items'] ?? []);

        // Filter and deduplicate
        final newBoosted = _removeDuplicateProducts(
          newProducts.where((p) => p['is_boosted'] == true).toList(),
        );

        final newMostViewed = _removeDuplicateProducts(
          newProducts
              .where((p) => p['view_count'] > 0 && p['is_boosted'] != true)
              .toList(),
        );


        setState(() {
          if (refresh) {
            boostedProducts = newBoosted;
            mostViewedProducts = newMostViewed;
          } else {
            // Only add new products that aren't already in the lists
            final existingBoostedIds = boostedProducts.map((p) => p['id']).toSet();
            final existingMostViewedIds = mostViewedProducts.map((p) => p['id']).toSet();
            
            boostedProducts.addAll(
              newBoosted.where((p) => !existingBoostedIds.contains(p['id'])),
            );
            mostViewedProducts.addAll(
              newMostViewed.where((p) => !existingMostViewedIds.contains(p['id'])),
            );
          }

          _hasMoreMostViewed = newProducts.length >= _mostViewedPerPage;
          isLoadingProducts = false;
          isRefreshing = false;
          _isLoadingMoreMostViewed = false;
        });
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      setState(() {
        isLoadingProducts = false;
        hasError = true;
        isRefreshing = false;
        _isLoadingMoreMostViewed = false;
      });
    }
  }

  void _scrollListener() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange &&
        !_isLoadingMoreMostViewed &&
        _hasMoreMostViewed) {
      _loadMoreMostViewedProducts();
    }
  }
  Future<void> _loadMoreMostViewedProducts() async {
    if (_isLoadingMoreMostViewed || !_hasMoreMostViewed) return;
    
    setState(() => _isLoadingMoreMostViewed = true);
    
    try {
      _mostViewedPage++;
      final response = await http.get(
        Uri.parse('$BASE_URL/products/all/?page=$_mostViewedPage&per_page=$_mostViewedPerPage'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final newProducts = List<Map<String, dynamic>>.from(data['products'] ?? []);
        
        // Filter for most viewed products (view_count > 0)
        final newMostViewed = _removeDuplicateProducts(
          newProducts.where((p) => (p['view_count'] ?? 0) > 0).toList(),
        );
        
        setState(() {
          // Only add products that aren't already in the list
          final existingIds = mostViewedProducts.map((p) => p['id']).toSet();
          final uniqueNewProducts = newMostViewed.where((p) => !existingIds.contains(p['id'])).toList();
          
          mostViewedProducts.addAll(uniqueNewProducts);
          _hasMoreMostViewed = newProducts.length >= _mostViewedPerPage;
          _isLoadingMoreMostViewed = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingMoreMostViewed = false);
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _mostViewedPage = 1;
      _hasMoreMostViewed = true;
      mostViewedProducts.clear();
      boostedProducts.clear();
    });
    await _fetchStructuredProducts(refresh: true);
  }

  Widget _buildSkeletonLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 12,
          childAspectRatio: 0.69,
        ),
        itemBuilder: (context, index) {
          return Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: SizedBox(
              height: 290,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 160,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 16,
                          width: double.infinity,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 14,
                          width: 100,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _cleanImageUrl(String url) {
    if (url.contains('https://moderntrademarket.comhttps://')) {
      return url.replaceFirst(
          'https://moderntrademarket.comhttps://', 'https://');
    }
    return url;
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

  void _toggleWishlist(int productId) async {
    final isWished = wishedIds.contains(productId);
    try {
      if (isWished) {
        await WishlistService.removeFromWishlist(
          productId: productId,
          showSnackbar: (msg) => ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg))),
          redirectToLogin: () => context.push('/login'),
        );
      } else {
        await WishlistService.addToWishlist(
          productId: productId,
          showSnackbar: (msg) => ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg))),
          redirectToLogin: () => context.push('/login'),
        );
      }
      setState(() {
        if (isWished) {
          wishedIds.remove(productId);
        } else {
          wishedIds.add(productId);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update wishlist')),
      );
    }
  }

  String _decodeEmojiSafe(dynamic text) {
    try {
      if (text == null) return '';
      if (text is! String) return text.toString();
      return jsonDecode('"$text"');
    } catch (_) {
      return text.toString();
    }
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final formattedPrice =
        NumberFormat("#,##0", "en_US").format(product['price']);
    final location = [
      if (product['town']?.toString().trim().isNotEmpty ?? false)
        product['town'].toString().trim(),
      if (product['county']?.toString().trim().isNotEmpty ?? false)
        product['county'].toString().trim(),
    ].join(', ');

    final rawImage = product['image']?.toString() ?? '';
    final imageUrl = _cleanImageUrl(rawImage);

    final isWished = wishedIds.contains(product['id']);

    return GestureDetector(
      onTap: () =>
          context.push('/product-details', extra: {"id": product["id"]}),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 290,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  if (imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 160,
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print("Image load error for: $imageUrl");
                        return Image.asset(
                          "assets/images/placeholder.png",
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  else
                    Image.asset(
                      "assets/images/placeholder.png",
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: IconButton(
                      icon: Icon(
                        isWished ? Icons.favorite : Icons.favorite_border,
                        color: isWished ? Colors.red : Colors.grey,
                      ),
                      onPressed: () => _toggleWishlist(product['id']),
                    ),
                  ),
                  if (product['is_boosted'] == true)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Color.fromARGB(237, 75, 7, 1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'BOOSTED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _decodeEmojiSafe(product['name']),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ksh $formattedPrice',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = _chunkedCategories(categories, 6);

    return BackButtonHandler(
      showExitConfirmation: true,
      child: Scaffold(
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
      body: hasError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Failed to load data'),
                  TextButton(
                    onPressed: _fetchInitialData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // CATEGORIES SECTION
                    isLoadingCategories
                        ? _buildSkeletonLoader()
                        : SizedBox(
                            height: 250,
                            child: categories.isEmpty
                                ? const Center(
                                    child: Text("No categories available"))
                                : PageView.builder(
                                    controller: _pageController,
                                    itemCount: pages.length,
                                    itemBuilder: (context, pageIndex) {
                                      final items = pages[pageIndex];
                                      return GridView.count(
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        crossAxisCount: 3,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 2),
                                        childAspectRatio: 0.85,
                                        mainAxisSpacing: 2,
                                        crossAxisSpacing: 8,
                                        children: items.map((category) {
                                          return GestureDetector(
                                            onTap: () => context.go(
                                                '/category-listing?category=${category['id']}'),
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
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[200],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                    child: category[
                                                                'background'] !=
                                                            null
                                                        ? ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        6),
                                                            child:
                                                                Image.network(
                                                              _cleanImageUrl(
                                                                  category[
                                                                      'background']),
                                                              fit: BoxFit.cover,
                                                              errorBuilder:
                                                                  (context,
                                                                      error,
                                                                      stackTrace) {
                                                                return Image
                                                                    .asset(
                                                                  "assets/images/placeholder.png",
                                                                  fit: BoxFit
                                                                      .cover,
                                                                );
                                                              },
                                                            ),
                                                          )
                                                        : Image.asset(
                                                            "assets/images/placeholder.png",
                                                            fit: BoxFit.cover,
                                                          ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    category['name'] ??
                                                        'Unnamed',
                                                    style: const TextStyle(
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.brown,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
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

                    // BOOSTED PRODUCTS SECTION
                    if (boostedProducts.isNotEmpty) ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            "Featured Products",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      isLoadingProducts && boostedProducts.isEmpty
                          ? _buildSkeletonLoader()
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: boostedProducts.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.69,
                              ),
                              itemBuilder: (context, index) {
                                return _buildProductCard(
                                    boostedProducts[index]);
                              },
                            ),
                      const SizedBox(height: 20),
                    ],

                    // MOST VIEWED PRODUCTS SECTION
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          "Most Viewed",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    isLoadingProducts && mostViewedProducts.isEmpty
                        ? _buildSkeletonLoader()
                        : mostViewedProducts.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: _buildSkeletonLoader(),
                              )
                            : Column(
                                children: [
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: mostViewedProducts.length,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 0.69,
                                    ),
                                    itemBuilder: (context, index) {
                                      return _buildProductCard(
                                          mostViewedProducts[index]);
                                    },
                                  ),
                                  if (_isLoadingMoreMostViewed)
                                    const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  if (!_hasMoreMostViewed &&
                                      mostViewedProducts.isNotEmpty)
                                    const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text("No more products available"),
                                    ),
                                ],
                              ),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}

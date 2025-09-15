// ignore_for_file: library_private_types_in_public_api, avoid_print

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:moderntr/constants.dart';
import 'package:intl/intl.dart';
import 'package:moderntr/widgets/back_button_handler.dart';

class CategoryListings extends StatefulWidget {
  const CategoryListings({super.key});

  @override
  _CategoryListingsState createState() => _CategoryListingsState();
}

class _CategoryListingsState extends State<CategoryListings> {
  // Products will be dynamically fetched.
  List products = [];

  // Lists for filter items.
  List categories = [];
  List subcategories = [];
  List variants = [];
  String? selectedCategory; // Stores the category id
  String? selectedSubcategory; // Stores the subcategory id
  String? selectedVariant; // Stores the variant id

  List counties = [];
  List subcounties = [];
  String? selectedCounty; // Stores the county id
  String? selectedSubcounty; // Stores the subcounty id

  bool _initialized = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreProducts = true;
  int _currentPage = 1;
  final int _productsPerPage = 20;
  final ScrollController _scrollController = ScrollController();

  // Toggle between grid and list view.
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchCounties();
    _scrollController.addListener(_scrollListener);
    // fetchProducts() will be called later after processing query parameters.
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange &&
        !_isLoadingMore &&
        _hasMoreProducts) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreProducts) return;
    
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    
    await fetchProducts(loadMore: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      // Use GoRouterState to get query parameters.
      final categoryParam =
          GoRouterState.of(context).uri.queryParameters['category'];
      if (categoryParam != null) {
        selectedCategory = categoryParam;
      }
      _initialized = true;
      fetchProducts();
    }
  }

  Future<void> fetchCategories() async {
    final response =
        await http.get(Uri.parse('$BASE_URL/products/categories/'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        categories = data['categories'];
        // If no category is selected, show all subcategories from every category.
        if (selectedCategory == null) {
          subcategories = _getAllSubcategories();
          // Also, if no subcategory is selected, show all variants.
          variants = _getAllVariants(from: subcategories);
        }
      });
    }
  }

  Future<void> fetchCounties() async {
    final response = await http.get(Uri.parse('$BASE_URL/products/counties/'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        counties = data['counties'];
        // If no county is selected, list all subcounties from every county.
        if (selectedCounty == null) {
          subcounties = _getAllSubcounties();
        }
      });
    }
  }

  /// Helper to get all subcategories from all categories.
  List _getAllSubcategories() {
    List allSubs = [];
    for (var category in categories) {
      if (category['subcategories'] != null) {
        allSubs.addAll(category['subcategories']);
      }
    }
    return allSubs;
  }

  /// Helper to get all variants from a list of subcategories.
  List _getAllVariants({required List from}) {
    List allVariants = [];
    for (var sub in from) {
      if (sub['variants'] != null) {
        allVariants.addAll(sub['variants']);
      }
    }
    return allVariants;
  }

  /// Helper to get all subcounties from all counties.
  List _getAllSubcounties() {
    List allSubs = [];
    for (var county in counties) {
      if (county['subcounties'] != null) {
        allSubs.addAll(county['subcounties']);
      }
    }
    return allSubs;
  }

  /// Fetch products using the selected filters (using IDs).
  Future<void> fetchProducts({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        _currentPage = 1;
        _hasMoreProducts = true;
        _isLoading = true;
      });
    }

    final queryParameters = {
      'page': _currentPage.toString(),
      'per_page': _productsPerPage.toString(),
      if (selectedCounty != null) 'county': selectedCounty!,
      if (selectedSubcounty != null) 'subcounty': selectedSubcounty!,
      if (selectedCategory != null) 'category': selectedCategory!,
      if (selectedSubcategory != null) 'subcategory': selectedSubcategory!,
      if (selectedVariant != null) 'variant': selectedVariant!,
    };

    final uri = Uri.parse("$BASE_URL/products/all/")
        .replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newProducts = List<Map<String, dynamic>>.from(data['products'] ?? []);
        
        setState(() {
          if (loadMore) {
            products.addAll(newProducts);
          } else {
            products = newProducts;
          }
          _hasMoreProducts = newProducts.length >= _productsPerPage;
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        print('Error: ${response.statusCode}');
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      print('Exception: $e');
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  /// Returns the display name for a given ID.
  String _getNameById(List items, String? id, String defaultLabel) {
    if (id == null) return defaultLabel;
    final item = items.firstWhere(
      (element) => element['id'].toString() == id,
      orElse: () => null,
    );
    return item != null ? item['name'] ?? defaultLabel : defaultLabel;
  }

  void _onCountySelected(String? countyId) {
    setState(() {
      selectedCounty = countyId;
      if (countyId == null) {
        // If no county is selected, list all subcounties.
        subcounties = _getAllSubcounties();
      } else {
        // Find the selected county and use its subcounties.
        final county = counties.firstWhere(
            (cat) => cat['id'].toString() == countyId,
            orElse: () => {'subcounties': []});
        subcounties = county['subcounties'] ?? [];
      }
      selectedSubcounty = null;
    });
    fetchProducts();
  }

  void onCategorySelected(String? categoryId) {
    setState(() {
      selectedCategory = categoryId;
      if (categoryId == null) {
        // If no category selected, display all subcategories from every category.
        subcategories = _getAllSubcategories();
        // And also display all variants from these subcategories.
        variants = _getAllVariants(from: subcategories);
      } else {
        // Find the selected category and use its subcategories.
        final category = categories.firstWhere(
            (cat) => cat['id'].toString() == categoryId,
            orElse: () => {'subcategories': []});
        subcategories = category['subcategories'] ?? [];
        // Clear subcategory selection since we are changing category.
        selectedSubcategory = null;
        // Reset variants accordingly.
        variants = _getAllVariants(from: subcategories);
      }
      // Clear variant selection.
      selectedVariant = null;
    });
    fetchProducts();
  }

  void onSubcategorySelected(String? subcategoryId) {
    setState(() {
      selectedSubcategory = subcategoryId;
      if (subcategoryId == null) {
        // If no subcategory is selected, list all variants from the current subcategories.
        variants = _getAllVariants(from: subcategories);
      } else {
        final subcat = subcategories.firstWhere(
            (sub) => sub['id'].toString() == subcategoryId,
            orElse: () => {'variants': []});
        variants = subcat['variants'] ?? [];
      }
      selectedVariant = null;
    });
    fetchProducts();
  }

  void onVariantSelected(String? variantId) {
    setState(() {
      selectedVariant = variantId;
    });
    fetchProducts();
  }

  void onSubcountySelected(String? subcountyId) {
    setState(() {
      selectedSubcounty = subcountyId;
    });
    fetchProducts();
  }

  /// Helper function to truncate description text.
  String _truncateDescription(String description, int maxLength) {
    return description.length > maxLength
        ? '${description.substring(0, maxLength)}...'
        : description;
  }

  /// A reusable dropdown builder that uses IDs for selection.
  /// It includes an initial option for "All {defaultLabel}".
  Widget buildStyledDropdown(String defaultLabel, List items,
      String? selectedId, void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ElevatedButton.icon(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              List<Widget> options = [];
              // Add the "All" option.
              options.add(
                ListTile(
                  title: Text("All $defaultLabel"),
                  onTap: () {
                    onChanged(null);
                    Navigator.pop(context);
                  },
                ),
              );
              options.addAll(
                items.map<Widget>((item) {
                  return ListTile(
                    title: Text(item['name']),
                    onTap: () {
                      onChanged(item['id'].toString());
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              );
              return ListView(children: options);
            },
          );
        },
        icon: const Icon(Icons.arrow_drop_down, color: Colors.brown),
        label: Text(
          selectedId != null
              ? _getNameById(items, selectedId, defaultLabel)
              : defaultLabel,
          style: const TextStyle(color: Colors.brown),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 1,
        ),
      ),
    );
  }

  Widget _buildCountyDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ElevatedButton.icon(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              List<Widget> options = [];
              // "All County" option.
              options.add(
                ListTile(
                  title: const Text("All County"),
                  onTap: () {
                    _onCountySelected(null);
                    Navigator.pop(context);
                  },
                ),
              );
              options.addAll(
                counties.map<Widget>((county) {
                  return ListTile(
                    title: Text(county['name']),
                    onTap: () {
                      _onCountySelected(county['id'].toString());
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              );
              return ListView(children: options);
            },
          );
        },
        icon: const Icon(Icons.arrow_drop_down, color: Colors.brown),
        label: Text(
          selectedCounty != null
              ? _getNameById(counties, selectedCounty, "County")
              : "County",
          style: const TextStyle(color: Colors.brown),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 1,
        ),
      ),
    );
  }

  Widget _buildSubCountyDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ElevatedButton.icon(
        onPressed: () {
          // If no county is selected, list all subcounties from every county.
          List availableSubcounties = [];
          if (selectedCounty == null) {
            availableSubcounties = _getAllSubcounties();
          } else {
            availableSubcounties = subcounties;
          }
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              List<Widget> options = [];
              options.add(
                ListTile(
                  title: const Text("All Sub County"),
                  onTap: () {
                    onSubcountySelected(null);
                    Navigator.pop(context);
                  },
                ),
              );
              options.addAll(
                availableSubcounties.map<Widget>((subcounty) {
                  return ListTile(
                    title: Text(subcounty['name']),
                    onTap: () {
                      onSubcountySelected(subcounty['id'].toString());
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              );
              return ListView(children: options);
            },
          );
        },
        icon: const Icon(Icons.arrow_drop_down, color: Colors.brown),
        label: Text(
          selectedSubcounty != null
              ? _getNameById(subcounties, selectedSubcounty, "Sub County")
              : "Sub County",
          style: const TextStyle(color: Colors.brown),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 1,
        ),
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      controller: _scrollController,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.7,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return _buildProductCard(products[index]);
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: products.length,
      itemBuilder: (context, index) {
        final item = products[index];
        return _buildProductListItem(item);
      },
    );
  }

  Widget _buildProductCard(Map item) {
    final String town = item['town']?.toString().trim() ?? '';
    final String county = item['county']?.toString().trim() ?? '';

    final String location = [
      if (town.isNotEmpty) town,
      if (county.isNotEmpty) county,
    ].join(', '); // Avoids trailing/leading commas

    final formattedPrice = NumberFormat("#,##0", "en_US").format(item['price']);

    return GestureDetector(
      onTap: () {
        // Navigate to product details passing the product id.
        context.push('/product-details', extra: {"id": item["id"]});
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            item['image'] != null
                ? AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      item['image'],
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(),
                    ),
                  ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? '',
                    style: const TextStyle(
                        color: Colors.brown, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // const SizedBox(height: 8),
                  // Text(
                  //   _truncateDescription(item['description'] ?? '', 50),
                  //   style: const TextStyle(color: Colors.black54),
                  //   maxLines: 2,
                  //   overflow: TextOverflow.ellipsis,
                  // ),
                  const SizedBox(height: 8),
                  Text(
                    "Ksh $formattedPrice",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Conditionally show location only if it exists
                  if (location.isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on,
                            size: 14, color: Colors.black54),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            location,
                            style: const TextStyle(color: Colors.black54),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductListItem(Map item) {
    final String town = item['town']?.toString().trim() ?? '';
    final String county = item['county']?.toString().trim() ?? '';

    final String location = [
      if (town.isNotEmpty) town,
      if (county.isNotEmpty) county,
    ].join(', '); // Avoids empty commas

    final formattedPrice = NumberFormat("#,##0", "en_US").format(item['price']);

    return GestureDetector(
      onTap: () {
        context.push('/product-details', extra: {"id": item["id"]});
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            item['image'] != null
                ? Image.network(
                    item['image'],
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 120,
                    width: 120,
                    color: Colors.grey[200],
                  ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] ?? '',
                      style: const TextStyle(
                          color: Colors.brown, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _truncateDescription(item['description'] ?? '', 50),
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Ksh $formattedPrice",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    // Conditionally show location only if it's not empty
                    if (location.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 14, color: Colors.black54),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              style: const TextStyle(color: Colors.black54),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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

  @override
  Widget build(BuildContext context) {
    return BackButtonHandler(
      parentRoute: '/',
      child: Scaffold(
        body: Column(
          children: [
            // Filters row.
            SizedBox(
              height: 50,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // For category filter, include an "All Category" option via buildStyledDropdown.
                    buildStyledDropdown("Category", categories, selectedCategory,
                        onCategorySelected),
                    buildStyledDropdown("Sub Category", subcategories,
                        selectedSubcategory, onSubcategorySelected),
                    buildStyledDropdown(
                        "Variant", variants, selectedVariant, onVariantSelected),
                    _buildCountyDropdown(),
                    _buildSubCountyDropdown(),
                  ],
                ),
              ),
            ),
            // Toggle view row.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.grid_view,
                        color: _isGridView ? Colors.blue : Colors.grey),
                    onPressed: () {
                      setState(() {
                        _isGridView = true;
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.list,
                        color: !_isGridView ? Colors.blue : Colors.grey),
                    onPressed: () {
                      setState(() {
                        _isGridView = false;
                      });
                    },
                  ),
                ],
              ),
            ),
            // Product listings.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : (products.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.search_off,
                                    size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  "No products available",
                                  style:
                                      TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: _isGridView
                                    ? _buildGridView()
                                    : _buildListView(),
                              ),
                              if (_isLoadingMore)
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              if (!_hasMoreProducts && products.isNotEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text("No more products available"),
                                ),
                            ],
                          )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
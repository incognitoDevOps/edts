// ignore_for_file: library_private_types_in_public_api

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:moderntr/constants.dart';
import 'package:intl/intl.dart'; // For price formatting

const String baseUrl = BASE_URL;

class SearchResultsPage extends StatefulWidget {
  final String searchQuery;

  const SearchResultsPage({super.key, required this.searchQuery});

  @override
  _SearchResultsPageState createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  List products = [];

  // Filter lists and selected values.
  List categories = [];
  List subcategories = [];
  List variants = [];
  String? selectedCategory;
  String? selectedSubcategory;
  String? selectedVariant;

  List counties = [];
  List subcounties = [];
  String? selectedCounty;
  String? selectedSubcounty;

  // The search query passed in via URL.
  String searchQuery = "";
  bool _initialized = false;

  // Toggle between grid and list view.
  bool _isGridView = true;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchCounties();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      // Extract the search query parameter from the URL.
      final queryParam = GoRouterState.of(context).uri.queryParameters['q'];
      if (queryParam != null && queryParam.isNotEmpty) {
        searchQuery = queryParam;
      } else {
        searchQuery = widget.searchQuery;
      }
      _initialized = true;
      fetchProducts();
    }
  }

  Future<void> fetchCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/products/categories/'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        categories = data['categories'];
      });
    }
  }

  Future<void> fetchCounties() async {
    final response = await http.get(Uri.parse('$baseUrl/products/counties/'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        counties = data['counties'];
      });
    }
  }

  /// Fetch products from the search endpoint with filters.
  Future<void> fetchProducts() async {
    final queryParameters = {
      'q': searchQuery,
      'page': '1',
      'per_page': '10',
      if (selectedCounty != null) 'county': selectedCounty!,
      if (selectedSubcounty != null) 'subcounty': selectedSubcounty!,
      if (selectedCategory != null) 'category': selectedCategory!,
      if (selectedSubcategory != null) 'subcategory': selectedSubcategory!,
      if (selectedVariant != null) 'variant': selectedVariant!,
    };

    final uri = Uri.parse(
        '$baseUrl/products/all/?${Uri(queryParameters: queryParameters).query}');
    setState(() {
      _isLoading = true;
    });
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        products = data['products'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
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
      final county = counties.firstWhere(
          (cat) => cat['id'].toString() == countyId,
          orElse: () => {'subcounties': []});
      subcounties = county['subcounties'] ?? [];
      selectedSubcounty = null;
    });
    fetchProducts();
  }

  void onCategorySelected(String? categoryId) {
    setState(() {
      selectedCategory = categoryId;
      final category = categories.firstWhere(
          (cat) => cat['id'].toString() == categoryId,
          orElse: () => {'subcategories': []});
      subcategories = category['subcategories'] ?? [];
      selectedSubcategory = null;
      variants = [];
    });
    fetchProducts();
  }

  void onSubcategorySelected(String? subcategoryId) {
    setState(() {
      selectedSubcategory = subcategoryId;
      final subcat = subcategories.firstWhere(
          (sub) => sub['id'].toString() == subcategoryId,
          orElse: () => {'variants': []});
      variants = subcat['variants'] ?? [];
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

  /// Reusable dropdown builder.
  Widget buildStyledDropdown(String defaultLabel, List items,
      String? selectedId, void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ElevatedButton.icon(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return ListView(
                children: items.map<Widget>((item) {
                  return ListTile(
                    title: Text(item['name']),
                    onTap: () {
                      onChanged(item['id'].toString());
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              );
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
              return ListView(
                children: counties.map<Widget>((county) {
                  return ListTile(
                    title: Text(county['name']),
                    onTap: () {
                      _onCountySelected(county['id'].toString());
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              );
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
          if (subcounties.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please select a county first")),
            );
            return;
          }
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return ListView(
                children: subcounties.map<Widget>((subcounty) {
                  return ListTile(
                    title: Text(subcounty['name']),
                    onTap: () {
                      onSubcountySelected(subcounty['id'].toString());
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              );
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

  /// Helper function to truncate description text.
  String _truncateDescription(String description, int maxLength) {
    return description.length > maxLength
        ? '${description.substring(0, maxLength)}...'
        : description;
  }

  /// Builds a product card for grid view.
  Widget _buildProductCard(Map item) {
    final String location = "${item['town'] ?? ''}, ${item['county'] ?? ''}";
    // Format the price with commas.
    final formattedPrice = NumberFormat("#,##0", "en_US").format(item['price']);
    return GestureDetector(
      onTap: () {
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
                ? Image.network(
                    item['image'],
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 120,
                    width: double.infinity,
                    color: Colors.grey[200],
                  ),
            Padding(
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
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: Colors.black54),
                      const SizedBox(width: 4),
                      Flexible(
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
          ],
        ),
      ),
    );
  }

  /// Builds a product list item for list view.
  Widget _buildProductListItem(Map item) {
    final String location = "${item['town'] ?? ''}, ${item['county'] ?? ''}";
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
                    height: 150,
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

  /// Custom header for search results.
  Widget _buildSearchHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Search Results",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          "Showing results for \"$searchQuery\"",
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Filters row.
          SizedBox(
            height: 50,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
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
          // Search header.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: _buildSearchHeader(),
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
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                "No products available",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _isGridView
                          ? GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.55,
                              ),
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                final item = products[index];
                                return _buildProductCard(item);
                              },
                            )
                          : ListView.builder(
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                final item = products[index];
                                return _buildProductListItem(item);
                              },
                            )),
            ),
          ),
        ],
      ),
    );
  }
}

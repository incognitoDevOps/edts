// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:moderntr/constants.dart';
import 'package:intl/intl.dart';
import 'package:moderntr/widgets/back_button_handler.dart';
import 'package:moderntr/services/products_service.dart';

class PromoteProductWidget extends StatefulWidget {
  final String productId;
  final String productName;

  const PromoteProductWidget({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  _PromoteProductWidgetState createState() => _PromoteProductWidgetState();
}

class _PromoteProductWidgetState extends State<PromoteProductWidget> {
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final ProductService _productService = ProductService();
  
  bool _isSubmitting = false;
  bool _isLoadingPricing = true;
  String? _resolvedProductCategory;
  double _monthlyAmount = 100.0; // Default amount
  Map<String, dynamic> _pricingConfig = {};
  List<Map<String, dynamic>> categories = [];

  @override
  void initState() {
    super.initState();
    _initializePromotion();
  }

  Future<void> _initializePromotion() async {
    await Future.wait([
      _fetchPricingConfig(),
      _fetchCategories(),
      _resolveProductCategory(),
    ]);
    _calculatePromotionAmount();
  }

  Future<void> _fetchPricingConfig() async {
    try {
      final response = await http.get(Uri.parse("$BASE_URL/ads/pricing-config/"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _pricingConfig = data;
        });
      }
    } catch (e) {
      print('Error fetching pricing config: $e');
      // Use defaults if API fails
      setState(() {
        _pricingConfig = {
          'premium_price': 150.0,
          'standard_price': 100.0,
          'premium_categories': [
            'vehicles',
            'vehicle parts', 
            'Appliances and furniture',
            'fashion',
            'electronics',
            'Phones & Tablets',
          ]
        };
      });
    }
  }

  Future<void> _fetchCategories() async {
    try {
      List<Map<String, dynamic>> data = await _productService.fetchCategories();
      setState(() {
        categories = data;
      });
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> _resolveProductCategory() async {
    try {
      // First try to get category from product details
      final response = await http.get(
        Uri.parse("$BASE_URL/products/fetch/?product_id=${widget.productId}"),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final product = data['product'];
        if (product != null && product['category'] != null) {
          setState(() {
            _resolvedProductCategory = product['category']['name'];
          });
          return;
        }
      }
    } catch (e) {
      print('Error fetching product details: $e');
    }

    // Fallback: guess category from product name
    setState(() {
      _resolvedProductCategory = _guessCategoryFromProductName(widget.productName);
    });
  }

  // Helper method to guess category from product name
  String _guessCategoryFromProductName(String productName) {
    final name = productName.toLowerCase();

    // Phones & Tablets
    if (name.contains('iphone') ||
        name.contains('samsung') ||
        name.contains('phone') ||
        name.contains('tablet') ||
        name.contains('android') ||
        name.contains('mobile') ||
        name.contains('ipad') ||
        name.contains('galaxy') ||
        name.contains('smartphone') ||
        name.contains('huawei') ||
        name.contains('xiaomi') ||
        name.contains('oppo') ||
        name.contains('tecno') ||
        name.contains('infinix') ||
        name.contains('pixel')) {
      return 'Phones & Tablets';
    }

    // Electronics (including laptops, gaming, etc.)
    else if (name.contains('tv') ||
        name.contains('television') ||
        name.contains('laptop') ||
        name.contains('computer') ||
        name.contains('electronic') ||
        name.contains('macbook') ||
        name.contains('dell') ||
        name.contains('hp') ||
        name.contains('lenovo') ||
        name.contains('asus') ||
        name.contains('acer') ||
        name.contains('monitor') ||
        name.contains('screen') ||
        name.contains('processor') ||
        name.contains('cpu') ||
        name.contains('gpu') ||
        name.contains('graphics') ||
        name.contains('playstation') ||
        name.contains('xbox') ||
        name.contains('ps4') ||
        name.contains('ps5') ||
        name.contains('console') ||
        name.contains('nintendo') ||
        name.contains('router') ||
        name.contains('modem') ||
        name.contains('printer') ||
        name.contains('scanner') ||
        name.contains('projector') ||
        name.contains('hard drive') ||
        name.contains('ssd') ||
        name.contains('memory') ||
        name.contains('ram')) {
      return 'Electronics';
    }

    // Vehicles
    else if (name.contains('car') ||
        name.contains('vehicle') ||
        name.contains('motor') ||
        name.contains('bike') ||
        name.contains('motorcycle') ||
        name.contains('scooter') ||
        name.contains('van') ||
        name.contains('truck') ||
        name.contains('bus') ||
        name.contains('toyota') ||
        name.contains('nissan') ||
        name.contains('bmw') ||
        name.contains('mercedes') ||
        name.contains('audi') ||
        name.contains('honda') ||
        name.contains('ford') ||
        name.contains('mazda') ||
        name.contains('hyundai') ||
        name.contains('kia') ||
        name.contains('peugeot') ||
        name.contains('lexus') ||
        name.contains('chevrolet')) {
      return 'Vehicles';
    }

    // Vehicle parts
    else if (name.contains('part') ||
        name.contains('tire') ||
        name.contains('engine') ||
        name.contains('wheel') ||
        name.contains('brake') ||
        name.contains('filter') ||
        name.contains('battery') ||
        name.contains('headlight') ||
        name.contains('radiator') ||
        name.contains('bumper') ||
        name.contains('windscreen') ||
        name.contains('mirror') ||
        name.contains('alternator') ||
        name.contains('exhaust') ||
        name.contains('shock absorber') ||
        name.contains('gearbox') ||
        name.contains('clutch') ||
        name.contains('spark plug') ||
        name.contains('rim') ||
        name.contains('dashboard')) {
      return 'Vehicle parts';
    }

    // Appliances and furniture
    else if (name.contains('furniture') ||
        name.contains('sofa') ||
        name.contains('chair') ||
        name.contains('table') ||
        name.contains('bed') ||
        name.contains('mattress') ||
        name.contains('wardrobe') ||
        name.contains('cabinet') ||
        name.contains('shelf') ||
        name.contains('appliance') ||
        name.contains('fridge') ||
        name.contains('refrigerator') ||
        name.contains('freezer') ||
        name.contains('washing machine') ||
        name.contains('dryer') ||
        name.contains('cooker') ||
        name.contains('gas cooker') ||
        name.contains('microwave') ||
        name.contains('oven') ||
        name.contains('blender') ||
        name.contains('toaster') ||
        name.contains('iron') ||
        name.contains('fan') ||
        name.contains('air conditioner') ||
        name.contains('ac') ||
        name.contains('heater') ||
        name.contains('vacuum')) {
      return 'Appliances and furniture';
    }

    // Fashion
    else if (name.contains('cloth') ||
        name.contains('clothing') ||
        name.contains('dress') ||
        name.contains('shirt') ||
        name.contains('t-shirt') ||
        name.contains('trouser') ||
        name.contains('jeans') ||
        name.contains('jacket') ||
        name.contains('sweater') ||
        name.contains('hoodie') ||
        name.contains('fashion') ||
        name.contains('shoe') ||
        name.contains('sneaker') ||
        name.contains('heel') ||
        name.contains('boot') ||
        name.contains('bag') ||
        name.contains('handbag') ||
        name.contains('backpack') ||
        name.contains('watch') ||
        name.contains('jewelry') ||
        name.contains('earring') ||
        name.contains('necklace') ||
        name.contains('bracelet') ||
        name.contains('ring') ||
        name.contains('scarf') ||
        name.contains('cap') ||
        name.contains('hat') ||
        name.contains('belt') ||
        name.contains('perfume') ||
        name.contains('suit') ||
        name.contains('shorts') ||
        name.contains('skirt') ||
        name.contains('blouse')) {
      return 'Fashion';
    }

    return ''; // Unknown category
  }

  void _calculatePromotionAmount() {
    print('\n=== CALCULATING PROMOTION AMOUNT ===');
    print('Resolved category: "$_resolvedProductCategory"');

    if (_resolvedProductCategory == null || _resolvedProductCategory!.isEmpty) {
      print('No category available, using standard amount');
      setState(() {
        _monthlyAmount = _pricingConfig['standard_price']?.toDouble() ?? 100.0;
        _isLoadingPricing = false;
      });
      return;
    }

    // Get premium categories from config
    final premiumCategories = List<String>.from(_pricingConfig['premium_categories'] ?? [
      'vehicles',
      'vehicle parts',
      'Appliances and furniture',
      'fashion',
      'electronics',
      'Phones & Tablets',
    ]);

    print('Premium categories: $premiumCategories');

    // Normalize the category name for comparison
    String normalize(String input) {
      return input
          .toLowerCase()
          .replaceAll(RegExp(r'\s*&\s*'), ' and ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }

    final normalizedProductCategory = normalize(_resolvedProductCategory!);
    final normalizedPremiumCategories = premiumCategories.map(normalize).toList();

    print('Normalized product category: "$normalizedProductCategory"');
    print('Normalized premium categories: $normalizedPremiumCategories');

    // Check if the product category is in the premium list
    final isPremium = normalizedPremiumCategories.contains(normalizedProductCategory);
    
    setState(() {
      if (isPremium) {
        _monthlyAmount = _pricingConfig['premium_price']?.toDouble() ?? 150.0;
        print('✅ Category IS in premium list - Amount: $_monthlyAmount');
      } else {
        _monthlyAmount = _pricingConfig['standard_price']?.toDouble() ?? 100.0;
        print('❌ Category NOT in premium list - Amount: $_monthlyAmount');
      }
      _isLoadingPricing = false;
    });
  }

  // Helper function to show the date picker.
  Future<void> _selectDate(TextEditingController controller) async {
    DateTime now = DateTime.now();
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now, // Prevent past dates.
      lastDate: DateTime(now.year + 5),
    );

    if (pickedDate != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  Future<void> _submitAd() async {
    if (_startDateController.text.isEmpty || _endDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select start and end dates")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Create the ad data payload with monthly amount
    final adData = {
      "product_id": widget.productId,
      "start_date": _startDateController.text,
      "end_date": _endDateController.text,
      "cost_per_month": _monthlyAmount.toString(), // Changed from cost_per_day
    };

    final token = await FlutterSecureStorage().read(key: "token");

    try {
      final response = await http.post(
        Uri.parse("$BASE_URL/ads/create/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(adData),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final adId = responseData["ad_id"]; // Extract ad id
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ad created successfully!")),
        );
        // Convert adId to String before passing it.
        context.push("/pay-ad", extra: {"ad_id": adId.toString()});
      } else if (response.statusCode == 401) {
        // Handle unauthorized response
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/login');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Session expired. Please log in again.")),
        );
      } else {
        final error = jsonDecode(response.body)["error"] ?? "Failed to create ad";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $e")),
      );
    }

    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return BackButtonHandler(
      parentRoute: '/my-listings',
      child: Scaffold(
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                const Text(
                  "Promote Product",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Create a monthly ad campaign",
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 15),

                // Product Name (Read-only)
                TextFormField(
                  readOnly: true,
                  initialValue: widget.productName,
                  decoration: _inputDecoration(),
                ),
                const SizedBox(height: 15),

                // Category and Pricing Info
                if (_isLoadingPricing)
                  const Center(child: CircularProgressIndicator())
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Category: ${_resolvedProductCategory ?? 'Unknown'}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Monthly Promotion Cost: Ksh ${NumberFormat('#,##0').format(_monthlyAmount)}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 15),

                // Start Date & End Date Fields with date picker
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startDateController,
                        readOnly: true,
                        onTap: () async {
                          await _selectDate(_startDateController);
                        },
                        decoration: _inputDecoration(hint: "Start date"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _endDateController,
                        readOnly: true,
                        onTap: () async {
                          await _selectDate(_endDateController);
                        },
                        decoration: _inputDecoration(hint: "End date"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // Buttons Row
                Row(
                  children: [
                    // Skip Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.black),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text("Skip",
                            style: TextStyle(color: Colors.black)),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Create Ad Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (_isSubmitting || _isLoadingPricing) ? null : _submitAd,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C1910),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text("Create Ad"),
                      ),
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

  // Custom Input Decoration helper.
  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF6C1910)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF6C1910), width: 2),
      ),
    );
  }
}
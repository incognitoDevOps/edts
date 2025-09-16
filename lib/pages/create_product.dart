// ignore_for_file: unnecessary_null_comparison, avoid_print, use_build_context_synchronously, deprecated_member_use

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:moderntr/constants.dart';
import 'package:moderntr/widgets/back_button_handler.dart';

const String baseUrl = BASE_URL;

class CreateProductPage extends StatefulWidget {
  const CreateProductPage({super.key});

  @override
  State<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  final Color maroon = const Color(0xFF6C1910);
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];

  // Controllers for input fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _townController =
      TextEditingController(); // New field for town

  bool _isSubmitting = false;
  // Dropdown selected values
  String? selectedCategory;
  String? selectedSubCategory;
  String? selectedVariant;
  String? selectedCounty;
  String? selectedSubCounty;

  // Lists for dropdown items
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> subCategories = [];
  List<Map<String, dynamic>> variants = [];
  List<Map<String, dynamic>> counties = [];
  List<Map<String, dynamic>> subCounties = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCategories();
      _fetchCounties();
    });
  }

  // Helper to handle 401 responses by showing a message and redirecting to login.
  void _handleUnauthorized(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      context.go('/login');
    });
  }

  Future<void> _fetchCategories() async {
    const String apiUrl = "$baseUrl/products/categories/";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          categories = List<Map<String, dynamic>>.from(data['categories']);
        });
      } else if (response.statusCode == 401) {
        _handleUnauthorized("Token expired. Please log in.");
      } else {
        print(
            "Failed to fetch categories. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }

  Future<void> _fetchCounties() async {
    const String apiUrl = "$baseUrl/products/counties/";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          counties = List<Map<String, dynamic>>.from(data['counties']);
        });
      } else if (response.statusCode == 401) {
        _handleUnauthorized("Token expired. Please log in.");
      } else {
        print("Failed to fetch counties. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching counties: $e");
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _selectedImages = pickedFiles.map((file) => File(file.path)).toList();
      });
    }
  }

  void _onCategorySelected(String? categoryId) {
    setState(() {
      selectedCategory = categoryId;
      // Reset dependent selections
      selectedSubCategory = null;
      selectedVariant = null;
      // Update subcategories for the selected category
      final intCategoryId = int.tryParse(categoryId ?? '') ?? 0;
      final category = categories.firstWhere(
        (cat) => cat['id'] == intCategoryId,
        orElse: () => {},
      );
      if (category.isNotEmpty && category.containsKey('subcategories')) {
        subCategories =
            List<Map<String, dynamic>>.from(category['subcategories'] ?? []);
        // If there are subcategories, auto-select the first one
        if (subCategories.isNotEmpty) {
          selectedSubCategory = subCategories.first['id'].toString();
          _onSubCategorySelected(selectedSubCategory);
        }
      } else {
        subCategories = [];
      }
      variants = [];
    });
  }

  void _onSubCategorySelected(String? subCategoryId) {
    setState(() {
      selectedSubCategory = subCategoryId;
      selectedVariant = null;
      final intSubCategoryId = int.tryParse(subCategoryId ?? '') ?? 0;
      final subCategory = subCategories.firstWhere(
        (sub) => sub['id'] == intSubCategoryId,
        orElse: () => {},
      );
      if (subCategory.isNotEmpty && subCategory.containsKey('variants')) {
        variants =
            List<Map<String, dynamic>>.from(subCategory['variants'] ?? []);
        // If variants are available, auto-select the first one
        if (variants.isNotEmpty) {
          selectedVariant = variants.first['id'].toString();
        }
      } else {
        variants = [];
      }
    });
  }

  void _onCountySelected(String? countyId) {
    setState(() {
      selectedCounty = countyId;
      selectedSubCounty = null;
      final intCountyId = int.tryParse(countyId ?? '') ?? 0;
      final county = counties.firstWhere(
        (c) => c['id'] == intCountyId,
        orElse: () => {},
      );
      if (county.isNotEmpty && county.containsKey('subcounties')) {
        subCounties =
            List<Map<String, dynamic>>.from(county['subcounties'] ?? []);
        // Auto-select first subcounty if available
        if (subCounties.isNotEmpty) {
          selectedSubCounty = subCounties.first['id'].toString();
        }
      } else {
        subCounties = [];
      }
    });
  }

  // This method will be called when the "Create Product" button is pressed.
  void _handleCreateProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true); // Disable button and show loader

      const String defaultUnit = "piece";
      await createProduct(
        context,
        _nameController.text,
        selectedCategory ?? '',
        selectedSubCategory ?? '',
        defaultUnit,
        _priceController.text,
        _descriptionController.text,
        selectedCounty ?? '',
        selectedSubCounty ?? '',
        selectedVariant ?? '',
        _townController.text,
        _selectedImages,
      );

      setState(() => _isSubmitting = false); // Re-enable button
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackButtonHandler(
      parentRoute: '/account',
      child: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Create a Product",
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text("*3MB max per image, 10 images max",
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                // Product name field
                _buildInputField("Enter your product’s name",
                    controller: _nameController),
                _buildCategoryRow(),
                const SizedBox(height: 16),
                _buildLocationRow(),
                const SizedBox(height: 16),
                // Price field
                _buildInputField("Price", controller: _priceController),
                // Description field
                _buildInputField("Enter a Brief product Description",
                    controller: _descriptionController, maxLines: 4),
                const SizedBox(height: 16),
                // New town field
                _buildInputField("Town", controller: _townController),
                const SizedBox(height: 16),
                const Text("Upload Product Images",
                    style: TextStyle(color: Color(0xFF6C1910))),
                const SizedBox(height: 6),
                _buildImagePicker(),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                        child: _buildButton("Cancel", Colors.white, maroon, () {
                      // Handle cancel action if needed
                    })),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildButton(
                        "Create Product",
                        maroon,
                        Colors.white,
                        _handleCreateProduct,
                        loading: _isSubmitting,
                        disabled: _isSubmitting,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildCategoryRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(
            width: 200,
            child: _buildDropdown(
              "Category",
              selectedCategory,
              _onCategorySelected,
              categories,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 200,
            child: _buildDropdown(
              "Sub Category",
              selectedSubCategory,
              _onSubCategorySelected,
              subCategories,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 200,
            child: _buildDropdown(
              "Variants",
              selectedVariant,
              (value) => setState(() => selectedVariant = value),
              variants,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(
            width: 165,
            child: _buildDropdown(
              "County",
              selectedCounty,
              _onCountySelected,
              counties,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 165,
            child: _buildDropdown(
              "Sub County",
              selectedSubCounty,
              (value) => setState(() => selectedSubCounty = value),
              subCounties,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String hint,
    String? selectedValue,
    ValueChanged<String?> onChanged,
    List<Map<String, dynamic>> items,
  ) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      decoration: _inputDecoration(hint),
      value: selectedValue,
      onChanged: onChanged,
      items: items.map((item) {
            const Text("*3MB max per image, 10 images max",
          value: item['id'].toString(),
          child: Text(item['name']),
        );
      }).toList(),
    );
  }

  Widget _buildInputField(String hint,
      {TextEditingController? controller, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: _inputDecoration(hint),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $hint';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _pickImages,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              border: Border.all(color: maroon),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _selectedImages.isEmpty
                ? Icon(Icons.add, color: maroon, size: 32)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_selectedImages.first, fit: BoxFit.cover),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        const Text("*2MB max per image, 10 images max",
            style: TextStyle(color: Colors.red, fontSize: 12)),
      ],
    );
  }

  Widget _buildButton(
    String text,
    Color bgColor,
    Color textColor,
    VoidCallback onPressed, {
    bool loading = false,
    bool disabled = false,
  }) {
    return ElevatedButton(
      onPressed: disabled || loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            )
          : Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

// Updated createProduct function now accepts a town parameter.
Future<void> createProduct(
  BuildContext context,
  String name,
  String category,
  String subCategory,
  String unit,
  String price,
  String description,
  String county,
  String subCounty,
  String variant,
  String town, // new parameter for town
  List<File> images,
) async {
  try {
    // Retrieve token
    final String? token = await TokenStorage.read(key: 'token');
    if (token == null) {
      if (context.mounted) {
        _showOverlaySnackBar(context, "Token expired. Please log in.");
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) context.go('/login');
        });
      }
      return;
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/products/create/'),
    );
    request.headers['Authorization'] = 'Bearer $token';

    // Attach product details including the new town field
    request.fields['name'] = name;
    request.fields['category'] = category;
    request.fields['sub_category'] = subCategory;
    request.fields['unit'] = unit;
    request.fields['price'] = price;
    request.fields['description'] = description;
    request.fields['county'] = county;
    request.fields['sub_county'] = subCounty;
    request.fields['variant'] = variant;
    request.fields['town'] = town; // sending town

    // Attach images if provided
    for (var image in images) {
      request.files
          .add(await http.MultipartFile.fromPath('images', image.path));
    }

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final jsonResponse = json.decode(responseData);

    // Handle unauthorized response
    if (response.statusCode == 401) {
      _showOverlaySnackBar(context, "Token expired. Please log in.");
      Future.delayed(const Duration(seconds: 2), () {
        if (context.mounted) context.go('/login');
      });
      return;
    }

    if (context.mounted) {
      if (response.statusCode == 201) {
        _showOverlaySnackBar(context, "Product Created Successfully!");
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) context.go('/my-listings');
        });
      } else if (response.statusCode == 403) {
        _showOverlaySnackBar(context, "You need a store to create a product!");
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) context.go('/create-store');
        });
      } else {
        _showOverlaySnackBar(
            context, "${jsonResponse['error'] ?? 'Something went wrong'}");
      }
    }
  } catch (e) {
    if (context.mounted) {
      _showOverlaySnackBar(context, "An error occurred: $e");
    }
  }
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

  // Remove the overlay after 2 seconds
  Future.delayed(const Duration(seconds: 2), () {
    overlayEntry.remove();
  });
}

class TokenStorage {
  static final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage();

  static Future<String?> read({required String key}) async {
    return await _secureStorage.read(key: key);
  }
}

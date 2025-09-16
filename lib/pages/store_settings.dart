// ignore_for_file: avoid_print, deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:moderntr/constants.dart';
import 'package:moderntr/widgets/back_button_handler.dart';

class StoreSettingsPage extends StatefulWidget {
  const StoreSettingsPage({super.key});

  @override
  State<StoreSettingsPage> createState() => _StoreSettingsPageState();
}

class _StoreSettingsPageState extends State<StoreSettingsPage> {
  final Color maroon = const Color(0xFF6C1910);
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();

  // Controllers to hold store details
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _twitterController = TextEditingController();
  final TextEditingController _linkedinController = TextEditingController();
  final TextEditingController _plusController = TextEditingController();

  String? _logoUrl;
  bool _isLoading = true; // Spinner state for fetching store details

  @override
  void initState() {
    super.initState();
    _fetchStoreDetails();
  }

  Future<void> _fetchStoreDetails() async {
    String? token = await _storage.read(key: 'token');
    if (token == null) {
      // Token missing: show snackbar and redirect.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Authentication token not found. Please log in."),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/login');
      });
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final response = await http.get(
      Uri.parse('$BASE_URL/products/edit/store/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _nameController.text = data["name"] ?? "";
        _addressController.text = data["address"] ?? "";
        _phoneController.text = data["phone_number"] ?? "";
        _emailController.text = data["email"] ?? "";
        _descriptionController.text = data["description"] ?? "";
        _productController.text = data["product"] ?? "";
        _facebookController.text = data["facebook"] ?? "";
        _twitterController.text = data["twitter"] ?? "";
        _linkedinController.text = data["linkedin"] ?? "";
        _plusController.text = data["plus"] ?? "";
        _logoUrl = data["logo"];
        _isLoading = false;
      });
    } else if (response.statusCode == 401) {
      // Token expired, show a message and redirect
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Token expired, please log in"),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/login');
      });
      setState(() {
        _isLoading = false;
      });
    } else {
      print("Failed to fetch store details: ${response.body}");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStoreDetails() async {
    String? token = await _storage.read(key: 'token');
    if (token == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Authentication token not found. Please log in."),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/login');
      });
      return;
    }

    final Map<String, String> storeData = {
      "name": _nameController.text,
      "address": _addressController.text,
      "phone_number": _phoneController.text,
      "email": _emailController.text,
      "description": _descriptionController.text,
      "product": _productController.text,
      "facebook": _facebookController.text,
      "twitter": _twitterController.text,
      "linkedin": _linkedinController.text,
      "plus": _plusController.text,
    };

    final response = await http.put(
      Uri.parse('$BASE_URL/products/edit/store/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(storeData),
    );

    if (!mounted) return; // Ensure the widget is still in the tree

    if (response.statusCode == 200) {
      _showOverlaySnackBar("Store details updated successfully!");
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          context.go('/store-settings');
        }
      });
    } else if (response.statusCode == 401) {
      // Token expired, show a message and redirect
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showOverlaySnackBar("Token expired, please log in");
        context.go('/login');
      });
    } else {
      _showOverlaySnackBar("An error occurred, please try again later!");
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          context.go('/store-settings');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackButtonHandler(
      parentRoute: '/account',
      child: Scaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Store Settings",
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("Manage your store below",
                          style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      _buildInputField("Store Name", Icons.store, _nameController),
                      _buildInputField("Address", Icons.location_on, _addressController),
                      Row(
                        children: [
                          Expanded(
                              child:
                                  _buildInputField("Email", Icons.email, _emailController)),
                          const SizedBox(width: 12),
                          Expanded(
                              child:
                                  _buildInputField("Phone Number", Icons.phone, _phoneController)),
                        ],
                      ),
                      _buildInputField("Description", Icons.description, _descriptionController),
                      _buildInputField("Products", Icons.shopping_cart, _productController),
                      _buildInputField("Facebook", Icons.facebook, _facebookController),
                      _buildInputField("X", Icons.language, _twitterController),
                      _buildInputField("Plus", Icons.add, _plusController),
                      _buildInputField("LinkedIn", Icons.business, _linkedinController),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: maroon),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Select your logo (optional)",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("*3MB max",
                                style: TextStyle(color: Colors.red, fontSize: 12)),
                            const SizedBox(height: 8),
                            _logoUrl != null
                                ? Image.network(_logoUrl!, height: 80)
                                : _buildLogoUploader(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                              child: _buildButton("Cancel", Colors.white, maroon, Icons.cancel,
                                  () {
                            context.go('/account');
                          })),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _buildButton("Update", maroon, Colors.white, Icons.update,
                                  _updateStoreDetails)),
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

  Widget _buildInputField(String hintText, IconData icon, TextEditingController controller,
      {bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, color: maroon),
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: maroon, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoUploader() {
    return GestureDetector(
      onTap: () {
        // Implement file picker logic
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(color: maroon, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.add, size: 30, color: Colors.grey),
      ),
    );
  }

  Widget _buildButton(String text, Color bgColor, Color textColor, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: text == "Cancel" ? BorderSide.none : BorderSide(color: bgColor),
        ),
      ),
      icon: Icon(icon, color: textColor),
      label: Text(
        text,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }

  void _showOverlaySnackBar(String message) {
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

    // Remove the overlay after 2 seconds.
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }
}
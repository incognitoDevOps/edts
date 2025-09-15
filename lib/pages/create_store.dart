// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:moderntr/services/products_service.dart';
import 'package:go_router/go_router.dart';

class CreateStorePage extends StatefulWidget {
  const CreateStorePage({super.key});

  @override
  _CreateStorePageState createState() => _CreateStorePageState();
}

class _CreateStorePageState extends State<CreateStorePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _productTypeController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _logo;
  final ImagePicker _picker = ImagePicker();
  final ProductService _productService = ProductService(); // Initialize service

  // Helper to handle 401 responses by showing a message and redirecting to login.
  void _handleUnauthorized(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      context.go('/login');
    });
  }

  Future<void> _pickLogo() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _logo = File(image.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _productService.createStore(
          context,
          _nameController.text,
          _emailController.text,
          _addressController.text,
          _phoneController.text,
          _productTypeController.text,
          _descriptionController.text,
          _logo, // Pass the file
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Store created successfully!')),
        );
        // Navigator.pop(context); // Go back after success
        context.go('/create-product'); // Redirect to create-product page
      } catch (e) {
        // Check if the error is due to an unauthorized (401) response.
        if (e.toString().contains("Unauthorized") ||
            e.toString().contains("401")) {
          _handleUnauthorized("Token expired. Please log in.");
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Create a store below.",
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text("Start selling immediately.",
                    style: TextStyle(color: Colors.grey)),
                SizedBox(height: 16),
                // Store Name
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration("Enter your shop's name"),
                  validator: (value) =>
                      value!.isEmpty ? "Required field" : null,
                ),
                SizedBox(height: 12),
                // Email & Address Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        decoration: _inputDecoration("Email address"),
                        validator: (value) =>
                            value!.isEmpty ? "Required" : null,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _addressController,
                        decoration: _inputDecoration("Physical address"),
                        validator: (value) =>
                            value!.isEmpty ? "Required" : null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                // Phone Number
                TextFormField(
                  controller: _phoneController,
                  decoration: _inputDecoration("Phone number"),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value!.isEmpty ? "Required" : null,
                ),
                SizedBox(height: 12),
                // Product Type
                TextFormField(
                  controller: _productTypeController,
                  decoration: _inputDecoration(
                      "Product type e.g., Electronics, cosmetics"),
                  validator: (value) => value!.isEmpty ? "Required" : null,
                ),
                SizedBox(height: 12),
                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: _inputDecoration(
                      "Enter brief description of your business..."),
                  maxLines: 4,
                  validator: (value) => value!.isEmpty ? "Required" : null,
                ),
                SizedBox(height: 16),
                // Logo Upload
                Text("Select your logo (optional)",
                    style: TextStyle(color: Color(0xFF6C1910))),
                SizedBox(height: 6),
                GestureDetector(
                  onTap: _pickLogo,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFF6C1910)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _logo != null
                        ? Image.file(_logo!, fit: BoxFit.cover)
                        : Icon(Icons.add, color: Color(0xFF6C1910), size: 32),
                  ),
                ),
                SizedBox(height: 4),
                Text("*2MB max",
                    style: TextStyle(color: Colors.red, fontSize: 12)),
                SizedBox(height: 24),
                // Buttons Row with 50/50 width
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: _buttonStyle(Colors.white, Color(0xFF6C1910)),
                        child: Text("Cancel",
                            style: TextStyle(color: Color(0xFF6C1910))),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: _buttonStyle(Color(0xFF6C1910), Colors.white),
                        child: Text("Create Store",
                            style: TextStyle(color: Colors.white)),
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

  // Input Field Decoration
  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF6C1910), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  // Button Style
  ButtonStyle _buttonStyle(Color bgColor, Color textColor) {
    return ElevatedButton.styleFrom(
      backgroundColor: bgColor,
      padding: EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

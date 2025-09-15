import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'country_code_picker.dart';

class PhoneInputField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String hintText;
  final Function(String)? onPhoneChanged;

  const PhoneInputField({
    super.key,
    required this.controller,
    this.validator,
    this.hintText = 'Phone number',
    this.onPhoneChanged,
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  String selectedCountryCode = '+254'; // Default to Kenya
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_updateFullPhoneNumber);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _updateFullPhoneNumber() {
    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isNotEmpty) {
      // Remove the + from country code and combine with phone number
      final countryCodeDigits = selectedCountryCode.substring(1);
      final fullPhoneNumber = countryCodeDigits + phoneNumber;
      widget.controller.text = fullPhoneNumber;
      widget.onPhoneChanged?.call(fullPhoneNumber);
    } else {
      widget.controller.text = '';
      widget.onPhoneChanged?.call('');
    }
  }

  void _onCountryCodeChanged(String newCountryCode) {
    setState(() {
      selectedCountryCode = newCountryCode;
    });
    _updateFullPhoneNumber();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CountryCodePicker(
              selectedCountryCode: selectedCountryCode,
              onCountryCodeChanged: _onCountryCodeChanged,
            ),
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12),
                ],
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
                validator: widget.validator,
              ),
            ),
          ],
        ),
        if (widget.controller.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Full number: ${widget.controller.text}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }
}
import 'package:flutter/material.dart';

class TermsConditionsDialog extends StatefulWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const TermsConditionsDialog({
    super.key,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<TermsConditionsDialog> createState() => _TermsConditionsDialogState();
}

class _TermsConditionsDialogState extends State<TermsConditionsDialog> {
  bool _hasScrolledToBottom = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent) {
      setState(() {
        _hasScrolledToBottom = true;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Terms & Conditions',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Vendor Terms & Conditions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                '1. Product Listing Requirements',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• All products must be accurately described\n'
                '• Images must be clear and represent the actual product\n'
                '• Pricing must be fair and competitive\n'
                '• No counterfeit or illegal items allowed',
              ),
              SizedBox(height: 16),
              Text(
                '2. Payment and Delivery',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Payment should only be made after product delivery\n'
                '• Vendors are responsible for safe delivery\n'
                '• Disputes will be handled through our support system\n'
                '• Refunds are subject to our refund policy',
              ),
              SizedBox(height: 16),
              Text(
                '3. Vendor Responsibilities',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Maintain accurate inventory\n'
                '• Respond to customer inquiries promptly\n'
                '• Honor all sales commitments\n'
                '• Comply with local laws and regulations',
              ),
              SizedBox(height: 16),
              Text(
                '4. Platform Rules',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• No spam or misleading content\n'
                '• Respect other users and vendors\n'
                '• Report any suspicious activity\n'
                '• Follow community guidelines',
              ),
              SizedBox(height: 16),
              Text(
                '5. Account Termination',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'We reserve the right to terminate accounts that violate these terms. '
                'Repeated violations may result in permanent suspension.',
              ),
              SizedBox(height: 24),
              Text(
                'By accepting these terms, you agree to abide by all the conditions listed above.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onDecline,
          child: const Text('Decline'),
        ),
        ElevatedButton(
          onPressed: _hasScrolledToBottom ? widget.onAccept : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _hasScrolledToBottom ? const Color(0xFF6C1910) : Colors.grey,
          ),
          child: Text(
            'Accept',
            style: TextStyle(
              color: _hasScrolledToBottom ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }
}
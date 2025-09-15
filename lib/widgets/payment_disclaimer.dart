import 'package:flutter/material.dart';

class PaymentDisclaimer extends StatelessWidget {
  const PaymentDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border.all(color: Colors.orange, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange[700], size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Payment Safety Notice',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '⚠️ IMPORTANT: For your safety, please follow these guidelines:\n\n'
            '• Only pay AFTER receiving and inspecting the product\n'
            '• Meet in safe, public locations for exchanges\n'
            '• Verify product quality before making payment\n'
            '• Report any suspicious activity to our support team\n'
            '• Use secure payment methods when possible\n\n'
            'Modern Trade Market is not responsible for transactions between buyers and sellers. '
            'Always exercise caution and use your best judgment.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.security, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Never pay in advance without seeing the product first!',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
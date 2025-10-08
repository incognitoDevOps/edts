import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';

class StripeService {
  final String stripeSecret;
  final String publishableKey;

  StripeService({
    required this.stripeSecret,
    required this.publishableKey,
  });

  Future<Map<String, dynamic>?> createPaymentIntent({
    required String amount,
    required String currency,
    bool captureMethod = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $stripeSecret',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': ((double.parse(amount) * 100).round()).toString(),
          'currency': currency,
          'capture_method': captureMethod ? 'manual' : 'automatic',
          'payment_method_types[]': 'card',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        log('Stripe API Error: ${response.statusCode} - ${response.body}');
        return {'error': json.decode(response.body)};
      }
    } catch (e) {
      log('Error creating payment intent: $e');
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>?> confirmPaymentIntent({
    required String paymentIntentId,
    required String paymentMethodId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://api.stripe.com/v1/payment_intents/$paymentIntentId/confirm'),
        headers: {
          'Authorization': 'Bearer $stripeSecret',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'payment_method': paymentMethodId,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        log('Stripe Confirm Error: ${response.statusCode} - ${response.body}');
        return {'error': json.decode(response.body)};
      }
    } catch (e) {
      log('Error confirming payment intent: $e');
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>?> capturePaymentIntent({
    required String paymentIntentId,
    String? amountToCapture,
  }) async {
    try {
      final Map<String, String> body = {};
      if (amountToCapture != null) {
        body['amount_to_capture'] =
            ((double.parse(amountToCapture) * 100).round()).toString();
      }

      final response = await http.post(
        Uri.parse(
            'https://api.stripe.com/v1/payment_intents/$paymentIntentId/capture'),
        headers: {
          'Authorization': 'Bearer $stripeSecret',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        log('Stripe Capture Error: ${response.statusCode} - ${response.body}');
        return {'error': json.decode(response.body)};
      }
    } catch (e) {
      log('Error capturing payment intent: $e');
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>?> cancelPaymentIntent({
    required String paymentIntentId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://api.stripe.com/v1/payment_intents/$paymentIntentId/cancel'),
        headers: {
          'Authorization': 'Bearer $stripeSecret',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        log('Stripe Cancel Error: ${response.statusCode} - ${response.body}');
        return {'error': json.decode(response.body)};
      }
    } catch (e) {
      log('Error cancelling payment intent: $e');
      return {'error': e.toString()};
    }
  }

  Future<bool> verifyCardBalance({
    required String amount,
    required String currency,
  }) async {
    try {
      final paymentIntent = await createPaymentIntent(
        amount: '1',
        currency: currency,
        captureMethod: true,
      );

      if (paymentIntent != null &&
          !paymentIntent.containsKey('error') &&
          paymentIntent['id'] != null) {
        await cancelPaymentIntent(paymentIntentId: paymentIntent['id']);
        return true;
      }
      return false;
    } catch (e) {
      log('Error verifying card balance: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> presentPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
      return {
        'success': true,
        'message': 'Payment authorized successfully',
        'cancelled': false,
      };
    } on StripeException catch (e) {
      log('Stripe Exception: ${e.error.localizedMessage}');
      log('Stripe Error Code: ${e.error.code}');

      return {
        'success': false,
        'errorCode': e.error.code?.name ?? 'unknown',
        'message': e.error.localizedMessage ?? 'Payment failed',
        'cancelled': e.error.code == FailureCode.Canceled,
      };
    } catch (e) {
      log('Unexpected error presenting payment sheet: $e');
      return {
        'success': false,
        'errorCode': 'unknown',
        'message': 'Unexpected error occurred',
        'cancelled': false,
      };
    }
  }

  Future<void> initPaymentSheet({
    required String paymentIntentClientSecret,
    required String merchantDisplayName,
    String? customerId,
    String? ephemeralKey,
  }) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentClientSecret,
          merchantDisplayName: merchantDisplayName,
          customerId: customerId,
          customerEphemeralKeySecret: ephemeralKey,
          style: ThemeMode.system,
          allowsDelayedPaymentMethods: false,
        ),
      );
    } catch (e) {
      log('Error initializing payment sheet: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createPreAuthorization({
    required String amount,
    required String currency,
  }) async {
    try {
      final paymentIntent = await createPaymentIntent(
        amount: amount,
        currency: currency,
        captureMethod: true,
      );

      if (paymentIntent != null && !paymentIntent.containsKey('error')) {
        return {
          'success': true,
          'paymentIntentId': paymentIntent['id'],
          'clientSecret': paymentIntent['client_secret'],
          'amount': paymentIntent['amount'],
        };
      } else {
        return {
          'success': false,
          'error': paymentIntent?['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      log('Error creating pre-authorization: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> capturePreAuthorization({
    required String paymentIntentId,
    required String finalAmount,
  }) async {
    try {
      final result = await capturePaymentIntent(
        paymentIntentId: paymentIntentId,
        amountToCapture: finalAmount,
      );

      if (result != null && !result.containsKey('error')) {
        return {
          'success': true,
          'data': result,
        };
      } else {
        return {
          'success': false,
          'error': result?['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      log('Error capturing pre-authorization: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<bool> releasePreAuthorization({
    required String paymentIntentId,
  }) async {
    try {
      final result = await cancelPaymentIntent(
        paymentIntentId: paymentIntentId,
      );

      return result != null && !result.containsKey('error');
    } catch (e) {
      log('Error releasing pre-authorization: $e');
      return false;
    }
  }
}

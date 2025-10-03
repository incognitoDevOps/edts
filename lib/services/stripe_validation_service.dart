import 'dart:convert';
import 'package:customer/constant/constant.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class StripeValidationService {
  static Future<StripeValidationResult> validatePaymentMethod(UserModel user) async {
    try {
      if (Constant.paymentModel?.strip == null || Constant.paymentModel?.strip?.enable != true) {
        return StripeValidationResult(
          isValid: false,
          errorMessage: 'Stripe is not enabled',
          requiresSetup: false,
        );
      }

      if (user.stripeCustomerId == null || user.stripeCustomerId!.isEmpty) {
        return StripeValidationResult(
          isValid: false,
          errorMessage: 'No payment method on file. Please add a payment method.',
          requiresSetup: true,
        );
      }

      if (user.stripePaymentMethodId == null || user.stripePaymentMethodId!.isEmpty) {
        return StripeValidationResult(
          isValid: false,
          errorMessage: 'No payment method on file. Please add a payment method.',
          requiresSetup: true,
        );
      }

      final lastVerified = user.stripeLastVerified;
      if (lastVerified != null) {
        final hoursSinceVerification = DateTime.now().difference(lastVerified.toDate()).inHours;
        if (hoursSinceVerification < 24 && user.stripePaymentVerified == true) {
          return StripeValidationResult(
            isValid: true,
            errorMessage: null,
            requiresSetup: false,
          );
        }
      }

      final verificationResult = await _verifyPaymentMethodWithStripe(
        user.stripeCustomerId!,
        user.stripePaymentMethodId!,
      );

      if (verificationResult.isValid) {
        await _updateUserVerificationStatus(user.id!, true);
      }

      return verificationResult;
    } catch (e) {
      return StripeValidationResult(
        isValid: false,
        errorMessage: 'Unable to verify payment method: ${e.toString()}',
        requiresSetup: false,
      );
    }
  }

  static Future<StripeValidationResult> _verifyPaymentMethodWithStripe(
    String customerId,
    String paymentMethodId,
  ) async {
    try {
      final stripeSecret = Constant.paymentModel?.strip?.stripeSecret;
      if (stripeSecret == null || stripeSecret.isEmpty) {
        return StripeValidationResult(
          isValid: false,
          errorMessage: 'Stripe configuration error',
          requiresSetup: false,
        );
      }

      final response = await http.get(
        Uri.parse('https://api.stripe.com/v1/payment_methods/$paymentMethodId'),
        headers: {
          'Authorization': 'Bearer $stripeSecret',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['customer'] != customerId) {
          return StripeValidationResult(
            isValid: false,
            errorMessage: 'Payment method not associated with your account',
            requiresSetup: true,
          );
        }

        final card = data['card'];
        if (card != null) {
          final expMonth = card['exp_month'] as int;
          final expYear = card['exp_year'] as int;
          final now = DateTime.now();

          if (expYear < now.year || (expYear == now.year && expMonth < now.month)) {
            return StripeValidationResult(
              isValid: false,
              errorMessage: 'Payment method has expired. Please update your payment method.',
              requiresSetup: true,
            );
          }
        }

        final customerResponse = await http.get(
          Uri.parse('https://api.stripe.com/v1/customers/$customerId'),
          headers: {
            'Authorization': 'Bearer $stripeSecret',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        );

        if (customerResponse.statusCode == 200) {
          final customerData = json.decode(customerResponse.body);

          if (customerData['delinquent'] == true) {
            return StripeValidationResult(
              isValid: false,
              errorMessage: 'Payment method has outstanding issues. Please contact support or update your payment method.',
              requiresSetup: true,
            );
          }
        }

        return StripeValidationResult(
          isValid: true,
          errorMessage: null,
          requiresSetup: false,
        );
      } else if (response.statusCode == 404) {
        return StripeValidationResult(
          isValid: false,
          errorMessage: 'Payment method not found. Please add a payment method.',
          requiresSetup: true,
        );
      } else {
        final errorData = json.decode(response.body);
        return StripeValidationResult(
          isValid: false,
          errorMessage: errorData['error']?['message'] ?? 'Unable to verify payment method',
          requiresSetup: false,
        );
      }
    } catch (e) {
      return StripeValidationResult(
        isValid: false,
        errorMessage: 'Network error during verification: ${e.toString()}',
        requiresSetup: false,
      );
    }
  }

  static Future<void> _updateUserVerificationStatus(String userId, bool isVerified) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'stripePaymentVerified': isVerified,
        'stripeLastVerified': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating verification status: $e');
    }
  }

  static Future<bool> checkIfPaymentMethodExists(UserModel user) async {
    return user.stripeCustomerId != null &&
           user.stripeCustomerId!.isNotEmpty &&
           user.stripePaymentMethodId != null &&
           user.stripePaymentMethodId!.isNotEmpty;
  }

  static String getPaymentMethodSetupUrl() {
    return 'https://your-app-domain.com/setup-payment';
  }
}

class StripeValidationResult {
  final bool isValid;
  final String? errorMessage;
  final bool requiresSetup;

  StripeValidationResult({
    required this.isValid,
    this.errorMessage,
    required this.requiresSetup,
  });
}

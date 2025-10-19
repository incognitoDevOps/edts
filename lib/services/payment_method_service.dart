import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/model/admin_commission.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/utils/fire_store_utils.dart';
// Add import for PaymentMethodService in constant.dart
import 'package:driver/services/payment_method_service.dart' as payment_service;

class PaymentMethodService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if driver can switch payment methods (24-hour cooldown)
  static bool canSwitchPaymentMethod(DriverUserModel driver) {
    if (driver.lastSwitched == null) return true;
    
    final lastSwitchTime = driver.lastSwitched!.toDate();
    final now = DateTime.now();
    final difference = now.difference(lastSwitchTime);
    
    return difference.inHours >= 24;
  }

  /// Get time remaining until next switch is allowed
  static Duration getTimeUntilNextSwitch(DriverUserModel driver) {
    if (driver.lastSwitched == null) return Duration.zero;
    
    final lastSwitchTime = driver.lastSwitched!.toDate();
    final nextAllowedTime = lastSwitchTime.add(const Duration(hours: 24));
    final now = DateTime.now();
    
    if (now.isAfter(nextAllowedTime)) return Duration.zero;
    return nextAllowedTime.difference(now);
  }

  /// Check if flat rate is currently active (paid within last 24 hours)
  static bool isFlatRateActive(DriverUserModel driver) {
    if (driver.paymentMethod != 'flat_rate' || 
        driver.flatRatePaidAt == null || 
        driver.flatRateActive != true) {
      return false;
    }
    
    final paidTime = driver.flatRatePaidAt!.toDate();
    final now = DateTime.now();
    final difference = now.difference(paidTime);
    
    return difference.inHours < 24;
  }

  /// Get time remaining for current flat rate period
  static Duration getFlatRateTimeRemaining(DriverUserModel driver) {
    if (driver.flatRatePaidAt == null) return Duration.zero;
    
    final paidTime = driver.flatRatePaidAt!.toDate();
    final expiryTime = paidTime.add(const Duration(hours: 24));
    final now = DateTime.now();
    
    if (now.isAfter(expiryTime)) return Duration.zero;
    return expiryTime.difference(now);
  }

  /// Check if driver has sufficient wallet balance for flat rate
  static bool hasSufficientBalanceForFlatRate(
    DriverUserModel driver, 
    AdminCommission adminCommission
  ) {
    final walletBalance = double.parse(driver.walletAmount ?? '0.0');
    final flatRateAmount = adminCommission.getFlatRateAmount();
    return walletBalance >= flatRateAmount;
  }

  /// Process flat rate payment (deduct from wallet)
  static Future<bool> processFlatRatePayment(String driverId) async {
    try {
      final driver = await FireStoreUtils.getDriverProfile(driverId);
      if (driver == null) return false;

      final adminCommission = await FireStoreUtils.getAdminCommission();
      if (adminCommission == null) return false;

      final flatRateAmount = adminCommission.getFlatRateAmount();
      final walletBalance = double.parse(driver.walletAmount ?? '0.0');

      if (walletBalance < flatRateAmount) {
        return false; // Insufficient balance
      }

      // Deduct from wallet and activate flat rate
      final newBalance = walletBalance - flatRateAmount;
      
      await _firestore
          .collection(CollectionName.driverUsers)
          .doc(driverId)
          .update({
        'walletAmount': newBalance.toString(),
        'flatRatePaidAt': Timestamp.now(),
        'flatRateActive': true,
        'paymentMethod': 'flat_rate',
        'lastSwitched': Timestamp.now(),
      });

      // Create wallet transaction record
      await _createFlatRateTransaction(driverId, flatRateAmount);

      return true;
    } catch (e) {
      print('Error processing flat rate payment: $e');
      return false;
    }
  }

  /// Create wallet transaction for flat rate payment
  static Future<void> _createFlatRateTransaction(String driverId, double amount) async {
    try {
      final transactionData = {
        'id': Constant.getUuid(),
        'amount': '-${amount.toString()}',
        'createdDate': Timestamp.now(),
        'paymentType': 'wallet',
        'transactionId': 'flat_rate_${DateTime.now().millisecondsSinceEpoch}',
        'userId': driverId,
        'userType': 'driver',
        'orderType': 'flat_rate',
        'note': 'Daily flat rate payment',
      };

      await _firestore
          .collection(CollectionName.walletTransaction)
          .doc(transactionData['id'] as String)
          .set(transactionData);
    } catch (e) {
      print('Error creating flat rate transaction: $e');
    }
  }

  /// Switch driver's payment method
  static Future<bool> switchPaymentMethod(
    String driverId, 
    String newPaymentMethod
  ) async {
    try {
      final updateData = <String, dynamic>{
        'paymentMethod': newPaymentMethod,
        'lastSwitched': Timestamp.now(),
      };

      // If switching away from flat rate, deactivate it
      if (newPaymentMethod != 'flat_rate') {
        updateData['flatRateActive'] = false;
      }

      await _firestore
          .collection(CollectionName.driverUsers)
          .doc(driverId)
          .update(updateData);
      return true;
    } catch (e) {
      print('Error switching payment method: $e');
      return false;
    }
  }

  /// Deactivate expired flat rate periods
  static Future<void> deactivateExpiredFlatRate(String driverId) async {
    try {
      await _firestore
          .collection(CollectionName.driverUsers)
          .doc(driverId)
          .update({
        'flatRateActive': false,
        'paymentMethod': 'commission', // Fallback to commission
      });
    } catch (e) {
      print('Error deactivating flat rate: $e');
    }
  }

  /// Calculate the appropriate charge based on driver's payment method
  static double calculateDriverCharge({
    required DriverUserModel driver,
    required AdminCommission adminCommission,
    required double rideAmount,
    required double discountAmount,
  }) {
    final chargeableAmount = rideAmount - discountAmount;
    
    // Check if flat rate is active and valid
    if (driver.paymentMethod == 'flat_rate' && isFlatRateActive(driver)) {
      return 0.0; // No charge per trip when flat rate is active
    }
    
    // Determine payment method to use (fallback logic)
    String paymentMethod = driver.paymentMethod ?? 'commission';
    
    // Auto-select if only one method is available
    if (adminCommission.hasOnlyCommission) {
      paymentMethod = 'commission';
    } else if (adminCommission.hasOnlyFlatRate) {
      paymentMethod = 'flat_rate';
    }

    // If flat rate is selected but not active/expired, use commission as fallback
    if (paymentMethod == 'flat_rate' && !isFlatRateActive(driver)) {
      paymentMethod = 'commission';
    }

    switch (paymentMethod) {
      case 'flat_rate':
        // This should not happen as we check isFlatRateActive above
        return 0.0;
      
      case 'commission':
      default:
        if (adminCommission.isEnabled == true) {
          return adminCommission.calculateCommissionAmount(chargeableAmount);
        }
        return 0.0;
    }
  }

  /// Get display text for payment method
  static String getPaymentMethodDisplayText(String paymentMethod) {
    switch (paymentMethod) {
      case 'flat_rate':
        return 'Daily Flat Rate';
      case 'commission':
      default:
        return 'Commission';
    }
  }

  /// Get description for payment method
  static String getPaymentMethodDescription(
    String paymentMethod, 
    AdminCommission adminCommission
  ) {
    switch (paymentMethod) {
      case 'flat_rate':
        final amount = adminCommission.getFlatRateAmount();
        return 'Pay ${Constant.amountShow(amount: amount.toString())} per day (24 hours)';
      
      case 'commission':
      default:
        final isPercentage = adminCommission.type != "fix";
        if (isPercentage) {
          return 'Pay ${adminCommission.amount}% commission on each ride';
        } else {
          return 'Pay ${Constant.amountShow(amount: adminCommission.amount.toString())} commission per ride';
        }
    }
  }

  /// Get flat rate status text for UI
  static String getFlatRateStatusText(DriverUserModel driver) {
    if (driver.paymentMethod != 'flat_rate') {
      return 'Not using flat rate';
    }
    
    if (isFlatRateActive(driver)) {
      final timeRemaining = getFlatRateTimeRemaining(driver);
      final hours = timeRemaining.inHours;
      final minutes = timeRemaining.inMinutes % 60;
      
      if (hours > 0) {
        return 'Active for ${hours}h ${minutes}m';
      } else {
        return 'Active for ${minutes}m';
      }
    } else {
      return 'Expired - Renew or switch to commission';
    }
  }
}
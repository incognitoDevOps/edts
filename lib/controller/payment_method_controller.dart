import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/model/admin_commission.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/wallet_transaction_model.dart';
import 'package:driver/services/payment_method_service.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class PaymentMethodController extends GetxController {
  // Observable variables
  Rx<AdminCommission> adminCommission = AdminCommission().obs;
  Rx<DriverUserModel> driverUser = DriverUserModel().obs;
  RxBool isLoading = true.obs;
  RxBool isSwitching = false.obs;
  RxBool isProcessingFlatRate = false.obs;
  RxString selectedPaymentMethod = "commission".obs;
  RxBool canSwitch = false.obs;
  RxBool flatRateActive = false.obs;
  Rx<Duration> timeUntilNextSwitch = Duration.zero.obs;
  Rx<Duration> flatRateTimeRemaining = Duration.zero.obs;
  RxBool hasSufficientBalance = false.obs;
  
  // Timer for countdown
  Timer? _countdownTimer;
  Timer? _flatRateTimer;

  @override
  void onInit() {
    super.onInit();
    loadPaymentMethodData();
    startTimers();
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    _flatRateTimer?.cancel();
    super.onClose();
  }

  /// Load admin commission and driver data
  Future<void> loadPaymentMethodData() async {
    try {
      isLoading.value = true;

      // Load admin commission settings
      final commissionDoc = await FirebaseFirestore.instance
          .collection(CollectionName.settings)
          .doc('adminCommission')
          .get();

      if (commissionDoc.exists) {
        adminCommission.value = AdminCommission.fromJson(commissionDoc.data()!);
      }

      // Load current driver data
      final driver = await FireStoreUtils.getDriverProfile(
        FireStoreUtils.getCurrentUid()
      );
      
      if (driver != null) {
        driverUser.value = driver;
        selectedPaymentMethod.value = driver.paymentMethod ?? 'commission';
        
        // Check if driver can switch
        canSwitch.value = PaymentMethodService.canSwitchPaymentMethod(driver);
        timeUntilNextSwitch.value = PaymentMethodService.getTimeUntilNextSwitch(driver);
        
        // Check flat rate status
        flatRateActive.value = PaymentMethodService.isFlatRateActive(driver);
        flatRateTimeRemaining.value = PaymentMethodService.getFlatRateTimeRemaining(driver);
        
        // Check wallet balance for flat rate
        hasSufficientBalance.value = PaymentMethodService.hasSufficientBalanceForFlatRate(
          driver, 
          adminCommission.value
        );

        // Auto-deactivate expired flat rate
        if (driver.paymentMethod == 'flat_rate' && !flatRateActive.value && driver.flatRateActive == true) {
          await PaymentMethodService.deactivateExpiredFlatRate(driver.id!);
          // Reload driver data
          final updatedDriver = await FireStoreUtils.getDriverProfile(driver.id!);
          if (updatedDriver != null) {
            driverUser.value = updatedDriver;
            selectedPaymentMethod.value = updatedDriver.paymentMethod ?? 'commission';
          }
        }
      }

    } catch (e) {
      ShowToastDialog.showToast('Failed to load payment settings: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Start countdown timers
  void startTimers() {
    startSwitchCountdownTimer();
    startFlatRateTimer();
  }

  /// Start countdown timer for next switch availability
  void startSwitchCountdownTimer() {
    _countdownTimer?.cancel();
    
    if (timeUntilNextSwitch.value.inSeconds > 0) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (timeUntilNextSwitch.value.inSeconds <= 1) {
          canSwitch.value = true;
          timeUntilNextSwitch.value = Duration.zero;
          timer.cancel();
        } else {
          timeUntilNextSwitch.value = Duration(
            seconds: timeUntilNextSwitch.value.inSeconds - 1
          );
        }
      });
    }
  }

  /// Start flat rate countdown timer
  void startFlatRateTimer() {
    _flatRateTimer?.cancel();
    
    if (flatRateTimeRemaining.value.inSeconds > 0) {
      _flatRateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (flatRateTimeRemaining.value.inSeconds <= 1) {
          flatRateActive.value = false;
          flatRateTimeRemaining.value = Duration.zero;
          timer.cancel();
          
          // Auto-deactivate expired flat rate
          if (driverUser.value.paymentMethod == 'flat_rate') {
            PaymentMethodService.deactivateExpiredFlatRate(driverUser.value.id!);
            selectedPaymentMethod.value = 'commission';
          }
        } else {
          flatRateTimeRemaining.value = Duration(
            seconds: flatRateTimeRemaining.value.inSeconds - 1
          );
        }
      });
    }
  }

  /// Switch to commission payment method
  Future<void> switchToCommission() async {
    if (!canSwitch.value) {
      ShowToastDialog.showToast('You can only switch payment methods once every 24 hours');
      return;
    }

    if (selectedPaymentMethod.value == 'commission') {
      return; // Already on commission
    }

    try {
      isSwitching.value = true;
      ShowToastDialog.showLoader('Switching to commission...');

      final success = await PaymentMethodService.switchPaymentMethod(
        FireStoreUtils.getCurrentUid(),
        'commission',
      );

      if (success) {
        selectedPaymentMethod.value = 'commission';
        driverUser.value.paymentMethod = 'commission';
        driverUser.value.lastSwitched = Timestamp.now();
        driverUser.value.flatRateActive = false;
        
        flatRateActive.value = false;
        canSwitch.value = false;
        timeUntilNextSwitch.value = const Duration(hours: 24);
        startSwitchCountdownTimer();
        
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast('Switched to commission-based payment');
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast('Failed to switch payment method');
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast('Error switching payment method: $e');
    } finally {
      isSwitching.value = false;
    }
  }

  /// Switch to flat rate payment method (with payment processing)
  Future<void> switchToFlatRate() async {
    if (!canSwitch.value) {
      ShowToastDialog.showToast('You can only switch payment methods once every 24 hours');
      return;
    }

    if (selectedPaymentMethod.value == 'flat_rate' && flatRateActive.value) {
      return; // Already on active flat rate
    }

    if (!hasSufficientBalance.value) {
      final flatRateAmount = adminCommission.value.getFlatRateAmount();
      ShowToastDialog.showToast(
        'Insufficient wallet balance. Need ${Constant.amountShow(amount: flatRateAmount.toString())} for daily flat rate.'
      );
      return;
    }

    try {
      isProcessingFlatRate.value = true;
      ShowToastDialog.showLoader('Processing flat rate payment...');

      final success = await PaymentMethodService.processFlatRatePayment(
        FireStoreUtils.getCurrentUid(),
      );

      if (success) {
        selectedPaymentMethod.value = 'flat_rate';
        flatRateActive.value = true;
        flatRateTimeRemaining.value = const Duration(hours: 24);
        canSwitch.value = false;
        timeUntilNextSwitch.value = const Duration(hours: 24);
        
        // Update local driver data
        final flatRateAmount = adminCommission.value.getFlatRateAmount();
        final currentBalance = double.parse(driverUser.value.walletAmount ?? '0.0');
        driverUser.value.walletAmount = (currentBalance - flatRateAmount).toString();
        driverUser.value.paymentMethod = 'flat_rate';
        driverUser.value.flatRatePaidAt = Timestamp.now();
        driverUser.value.flatRateActive = true;
        driverUser.value.lastSwitched = Timestamp.now();
        
        hasSufficientBalance.value = PaymentMethodService.hasSufficientBalanceForFlatRate(
          driverUser.value, 
          adminCommission.value
        );
        
        startTimers();
        
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
          'Daily flat rate activated! Valid for 24 hours.'
        );
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast('Failed to process flat rate payment');
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast('Error processing flat rate payment: $e');
    } finally {
      isProcessingFlatRate.value = false;
    }
  }

  /// Renew flat rate (pay for another 24 hours)
  Future<void> renewFlatRate() async {
    if (!hasSufficientBalance.value) {
      final flatRateAmount = adminCommission.value.getFlatRateAmount();
      ShowToastDialog.showToast(
        'Insufficient wallet balance. Need ${Constant.amountShow(amount: flatRateAmount.toString())} to renew flat rate.'
      );
      return;
    }

    try {
      isProcessingFlatRate.value = true;
      ShowToastDialog.showLoader('Renewing flat rate...');

      final success = await PaymentMethodService.processFlatRatePayment(
        FireStoreUtils.getCurrentUid(),
      );

      if (success) {
        flatRateActive.value = true;
        flatRateTimeRemaining.value = const Duration(hours: 24);
        
        // Update local driver data
        final flatRateAmount = adminCommission.value.getFlatRateAmount();
        final currentBalance = double.parse(driverUser.value.walletAmount ?? '0.0');
        driverUser.value.walletAmount = (currentBalance - flatRateAmount).toString();
        driverUser.value.flatRatePaidAt = Timestamp.now();
        driverUser.value.flatRateActive = true;
        
        hasSufficientBalance.value = PaymentMethodService.hasSufficientBalanceForFlatRate(
          driverUser.value, 
          adminCommission.value
        );
        
        startFlatRateTimer();
        
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast('Flat rate renewed for another 24 hours!');
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast('Failed to renew flat rate');
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast('Error renewing flat rate: $e');
    } finally {
      isProcessingFlatRate.value = false;
    }
  }

  /// Check if payment method switching should be shown
  bool get shouldShowPaymentMethodSwitch => 
      adminCommission.value.hasBothPaymentMethods;

  /// Get formatted countdown text for switch cooldown
  String get switchCountdownText {
    if (timeUntilNextSwitch.value.inSeconds <= 0) return '';
    
    final hours = timeUntilNextSwitch.value.inHours;
    final minutes = timeUntilNextSwitch.value.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m remaining';
    } else {
      return '${minutes}m remaining';
    }
  }

  /// Get formatted countdown text for flat rate
  String get flatRateCountdownText {
    if (flatRateTimeRemaining.value.inSeconds <= 0) return '';
    
    final hours = flatRateTimeRemaining.value.inHours;
    final minutes = flatRateTimeRemaining.value.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m remaining';
    } else {
      return '${minutes}m remaining';
    }
  }

  /// Get current payment method description
  String get currentPaymentMethodDescription =>
      PaymentMethodService.getPaymentMethodDescription(
        selectedPaymentMethod.value,
        adminCommission.value,
      );

  /// Get flat rate amount for display
  String get flatRateAmountText =>
      Constant.amountShow(amount: adminCommission.value.getFlatRateAmount().toString());
}
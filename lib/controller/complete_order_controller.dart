import 'package:customer/constant/constant.dart';
import 'package:customer/model/coupon_model.dart';
import 'package:customer/model/driver_user_model.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class CompleteOrderController extends GetxController {
  Rx<OrderModel> orderModel = OrderModel().obs;
  Rx<CouponModel> couponModel = CouponModel().obs;
  RxString couponAmount = "0.0".obs;
  RxBool isLoading = true.obs;

  // 🔥 NEW: Add driver data loading
  Rx<DriverUserModel?> driverUserModel = Rx<DriverUserModel?>(null);
  RxBool isDriverLoading = false.obs;
  RxString driverError = "".obs;

  @override
  void onInit() {
    getArgument();
    super.onInit();
  }

  getArgument() async {
    try {
      isLoading.value = true;

      dynamic argumentData = Get.arguments;
      if (argumentData == null) {
        print("❌ No order data provided");
        isLoading.value = false;
        return;
      }

      OrderModel passedOrder = argumentData['orderModel'];

      // 🔥 CRITICAL: Load FRESH from Firestore - NO RECOVERY
      final freshOrder = await FireStoreUtils.getOrder(passedOrder.id!);

      if (freshOrder == null) {
        print("❌ Order not found");
        orderModel.value = passedOrder;
      } else {
        orderModel.value = freshOrder;
      }

      print("✅ [COMPLETE SCREEN] Order loaded:");
      orderModel.value.debugPrint();

      // Load driver if assigned
      if (orderModel.value.driverId != null &&
          orderModel.value.driverId!.isNotEmpty) {
        await _loadDriverInformation();
      } else {
        driverError.value = "No driver assigned";
      }

      // Load coupon
      if (orderModel.value.coupon != null) {
        couponModel.value = orderModel.value.coupon!;
        if (orderModel.value.coupon!.type == "fix") {
          couponAmount.value = orderModel.value.coupon!.amount.toString();
        } else {
          couponAmount.value =
              ((double.parse(orderModel.value.finalRate.toString()) *
                          double.parse(
                              orderModel.value.coupon!.amount.toString())) /
                      100)
                  .toString();
        }
      }
    } catch (e) {
      print("❌ Error loading order: $e");
      driverError.value = "Error loading ride details";
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // 🔥 NEW: Load driver information with retry mechanism
  Future<void> _loadDriverInformation() async {
    try {
      isDriverLoading.value = true;
      driverError.value = "";

      print(
          "🔍 [COMPLETE SCREEN] Loading driver information: ${orderModel.value.driverId}");

      // Use retry mechanism to load driver
      final driver = await FireStoreUtils.getDriverWithRetry(
        orderModel.value.driverId,
        maxRetries: 2, retryDelay: Duration(seconds: 2),
      );

      if (driver != null) {
        driverUserModel.value = driver;
        driverError.value = "";
        print(
            "✅ [COMPLETE SCREEN] Driver loaded successfully: ${driver.fullName}");
      } else {
        driverError.value = "Driver information not available";
        print("❌ [COMPLETE SCREEN] Failed to load driver after retries");
      }
    } catch (error) {
      driverError.value = "Error loading driver information";
      print("❌ [COMPLETE SCREEN] Error loading driver: $error");
    } finally {
      isDriverLoading.value = false;
      update();
    }
  }

  // 🔥 NEW: Debug method to check order state
  void _debugOrderState() {
    print("🔍 [COMPLETE SCREEN DEBUG] Current Order State:");
    print("   Order ID: ${orderModel.value.id}");
    print("   Driver ID: ${orderModel.value.driverId}");
    print("   Driver Loaded: ${driverUserModel.value != null}");
    print("   Payment Intent: ${orderModel.value.paymentIntentId}");
    print("   Pre-auth Amount: ${orderModel.value.preAuthAmount}");
    print("   Payment Status: ${orderModel.value.paymentIntentStatus}");
    print("   Pre-auth Created: ${orderModel.value.preAuthCreatedAt}");
    print("   Order Status: ${orderModel.value.status}");
  }

  // 🔥 UPDATED: Enhanced calculateAmount method with better error handling
  double calculateAmount() {
    try {
      double amount = double.parse(orderModel.value.finalRate ?? "0.0");
      double taxTotal = 0.0;

      // Calculate taxes
      if (orderModel.value.taxList != null &&
          orderModel.value.taxList!.isNotEmpty) {
        for (var tax in orderModel.value.taxList!) {
          taxTotal += Constant().calculateTax(
              amount: (amount - double.parse(couponAmount.value)).toString(),
              taxModel: tax);
        }
      }

      // Apply coupon discount
      double couponDiscount = double.parse(couponAmount.value);

      final totalAmount = (amount - couponDiscount) + taxTotal;

      print("🧮 [COMPLETE SCREEN] Amount Calculation:");
      print("   Base Amount: $amount");
      print("   Coupon Discount: $couponDiscount");
      print("   Total Tax: $taxTotal");
      print("   Final Amount: $totalAmount");

      return totalAmount;
    } catch (e) {
      print("❌ [COMPLETE SCREEN] Error calculating amount: $e");
      return 0.0;
    }
  }

  // 🔥 NEW: Enhanced amount calculation with formatted return
  String calculateAmountFormatted() {
    final amount = calculateAmount();
    return amount.toStringAsFixed(Constant.currencyModel?.decimalDigits ?? 2);
  }

  // 🔥 NEW: Refresh method to reload all data
  Future<void> refreshData() async {
    print("🔄 [COMPLETE SCREEN] Refreshing all data...");
    await getArgument();
  }

  // 🔥 NEW: Check if driver data is available
  bool get hasDriverData => driverUserModel.value != null;

  // 🔥 NEW: Get driver name safely
  String get driverName {
    if (driverUserModel.value?.fullName != null) {
      return driverUserModel.value!.fullName!;
    }
    return "Driver information not available";
  }

  // 🔥 NEW: Get vehicle information safely
  String? get vehicleType =>
      driverUserModel.value?.vehicleInformation?.vehicleType;
  String? get vehicleColor =>
      driverUserModel.value?.vehicleInformation?.vehicleColor;
  String? get vehicleNumber =>
      driverUserModel.value?.vehicleInformation?.vehicleNumber;

  // 🔥 NEW: Check payment status
  bool get isPaid => orderModel.value.paymentStatus == true;
  bool get hasPaymentIntent =>
      orderModel.value.paymentIntentId != null &&
      orderModel.value.paymentIntentId!.isNotEmpty;

  // 🔥 NEW: Format timestamp for display
  String get formattedDate {
    if (orderModel.value.createdDate != null) {
      return Constant().formatTimestamp(orderModel.value.createdDate!);
    }
    return "Date not available";
  }

  // 🔥 ADD TO CompleteOrderController
  void _debugOrderDriverState() {
    print("🔍 [ORDER DRIVER DEBUG] Complete Order Analysis:");
    print("   Order ID: ${orderModel.value.id}");
    print("   Driver ID: ${orderModel.value.driverId}");
    print("   Status: ${orderModel.value.status}");
    print("   Payment Intent: ${orderModel.value.paymentIntentId}");
    print("   Pre-auth Amount: ${orderModel.value.preAuthAmount}");
    print("   Created Date: ${orderModel.value.createdDate}");

    // Check if this is a completed ride without driver
    if (orderModel.value.driverId == null ||
        orderModel.value.driverId!.isEmpty) {
      print("🚨 [ORDER DRIVER DEBUG] ORDER HAS NO DRIVER ASSIGNED!");

      if (orderModel.value.status == Constant.rideComplete) {
        print(
            "💡 This is a COMPLETED ride without driver assignment - this shouldn't happen!");
      } else if (orderModel.value.status == Constant.ridePlaced) {
        print("💡 This ride is still PLACED - waiting for driver acceptance");
      } else if (orderModel.value.status == Constant.rideCanceled) {
        print("💡 This ride was CANCELLED - no driver assigned");
      }
    }
  }
}

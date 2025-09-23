import 'package:driver/constant/constant.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/order_model.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class CompleteOrderController extends GetxController {
  RxBool isLoading = true.obs;
  Rx<DriverUserModel> driverUser = DriverUserModel().obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getArgument();
    loadDriverData();
    super.onInit();
  }

  Rx<OrderModel> orderModel = OrderModel().obs;

  RxString couponAmount = "0.0".obs;

  loadDriverData() async {
    final driver = await FireStoreUtils.getDriverProfile(
      FireStoreUtils.getCurrentUid()
    );
    if (driver != null) {
      driverUser.value = driver;
    }
  }

  double calculateAmount() {
    RxString taxAmount = "0.0".obs;
    if (orderModel.value.taxList != null) {
      for (var element in orderModel.value.taxList!) {
        taxAmount.value = (double.parse(taxAmount.value) +
                Constant.calculateTax(amount: (double.parse(orderModel.value.finalRate.toString()) - double.parse(couponAmount.value.toString())).toString(), taxModel: element))
            .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
      }
    }
    return (double.parse(orderModel.value.finalRate.toString()) - double.parse(couponAmount.value.toString())) + double.parse(taxAmount.value);
  }

  /// Calculate driver charge using new payment method logic
  double calculateDriverCharge() {
    if (orderModel.value.adminCommission == null) return 0.0;
    
    return Constant.calculateDriverCharge(
      driver: driverUser.value,
      adminCommission: orderModel.value.adminCommission!,
      rideAmount: double.parse(orderModel.value.finalRate.toString()),
      discountAmount: double.parse(couponAmount.value.toString()),
    );
  }

  getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      orderModel.value = argumentData['orderModel'];

      if (orderModel.value.coupon != null) {
        if (orderModel.value.coupon?.code != null) {
          if (orderModel.value.coupon!.type == "fix") {
            couponAmount.value = orderModel.value.coupon!.amount.toString();
          } else {
            couponAmount.value =
                ((double.parse(orderModel.value.finalRate.toString()) * double.parse(orderModel.value.coupon!.amount.toString())) / 100).toString();
          }
        }

      }
    }
    print("=====>");
    print(orderModel.value.adminCommission!.toJson());
    isLoading.value = false;
    update();
  }
}

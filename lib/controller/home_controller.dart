import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controller/dash_board_controller.dart';
import 'package:customer/model/admin_commission.dart';
import 'package:customer/model/airport_model.dart';
import 'package:customer/model/banner_model.dart';
import 'package:customer/model/contact_model.dart';
import 'package:customer/model/order/location_lat_lng.dart';
import 'package:customer/model/order/positions.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/model/payment_model.dart';
import 'package:customer/model/service_model.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/model/zone_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/utils/Preferences.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/utils/notification_service.dart';
import 'package:customer/utils/utils.dart';
import 'package:customer/widget/geoflutterfire/src/geoflutterfire.dart';
import 'package:customer/widget/geoflutterfire/src/models/point.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:osm_nominatim/osm_nominatim.dart';
import 'package:http/http.dart' as http;

class HomeController extends GetxController {
  DashBoardController dashboardController = Get.put(DashBoardController());

  Rx<TextEditingController> sourceLocationController =
      TextEditingController().obs;
  Rx<TextEditingController> destinationLocationController =
      TextEditingController().obs;
  Rx<TextEditingController> offerYourRateController =
      TextEditingController().obs;
  Rx<ServiceModel> selectedType = ServiceModel().obs;

  Rx<LocationLatLng> sourceLocationLAtLng = LocationLatLng().obs;
  Rx<LocationLatLng> destinationLocationLAtLng = LocationLatLng().obs;

  RxString currentLocation = "".obs;
  RxBool isLoading = true.obs;
  RxList serviceList = <ServiceModel>[].obs;
  RxList bannerList = <BannerModel>[].obs;
  RxList zoneList = <ZoneModel>[].obs;
  Rx<ZoneModel> selectedZone = ZoneModel().obs;
  Rx<UserModel> userModel = UserModel().obs;
  final PageController pageController =
      PageController(viewportFraction: 0.96, keepPage: true);

  RxBool isPaymentLoading = false.obs;

  var colors = [
    AppColors.serviceColor1,
    AppColors.serviceColor2,
    AppColors.serviceColor3,
  ];

  @override
  void onInit() {
    // TODO: implement onInit
    getServiceType();
    getPaymentData();
    getContact();
    super.onInit();
  }

  getServiceType() async {
    await FireStoreUtils.getService().then((value) {
      serviceList.value = value.where((service) {
        final title = service.title?.toLowerCase() ?? '';
        return title != 'bicycle' && title != 'scooter';
      }).toList();
      if (serviceList.isNotEmpty) {
        selectedType.value = serviceList.first;
      }
    });

    await FireStoreUtils.getBanner().then((value) {
      bannerList.value = value;
    });

    try {
      Constant.currentLocation = await Utils.getCurrentLocation();

      if (Constant.currentLocation != null) {
        if (Constant.selectedMapType == 'google') {
          List<Placemark> placeMarks = await placemarkFromCoordinates(
              Constant.currentLocation!.latitude,
              Constant.currentLocation!.longitude);
          print("=====>");
          print(placeMarks.first);
          Constant.country = placeMarks.first.country;
          Constant.city = placeMarks.first.locality;
          currentLocation.value =
              "${placeMarks.first.name}, ${placeMarks.first.subLocality}, ${placeMarks.first.locality}, ${placeMarks.first.administrativeArea}, ${placeMarks.first.postalCode}, ${placeMarks.first.country}";
        } else {
          try {
            Place place = await Nominatim.reverseSearch(
              lat: Constant.currentLocation!.latitude,
              lon: Constant.currentLocation!.longitude,
              zoom: 14,
              addressDetails: true,
              extraTags: true,
              nameDetails: true,
            ).timeout(const Duration(seconds: 5), onTimeout: () {
              throw Exception('Location search timed out');
            });
            currentLocation.value = place.displayName.toString();
            Constant.country = place.address?['country'] ?? '';
            Constant.city = place.address?['city'] ?? '';
          } catch (e) {
            print("Error getting location name: $e");
            currentLocation.value = "Current Location";
            // Set default values if needed
            Constant.country = Constant.country ?? '';
            Constant.city = Constant.city ?? '';
          }
        }
        await FireStoreUtils().getTaxList().then((value) {
          if (value != null) {
            Constant.taxList = value;
          }
        });

        await FireStoreUtils().getAirports().then((value) {
          if (value != null) {
            Constant.airaPortList = value;
            print("====>");
            print(Constant.airaPortList!.length);
          }
        });
      }
    } catch (e) {
      print("=====>");
      print(e.toString());
      ShowToastDialog.showToast(
          "Location access permission is currently unavailable. You're unable to retrieve any location data. Please grant permission from your device settings.",
          position: EasyLoadingToastPosition.center,
          duration: const Duration(seconds: 3));
    }

    String token = await NotificationService.getToken();
    await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid())
        .then((value) {
      userModel.value = value!;
      userModel.value.fcmToken = token;
      FireStoreUtils.updateUser(userModel.value);
    });

    isLoading.value = false;
  }

  RxString duration = "".obs;
  RxString distance = "".obs;
  RxString amount = "".obs;

  // --- Added for embedded map/ride info ---
  /// List of LatLng points for the route polyline (set this from your route API)
  RxList<LatLng> routePoints = <LatLng>[].obs;

  /// Traffic status for the route: 'heavy', 'moderate', 'clear' (set this from your traffic API or mock)
  RxString trafficStatus = 'clear'.obs;

  /// Pickup status: e.g. 'Pending', 'Arriving', 'Picked Up' (set this from your ride status logic)
  RxString pickupStatus = 'Pending'.obs;
  // --- End embedded map fields ---

  calculateAmount() async {
    if (sourceLocationLAtLng.value.latitude != null &&
        destinationLocationLAtLng.value.latitude != null) {
      ShowToastDialog.showLoader("Calculating route...");
      try {
        if (Constant.selectedMapType == 'osm') {
          await calculateOsmAmount();
        } else {
          await Constant.getDurationDistance(
                  LatLng(sourceLocationLAtLng.value.latitude!,
                      sourceLocationLAtLng.value.longitude!),
                  LatLng(destinationLocationLAtLng.value.latitude!,
                      destinationLocationLAtLng.value.longitude!))
              .timeout(const Duration(seconds: 10), onTimeout: () {
            throw Exception('Route calculation timed out');
          }).then((value) {
            ShowToastDialog.closeLoader();
            if (value != null) {
              duration.value =
                  value.rows!.first.elements!.first.duration!.text.toString();
              print("duration :: 00 :: ${duration.value}");
              if (Constant.distanceType == "Km") {
                distance.value = (value
                            .rows!.first.elements!.first.distance!.value!
                            .toInt() /
                        1000)
                    .toString();
                amount.value = Constant.amountCalculate(
                        selectedType.value.kmCharge.toString(), distance.value)
                    .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
              } else {
                distance.value = (value
                            .rows!.first.elements!.first.distance!.value!
                            .toInt() /
                        1609.34)
                    .toString();
                amount.value = Constant.amountCalculate(
                        selectedType.value.kmCharge.toString(), distance.value)
                    .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
              }
            }
          });
        }
      } catch (e) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
            "Failed to calculate route. Please try again.");
        print("Error calculating route: $e");
      }
    }
  }

  calculateOsmAmount() async {
    if (sourceLocationLAtLng.value.latitude != null &&
        destinationLocationLAtLng.value.latitude != null) {
      ShowToastDialog.showLoader("Calculating route...");
      try {
        await Constant.getDurationOsmDistance(
                LatLng(sourceLocationLAtLng.value.latitude!,
                    sourceLocationLAtLng.value.longitude!),
                LatLng(destinationLocationLAtLng.value.latitude!,
                    destinationLocationLAtLng.value.longitude!))
            .timeout(const Duration(seconds: 10), onTimeout: () {
          throw Exception('Route calculation timed out');
        }).then((value) {
          ShowToastDialog.closeLoader();
          if (value != {} && value.isNotEmpty) {
            int hours = value['routes'].first['duration'] ~/ 3600;
            int minutes =
                ((value['routes'].first['duration'] % 3600) / 60).round();
            duration.value = '$hours hours $minutes minutes';
            if (Constant.distanceType == "Km") {
              distance.value =
                  (value['routes'].first['distance'] / 1000).toString();
              amount.value = Constant.amountCalculate(
                      selectedType.value.kmCharge.toString(), distance.value)
                  .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
            } else {
              distance.value =
                  (value['routes'].first['distance'] / 1609.34).toString();
              amount.value = Constant.amountCalculate(
                      selectedType.value.kmCharge.toString(), distance.value)
                  .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
            }
          }
        });
      } catch (e) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
            "Failed to calculate route. Please try again.");
        print("Error calculating OSM route: $e");
      }
    }
  }

  Rx<PaymentModel> paymentModel = PaymentModel().obs;

  RxString selectedPaymentMethod = "".obs;
  RxList airPortList = <AriPortModel>[].obs;

  getPaymentData() async {
    isPaymentLoading.value = true;
    try {
      await FireStoreUtils().getPayment().then((value) {
        if (value != null) {
          paymentModel.value = value;
          print("Payment data loaded successfully");
        } else {
          print("No payment data found");
          // Initialize with default empty payment model
          paymentModel.value = PaymentModel(
            strip: null,
            wallet: null,
            cash: null,
            payStack: null,
            flutterWave: null,
            razorpay: null,
            paytm: null,
            payfast: null,
            mercadoPago: null,
          );
        }
      }).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Payment data fetch timed out');
      });

      await FireStoreUtils().getZone().then((value) {
        if (value != null) {
          zoneList.value = value;
        }
      }).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Zone data fetch timed out');
      });
    } catch (e) {
      print("Error loading payment data: $e");
      // Initialize with default empty payment model on error
      paymentModel.value = PaymentModel(
        strip: null,
        wallet: null,
        cash: null,
        payStack: null,
        flutterWave: null,
        razorpay: null,
        paytm: null,
        payfast: null,
        mercadoPago: null,
      );
    } finally {
      isPaymentLoading.value = false;
    }
  }

  // Add a method to refresh payment data
  Future<void> refreshPaymentData() async {
    isPaymentLoading.value = true;
    try {
      await FireStoreUtils().getPayment().then((value) {
        if (value != null) {
          paymentModel.value = value;
          print("Payment data refreshed successfully");
        }
      }).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Payment data refresh timed out');
      });
    } catch (e) {
      print("Error refreshing payment data: $e");
      ShowToastDialog.showToast(
          "Failed to load payment methods. Please try again.");
    } finally {
      isPaymentLoading.value = false;
    }
  }

  RxList<ContactModel> contactList = <ContactModel>[].obs;
  Rx<ContactModel> selectedTakingRide =
      ContactModel(fullName: "Myself", contactNumber: "").obs;
  Rx<AriPortModel> selectedAirPort = AriPortModel().obs;

  get isUserLoading => null;

  setContact() {
    print(jsonEncode(contactList));
    Preferences.setString(
        Preferences.contactList,
        json.encode(contactList
            .map<Map<String, dynamic>>((music) => music.toJson())
            .toList()));
    getContact();
  }

  getContact() {
    String contactListJson = Preferences.getString(Preferences.contactList);

    if (contactListJson.isNotEmpty) {
      print("---->");
      contactList.clear();
      contactList.value = (json.decode(contactListJson) as List<dynamic>)
          .map<ContactModel>((item) => ContactModel.fromJson(item))
          .toList();
    }
  }

  /// Enhanced ride booking method with proper driver finding
  Future<bool> bookRide() async {
    try {
      // Validate all required fields
      if (selectedPaymentMethod.value.isEmpty) {
        ShowToastDialog.showToast("Please select Payment Method".tr);
        return false;
      }

      // Check wallet balance if wallet payment is selected
      if (selectedPaymentMethod.value.toLowerCase() == "wallet") {
        await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid())
            .then((user) {
          if (user != null) {
            userModel.value = user;
            double walletBalance = double.parse(user.walletAmount ?? "0.0");
            double payableAmount = double.parse(amount.value);

            // Add tax calculation to payable amount
            if (Constant.taxList != null) {
              for (var tax in Constant.taxList!) {
                payableAmount += Constant()
                    .calculateTax(amount: amount.value, taxModel: tax);
              }
            }

            if (walletBalance < payableAmount) {
              ShowToastDialog.showToast(
                  "Insufficient balance. Please top up your wallet or choose another payment method.");
              return false;
            }
          }
        });
      }

      if (sourceLocationController.value.text.isEmpty) {
        ShowToastDialog.showToast("Please select source location".tr);
        return false;
      }

      if (destinationLocationController.value.text.isEmpty) {
        ShowToastDialog.showToast("Please select destination location".tr);
        return false;
      }

      if (sourceLocationLAtLng.value.latitude == null ||
          destinationLocationLAtLng.value.latitude == null) {
        ShowToastDialog.showToast("Invalid location coordinates".tr);
        return false;
      }

      if (distance.value.isEmpty || double.parse(distance.value) <= 2) {
        ShowToastDialog.showToast(
            "Please select more than two ${Constant.distanceType} location".tr);
        return false;
      }

      if (selectedType.value.offerRate == true &&
          offerYourRateController.value.text.isEmpty) {
        ShowToastDialog.showToast("Please Enter offer rate".tr);
        return false;
      }

      // Check for pending payments
      bool isPaymentNotCompleted = await FireStoreUtils.paymentStatusCheck();
      if (isPaymentNotCompleted) {
        ShowToastDialog.showToast(
            "Please complete payment for your previous ride before booking a new one");
        return false;
      }

      // Create order model
      OrderModel orderModel = OrderModel();
      orderModel.id = Constant.getUuid();
      orderModel.userId = FireStoreUtils.getCurrentUid();
      orderModel.sourceLocationName = sourceLocationController.value.text;
      orderModel.destinationLocationName =
          destinationLocationController.value.text;
      orderModel.sourceLocationLAtLng = sourceLocationLAtLng.value;
      orderModel.destinationLocationLAtLng = destinationLocationLAtLng.value;
      orderModel.distance = distance.value;
      orderModel.distanceType = Constant.distanceType;
      orderModel.offerRate = selectedType.value.offerRate == true
          ? offerYourRateController.value.text
          : amount.value;
      orderModel.finalRate = orderModel.offerRate;
      orderModel.serviceId = selectedType.value.id;
      orderModel.createdDate = Timestamp.now();
      orderModel.status = Constant.ridePlaced;
      orderModel.paymentType = selectedPaymentMethod.value;
      orderModel.paymentStatus = false;
      orderModel.service = selectedType.value;

      // Set admin commission - always use the global commission settings
      if (Constant.adminCommission != null) {
        orderModel.adminCommission = Constant.adminCommission;
        print(
            "✅ Added admin commission to order: ${Constant.adminCommission!.toJson()}");
      } else {
        print("⚠️  No global admin commission available");
        // Create a default commission to avoid null errors
        orderModel.adminCommission = AdminCommission(
            isEnabled: false,
            type: "percentage",
            amount: "0",
            flatRatePromotion:
                FlatRatePromotion(isEnabled: false, amount: 0.0));
      }

      // Debug: Log what commission was set
      if (orderModel.adminCommission != null) {
        print("🧾 Order commission details:");
        print("   Enabled: ${orderModel.adminCommission!.isEnabled}");
        print("   Type: ${orderModel.adminCommission!.type}");
        print("   Amount: ${orderModel.adminCommission!.amount}");
        if (orderModel.adminCommission!.flatRatePromotion != null) {
          print(
              "   Flat Rate Enabled: ${orderModel.adminCommission!.flatRatePromotion!.isEnabled}");
          print(
              "   Flat Rate Amount: ${orderModel.adminCommission!.flatRatePromotion!.amount}");
        }
      } else {
        print(
            "❌ CRITICAL: Order commission is null after attempted assignment");
      }

      orderModel.otp = Constant.getReferralCode();
      orderModel.taxList = Constant.taxList;

      // Handle Stripe pre-authorization for ride booking
      if (selectedPaymentMethod.value.toLowerCase() == "stripe") {
        try {
          ShowToastDialog.showLoader("Authorizing payment...");

          // Calculate total amount including taxes
          double totalAmount = double.parse(orderModel.offerRate!);
          if (Constant.taxList != null) {
            for (var tax in Constant.taxList!) {
              totalAmount += Constant()
                  .calculateTax(amount: orderModel.offerRate!, taxModel: tax);
            }
          }

          // Create Stripe payment intent with manual capture
          Map<String, dynamic>? paymentIntentData =
              await _createStripePreAuth(totalAmount.toString());

          if (paymentIntentData != null &&
              !paymentIntentData.containsKey("error")) {
            orderModel.paymentIntentId = paymentIntentData['id'];
            ShowToastDialog.closeLoader();
          } else {
            ShowToastDialog.closeLoader();
            ShowToastDialog.showToast(
                "Failed to authorize payment. Please try again.");
            return false;
          }
        } catch (e) {
          ShowToastDialog.closeLoader();
          ShowToastDialog.showToast("Payment authorization failed: $e");
          return false;
        }
      }

      if (selectedTakingRide.value.fullName != "Myself") {
        orderModel.someOneElse = selectedTakingRide.value;
      }

      // Create geofire position
      GeoFirePoint position = Geoflutterfire().point(
          latitude: sourceLocationLAtLng.value.latitude!,
          longitude: sourceLocationLAtLng.value.longitude!);
      orderModel.position =
          Positions(geoPoint: position.geoPoint, geohash: position.hash);

      // Find appropriate zone
      bool zoneFound = false;
      for (int i = 0; i < zoneList.length; i++) {
        if (Constant.isPointInPolygon(
            LatLng(sourceLocationLAtLng.value.latitude!,
                sourceLocationLAtLng.value.longitude!),
            zoneList[i].area!)) {
          selectedZone.value = zoneList[i];
          orderModel.zoneId = selectedZone.value.id;
          orderModel.zone = selectedZone.value;
          zoneFound = true;
          break;
        }
      }

      if (!zoneFound) {
        ShowToastDialog.showToast(
          "Services are currently unavailable in the selected location. Please reach out to the administrator for assistance.",
        );
        return false;
      }

      // Place the ride request
      bool success = await FireStoreUtils.placeRideRequest(orderModel);

      if (success) {
        // Verify the commission was saved to Firestore
        print("🔍 Verifying commission data was saved to Firestore...");
        await FireStoreUtils.verifyOrderCommission(orderModel.id!);

        // Clear form data
        sourceLocationController.value.clear();
        destinationLocationController.value.clear();
        offerYourRateController.value.clear();
        sourceLocationLAtLng.value = LocationLatLng();
        destinationLocationLAtLng.value = LocationLatLng();
        distance.value = "";
        duration.value = "";
        amount.value = "";
        selectedPaymentMethod.value = "";

        return true;
      }

      return false;
    } catch (e) {
      print("❌ Error in bookRide: $e");
      ShowToastDialog.showToast("Failed to book ride: ${e.toString()}");
      return false;
    }
  }

  // Helper method to create Stripe pre-authorization
  Future<Map<String, dynamic>?> _createStripePreAuth(String amount) async {
    try {
      Map<String, dynamic> body = {
        'amount': ((double.parse(amount) * 100).round()).toString(),
        'currency': "CAD",
        'payment_method_types[]': 'card',
        'capture_method': 'manual', // This creates a pre-authorization
        "description": "BuzRyde Ride Pre-authorization",
        "shipping[name]": userModel.value.fullName,
        "shipping[address][line1]": "123 Main St",
        "shipping[address][postal_code]": "K1A 0A6",
        "shipping[address][city]": "Ottawa",
        "shipping[address][state]": "ON",
        "shipping[address][country]": "CA",
      };

      // You'll need to get the stripe secret from payment model
      final paymentData = await FireStoreUtils().getPayment();
      if (paymentData?.strip?.stripeSecret == null) {
        throw Exception("Stripe not configured");
      }

      var response = await http.post(
          Uri.parse('https://api.stripe.com/v1/payment_intents'),
          body: body,
          headers: {
            'Authorization': 'Bearer ${paymentData!.strip!.stripeSecret}',
            'Content-Type': 'application/x-www-form-urlencoded'
          });
      return jsonDecode(response.body);
    } catch (e) {
      print("Error creating Stripe pre-auth: $e");
      return null;
    }
  }
}

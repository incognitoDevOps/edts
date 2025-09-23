import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/controller/home_controller.dart';
import 'package:driver/model/order/location_lat_lng.dart';
import 'package:driver/model/order/positions.dart';
import 'package:driver/model/order_model.dart';
import 'package:driver/ui/home_screens/order_map_screen.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:driver/widget/geoflutterfire/src/geoflutterfire.dart';
import 'package:driver/widget/geoflutterfire/src/models/point.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

// *** DEMO CHANGES - RATES SET TO 50 FOR TESTING ***
// NOTE: FOR PRODUCTION - RESTORE ORIGINAL VALUES:
// - In _processRouteQRCode() - Change offerRate/finalRate defaults from '50' to '0.0'
// - In acceptedDriver collection - Change offerAmount default from '50' to '0.0'
// *** END DEMO CHANGES ***

class InstantBookingController extends GetxController {
  RxBool isLoading = false.obs;
  late HomeController homeController;
  final FirebaseFirestore fireStore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    homeController = Get.find<HomeController>();
  }

  void processQRCode(String qrCode) async {
    try {
      isLoading.value = true;
      
      // Check if the QR code is empty
      if (qrCode.isEmpty) {
        Get.back();
        Get.snackbar(
          'Error'.tr,
          'Invalid QR code'.tr,
          snackPosition: SnackPosition.BOTTOM,
          colorText: Colors.white,
          backgroundColor: Colors.red,
        );
        return;
      }

      // First attempt to parse the QR code as JSON which might contain route information
      try {
        final jsonData = jsonDecode(qrCode);
        // If parsing succeeds, it's likely a route QR code
        await _processRouteQRCode(jsonData);
        return;
      } catch (e) {
        // If parsing fails, it might be a simple order ID
        print("QR is not a JSON: $e");
      }

      // Check if the QR code is an existing order ID
      final orderDoc = await fireStore.collection(CollectionName.orders).doc(qrCode).get();
      
      if (orderDoc.exists) {
        // This is an existing order, show order details
        Get.back();
        Get.to(const OrderMapScreen(), arguments: {"orderModel": qrCode})!.then((value) {
          if (value != null && value == true) {
            homeController.selectedIndex.value = 1;
          }
        });
      } else {
        // Not a valid order ID, show manual entry dialog
        Get.back();
        _showManualEntryDialog(qrCode);
      }
    } catch (e) {
      Get.back();
      Get.snackbar(
        'Error'.tr,
        'Failed to process QR code: ${e.toString()}'.tr,
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Process a QR code that contains route information
  Future<void> _processRouteQRCode(Map<String, dynamic> jsonData) async {
    try {
      // Check if the QR code contains the necessary route information
      if (!_validateRouteData(jsonData)) {
        Get.back();
        Get.snackbar(
          'Error'.tr,
          'Invalid route information in QR code'.tr,
          snackPosition: SnackPosition.BOTTOM,
          colorText: Colors.white,
          backgroundColor: Colors.red,
        );
        return;
      }

      // Extract route information
      final userId = jsonData['userId'] ?? '';
      final sourceLocationName = jsonData['sourceLocationName'] ?? '';
      final destinationLocationName = jsonData['destinationLocationName'] ?? '';
      final sourceLatitude = double.tryParse(jsonData['sourceLatitude']?.toString() ?? '0') ?? 0.0;
      final sourceLongitude = double.tryParse(jsonData['sourceLongitude']?.toString() ?? '0') ?? 0.0;
      final destLatitude = double.tryParse(jsonData['destLatitude']?.toString() ?? '0') ?? 0.0;
      final destLongitude = double.tryParse(jsonData['destLongitude']?.toString() ?? '0') ?? 0.0;
      final distance = jsonData['distance']?.toString() ?? '0.0';
      final distanceType = jsonData['distanceType'] ?? 'Km';
      
      // Create a new order ID
      final String orderId = const Uuid().v4();
      
      // Create source and destination location objects
      final sourceLocationLatLng = LocationLatLng(latitude: sourceLatitude, longitude: sourceLongitude);
      final destLocationLatLng = LocationLatLng(latitude: destLatitude, longitude: destLongitude);
      
      // Create a GeoFirePoint for the source location (for proximity queries)
      final GeoFirePoint geoFirePoint = Geoflutterfire().point(
        latitude: sourceLatitude,
        longitude: sourceLongitude
      );
      final position = Positions(geoPoint: geoFirePoint.geoPoint, geohash: geoFirePoint.hash);
      
      // ALWAYS use fallback values for testing/demo purposes
      String serviceId = "test_service_id";
      List<dynamic> zoneIds = ["test_zone_id"];
      String driverId = FireStoreUtils.getCurrentUid();
      
      // Create the order model
      final orderData = {
        'id': orderId,
        'userId': userId,
        'sourceLocationName': sourceLocationName,
        'destinationLocationName': destinationLocationName,
        'sourceLocationLAtLng': sourceLocationLatLng.toJson(),
        'destinationLocationLAtLng': destLocationLatLng.toJson(),
        'distance': distance,
        'distanceType': distanceType,
        'status': Constant.rideActive, // Set status to active instead of placed
        'createdDate': Timestamp.now(),
        'serviceId': serviceId,
        'zoneId': zoneIds.first,
        'position': position.toJson(),
        'offerRate': jsonData['offerRate'] ?? '50', // DEMO: Changed from '0.0' to '50'
        'finalRate': jsonData['finalRate'] ?? '50', // DEMO: Changed from '0.0' to '50'
        'paymentType': jsonData['paymentType'] ?? 'cash',
        'paymentStatus': false,
        'otp': '${1000 + DateTime.now().millisecond}', // Generate a simple OTP
        'acceptedDriverId': [driverId],
        'rejectedDriverId': [],
        'driverId': driverId // Set the current driver as the assigned driver
      };
      
      // Save to Firestore
      await fireStore.collection(CollectionName.orders).doc(orderId).set(orderData);
      
      // Create an order model for further processing
      OrderModel orderModel = OrderModel.fromJson(orderData);
      
      // Create driver acceptance entry in the order's acceptedDriver subcollection
      await fireStore
          .collection(CollectionName.orders)
          .doc(orderId)
          .collection("acceptedDriver")
          .doc(driverId)
          .set({
        'driverId': driverId,
        'accepted': true,
        'offerAmount': jsonData['offerRate'] ?? '50', // DEMO: Changed from '0.0' to '50'
        'acceptedRejectTime': Timestamp.now(),
        'createdDate': Timestamp.now(),
      });
      
      // Navigate back to the home screen
      Get.back();
      
      // Show success message
      Get.snackbar(
        'Success'.tr,
        'Test ride accepted! Check your ongoing rides tab.'.tr,
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      );
      
      // Switch to the accepted orders tab
      homeController.selectedIndex.value = 1;
      
      // Navigate to order map screen
      Future.delayed(const Duration(milliseconds: 500), () {
        Get.to(const OrderMapScreen(), arguments: {"orderModel": orderId});
      });
      
    } catch (e) {
      Get.back();
      Get.snackbar(
        'Error'.tr,
        'Failed to create new ride: ${e.toString()}'.tr,
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
    }
  }
  
  // Validate if the QR code data contains required route information
  bool _validateRouteData(Map<String, dynamic> data) {
    return data.containsKey('sourceLocationName') && 
           data.containsKey('destinationLocationName') &&
           data.containsKey('sourceLatitude') && 
           data.containsKey('sourceLongitude') &&
           data.containsKey('destLatitude') && 
           data.containsKey('destLongitude');
  }

  void _showManualEntryDialog(String scannedCode) {
    final TextEditingController textController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        title: Text('Order Not Found'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('The scanned QR code "$scannedCode" is not a valid order ID.'.tr),
            SizedBox(height: 16),
            Text('Please enter a valid order ID:'.tr),
            SizedBox(height: 8),
            TextField(
              controller: textController,
              decoration: InputDecoration(
                hintText: 'Order ID'.tr,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: Text('Cancel'.tr),
          ),
          TextButton(
            onPressed: () async {
              final orderId = textController.text.trim();
              if (orderId.isNotEmpty) {
                Get.back();
                isLoading.value = true;
                
                // Check if manually entered order ID exists
                final orderDoc = await fireStore.collection(CollectionName.orders).doc(orderId).get();
                
                isLoading.value = false;
                if (orderDoc.exists) {
                  Get.to(const OrderMapScreen(), arguments: {"orderModel": orderId})!.then((value) {
                    if (value != null && value == true) {
                      homeController.selectedIndex.value = 1;
                    }
                  });
                } else {
                  Get.snackbar(
                    'Error'.tr,
                    'Order not found'.tr,
                    snackPosition: SnackPosition.BOTTOM,
                    colorText: Colors.white,
                    backgroundColor: Colors.red,
                  );
                }
              }
            },
            child: Text('Submit'.tr),
          ),
        ],
      ),
    );
  }
} 
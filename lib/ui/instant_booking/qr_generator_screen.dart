import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/model/order_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:qr/qr.dart';
import 'package:uuid/uuid.dart';

// *** DEMO CHANGES - RATES SET TO 50 FOR TESTING ***
// NOTE: FOR PRODUCTION - RESTORE ORIGINAL VALUES:
// - In createRouteQRCode() - Change offerRate/finalRate from '50' to '0.0'
// - In QR scanner screen manual entry JSON - Change rates from '50' to '0.0'
// *** END DEMO CHANGES ***

class QRGeneratorScreen extends StatefulWidget {
  const QRGeneratorScreen({super.key});

  @override
  State<QRGeneratorScreen> createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _orderIdController = TextEditingController();
  String orderId = '';
  bool isCreatingTestOrder = false;
  bool isCreatingRouteQR = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _orderIdController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<String> createTestOrder() async {
    setState(() {
      isCreatingTestOrder = true;
    });
    
    try {
      final String uuid = const Uuid().v4();
      
      // Create a minimal but valid test order
      final testOrder = {
        'id': uuid,
        'userId': FireStoreUtils.getCurrentUid() ?? 'test_user',
        'sourceLocationName': 'Test Source Location',
        'destinationLocationName': 'Test Destination Location',
        'distance': '5.0',
        'distanceType': 'Km',
        'status': 'placed',
        'createdDate': Timestamp.now(),
        'serviceId': 'test_service_id',
        'offerRate': '100',
        'finalRate': '100',
        'paymentType': 'cash',
        'paymentStatus': false,
        'otp': '1234',
        'acceptedDriverId': [],
        'rejectedDriverId': []
      };
      
      // Save to Firestore
      await FirebaseFirestore.instance
          .collection(CollectionName.orders)
          .doc(uuid)
          .set(testOrder);
          
      return uuid;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create test order: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return '';
    } finally {
      setState(() {
        isCreatingTestOrder = false;
      });
    }
  }

  String createRouteQRCode() {
    setState(() {
      isCreatingRouteQR = true;
    });
    
    try {
      // Create a sample route data with current driver's location for testing
      final routeData = {
        'userId': FireStoreUtils.getCurrentUid() ?? 'test_user',
        'sourceLocationName': 'TEST SOURCE: Current Location',
        'destinationLocationName': 'TEST DESTINATION: Demo Location',
        // Use approximate coordinates that would be in range for testing
        'sourceLatitude': 37.7749,
        'sourceLongitude': -122.4194,
        'destLatitude': 37.3352,
        'destLongitude': -121.8811,
        'distance': '50.0',
        'distanceType': 'Km',
        // DEMO: Rates set to '50', change to '0.0' for production
        'offerRate': '50',
        'finalRate': '50',
        'paymentType': 'cash',
        // Add test flags to ensure proper handling
        'is_test_qr': true,
        'test_note': 'This is a test route for demo purposes'
      };
      
      // Convert to JSON string
      final jsonString = jsonEncode(routeData);
      
      return jsonString;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create route QR code: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return '';
    } finally {
      setState(() {
        isCreatingRouteQR = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Generate QR Code'.tr),
        backgroundColor: themeChange.getThem() ? AppColors.darkGray : AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Order ID QR'.tr),
            Tab(text: 'Route QR'.tr),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Order ID QR Tab
          _buildOrderIdQRTab(themeChange),
          
          // Route QR Tab
          _buildRouteQRTab(themeChange),
        ],
      ),
    );
  }
  
  Widget _buildOrderIdQRTab(DarkThemeProvider themeChange) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              'Enter Order ID to Generate QR Code'.tr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _orderIdController,
              decoration: InputDecoration(
                hintText: 'Order ID'.tr,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: themeChange.getThem() ? AppColors.darkGray.withOpacity(0.5) : Colors.grey.withOpacity(0.1),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      orderId = _orderIdController.text.trim();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeChange.getThem() ? AppColors.darkGray : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Generate QR Code'.tr),
                ),
                ElevatedButton(
                  onPressed: isCreatingTestOrder 
                    ? null 
                    : () async {
                      final String newOrderId = await createTestOrder();
                      if (newOrderId.isNotEmpty) {
                        setState(() {
                          _orderIdController.text = newOrderId;
                          orderId = newOrderId;
                        });
                        Get.snackbar(
                          'Success',
                          'Test order created with ID: $newOrderId',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                        );
                      }
                    },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeChange.getThem() ? Colors.blueGrey : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isCreatingTestOrder
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('Create Test Order'.tr),
                ),
              ],
            ),
            const SizedBox(height: 40),
            if (orderId.isNotEmpty)
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: QRCodeWidget(
                      data: orderId,
                      size: 250,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Order ID: $orderId',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Scan this QR code with the BuzRyde Driver app for instant booking'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRouteQRTab(DarkThemeProvider themeChange) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              'Generate Route QR Code'.tr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'This will create a QR code containing route information which will create a new ride when scanned.'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: isCreatingRouteQR 
                ? null 
                : () {
                  final String routeQRData = createRouteQRCode();
                  if (routeQRData.isNotEmpty) {
                    setState(() {
                      orderId = routeQRData;
                    });
                    Get.snackbar(
                      'Success',
                      'Route QR code created',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                    );
                  }
                },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeChange.getThem() ? AppColors.darkGray : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: isCreatingRouteQR
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text('Create Route QR Code'.tr),
            ),
            const SizedBox(height: 40),
            if (orderId.isNotEmpty && _tabController.index == 1)
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: QRCodeWidget(
                      data: orderId,
                      size: 250,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Route QR Code',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Scan this QR code with the BuzRyde Driver app to create a new ride.'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Text(
                      'This QR code will create a test ride from "TEST SOURCE" to "TEST DESTINATION" using default test values for zone information.'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class QRCodeWidget extends StatelessWidget {
  final String data;
  final double size;
  final int errorCorrectionLevel;

  const QRCodeWidget({
    super.key,
    required this.data,
    required this.size,
    this.errorCorrectionLevel = QrErrorCorrectLevel.L,
  });

  @override
  Widget build(BuildContext context) {
    // Create the QR code
    final qrCode = QrCode.fromData(
      data: data,
      errorCorrectLevel: errorCorrectionLevel,
    );
    
    // Create a QR image from the code
    final qrImage = QrImage(qrCode);

    return CustomPaint(
      size: Size(size, size),
      painter: _QRPainter(qrImage),
    );
  }
}

class _QRPainter extends CustomPainter {
  final QrImage qrImage;

  _QRPainter(this.qrImage);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black;

    final squareSize = size.width / qrImage.moduleCount;

    // Draw QR code by iterating through modules
    for (int row = 0; row < qrImage.moduleCount; row++) {
      for (int col = 0; col < qrImage.moduleCount; col++) {
        // Only draw black squares, white is the background
        if (qrImage.isDark(row, col)) {
          final left = col * squareSize;
          final top = row * squareSize;
          canvas.drawRect(
            Rect.fromLTWH(left, top, squareSize, squareSize),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 
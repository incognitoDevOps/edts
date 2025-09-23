import 'dart:async';
import 'package:driver/constant/constant.dart';
import 'package:driver/controller/home_controller.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/ui/instant_booking/instant_booking_controller.dart';
import 'package:driver/ui/instant_booking/qr_generator_screen.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

// *** DEMO CHANGES - RATES SET TO 50 FOR TESTING ***
// NOTE: FOR PRODUCTION - RESTORE ORIGINAL VALUES:
// - In _showManualEntryDialog() - Change the sample JSON offerRate/finalRate from '50' to '0.0'
// *** END DEMO CHANGES ***

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> with WidgetsBindingObserver {
  final InstantBookingController controller = Get.put(InstantBookingController());
  final HomeController homeController = Get.find<HomeController>();
  MobileScannerController? scannerController;
  bool hasScanned = false;
  bool isFlashOn = false;
  bool isFrontCamera = false;
  bool hasError = false;
  String errorMessage = '';
  Timer? cameraInitTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initScanner();
    
    // Set a timeout for camera initialization
    cameraInitTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && scannerController == null) {
        setState(() {
          hasError = true;
          errorMessage = 'Camera initialization timed out. Try manual entry.';
        });
      }
    });
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app is resumed, try to reinitialize the scanner if there was an error
    if (state == AppLifecycleState.resumed && hasError) {
      initScanner();
    }
  }

  void initScanner() {
    try {
      setState(() {
        hasError = false;
        errorMessage = '';
      });
      
      // Cancel any existing timer
      cameraInitTimer?.cancel();
      
      scannerController = MobileScannerController(
        // Adding controller settings makes initialization more reliable
        facing: CameraFacing.back,
        detectionSpeed: DetectionSpeed.normal,
        torchEnabled: false,
      );
      
      // Set a new timeout for camera initialization
      cameraInitTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          // Check if the camera is actually working
          if (scannerController?.isStarting ?? true) {
            setState(() {
              hasError = true;
              errorMessage = 'Camera failed to initialize. Please use manual entry.';
            });
          }
        }
      });
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = 'Failed to initialize camera: $e';
      });
      
      // Show manual entry dialog automatically after a delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _showManualEntryDialog();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cameraInitTimer?.cancel();
    scannerController?.dispose();
    super.dispose();
  }

  // Handle manual entry if camera fails
  void _showManualEntryDialog() {
    final TextEditingController textController = TextEditingController();
    final bool isDarkMode = Provider.of<DarkThemeProvider>(Get.context!, listen: false).getThem();
    
    Get.dialog(
      AlertDialog(
        title: Text('Enter QR Code Manually'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You can enter the QR code data manually:'.tr),
            const SizedBox(height: 16),
            
            // Tab options for order ID or route QR
            DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    labelColor: isDarkMode ? Colors.white : AppColors.primary,
                    tabs: [
                      Tab(text: 'Order ID'.tr),
                      Tab(text: 'Route QR'.tr),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 100,
                    child: TabBarView(
                      children: [
                        // Order ID Tab
                        TextField(
                          controller: textController,
                          decoration: InputDecoration(
                            hintText: 'Enter Order ID'.tr,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        
                        // Route QR Tab
                        Column(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                // Insert a sample route QR JSON
                                textController.text = '{"userId":"test_user","sourceLocationName":"TEST SOURCE: Current Location","destinationLocationName":"TEST DESTINATION: Demo Location","sourceLatitude":37.7749,"sourceLongitude":-122.4194,"destLatitude":37.3352,"destLongitude":-121.8811,"distance":"50.0","distanceType":"Km","offerRate":"50","finalRate":"50","paymentType":"cash","is_test_qr":true}'; // DEMO: Rates set to "50", change to "0.0" for production
                                // Show a snackbar to inform user
                                Get.snackbar(
                                  'Test Data',
                                  'Sample route QR data inserted',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.green,
                                  colorText: Colors.white,
                                  duration: const Duration(seconds: 2),
                                );
                              },
                              icon: const Icon(Icons.add_location),
                              label: Text('Insert Test Route Data'.tr),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Or paste a route QR JSON in the field'.tr,
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
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
            onPressed: () {
              final qrCode = textController.text.trim();
              if (qrCode.isNotEmpty) {
                Get.back();
                controller.processQRCode(qrCode);
              }
            },
            child: Text('Submit'.tr),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR Code'.tr),
        backgroundColor: themeChange.getThem() ? AppColors.darkGray : AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!hasError && scannerController != null) IconButton(
            color: Colors.white,
            icon: Icon(
              isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: isFlashOn ? Colors.yellow : Colors.white,
            ),
            onPressed: () {
              try {
                scannerController?.toggleTorch();
                setState(() {
                  isFlashOn = !isFlashOn;
                });
              } catch (e) {
                // Silently fail if torch can't be toggled
              }
            },
          ),
          if (!hasError && scannerController != null) IconButton(
            color: Colors.white,
            icon: Icon(
              isFrontCamera ? Icons.camera_front : Icons.camera_rear,
            ),
            onPressed: () {
              try {
                scannerController?.switchCamera();
                setState(() {
                  isFrontCamera = !isFrontCamera;
                });
              } catch (e) {
                // Silently fail if camera can't be switched
              }
            },
          ),
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.keyboard),
            onPressed: _showManualEntryDialog,
          ),
        ],
      ),
      body: Obx(() => controller.isLoading.value
          ? Constant.loader(context)
          : Stack(
              children: [
                hasError || scannerController == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 60,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Camera Error'.tr,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            errorMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton.icon(
                          onPressed: _showManualEntryDialog,
                          icon: const Icon(Icons.keyboard),
                          label: Text('Enter QR Code Manually'.tr),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () {
                            initScanner();
                          },
                          child: Text('Try Again'.tr),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            Get.to(() => const QRGeneratorScreen());
                          },
                          icon: const Icon(Icons.qr_code),
                          label: Text('Generate Test QR Code'.tr),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeChange.getThem() ? Colors.blueGrey : Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : scannerController != null ? MobileScanner(
                    controller: scannerController!,
                    onDetect: (capture) {
                      if (hasScanned) return;
                      
                      if (capture.barcodes.isNotEmpty) {
                        final String? qrCode = capture.barcodes.first.rawValue;
                        if (qrCode != null && qrCode.isNotEmpty) {
                          hasScanned = true;
                          controller.processQRCode(qrCode);
                        }
                      }
                    },
                    errorBuilder: (context, error, child) {
                      // Handle errors directly in the widget
                      setState(() {
                        hasError = true;
                        errorMessage = error.errorDetails?.message ?? 'Unknown error'.tr;
                      });
                      
                      // Show manual entry dialog automatically after a delay
                      Future.delayed(const Duration(seconds: 1), () {
                        if (mounted) {
                          _showManualEntryDialog();
                        }
                      });
                      
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 60,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Scanner Error'.tr,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                errorMessage,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 30),
                              ElevatedButton.icon(
                                onPressed: _showManualEntryDialog,
                                icon: const Icon(Icons.keyboard),
                                label: Text('Enter QR Code Manually'.tr),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ) : const SizedBox(),
                if (!hasError && scannerController != null) CustomPaint(
                  painter: ScannerOverlay(
                    overlayColour: themeChange.getThem() ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.5),
                  ),
                  child: Container(),
                ),
                // Positioned(
                //   bottom: 90,
                //   left: 0,
                //   right: 0,
                //   child: Center(
                //     child: Text(
                //       'Scan a QR code for instant booking'.tr,
                //       style: TextStyle(
                //         color: themeChange.getThem() ? Colors.white : Colors.black,
                //         fontSize: 16,
                //         fontWeight: FontWeight.bold,
                //       ),
                //     ),
                //   ),
                // ),
                // if (!hasError) Positioned(
                //   bottom: 30,
                //   left: 0,
                //   right: 0,
                //   child: Center(
                //     child: ElevatedButton.icon(
                //       onPressed: () {
                //         Get.to(() => const QRGeneratorScreen());
                //       },
                //       icon: const Icon(Icons.qr_code),
                //       label: Text('Generate Test QR Code'.tr),
                //       style: ElevatedButton.styleFrom(
                //         backgroundColor: themeChange.getThem() ? AppColors.darkGray : AppColors.primary,
                //         foregroundColor: Colors.white,
                //         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                //         shape: RoundedRectangleBorder(
                //           borderRadius: BorderRadius.circular(10),
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
                if (!hasError) Positioned(
                  top: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Scan the Customer QR code, To get the ride details.'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        // Text(
                        //   'If camera fails, you can use manual entry (keyboard icon).'.tr,
                        //   style: const TextStyle(
                        //     color: Colors.yellow,
                        //     fontSize: 12,
                        //     fontWeight: FontWeight.bold,
                        //   ),
                        //   textAlign: TextAlign.center,
                        // ),
                      ],
                    ),
                  ),
                ),
              ],
            )),
    );
  }
}

class ScannerOverlay extends CustomPainter {
  final Color overlayColour;

  ScannerOverlay({required this.overlayColour});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: size.width * 0.8,
            height: size.width * 0.8,
          ),
          topLeft: const Radius.circular(10),
          topRight: const Radius.circular(10),
          bottomLeft: const Radius.circular(10),
          bottomRight: const Radius.circular(10),
        ),
      );

    final backgroundPaint = Paint()
      ..color = overlayColour
      ..style = PaintingStyle.fill;

    final scannerPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Draw the semi-transparent overlay around the scanner
    final finalPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );
    canvas.drawPath(finalPath, backgroundPaint);

    // Draw the scanner border
    final scannerRect = RRect.fromRectAndCorners(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.8,
        height: size.width * 0.8,
      ),
      topLeft: const Radius.circular(10),
      topRight: const Radius.circular(10),
      bottomLeft: const Radius.circular(10),
      bottomRight: const Radius.circular(10),
    );
    canvas.drawRRect(scannerRect, scannerPaint);

    // Draw corner markers
    final cornerSize = 20.0;
    final cornerPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;

    // Top-left corner
    canvas.drawLine(
      Offset(scannerRect.left, scannerRect.top + cornerSize),
      Offset(scannerRect.left, scannerRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scannerRect.left, scannerRect.top),
      Offset(scannerRect.left + cornerSize, scannerRect.top),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(scannerRect.right - cornerSize, scannerRect.top),
      Offset(scannerRect.right, scannerRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scannerRect.right, scannerRect.top),
      Offset(scannerRect.right, scannerRect.top + cornerSize),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(scannerRect.left, scannerRect.bottom - cornerSize),
      Offset(scannerRect.left, scannerRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scannerRect.left, scannerRect.bottom),
      Offset(scannerRect.left + cornerSize, scannerRect.bottom),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(scannerRect.right - cornerSize, scannerRect.bottom),
      Offset(scannerRect.right, scannerRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scannerRect.right, scannerRect.bottom),
      Offset(scannerRect.right, scannerRect.bottom - cornerSize),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
} 
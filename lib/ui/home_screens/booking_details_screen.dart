import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controller/home_controller.dart';
import 'package:customer/model/contact_model.dart';
import 'package:customer/model/qr_route_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/text_field_them.dart';
import 'package:customer/ui/qr_code_screen.dart';
import 'package:customer/ui/home_screens/last_active_ride_screen.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class BookingDetailsScreen extends StatelessWidget {
  final HomeController homeController;

  const BookingDetailsScreen({Key? key, required this.homeController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeChange.getThem() ? AppColors.darkBackground : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Booking Details',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 0), // remove extra space for floating card
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Trip Summary Header
                    _buildTripSummaryHeader(context, themeChange),

                    // Removed Embedded Map Section for mobile friendliness
                    // _buildTripMapSection(context, themeChange),

                    // Main Content
                    const SizedBox(height: 12),
                    _buildOfferRateSection(context, themeChange),
                    const SizedBox(height: 12),
                    _buildPassengerSection(context, themeChange),
                    const SizedBox(height: 12),
                    _buildPaymentSection(context, themeChange),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Floating action card for buttons, always at the bottom
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _buildActionButtons(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripSummaryHeader(BuildContext context, DarkThemeProvider themeChange) {
    return Obx(() {
      if (homeController.sourceLocationLAtLng.value.latitude == null ||
          homeController.destinationLocationLAtLng.value.latitude == null ||
          homeController.amount.value.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.teal.withOpacity(0.05),
          border: Border(
            bottom: BorderSide(
              color: Colors.teal.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            // Selected vehicle info
            Row(
              children: [
                Container(
                  width: 50,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Icon(
                      Icons.directions_car,
                      color: Colors.grey[600],
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        homeController.selectedType.value.title ?? 'Selected Vehicle',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.teal,
                        ),
                      ),
                      Text(
                        '${homeController.selectedType.value.passengerCount ?? 1} seats',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  Constant.amountShow(amount: homeController.amount.value),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Trip details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTripDetailItem('Distance', 
                  '${double.parse(homeController.distance.value).toStringAsFixed(1)} ${Constant.distanceType}'),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.grey[300],
                ),
                _buildTripDetailItem('Duration', homeController.duration.value),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.grey[300],
                ),
                _buildTripDetailItem('Price', Constant.amountShow(amount: homeController.amount.value)),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTripDetailItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.teal,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildOfferRateSection(BuildContext context, DarkThemeProvider themeChange) {
    return Obx(() {
      if (homeController.selectedType.value.offerRate != true) {
        return const SizedBox.shrink();
      }
      
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.orange.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_offer, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Offer Your Rate',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.orange[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'This is a recommended price. You can offer your own rate.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.orange[700],
              ),
            ),
            const SizedBox(height: 16),
            TextFieldThem.buildTextFiledWithPrefixIcon(
              context,
              hintText: "Enter your offer rate".tr,
              controller: homeController.offerYourRateController.value,
              prefix: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  Constant.currencyModel!.symbol.toString(),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPassengerSection(BuildContext context, DarkThemeProvider themeChange) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person_outline, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Who\'s riding?',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => someOneTakingDialog(context, homeController),
                child: Text(
                  'Change',
                  style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeChange.getThem() ? Colors.grey[800] : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: themeChange.getThem() ? Colors.grey[700]! : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    homeController.selectedTakingRide.value.fullName == "Myself"
                        ? "Myself".tr
                        : homeController.selectedTakingRide.value.fullName.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(BuildContext context, DarkThemeProvider themeChange) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.payment, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Payment method',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() => InkWell(
            onTap: () => paymentMethodDialog(context, homeController),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeChange.getThem() ? Colors.grey[800] : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: themeChange.getThem() ? Colors.grey[700]! : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.credit_card,
                      color: Colors.green,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      homeController.selectedPaymentMethod.value.isNotEmpty 
                        ? homeController.selectedPaymentMethod.value 
                        : "Select Payment type".tr,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: homeController.selectedPaymentMethod.value.isNotEmpty
                          ? Theme.of(context).textTheme.bodyLarge?.color
                          : Colors.grey[600],
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _handleInstantBooking(context, homeController),
              icon: Icon(Icons.qr_code, color: Colors.white),
              label: Text(
                "Instant Booking".tr,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary.withOpacity(0.8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 0),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _handleBookRide(context, homeController),
              icon: Icon(Icons.directions_car, color: Colors.white),
              label: Text(
                "Book Ride".tr,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 2,
                shadowColor: AppColors.primary.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 0),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Instant booking handler
  void _handleInstantBooking(BuildContext context, HomeController controller) async {
    if (controller.selectedPaymentMethod.value.isEmpty) {
      ShowToastDialog.showToast("Please select Payment Method".tr);
    } else if (controller.sourceLocationController.value.text.isEmpty) {
      ShowToastDialog.showToast("Please select source location".tr);
    } else if (controller.destinationLocationController.value.text.isEmpty) {
      ShowToastDialog.showToast("Please select destination location".tr);
    } else if (double.parse(controller.distance.value) <= 2) {
      ShowToastDialog.showToast("Please select more than two ${Constant.distanceType} location".tr);
    } else if (controller.selectedType.value.offerRate == true && controller.offerYourRateController.value.text.isEmpty) {
      ShowToastDialog.showToast("Please Enter offer rate".tr);
    } else {
      final qrData = QrRouteModel(
        userId: FireStoreUtils.getCurrentUid(),
        sourceLocationName: controller.sourceLocationController.value.text,
        destinationLocationName: controller.destinationLocationController.value.text,
        sourceLatitude: controller.sourceLocationLAtLng.value.latitude!,
        sourceLongitude: controller.sourceLocationLAtLng.value.longitude!,
        destLatitude: controller.destinationLocationLAtLng.value.latitude!,
        destLongitude: controller.destinationLocationLAtLng.value.longitude!,
        distance: controller.distance.value,
        distanceType: Constant.distanceType,
        offerRate: controller.selectedType.value.offerRate == true 
            ? controller.offerYourRateController.value.text 
            : controller.amount.value,
        finalRate: controller.selectedType.value.offerRate == true 
            ? controller.offerYourRateController.value.text 
            : controller.amount.value,
        paymentType: controller.selectedPaymentMethod.value,
      );
      
      Get.to(() => QrCodeScreen(routeData: qrData));
    }
  }

  // Book ride handler
  void _handleBookRide(BuildContext context, HomeController controller) async {
    // Enhanced validation with wallet balance check
    if (controller.selectedPaymentMethod.value.isEmpty) {
      ShowToastDialog.showToast("Please select Payment Method".tr);
      return;
    }
    
    // Check wallet balance if wallet payment is selected
    if (controller.selectedPaymentMethod.value.toLowerCase() == "wallet") {
      final user = await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid());
      if (user != null) {
        double walletBalance = double.parse(user.walletAmount ?? "0.0");
        double payableAmount = double.parse(controller.amount.value);
        
        // Add tax calculation to payable amount
        if (Constant.taxList != null) {
          for (var tax in Constant.taxList!) {
            payableAmount += Constant().calculateTax(
              amount: controller.amount.value, 
              taxModel: tax
            );
          }
        }
        
        if (walletBalance < payableAmount) {
          ShowToastDialog.showToast("Insufficient balance. Please top up your wallet or choose another payment method.");
          return;
        }
      }
    }
    
    // Use the enhanced booking method from controller
    bool success = await controller.bookRide();
    
    if (success) {
      // Navigate to active ride screen
      Get.offAll(() => const LastActiveRideScreen());
    }
  }

  // --- Embedded Map Section ---
  // Widget _buildTripMapSection(BuildContext context, DarkThemeProvider themeChange) { ... } // REMOVED

  // Dark map style string for Google Maps
  static const String _darkMapStyle = '''
  [
    {"elementType": "geometry","stylers": [{"color": "#212121"}]},
    {"elementType": "labels.icon","stylers": [{"visibility": "off"}]},
    {"elementType": "labels.text.fill","stylers": [{"color": "#757575"}]},
    {"elementType": "labels.text.stroke","stylers": [{"color": "#212121"}]},
    {"featureType": "administrative","elementType": "geometry","stylers": [{"color": "#757575"}]},
    {"featureType": "poi","elementType": "labels.text.fill","stylers": [{"color": "#757575"}]},
    {"featureType": "poi.park","elementType": "geometry","stylers": [{"color": "#181818"}]},
    {"featureType": "poi.park","elementType": "labels.text.fill","stylers": [{"color": "#616161"}]},
    {"featureType": "poi.park","elementType": "labels.text.stroke","stylers": [{"color": "#1b1b1b"}]},
    {"featureType": "road","elementType": "geometry.fill","stylers": [{"color": "#2c2c2c"}]},
    {"featureType": "road","elementType": "labels.text.fill","stylers": [{"color": "#8a8a8a"}]},
    {"featureType": "road.arterial","elementType": "geometry","stylers": [{"color": "#373737"}]},
    {"featureType": "road.highway","elementType": "geometry","stylers": [{"color": "#3c3c3c"}]},
    {"featureType": "road.highway.controlled_access","elementType": "geometry","stylers": [{"color": "#4e4e4e"}]},
    {"featureType": "road.local","elementType": "labels.text.fill","stylers": [{"color": "#616161"}]},
    {"featureType": "transit","elementType": "labels.text.fill","stylers": [{"color": "#757575"}]},
    {"featureType": "water","elementType": "geometry","stylers": [{"color": "#000000"}]},
    {"featureType": "water","elementType": "labels.text.fill","stylers": [{"color": "#3d3d3d"}]}
  ]
  ''';

  // Dialog helper functions (moved from original file)
  someOneTakingDialog(BuildContext context, HomeController controller) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        final themeChange = Provider.of<DarkThemeProvider>(context);
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: Container(
            constraints: BoxConstraints(maxHeight: Get.height * 0.8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        "Who's riding?".tr,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Obx(() {
                    final contacts = controller.contactList;
                    final selected = controller.selectedTakingRide.value;
                    final myself = ContactModel(fullName: "Myself", contactNumber: "");
                    final items = <ContactModel>[myself, ...contacts];
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final contact = items[index];
                        return RadioListTile<ContactModel>(
                          value: contact,
                          groupValue: selected,
                          onChanged: (ContactModel? value) {
                            controller.selectedTakingRide.value = value!;
                            Get.back();
                          },
                          title: Text(
                            contact.fullName.toString(),
                            style: GoogleFonts.poppins(),
                          ),
                          subtitle: contact.fullName == "Myself"
                              ? null
                              : Text(contact.contactNumber.toString(), style: GoogleFonts.poppins()),
                          activeColor: AppColors.primary,
                        );
                      },
                    );
                  }),
                ),
                Obx(() {
                  if (controller.contactList.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          Text(
                            "No contacts found. You can add a contact to book for someone else.".tr,
                            style: GoogleFonts.poppins(fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () async {
                              // Check permission status
                              final status = await Permission.contacts.status;
                              if (status.isGranted) {
                                // Permission granted, open native contact picker
                                final contact = await FlutterContacts.openExternalPick();
                                if (contact != null) {
                                  final name = contact.displayName;
                                  String phone = '';
                                  if (contact.phones.isNotEmpty) {
                                    phone = contact.phones.first.number;
                                  }
                                  final newContact = ContactModel(fullName: name, contactNumber: phone);
                                  controller.contactList.add(newContact);
                                  controller.selectedTakingRide.value = newContact;
                                  Get.back();
                                }
                                return;
                              }
                              // If not granted, request permission
                              final granted = await FlutterContacts.requestPermission();
                              if (granted) {
                                final contact = await FlutterContacts.openExternalPick();
                                if (contact != null) {
                                  final name = contact.displayName;
                                  String phone = '';
                                  if (contact.phones.isNotEmpty) {
                                    phone = contact.phones.first.number;
                                  }
                                  final newContact = ContactModel(fullName: name, contactNumber: phone);
                                  controller.contactList.add(newContact);
                                  controller.selectedTakingRide.value = newContact;
                                  Get.back();
                                }
                                return;
                              }
                              // If permanently denied, show dialog
                              if (status.isPermanentlyDenied) {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text('Permission Required', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                    content: Text(
                                      'BuzRyde needs access to your contacts to add a rider. Please grant permission in settings.',
                                      style: GoogleFonts.poppins(),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(),
                                        child: Text('Cancel', style: GoogleFonts.poppins()),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          await openAppSettings();
                                          Navigator.of(ctx).pop();
                                        },
                                        child: Text('Open Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.person_add),
                            label: Text("Add Contact".tr),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  paymentMethodDialog(BuildContext context, HomeController controller) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        final themeChange = Provider.of<DarkThemeProvider>(context);
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Text(
                      "Select Payment Method".tr,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Obx(() {
                  if (controller.isPaymentLoading.value) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final pm = controller.paymentModel.value;
                  final List<Widget> options = [];
                  if (pm.cash != null && pm.cash!.enable == true) {
                    options.add(_buildPaymentOption(context, controller, pm.cash!.name ?? "Cash", Icons.money));
                  }
                  if (pm.wallet != null && pm.wallet!.enable == true) {
                    options.add(_buildPaymentOption(context, controller, pm.wallet!.name ?? "Wallet", Icons.account_balance_wallet));
                  }
                  if (pm.strip != null && pm.strip!.enable == true) {
                    options.add(_buildPaymentOption(context, controller, pm.strip!.name ?? "Stripe", Icons.credit_card));
                  }
                  if (pm.razorpay != null && pm.razorpay!.enable == true) {
                    options.add(_buildPaymentOption(context, controller, pm.razorpay!.name ?? "RazorPay", Icons.payment));
                  }
                  if (pm.payStack != null && pm.payStack!.enable == true) {
                    options.add(_buildPaymentOption(context, controller, pm.payStack!.name ?? "PayStack", Icons.payment));
                  }
                  if (pm.flutterWave != null && pm.flutterWave!.enable == true) {
                    options.add(_buildPaymentOption(context, controller, pm.flutterWave!.name ?? "FlutterWave", Icons.payment));
                  }
                  if (pm.paytm != null && pm.paytm!.enable == true) {
                    options.add(_buildPaymentOption(context, controller, pm.paytm!.name ?? "PayTM", Icons.payment));
                  }
                  if (pm.payfast != null && pm.payfast!.enable == true) {
                    options.add(_buildPaymentOption(context, controller, pm.payfast!.name ?? "PayFast", Icons.payment));
                  }
                  if (pm.mercadoPago != null && pm.mercadoPago!.enable == true) {
                    options.add(_buildPaymentOption(context, controller, pm.mercadoPago!.name ?? "MercadoPago", Icons.payment));
                  }
                  if (options.isEmpty) {
                    return Text(
                      "No payment methods available".tr,
                      style: GoogleFonts.poppins(),
                      textAlign: TextAlign.center,
                    );
                  }
                  return Column(children: options);
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentOption(BuildContext context, HomeController controller, String method, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        method,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
      ),
      onTap: () {
        controller.selectedPaymentMethod.value = method;
        Get.back();
      },
    );
  }

  showAlertDialog(BuildContext context) {
    // set up the button
    Widget okButton = TextButton(
      child: const Text("OK"),
      onPressed: () {
        Get.back();
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Warning"),
      content: const Text("You are not able book new ride please complete previous ride payment"),
      actions: [
        okButton,
      ],
    );
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}




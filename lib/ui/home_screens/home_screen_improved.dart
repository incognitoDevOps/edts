import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/controller/home_controller.dart';
import 'package:customer/model/airport_model.dart';
import 'package:customer/model/banner_model.dart';
import 'package:customer/model/contact_model.dart';
import 'package:customer/model/order/location_lat_lng.dart';
import 'package:customer/model/service_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/button_them.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/ui/home_screens/booking_details_screen.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/widget/google_place_picker_with_debounce.dart';
import 'package:customer/widget/place_picker_osm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class HomeScreenImproved extends StatelessWidget {
  const HomeScreenImproved({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<HomeController>(
        init: HomeController(),
        builder: (controller) {
          final showTripSummary = controller.sourceLocationLAtLng.value.latitude != null &&
              controller.destinationLocationLAtLng.value.latitude != null &&
              controller.amount.value.isNotEmpty;

          return Scaffold(
            backgroundColor: themeChange.getThem() ? AppColors.darkBackground : Colors.grey[50],
            body: SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      _buildTopHeader(context, controller, themeChange),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: showTripSummary ? 100 : 0), // Add space for floating summary/button
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Banner Section
                                _buildBannerSection(context, controller),
                                const SizedBox(height: 24),
                                // Trip Planning Card
                                _buildTripPlanningCard(context, controller, themeChange),
                                const SizedBox(height: 24),
                                // Vehicle Selection
                                _buildVehicleSelection(context, controller, themeChange),
                                const SizedBox(height: 120), // Add space for floating summary/button
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (showTripSummary)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 32), // Lower the floating card
                        child: Material(
                          color: Colors.transparent,
                          elevation: 8,
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.92,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                            decoration: BoxDecoration(
                              color: themeChange.getThem() ? AppColors.darkBackground : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildTripDetails(context, controller, themeChange),
                                const SizedBox(height: 16),
                                _buildContinueButton(context, controller),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        });
  }

  Widget _buildTopHeader(BuildContext context, HomeController controller, DarkThemeProvider themeChange) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF20C9A6), // Teal shade 1
            Color(0xFF009688), // Teal shade 2
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33009688),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // User profile picture next to greeting
                    GestureDetector(
                      onTap: () {
                        Get.toNamed('/myProfile');
                      },
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white,
                        backgroundImage: controller.userModel.value.profilePic != null && controller.userModel.value.profilePic!.isNotEmpty
                            ? NetworkImage(controller.userModel.value.profilePic!)
                            : null,
                        child: controller.userModel.value.profilePic == null || controller.userModel.value.profilePic!.isEmpty
                            ? Icon(Icons.person, color: Color(0xFF009688))
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello,${controller.userModel.value.fullName?.split(' ').first ?? ''}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Where are you going today?',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
         
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBannerSection(BuildContext context, HomeController controller) {
    if (controller.bannerList.isEmpty) return const SizedBox.shrink();
    
    return Container(
      height: 160,
      child: PageView.builder(
        controller: controller.pageController,
        itemCount: controller.bannerList.length,
        itemBuilder: (context, index) {
          BannerModel bannerModel = controller.bannerList[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: bannerModel.image.toString(),
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTripPlanningCard(BuildContext context, HomeController controller, DarkThemeProvider themeChange) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plan your trip',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 20),
          
          controller.sourceLocationLAtLng.value.latitude == null
              ? _buildLocationInputField(
                  context, 
                  controller, 
                  themeChange,
                  'From',
                  Icons.my_location,
                  controller.sourceLocationController.value,
                  true,
                )
              : _buildLocationInputsWithConnector(context, controller, themeChange),
        ],
      ),
    );
  }

  Widget _buildLocationInputField(
    BuildContext context,
    HomeController controller,
    DarkThemeProvider themeChange,
    String hint,
    IconData icon,
    TextEditingController textController,
    bool isSource,
  ) {
    return InkWell(
      onTap: () => _handleLocationSelection(context, controller, isSource),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeChange.getThem() ? Colors.grey[800] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: themeChange.getThem() ? Colors.grey[600]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.teal, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                textController.text.isEmpty ? hint.tr : textController.text,
                style: GoogleFonts.poppins(
                  color: textController.text.isEmpty 
                    ? Colors.grey[600]
                    : Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(Icons.search, color: Colors.grey[600], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInputsWithConnector(BuildContext context, HomeController controller, DarkThemeProvider themeChange) {
    return Column(
      children: [
        Row(
          children: [
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                Container(
                  width: 2,
                  height: 40,
                  color: Colors.grey[400],
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  Obx(() => _buildModernLocationField(
                    context,
                    controller.sourceLocationController.value.text,
                    'Pickup location',
                    () => _handleLocationSelection(context, controller, true),
                    themeChange,
                  )),
                  const SizedBox(height: 12),
                  Obx(() => _buildModernLocationField(
                    context,
                    controller.destinationLocationController.value.text,
                    'Where to?',
                    () => _handleLocationSelection(context, controller, false),
                    themeChange,
                  )),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernLocationField(
    BuildContext context,
    String text,
    String hint,
    VoidCallback onTap,
    DarkThemeProvider themeChange,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: themeChange.getThem() ? Colors.grey[800] : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: themeChange.getThem() ? Colors.grey[700]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text.isEmpty ? hint : text,
                style: GoogleFonts.poppins(
                  color: text.isEmpty 
                    ? Colors.grey[600]
                    : Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 14,
                  fontWeight: text.isEmpty ? FontWeight.w400 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.edit_outlined, color: Colors.grey[600], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleSelection(BuildContext context, HomeController controller, DarkThemeProvider themeChange) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double maxListHeight = screenHeight * 0.32; // Responsive max height for ride options
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Choose a ride',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            Obx(() => controller.serviceList.isNotEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${controller.serviceList.length} options',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.teal[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Obx(() {
          if (controller.serviceList.isEmpty) {
            return Container(
              height: 120,
              child: Center(
                child: controller.isLoading.value 
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                          strokeWidth: 2,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Loading ride options...',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.directions_car_outlined,
                          color: Colors.grey[400],
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No ride options available',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Please check your internet connection',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
              ),
            );
          }
          int itemCount = controller.serviceList.length;
          double itemHeight = 88.0;
          double calculatedHeight = itemHeight * (itemCount > 3 ? 3 : itemCount);
          double listHeight = itemCount > 3 ? maxListHeight : calculatedHeight;
          return Container(
            constraints: BoxConstraints(
              maxHeight: listHeight,
              minHeight: itemHeight,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: themeChange.getThem() ? Colors.grey[900] : Colors.grey[50],
            ),
            child: Scrollbar(
              thumbVisibility: itemCount > 3,
              thickness: 5,
              radius: const Radius.circular(4),
              child: ListView.separated(
                shrinkWrap: true,
                physics: itemCount > 3 
                  ? const BouncingScrollPhysics() 
                  : const NeverScrollableScrollPhysics(),
                itemCount: controller.serviceList.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  ServiceModel serviceModel = controller.serviceList[index];
                  return _buildVehicleCard(context, controller, themeChange, serviceModel);
                },
              ),
            ),
          );
        }),
        if (controller.serviceList.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.swipe_vertical,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  'Scroll to see more options',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildVehicleCard(BuildContext context, HomeController controller, DarkThemeProvider themeChange, ServiceModel serviceModel) {
  return Obx(() {
    bool isSelected = controller.selectedType.value == serviceModel;
    
    return GestureDetector(
      onTap: () {
        // Immediate selection update - no delays
        controller.selectedType.value = serviceModel;
        
        // Background calculation only if needed
        if (controller.sourceLocationLAtLng.value.latitude != null && 
            controller.destinationLocationLAtLng.value.latitude != null) {
          // Use a timer instead of Future.microtask for better performance
          Future.delayed(Duration.zero, () {
            if (Constant.selectedMapType == 'osm') {
              controller.calculateOsmAmount();
            } else {
              controller.calculateAmount();
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
            ? Colors.teal.withOpacity(0.15)
            : Theme.of(context).colorScheme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
              ? Colors.teal
              : themeChange.getThem() ? Colors.grey[700]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                ? Colors.teal.withOpacity(0.15)
                : Colors.black.withOpacity(0.03),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Vehicle Icon/Image
            Container(
              width: 60,
              height: 40,
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
                padding: const EdgeInsets.all(8.0),
                child: CachedNetworkImage(
                  imageUrl: serviceModel.image.toString(),
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Icon(
                    Icons.directions_car,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.directions_car,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Service Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Name (Bold)
                  Text(
                    serviceModel.title.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected 
                        ? Colors.teal
                        : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Passenger Capacity
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${serviceModel.passengerCount ?? 1} seats",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Selection Indicator
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                ? Container(
                    key: const ValueKey('selected'),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.teal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  )
                : const SizedBox(
                    key: ValueKey('unselected'),
                    width: 24,
                    height: 24,
                  ),
            ),
          ],
        ),
      ),
    ); // <-- Fix: Add proper closing parenthesis here
  });
}




  Widget _buildTripDetails(BuildContext context, HomeController controller, DarkThemeProvider themeChange) {
    return Obx(() {
      if (controller.sourceLocationLAtLng.value.latitude == null ||
          controller.destinationLocationLAtLng.value.latitude == null ||
          controller.amount.value.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.teal.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.teal.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Trip Summary',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTripDetailItem('Distance', 
                  '${double.parse(controller.distance.value).toStringAsFixed(1)} ${Constant.distanceType}'),
                _buildTripDetailItem('Duration', controller.duration.value),
                _buildTripDetailItem('Price', Constant.amountShow(amount: controller.amount.value)),
              ],
            ),
            if (controller.selectedType.value.offerRate == true) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_offer, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'This is a recommended price. You can offer your rate.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.orange[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
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

  Widget _buildContinueButton(BuildContext context, HomeController controller) {
    return Obx(() {
      bool canContinue = controller.sourceLocationLAtLng.value.latitude != null &&
                        controller.destinationLocationLAtLng.value.latitude != null &&
                        controller.selectedType.value.id != null &&
                        controller.amount.value.isNotEmpty;

      return Container(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: canContinue ? () => _handleContinueToBooking(context, controller) : null,
          icon: Icon(
            Icons.arrow_forward,
            color: canContinue ? Colors.white : Colors.grey[400],
          ),
          label: Text(
            "Continue to Booking".tr,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: canContinue ? Colors.white : Colors.grey[400],
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: canContinue ? AppColors.primary : Colors.grey[300],
            elevation: canContinue ? 2 : 0,
            shadowColor: canContinue ? AppColors.primary.withOpacity(0.3) : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    });
  }

  // Location selection handler
  void _handleLocationSelection(BuildContext context, HomeController controller, bool isSource) async {
    if (Constant.selectedMapType == 'osm') {
      Get.to(() => LocationPicker(isSource: isSource))?.then((value) {
        if (value != null) {
          if (isSource) {
            controller.sourceLocationController.value.text = value.displayName!;
            controller.sourceLocationLAtLng.value = LocationLatLng(latitude: value.lat, longitude: value.lon);
          } else {
            controller.destinationLocationController.value = TextEditingController(text: value.displayName!);
            controller.destinationLocationLAtLng.value = LocationLatLng(latitude: value.lat, longitude: value.lon);
          }
          controller.calculateOsmAmount();
        }
      });
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GooglePlacePickerWithDebounce(
            apiKey: Constant.mapAPIKey,
            initialPosition: const LatLng(-33.8567844, 151.213108),
            isSource: isSource,
            onPlacePicked: (result) {
              if (isSource) {
                controller.sourceLocationController.value.text = result.formattedAddress.toString();
                controller.sourceLocationLAtLng.value =
                    LocationLatLng(latitude: result.geometry!.location.lat, longitude: result.geometry!.location.lng);
              } else {
                controller.destinationLocationController.value.text = result.formattedAddress.toString();
                controller.destinationLocationLAtLng.value =
                    LocationLatLng(latitude: result.geometry!.location.lat, longitude: result.geometry!.location.lng);
              }
              controller.calculateAmount();
            },
          ),
        ),
      );
    }
  }

  // Continue to booking handler
  void _handleContinueToBooking(BuildContext context, HomeController controller) {
    Get.to(() => BookingDetailsScreen(homeController: controller));
  }



  // Dialog methods from original file
  someOneTakingDialog(BuildContext context, HomeController controller) {
    // Implementation from original file - keeping same functionality
    return showModalBottomSheet(
        backgroundColor: Theme.of(context).colorScheme.background,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(15), topLeft: Radius.circular(15))),
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        builder: (context1) {
          return FractionallySizedBox(
            heightFactor: 0.9,
            child: StatefulBuilder(builder: (context1, setState) {
              return Obx(
                () => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            InkWell(
                                onTap: () {
                                  Get.back();
                                },
                                child: const Icon(Icons.arrow_back_ios)),
                            const Expanded(
                                child: Center(
                                    child: Text(
                              "Someone Else Taking Ride?",
                            ))),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              const SizedBox(
                                height: 10,
                              ),
                              Obx(
                                () => InkWell(
                                  onTap: () {
                                    controller.selectedTakingRide.value = ContactModel(fullName: "Myself", contactNumber: "");
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                                      border: Border.all(
                                          color: controller.selectedTakingRide.value.fullName == "Myself"
                                              ? AppColors.primary
                                              : AppColors.textFieldBorder,
                                          width: 1),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      child: Row(
                                        children: [
                                          Container(
                                            height: 40,
                                            width: 80,
                                            decoration: const BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.all(Radius.circular(5))),
                                            child: const Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Icon(Icons.person, color: Colors.black),
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          Expanded(
                                            child: Text(
                                              "Myself".tr,
                                              style: GoogleFonts.poppins(),
                                            ),
                                          ),
                                          Radio(
                                            value: "Myself",
                                            groupValue: controller.selectedTakingRide.value.fullName.toString(),
                                            activeColor: AppColors.primary,
                                            onChanged: (value) {
                                              controller.selectedTakingRide.value = ContactModel(fullName: "Myself", contactNumber: "");
                                            },
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              ListView.builder(
                                itemCount: controller.contactList.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  ContactModel contactModel = controller.contactList[index];
                                  return Obx(
  () => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: InkWell(
      onTap: () {
        controller.selectedTakingRide.value = contactModel;
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          border: Border.all(
            color: controller.selectedTakingRide.value.fullName == contactModel.fullName
                ? AppColors.primary
                : AppColors.textFieldBorder,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 80,
                decoration: const BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    contactModel.fullName!.substring(0, 1).toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contactModel.fullName.toString(),
                      style: GoogleFonts.poppins(),
                    ),
                    Text(
                      contactModel.contactNumber.toString(),
                      style: GoogleFonts.poppins(),
                    ),
                  ],
                ),
              ),
              Radio(
                value: contactModel.fullName.toString(),
                groupValue: controller.selectedTakingRide.value.fullName.toString(),
                activeColor: AppColors.primary,
                onChanged: (value) {
                  controller.selectedTakingRide.value = contactModel;
                },
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);

                                },
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 30),
                                child: ButtonThem.buildButton(
                                  context,
                                  title: "Add New Contact".tr,
                                  btnWidthRatio: Responsive.width(100, context),
                                  onPress: () async {
                                    Get.back();
                                    if (await FlutterContacts.requestPermission()) {
                                      final contact = await FlutterContacts.openExternalPick();
                                      if (contact != null) {
                                        final fullContact = await FlutterContacts.getContact(contact.id);
                                        if (fullContact != null) {
                                          ContactModel contactModel = ContactModel();
                                          contactModel.fullName = fullContact.displayName;
                                          contactModel.contactNumber = fullContact.phones.isNotEmpty ? fullContact.phones.first.number : '';
                                          controller.contactList.add(contactModel);
                                          controller.setContact();
                                        }
                                      }
                                    } else {
                                      await Permission.contacts.request().then((value) async {
                                        if (value.isGranted) {
                                          final contact = await FlutterContacts.openExternalPick();
                                          if (contact != null) {
                                            final fullContact = await FlutterContacts.getContact(contact.id);
                                            if (fullContact != null) {
                                              ContactModel contactModel = ContactModel();
                                              contactModel.fullName = fullContact.displayName;
                                              contactModel.contactNumber = fullContact.phones.isNotEmpty ? fullContact.phones.first.number : '';
                                              controller.contactList.add(contactModel);
                                              controller.setContact();
                                            }
                                          }
                                        }
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 30),
                                child: ButtonThem.buildButton(
                                  context,
                                  title: "DONE".tr,
                                  btnWidthRatio: Responsive.width(100, context),
                                  onPress: () {
                                    Get.back();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          );
        });
  }

  paymentMethodDialog(BuildContext context, HomeController controller) {
  return showModalBottomSheet(
      backgroundColor: Theme.of(context).colorScheme.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(15), topLeft: Radius.circular(15))),
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      builder: (context1) {
        final themeChange = Provider.of<DarkThemeProvider>(context1);

        return FractionallySizedBox(
          heightFactor: 0.9,
          child: StatefulBuilder(builder: (context1, setState) {
            return Obx(
              () => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          InkWell(
                              onTap: () {
                                Get.back();
                              },
                              child: const Icon(Icons.arrow_back_ios)),
                          Expanded(
                              child: Center(
                                  child: Text(
                            "Select Payment Method".tr,
                          ))),
                        ],
                      ),
                    ),
                    controller.isPaymentLoading.value
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Cash Payment Method
                            Visibility(
                              visible: controller.paymentModel.value.cash != null && controller.paymentModel.value.cash!.enable == true,
                              child: Obx(
                                () => Column(
                                  children: [
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    InkWell(
                                      onTap: () {
                                        controller.selectedPaymentMethod.value = controller.paymentModel.value.cash!.name.toString();
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.all(Radius.circular(10)),
                                          border: Border.all(
                                              color: controller.selectedPaymentMethod.value == controller.paymentModel.value.cash!.name.toString()
                                                  ? themeChange.getThem()
                                                      ? AppColors.darkModePrimary
                                                      : AppColors.primary
                                                  : AppColors.textFieldBorder,
                                              width: 1),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                          child: Row(
                                            children: [
                                              Container(
                                                height: 40,
                                                width: 80,
                                                decoration: const BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.all(Radius.circular(5))),
                                                child: const Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: Icon(Icons.money, color: Colors.black),
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              Expanded(
                                                child: Text(
                                                  controller.paymentModel.value.cash!.name.toString(),
                                                  style: GoogleFonts.poppins(),
                                                ),
                                              ),
                                              Radio(
                                                value: controller.paymentModel.value.cash!.name.toString(),
                                                groupValue: controller.selectedPaymentMethod.value,
                                                activeColor: themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary,
                                                onChanged: (value) {
                                                  controller.selectedPaymentMethod.value = controller.paymentModel.value.cash!.name.toString();
                                                },
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Wallet Payment Method
                            Visibility(
                              visible: controller.paymentModel.value.wallet != null && controller.paymentModel.value.wallet!.enable == true,
                              child: Obx(
                                () => Column(
                                  children: [
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    InkWell(
                                      onTap: () {
                                        controller.selectedPaymentMethod.value = controller.paymentModel.value.wallet!.name.toString();
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.all(Radius.circular(10)),
                                          border: Border.all(
                                              color: controller.selectedPaymentMethod.value == controller.paymentModel.value.wallet!.name.toString()
                                                  ? themeChange.getThem()
                                                      ? AppColors.darkModePrimary
                                                      : AppColors.primary
                                                  : AppColors.textFieldBorder,
                                              width: 1),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                          child: Row(
                                            children: [
                                              Container(
                                                height: 40,
                                                width: 80,
                                                decoration: const BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.all(Radius.circular(5))),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(8.0),
                                                  child: Icon(Icons.account_balance_wallet, color: AppColors.primary),
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              Expanded(
                                                child: Text(
                                                  controller.paymentModel.value.wallet!.name.toString(),
                                                  style: GoogleFonts.poppins(),
                                                ),
                                              ),
                                              Radio(
                                                value: controller.paymentModel.value.wallet!.name.toString(),
                                                groupValue: controller.selectedPaymentMethod.value,
                                                activeColor: themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary,
                                                onChanged: (value) {
                                                  controller.selectedPaymentMethod.value = controller.paymentModel.value.wallet!.name.toString();
                                                },
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Stripe Payment Method
                            Visibility(
                              visible: controller.paymentModel.value.strip != null && controller.paymentModel.value.strip!.enable == true,
                              child: Obx(
                                () => Column(
                                  children: [
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    InkWell(
                                      onTap: () {
                                        controller.selectedPaymentMethod.value = controller.paymentModel.value.strip!.name.toString();
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.all(Radius.circular(10)),
                                          border: Border.all(
                                              color: controller.selectedPaymentMethod.value == controller.paymentModel.value.strip!.name.toString()
                                                  ? themeChange.getThem()
                                                      ? AppColors.darkModePrimary
                                                      : AppColors.primary
                                                  : AppColors.textFieldBorder,
                                              width: 1),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                          child: Row(
                                            children: [
                                              Container(
                                                height: 40,
                                                width: 80,
                                                decoration: const BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.all(Radius.circular(5))),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(8.0),
                                                  child: Image.asset('assets/images/stripe.png'),
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              Expanded(
                                                child: Text(
                                                  '${controller.paymentModel.value.strip!.name} - Credit Card / Debit',
                                                  style: GoogleFonts.poppins(),
                                                ),
                                              ),
                                              Radio(
                                                value: controller.paymentModel.value.strip!.name.toString(),
                                                groupValue: controller.selectedPaymentMethod.value,
                                                activeColor: themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary,
                                                onChanged: (value) {
                                                  controller.selectedPaymentMethod.value = controller.paymentModel.value.strip!.name.toString();
                                                },
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // RazorPay Payment Method
                            Visibility(
                              visible: controller.paymentModel.value.razorpay != null && controller.paymentModel.value.razorpay!.enable == true,
                              child: Obx(
                                () => Column(
                                  children: [
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    InkWell(
                                      onTap: () {
                                        controller.selectedPaymentMethod.value = controller.paymentModel.value.razorpay!.name.toString();
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.all(Radius.circular(10)),
                                          border: Border.all(
                                              color: controller.selectedPaymentMethod.value == controller.paymentModel.value.razorpay!.name.toString()
                                                  ? themeChange.getThem()
                                                      ? AppColors.darkModePrimary
                                                      : AppColors.primary
                                                  : AppColors.textFieldBorder,
                                              width: 1),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                          child: Row(
                                            children: [
                                              Container(
                                                height: 40,
                                                width: 80,
                                                decoration: const BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.all(Radius.circular(5))),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(8.0),
                                                  child: Image.asset('assets/images/razorpay.png'),
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              Expanded(
                                                child: Text(
                                                  controller.paymentModel.value.razorpay!.name.toString(),
                                                  style: GoogleFonts.poppins(),
                                                ),
                                              ),
                                              Radio(
                                                value: controller.paymentModel.value.razorpay!.name.toString(),
                                                groupValue: controller.selectedPaymentMethod.value,
                                                activeColor: themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary,
                                                onChanged: (value) {
                                                  controller.selectedPaymentMethod.value = controller.paymentModel.value.razorpay!.name.toString();
                                                },
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Add more payment methods here following the same pattern
                            // (PayStack, Flutterwave, PayTM, PayFast, MercadoPago, etc.)
                            const SizedBox(height: 10),
                            // Refresh payment methods button (in case of loading issues)
                            if (controller.paymentModel.value.cash == null && 
                                controller.paymentModel.value.wallet == null &&
                                controller.paymentModel.value.strip == null &&
                                controller.paymentModel.value.razorpay == null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              child: TextButton.icon(
                                onPressed: () async {
                                  await controller.refreshPaymentData();
                                },
                                icon: const Icon(Icons.refresh, color: AppColors.primary),
                                label: Text(
                                  "Refresh Payment Methods",
                                  style: GoogleFonts.poppins(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 30),
                              child: ButtonThem.buildButton(
                                context,
                                title: "DONE".tr,
                                btnWidthRatio: Responsive.width(100, context),
                                onPress: () {
                                  Get.back();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ));
            }),


          );
        });
  }

  showAlertDialog(BuildContext context) {
    // Alert dialog for pending payments
    Widget cancelButton = TextButton(
      child: Text("Cancel".tr),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
    Widget continueButton = TextButton(
      child: Text("Continue".tr),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Alert".tr),
      content: const Text("You are not able book new ride please complete previous ride payment"),
      actions: [
        cancelButton,
        continueButton,
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

  ariPortDialog(BuildContext context, HomeController controller, bool isSource) {
    // Airport selection dialog implementation
    return showModalBottomSheet(
        backgroundColor: Theme.of(context).colorScheme.background,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(15), topLeft: Radius.circular(15))),
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        builder: (context1) {
          return FractionallySizedBox(
            heightFactor: 0.5,
            child: StatefulBuilder(builder: (context1, setState) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          InkWell(
                              onTap: () {
                                Get.back();
                              },
                              child: const Icon(Icons.arrow_back_ios)),
                          const Expanded(
                              child: Center(
                                  child: Text(
                            "Select Airport",
                          ))),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                          itemCount: Constant.airaPortList!.length,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            AriPortModel ariPortModel = Constant.airaPortList![index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                              child: ListTile(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                tileColor: Theme.of(context).colorScheme.surface,
                                title: Text(ariPortModel.airportName ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                                subtitle: Text(ariPortModel.id ?? '', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                                onTap: () {
                                  if (isSource) {
                                    controller.sourceLocationController.value.text = ariPortModel.airportName ?? '';
                                    controller.sourceLocationLAtLng.value = LocationLatLng(
                                      latitude: double.tryParse(ariPortModel.airportLat ?? '') ?? 0.0,
                                      longitude: double.tryParse(ariPortModel.airportLng ?? '') ?? 0.0,
                                    );
                                  } else {
                                    controller.destinationLocationController.value.text = ariPortModel.airportName ?? '';
                                    controller.destinationLocationLAtLng.value = LocationLatLng(
                                      latitude: double.tryParse(ariPortModel.airportLat ?? '') ?? 0.0,
                                      longitude: double.tryParse(ariPortModel.airportLng ?? '') ?? 0.0,
                                    );
                                  }
                                  Navigator.of(context).pop();
                                },
                              ),
                            );
                          }),
                    ),
                  ],
                ),
              );
            }),
          );
        });
  }
}

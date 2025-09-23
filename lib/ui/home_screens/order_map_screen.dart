import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/send_notification.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/controller/order_map_controller.dart';
import 'package:driver/model/order/driverId_accept_reject.dart';
import 'package:driver/model/order_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/button_them.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/themes/text_field_them.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:driver/widget/location_view.dart';
import 'package:driver/widget/user_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class OrderMapScreen extends StatelessWidget {
  const OrderMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<OrderMapController>(
      init: OrderMapController(),
      builder: (controller) {
        // Handle loading state
        if (controller.isLoading.value) {
          return Scaffold(
            body: Constant.loader(context),
          );
        }

        // Handle error state
        if (controller.errorMessage.value.isNotEmpty) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.primary,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Get.back(),
              ),
            ),
            body: Center(
              child: Text("Error: ${controller.errorMessage.value}"),
            ),
          );
        }

        // Handle null order data
        if (controller.orderModel.value == null) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.primary,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Get.back(),
              ),
            ),
            body: const Center(
              child: Text("No order data available"),
            ),
          );
        }

        final order = controller.orderModel.value!;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Get.back(),
            ),
          ),
          body: Column(
            children: [
              Container(
                height: Responsive.width(10, context),
                width: Responsive.width(100, context),
                color: AppColors.primary,
              ),
              Expanded(
                child: Container(
                  transform: Matrix4.translationValues(0.0, -20.0, 0.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    child: Stack(
                      children: [
                        // Map Section
                        _buildMapSection(context, controller, themeChange),
                        
                        // Bottom Info Card
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: _buildOrderInfoCard(context, controller, themeChange, order),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapSection(BuildContext context, OrderMapController controller, DarkThemeProvider themeChange) {
    // Check if we have valid coordinates
    final hasValidCoordinates = controller.orderModel.value?.sourceLocationLAtLng != null &&
        controller.orderModel.value?.destinationLocationLAtLng != null;

    if (!hasValidCoordinates) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 50, color: Colors.grey),
            const SizedBox(height: 10),
            Text(
              "Missing location coordinates",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Text(
              "Unable to display map without valid coordinates",
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Constant.selectedMapType == 'osm'
        ? OSMFlutter(
            controller: controller.mapOsmController,
            osmOption: OSMOption(
              userTrackingOption: const UserTrackingOption(
                enableTracking: false,
                unFollowUser: false,
              ),
              zoomOption: const ZoomOption(
                initZoom: 12,
                minZoomLevel: 2,
                maxZoomLevel: 19,
                stepZoom: 1.0,
              ),
              roadConfiguration: RoadOption(
                roadColor: themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary,
              ),
            ),
            onMapIsReady: (active) async {
              if (active) {
                controller.getOSMPolyline(themeChange.getThem());
                ShowToastDialog.closeLoader();
              }
            },
          )
        : GoogleMap(
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // Reduced to prevent rendering issues
            mapType: MapType.normal,
            zoomControlsEnabled: false,
            polylines: Set<Polyline>.of(controller.polyLines.values),
            padding: const EdgeInsets.only(top: 22.0),
            markers: Set<Marker>.of(controller.markers.values),
            onMapCreated: (GoogleMapController mapController) {
              controller.mapController.complete(mapController);
              // Add a small delay before calculating the route
              Future.delayed(const Duration(milliseconds: 500), () {
                controller.getPolyline();
              });
            },
            initialCameraPosition: CameraPosition(
              target: LatLng(
                controller.orderModel.value?.sourceLocationLAtLng?.latitude ?? 
                  (Constant.currentLocation?.latitude ?? 45.521563),
                controller.orderModel.value?.sourceLocationLAtLng?.longitude ?? 
                  (Constant.currentLocation?.longitude ?? -122.677433),
              ),
              zoom: 15,
            ),
          );
  }

  Widget _buildOrderInfoCard(BuildContext context, OrderMapController controller, DarkThemeProvider themeChange, OrderModel order) {
    return Container(
      decoration: BoxDecoration(
        color: themeChange.getThem()
            ? AppColors.darkContainerBackground
            : AppColors.containerBackground,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(
          color: themeChange.getThem()
              ? AppColors.darkContainerBorder
              : AppColors.containerBorder,
          width: 0.5,
        ),
        boxShadow: themeChange.getThem()
            ? null
            : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserView(
              userId: order.userId ?? 'Unknown user',
              amount: order.offerRate ?? '0.0',
              distance: order.distance ?? '0.0',
              distanceType: order.distanceType ?? 'km',
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(),
            ),
            LocationView(
              sourceLocation: order.sourceLocationName ?? 'Unknown location',
              destinationLocation: order.destinationLocationName ?? 'Unknown destination',
            ),
            const SizedBox(height: 16),
            
            // Offer Rate Section
            if (order.service?.offerRate == true) ...[
              _buildOfferRateSection(context, controller),
              const SizedBox(height: 16),
            ],
            
            // Action Button
            _buildActionButton(context, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferRateSection(BuildContext context, OrderMapController controller) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Decrease Button
            InkWell(
              onTap: () {
                final currentAmount = double.tryParse(controller.newAmount.value) ?? 0.0;
                if (currentAmount >= 10) {
                  controller.newAmount.value = (currentAmount - 10).toStringAsFixed(2);
                  controller.enterOfferRateController.value.text = controller.newAmount.value;
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.textFieldBorder),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text("- 10"),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Amount Display
            Text(
              Constant.amountShow(amount: controller.newAmount.value),
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(width: 16),
            
            // Increase Button
            ElevatedButton(
              onPressed: () {
                final currentAmount = double.tryParse(controller.newAmount.value) ?? 0.0;
                controller.newAmount.value = (currentAmount + 10).toStringAsFixed(2);
                controller.enterOfferRateController.value.text = controller.newAmount.value;
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text("+ 10"),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Amount Input Field
        TextFieldThem.buildTextFiledWithPrefixIcon(
          context,
          hintText: "Enter Fare rate",
          controller: controller.enterOfferRateController.value,
          keyBoardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
          onChanged: (value) {
            controller.newAmount.value = value.isEmpty ? "0.0" : value;
          },
          prefix: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Text(Constant.currencyModel?.symbol ?? "\$"),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, OrderMapController controller) {
    return ButtonThem.buildButton(
      context,
      title: "Accept fare on ${Constant.amountShow(amount: controller.newAmount.value)}".tr,
      onPress: () async {
        final driverModel = controller.driverModel.value;
        if (driverModel == null) {
          ShowToastDialog.showToast("Driver information not available".tr);
          return;
        }

        final walletAmount = double.tryParse(driverModel.walletAmount.toString()) ?? 0.0;
        final minimumAmount = double.tryParse(Constant.minimumAmountToWithdrawal) ?? 0.0;

        if (walletAmount >= minimumAmount) {
          await _acceptRide(controller);
        } else {
          ShowToastDialog.showToast(
            "You need minimum ${Constant.amountShow(amount: Constant.minimumDepositToRideAccept.toString())} wallet amount to Accept Order".tr,
          );
        }
      },
    );
  }

  Future<void> _acceptRide(OrderMapController controller) async {
    ShowToastDialog.showLoader("Please wait".tr);
    
    try {
      final order = controller.orderModel.value!;
      final newAcceptedDriverId = order.acceptedDriverId?.toList() ?? [];
      newAcceptedDriverId.add(FireStoreUtils.getCurrentUid());
      
      order.acceptedDriverId = newAcceptedDriverId;
      await FireStoreUtils.setOrder(order);

      // Send notification to customer
      final customer = await FireStoreUtils.getCustomer(order.userId.toString());
      if (customer != null && customer.fcmToken != null) {
        await SendNotification.sendOneNotification(
          token: customer.fcmToken!,
          title: 'New Driver Bid'.tr,
          body: 'Driver has offered ${Constant.amountShow(amount: controller.newAmount.value)} for your journey.🚗'.tr,
          payload: {},
        );
      }

      final driverIdAcceptReject = DriverIdAcceptReject(
        driverId: FireStoreUtils.getCurrentUid(),
        acceptedRejectTime: Timestamp.now(),
        offerAmount: controller.newAmount.value,
      );

      await FireStoreUtils.acceptRide(order, driverIdAcceptReject);
      
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Ride Accepted".tr);
      Get.back(result: true);
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Error accepting ride: $e".tr);
    }
  }
}
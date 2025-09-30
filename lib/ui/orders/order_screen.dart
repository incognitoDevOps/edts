import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/ui/orders/complete_order_screen.dart';
import 'package:customer/ui/orders/live_tracking_screen.dart';
import 'package:customer/ui/orders/order_details_screen.dart';
import 'package:customer/ui/orders/payment_order_screen.dart';
import 'package:customer/ui/review/review_screen.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/widget/driver_view.dart';
import 'package:customer/widget/firebase_pagination/src/firestore_pagination.dart';
import 'package:customer/widget/firebase_pagination/src/models/view_type.dart';
import 'package:customer/widget/location_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Column(
          children: [
            Container(
              height: Responsive.width(8, context),
              width: Responsive.width(100, context),
              color: AppColors.primary,
            ),
            Container(
              color: AppColors.primary,
              child: TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w400),
                tabs: [
                  Tab(text: "Active Rides".tr),
                  Tab(text: "Completed Rides".tr),
                  Tab(text: "Canceled Rides".tr),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: TabBarView(
                  children: [
                    _buildOrderList(context, themeChange, [Constant.ridePlaced, Constant.rideActive, Constant.rideInProgress]),
                    _buildOrderList(context, themeChange, [Constant.rideComplete]),
                    _buildOrderList(context, themeChange, [Constant.rideCanceled]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(BuildContext context, DarkThemeProvider themeChange, List<String> statuses) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: FirestorePagination(
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, documentSnapshots, index) {
          final data = documentSnapshots[index].data() as Map<String, dynamic>?;
          if (data == null) {
            return _buildErrorCard("Invalid order data");
          }
          
          OrderModel orderModel = OrderModel.fromJson(data);
          return _buildOrderCard(context, themeChange, orderModel);
        },
        onEmpty: _buildEmptyState(statuses),
        query: FirebaseFirestore.instance
            .collection(CollectionName.orders)
            .where("userId", isEqualTo: FireStoreUtils.getCurrentUid())
            .where("status", whereIn: statuses)
            .orderBy('createdDate', descending: true),
        viewType: ViewType.list,
        initialLoader: Constant.loader(),
        isLive: true,
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, DarkThemeProvider themeChange, OrderModel orderModel) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: themeChange.getThem() ? AppColors.darkContainerBackground : AppColors.containerBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeChange.getThem() ? AppColors.darkContainerBorder : AppColors.containerBorder,
          width: 0.5,
        ),
        boxShadow: themeChange.getThem()
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "#${orderModel.id?.substring(0, 8).toUpperCase() ?? 'Unknown'}",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                _buildStatusChip(orderModel.status ?? "Unknown"),
              ],
            ),
            const SizedBox(height: 12),

            // Location information
            LocationView(
              sourceLocation: orderModel.sourceLocationName ?? "Unknown pickup",
              destinationLocation: orderModel.destinationLocationName ?? "Unknown destination",
            ),
            const SizedBox(height: 12),

            // Driver information with enhanced error handling
            if (orderModel.driverId != null && orderModel.driverId!.isNotEmpty)
              DriverView(
                driverId: orderModel.driverId!,
                amount: orderModel.finalRate ?? orderModel.offerRate ?? "0",
                showCallButton: orderModel.status == Constant.rideActive || orderModel.status == Constant.rideInProgress,
                showMessageButton: orderModel.status == Constant.rideActive || orderModel.status == Constant.rideInProgress,
              )
            else
              _buildLookingForDriverState(orderModel),

            const SizedBox(height: 16),

            // Action buttons
            _buildActionButtons(context, orderModel),
          ],
        ),
      ),
    );
  }

  Widget _buildLookingForDriverState(OrderModel orderModel) {
    // Check if we have accepted drivers
    if (orderModel.acceptedDriverId != null && orderModel.acceptedDriverId!.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.local_taxi, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Text(
              "${orderModel.acceptedDriverId!.length} driver(s) responded",
              style: GoogleFonts.poppins(
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_empty, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Text(
            "Looking for driver...",
            style: GoogleFonts.poppins(
              color: Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    
    switch (status) {
      case Constant.ridePlaced:
        backgroundColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        break;
      case Constant.rideActive:
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        break;
      case Constant.rideInProgress:
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        break;
      case Constant.rideComplete:
        backgroundColor = Colors.teal.withOpacity(0.1);
        textColor = Colors.teal;
        break;
      case Constant.rideCanceled:
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, OrderModel orderModel) {
    final status = orderModel.status ?? "";
    
    if (status == Constant.ridePlaced && orderModel.acceptedDriverId?.isNotEmpty == true) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Get.to(() => OrderDetailsScreen(orderModel: orderModel)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text("View bids".tr, style: GoogleFonts.poppins(color: Colors.white)),
        ),
      );
    }
    
    if (status == Constant.rideActive || status == Constant.rideInProgress) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Get.to(() => const LiveTrackingScreen(), arguments: {
                'type': 'orderModel',
                'orderModel': orderModel,
              }),
              icon: const Icon(Icons.map, size: 18),
              label: Text("Map view".tr, style: GoogleFonts.poppins(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      );
    }
    
    if (status == Constant.rideComplete) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (orderModel.paymentStatus == false) {
                  Get.to(() => const PaymentOrderScreen(), arguments: {"orderModel": orderModel});
                } else {
                  Get.to(() => const CompleteOrderScreen(), arguments: {"orderModel": orderModel});
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: orderModel.paymentStatus == false ? Colors.red : AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                orderModel.paymentStatus == false ? "Pay".tr : "View".tr,
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ),
          if (orderModel.paymentStatus == true) ...[
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Get.to(() => const ReviewScreen(), arguments: {
                  'type': 'orderModel',
                  'orderModel': orderModel,
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text("Review".tr, style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ),
          ],
        ],
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildEmptyState(List<String> statuses) {
    String message;
    IconData icon;
    
    if (statuses.contains(Constant.ridePlaced) || 
        statuses.contains(Constant.rideActive) || 
        statuses.contains(Constant.rideInProgress)) {
      message = "No active rides found".tr;
      icon = Icons.directions_car_outlined;
    } else if (statuses.contains(Constant.rideComplete)) {
      message = "No completed rides found".tr;
      icon = Icons.check_circle_outline;
    } else {
      message = "No canceled rides found".tr;
      icon = Icons.cancel_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your rides will appear here",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/ui/home_screens/last_active_ride_screen.dart';
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
            return _buildErrorCard("Invalid order data", showRetry: true);
          }
          
          try {
            OrderModel orderModel = OrderModel.fromJson(data);
            
            // 🔥 CRITICAL: Validate payment data integrity
            _validateOrderPaymentData(orderModel);
            
            return _buildOrderCard(context, themeChange, orderModel);
          } catch (e) {
            print("❌ [ORDER SCREEN] Error parsing order: $e");
            return _buildErrorCard("Failed to load order data", showRetry: true);
          }
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
        bottomLoader: Constant.loader(),
        limit: 10,
      ),
    );
  }

  /// 🔥 CRITICAL: Validate payment data for all orders
  void _validateOrderPaymentData(OrderModel orderModel) {
    if (orderModel.paymentType?.toLowerCase().contains("stripe") == true) {
      bool hasValidPayment = orderModel.hasValidPaymentData();
      
      if (!hasValidPayment) {
        print("🚨 [ORDER SCREEN] PAYMENT DATA VALIDATION FAILED:");
        print("   Order ID: ${orderModel.id}");
        print("   Payment Type: ${orderModel.paymentType}");
        print("   Payment Intent ID: ${orderModel.paymentIntentId}");
        print("   Pre-auth Amount: ${orderModel.preAuthAmount}");
        print("   Pre-auth Created: ${orderModel.preAuthCreatedAt}");
        print("   Status: ${orderModel.status}");
        
        // Attempt automatic recovery for active rides
        if (orderModel.status == Constant.ridePlaced || 
            orderModel.status == Constant.rideActive || 
            orderModel.status == Constant.rideInProgress) {
          print("🔄 [ORDER SCREEN] Attempting automatic payment data recovery...");
          _attemptPaymentDataRecovery(orderModel);
        }
      } else {
        print("✅ [ORDER SCREEN] Payment data validated for order: ${orderModel.id}");
      }
    }
  }

  /// Attempt to recover lost payment data
  void _attemptPaymentDataRecovery(OrderModel orderModel) {
    // This would be called when payment data is missing
    // In a real implementation, you might want to trigger a recovery process
    print("🔄 Recovery process triggered for order: ${orderModel.id}");
  }

  Widget _buildOrderCard(BuildContext context, DarkThemeProvider themeChange, OrderModel orderModel) {
    return InkWell(
      onTap: () {
        _handleOrderCardTap(orderModel);
      },
      child: Container(
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
              // Order header with ID and status
              _buildOrderHeader(orderModel),
              const SizedBox(height: 12),

              // Payment method and warning
              _buildPaymentInfo(orderModel),
              const SizedBox(height: 8),

              // Location information
              LocationView(
                sourceLocation: orderModel.sourceLocationName ?? "Unknown pickup",
                destinationLocation: orderModel.destinationLocationName ?? "Unknown destination",
              ),
              const SizedBox(height: 12),

              // Driver information or search status
              _buildDriverSection(orderModel),
              const SizedBox(height: 16),

              // Action buttons
              _buildActionButtons(context, orderModel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderHeader(OrderModel orderModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "#${orderModel.id?.substring(0, 8).toUpperCase() ?? 'Unknown'}",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              if (orderModel.createdDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  _formatOrderDate(orderModel.createdDate!),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
        _buildStatusChip(orderModel.status ?? "Unknown"),
      ],
    );
  }

  Widget _buildPaymentInfo(OrderModel orderModel) {
    bool showPaymentWarning = orderModel.paymentType?.toLowerCase().contains("stripe") == true && 
                             !orderModel.hasValidPaymentData();

    return Row(
      children: [
        // Payment method icon and text
        Icon(
          _getPaymentMethodIcon(orderModel.paymentType ?? "Unknown"),
          size: 16,
          color: showPaymentWarning ? Colors.orange : Colors.grey[600],
        ),
        const SizedBox(width: 6),
        Text(
          orderModel.paymentType ?? "Unknown",
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: showPaymentWarning ? Colors.orange : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        
        // Payment amount if available
        if (orderModel.finalRate != null || orderModel.offerRate != null) ...[
          const SizedBox(width: 8),
          Text(
            "• ${Constant.amountShow(amount: orderModel.finalRate ?? orderModel.offerRate ?? "0")}",
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        
        // Payment warning for Stripe
        if (showPaymentWarning) ...[
          const SizedBox(width: 6),
          Tooltip(
            message: "Payment authorization data may be incomplete",
            child: Icon(
              Icons.warning_amber_rounded,
              size: 14,
              color: Colors.orange,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDriverSection(OrderModel orderModel) {
    if (orderModel.driverId != null && orderModel.driverId!.isNotEmpty) {
      return DriverView(
        driverId: orderModel.driverId!,
        amount: orderModel.finalRate ?? orderModel.offerRate ?? "0",
        showCallButton: orderModel.status == Constant.rideActive || orderModel.status == Constant.rideInProgress,
        showMessageButton: orderModel.status == Constant.rideActive || orderModel.status == Constant.rideInProgress,
      );
    } else {
      return _buildLookingForDriverState(orderModel);
    }
  }

  Widget _buildLookingForDriverState(OrderModel orderModel) {
    // Check if we have accepted drivers waiting for response
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
            const Icon(Icons.local_taxi, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${orderModel.acceptedDriverId!.length} driver(s) responded",
                    style: GoogleFonts.poppins(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Tap to view and accept",
                    style: GoogleFonts.poppins(
                      color: Colors.blue,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.blue, size: 16),
          ],
        ),
      );
    }
    
    // Standard searching state
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_empty, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Looking for driver...",
                  style: GoogleFonts.poppins(
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "We're finding the best driver for you",
                  style: GoogleFonts.poppins(
                    color: Colors.orange,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    IconData? icon;
    
    switch (status) {
      case Constant.ridePlaced:
        backgroundColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        icon = Icons.search;
        break;
      case Constant.rideActive:
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        icon = Icons.directions_car;
        break;
      case Constant.rideInProgress:
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        icon = Icons.navigation;
        break;
      case Constant.rideComplete:
        backgroundColor = Colors.teal.withOpacity(0.1);
        textColor = Colors.teal;
        icon = Icons.check_circle;
        break;
      case Constant.rideCanceled:
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            status,
            style: GoogleFonts.poppins(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, OrderModel orderModel) {
    final status = orderModel.status ?? "";
    
    if (status == Constant.ridePlaced && orderModel.acceptedDriverId?.isNotEmpty == true) {
      return _buildBidsActionButton(orderModel);
    }
    
    if (status == Constant.rideActive || status == Constant.rideInProgress) {
      return _buildActiveRideActionButtons(orderModel);
    }
    
    if (status == Constant.rideComplete) {
      return _buildCompletedRideActionButtons(orderModel);
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildBidsActionButton(OrderModel orderModel) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _handleViewBids(orderModel),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_offer, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text("View Bids".tr, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveRideActionButtons(OrderModel orderModel) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _handleMapView(orderModel),
            icon: const Icon(Icons.map, size: 18),
            label: Text("Map View".tr, style: GoogleFonts.poppins(fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedRideActionButtons(OrderModel orderModel) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _handleCompletedRideAction(orderModel),
            style: ElevatedButton.styleFrom(
              backgroundColor: orderModel.paymentStatus == false ? Colors.red : AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  orderModel.paymentStatus == false ? Icons.payment : Icons.visibility,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  orderModel.paymentStatus == false ? "Pay Now".tr : "View Details".tr,
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        if (orderModel.paymentStatus == true) ...[
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _handleReviewAction(orderModel),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text("Review".tr, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ========== HANDLER METHODS ==========

  void _handleOrderCardTap(OrderModel orderModel) {
    print("🔄 [ORDER SCREEN] Order card tapped: ${orderModel.id}");
    orderModel.debugPaymentData();

    if (orderModel.status == Constant.ridePlaced ||
        orderModel.status == Constant.rideActive ||
        orderModel.status == Constant.rideInProgress) {
      Get.to(() => LastActiveRideScreen(initialOrder: orderModel));
    }
  }

  void _handleViewBids(OrderModel orderModel) {
    print("🔄 [ORDER SCREEN] Viewing bids for order: ${orderModel.id}");
    orderModel.debugPaymentData();
    Get.to(() => OrderDetailsScreen(orderModel: orderModel));
  }

  void _handleMapView(OrderModel orderModel) {
    print("🔄 [ORDER SCREEN] Opening map view for order: ${orderModel.id}");
    orderModel.debugPaymentData();
    Get.to(() => const LiveTrackingScreen(), arguments: {
      'type': 'orderModel',
      'orderModel': orderModel,
    });
  }

  Future<void> _handleCompletedRideAction(OrderModel orderModel) async {
    print("🔄 [ORDER SCREEN] Handling completed ride action: ${orderModel.id}");
    
    // 🔥 CRITICAL: Enhanced payment data validation for Stripe
    if (orderModel.paymentType?.toLowerCase().contains("stripe") == true) {
      if (!orderModel.hasValidPaymentData()) {
        print("🚨 [ORDER SCREEN] Payment data missing for completed Stripe order");
        
        // Attempt recovery before navigation
        ShowToastDialog.showLoader("Validating payment...");
        final recoveredOrder = await FireStoreUtils.getOrder(orderModel.id!);
        ShowToastDialog.closeLoader();
        
        if (recoveredOrder != null && recoveredOrder.hasValidPaymentData()) {
          print("✅ [ORDER SCREEN] Recovery successful, using recovered order");
          orderModel = recoveredOrder;
        } else {
          print("❌ [ORDER SCREEN] Recovery failed, showing error");
          ShowToastDialog.showToast(
            "Payment authorization data is missing. Please contact support with order ID: ${orderModel.id}",
            duration: const Duration(seconds: 5),
          );
          return;
        }
      }
    }

    if (orderModel.paymentStatus == false) {
      print("💳 [ORDER SCREEN] Navigating to payment screen");
      orderModel.debugPaymentData();
      Get.to(() => const PaymentOrderScreen(), arguments: {"orderModel": orderModel});
    } else {
      print("✅ [ORDER SCREEN] Navigating to complete order screen");
      orderModel.debugPaymentData();
      Get.to(() => const CompleteOrderScreen(), arguments: {"orderModel": orderModel});
    }
  }

  void _handleReviewAction(OrderModel orderModel) {
    print("🔄 [ORDER SCREEN] Navigating to review screen: ${orderModel.id}");
    orderModel.debugPaymentData();
    Get.to(() => const ReviewScreen(), arguments: {
      'type': 'orderModel',
      'orderModel': orderModel,
    });
  }

  // ========== HELPER METHODS ==========

  IconData _getPaymentMethodIcon(String paymentType) {
    switch (paymentType.toLowerCase()) {
      case 'stripe':
      case 'card':
        return Icons.credit_card;
      case 'cash':
        return Icons.money;
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'paypal':
        return Icons.payment;
      default:
        return Icons.payment;
    }
  }

  String _formatOrderDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildEmptyState(List<String> statuses) {
    String message;
    String subMessage;
    IconData icon;
    
    if (statuses.contains(Constant.ridePlaced) || 
        statuses.contains(Constant.rideActive) || 
        statuses.contains(Constant.rideInProgress)) {
      message = "No Active Rides".tr;
      subMessage = "Your active rides will appear here when you book a ride";
      icon = Icons.directions_car_outlined;
    } else if (statuses.contains(Constant.rideComplete)) {
      message = "No Completed Rides".tr;
      subMessage = "Completed rides will appear here after your trips";
      icon = Icons.check_circle_outline;
    } else {
      message = "No Canceled Rides".tr;
      subMessage = "Canceled rides will appear here if any";
      icon = Icons.cancel_outlined;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 20,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subMessage,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                // Refresh the page
                Get.forceAppUpdate();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: Text("Refresh", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message, {bool showRetry = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Data Error",
                  style: GoogleFonts.poppins(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.poppins(
              color: Colors.red[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (showRetry) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Get.forceAppUpdate();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: Text("Retry Loading", style: GoogleFonts.poppins()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
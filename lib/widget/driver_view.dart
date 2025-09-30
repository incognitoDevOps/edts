import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/model/driver_user_model.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/ui/chat_screen/chat_screen.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

class DriverView extends StatelessWidget {
  final String? driverId;
  final String? amount;
  final bool showCallButton;
  final bool showMessageButton;

  const DriverView({
    Key? key, 
    this.driverId, 
    this.amount,
    this.showCallButton = false,
    this.showMessageButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Validate driverId
    if (driverId == null || driverId!.isEmpty) {
      return _buildErrorState("Driver information not available");
    }

    return FutureBuilder<DriverUserModel?>(
        future: FireStoreUtils.getDriverWithRetry(driverId.toString(), maxRetries: 2),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return _buildLoadingState();
            case ConnectionState.done:
              if (snapshot.hasError) {
                return _buildErrorState("Error loading driver information");
              } else {
                if (snapshot.data == null) {
                  return _buildErrorState("Driver not found");
                }
                DriverUserModel driverModel = snapshot.data!;
                return _buildDriverInfo(context, driverModel);
              }
            default:
              return _buildLoadingState();
          }
        });
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Loading driver information...",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  "Please wait",
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverInfo(BuildContext context, DriverUserModel driverModel) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              child: CachedNetworkImage(
                height: 50,
                width: 50,
                imageUrl: driverModel.profilePic?.isNotEmpty == true 
                    ? driverModel.profilePic! 
                    : Constant.userPlaceHolder,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person, color: Colors.grey),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driverModel.fullName?.isNotEmpty == true 
                        ? driverModel.fullName! 
                        : "Driver",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 22,
                              color: AppColors.ratingColour,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              Constant.calculateReview(
                                reviewCount: driverModel.reviewsCount ?? "0.0",
                                reviewSum: driverModel.reviewsSum ?? "0.0",
                              ),
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      if (amount != null && amount!.isNotEmpty)
                        Text(
                          Constant.amountShow(amount: amount!),
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (showCallButton || showMessageButton) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (showCallButton)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _makePhoneCall(driverModel.phoneNumber),
                    icon: const Icon(Icons.phone, size: 18),
                    label: Text("Call", style: GoogleFonts.poppins(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              if (showCallButton && showMessageButton) const SizedBox(width: 8),
              if (showMessageButton)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openChat(context, driverModel),
                    icon: const Icon(Icons.message, size: 18),
                    label: Text("Message", style: GoogleFonts.poppins(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  void _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ShowToastDialog.showToast("Driver phone number not available");
      return;
    }
    
    try {
      await Constant.makePhoneCall(phoneNumber);
    } catch (e) {
      ShowToastDialog.showToast("Could not make phone call");
    }
  }

  void _openChat(BuildContext context, DriverUserModel driverModel) async {
    if (driverModel.id == null) {
      ShowToastDialog.showToast("Cannot open chat - driver information unavailable");
      return;
    }
    
    try {
      // Get current user information
      UserModel? currentUser = await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid());
      if (currentUser == null) {
        ShowToastDialog.showToast("Unable to load user information");
        return;
      }

      // Navigate to chat screen with proper parameters
      Get.to(() => ChatScreens(
        driverId: driverModel.id,
        customerId: currentUser.id,
        customerName: currentUser.fullName,
        customerProfileImage: currentUser.profilePic,
        driverName: driverModel.fullName,
        driverProfileImage: driverModel.profilePic,
        orderId: "general_chat", // You might want to pass actual order ID
        token: driverModel.fcmToken,
      ));
    } catch (e) {
      ShowToastDialog.showToast("Failed to open chat");
    }
  }
}

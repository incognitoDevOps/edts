import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/button_them.dart';
import 'package:driver/ui/auth_screen/login_screen.dart';
import 'package:driver/ui/dashboard_screen.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          // Just trigger UI rebuild, the stream will do the rest
          setState(() {});
        },
        child: StreamBuilder<DriverUserModel?>(
          stream: FireStoreUtils.fireStore
              .collection(CollectionName.driverUsers)
              .doc(FireStoreUtils.getCurrentUid())
              .snapshots()
              .map((snapshot) => snapshot.exists
                  ? DriverUserModel.fromJson(snapshot.data()!)
                  : null),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: Constant.loader(context));
            }

            if (!snapshot.hasData) {
              return const Center(child: Text("Error loading user data"));
            }

            DriverUserModel user = snapshot.data!;

            if (user.approvalStatus == 'approved') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Get.offAll(() => const DashBoardScreen());
              });
              return const SizedBox();
            }

            if (user.approvalStatus == 'rejected') {
              return _buildRejectedView(context, themeChange);
            }

            return _buildPendingView(context, themeChange, user);
          },
        ),
      ),
    );
  }

  Widget _buildPendingView(BuildContext context, DarkThemeProvider themeChange,
      DriverUserModel user) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animation or illustration
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: themeChange.getThem()
                      ? AppColors.darkModePrimary.withOpacity(0.1)
                      : AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.hourglass_empty,
                  size: 80,
                  color: themeChange.getThem()
                      ? AppColors.darkModePrimary
                      : AppColors.primary,
                ),
              ),

              const SizedBox(height: 40),

              Text(
                "Application Under Review".tr,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                "Thank you for submitting your information! Our team is reviewing your application and documents."
                    .tr,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              // Status cards
              _buildStatusCard(
                context,
                themeChange,
                "Personal Information".tr,
                user.profileCompleted == true,
                Icons.person,
              ),

              const SizedBox(height: 12),

              _buildStatusCard(
                context,
                themeChange,
                "Vehicle Information".tr,
                user.vehicleInformation != null,
                Icons.directions_car,
              ),

              const SizedBox(height: 12),

              _buildStatusCard(
                context,
                themeChange,
                "Documents".tr,
                user.documentsSubmitted == true,
                Icons.description,
              ),

              const SizedBox(height: 40),

              Text(
                "We'll notify you once your application is approved. This usually takes 24-48 hours."
                    .tr,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              // const SizedBox(height: 40),

              // Contact support button
              // ButtonThem.buildBorderButton(
              //   context,
              //   title: "Contact Support".tr,
              //   onPress: () {
              //     // Implement contact support
              //   },
              // ),

              const SizedBox(height: 16),

              // Sign out button
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Get.offAll(() => const LoginScreen());
                },
                child: Text(
                  "Sign Out".tr,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRejectedView(
      BuildContext context, DarkThemeProvider themeChange) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cancel,
                  size: 80,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                "Application Rejected".tr,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                "Unfortunately, your application has been rejected. Please contact our support team for more information."
                    .tr,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ButtonThem.buildButton(
                context,
                title: "Contact Support".tr,
                onPress: () {
                  // Implement contact support
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Get.offAll(() => const LoginScreen());
                },
                child: Text(
                  "Sign Out".tr,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, DarkThemeProvider themeChange,
      String title, bool isCompleted, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeChange.getThem()
            ? AppColors.darkContainerBackground
            : AppColors.containerBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? Colors.green
              : (themeChange.getThem()
                  ? AppColors.darkContainerBorder
                  : AppColors.containerBorder),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.green.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isCompleted ? Colors.green : Colors.grey[600],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCompleted ? Colors.green : Colors.grey[400],
            size: 24,
          ),
        ],
      ),
    );
  }
}

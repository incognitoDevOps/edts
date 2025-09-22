import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/model/driver_user_model.dart';
import 'package:customer/model/inbox_model.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/ui/chat_screen/chat_screen.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/widget/firebase_pagination/src/firestore_pagination.dart';
import 'package:customer/widget/firebase_pagination/src/models/view_type.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          SizedBox(
            height: Responsive.width(6, context),
            width: Responsive.width(100, context),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.background,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: FirestorePagination(
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, documentSnapshots, index) {
                    final data = documentSnapshots[index].data() as Map<String, dynamic>?;
                    InboxModel inboxModel = InboxModel.fromJson(data!);
                    return InkWell(
                      onTap: () async {
                        UserModel? customer = await FireStoreUtils.getUserProfile(inboxModel.customerId.toString());
                        DriverUserModel? driver = await FireStoreUtils.getDriver(inboxModel.driverId.toString());
                        Get.to(ChatScreens(
                          driverId: driver!.id,
                          customerId: customer!.id,
                          customerName: customer.fullName,
                          customerProfileImage: customer.profilePic,
                          driverName: driver.fullName,
                          driverProfileImage: driver.profilePic,
                          orderId: inboxModel.orderId,
                          token: driver.fcmToken,
                        ));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkContainerBackground : AppColors.containerBackground,
                            borderRadius: const BorderRadius.all(Radius.circular(10)),
                            border: Border.all(color: isDark ? AppColors.darkContainerBorder : AppColors.containerBorder, width: 0.5),
                            boxShadow: isDark
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                            child: Material(
                              color: Colors.transparent,
                              elevation: 2,
                              borderRadius: BorderRadius.circular(10),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                leading: Stack(
                                  children: [
                                    ClipOval(
                                      child: CachedNetworkImage(
                                        width: 48,
                                        height: 48,
                                        imageUrl: inboxModel.driverProfileImage.toString(),
                                        imageBuilder: (context, imageProvider) => Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            image: DecorationImage(
                                              image: imageProvider,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) => ClipOval(
                                          child: Image.network(
                                            Constant.userPlaceHolder,
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 2,
                                      right: 2,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: isDark ? colorScheme.background : Colors.white, width: 2),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        inboxModel.customerName.toString(),
                                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: isDark ? Colors.white : Colors.black),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      Constant.dateFormatTimestamp(inboxModel.createdAt),
                                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 2),
                                    Text(
                                      "Ride Id : #${inboxModel.orderId}".tr,
                                      style: GoogleFonts.poppins(fontSize: 13, color: isDark ? Colors.grey[300] : Colors.grey[700]),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      inboxModel.lastMessage ?? "Tap to view conversation",
                                      style: GoogleFonts.poppins(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ));
                  },
                  shrinkWrap: true,
                  onEmpty: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 60, color: isDark ? Colors.grey[700] : Colors.grey[400]),
                        SizedBox(height: 12),
                        Text(
                          "No Conversation found".tr,
                          style: GoogleFonts.poppins(fontSize: 18, color: isDark ? Colors.grey[300] : Colors.grey[600], fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Start a new chat to see it here!",
                          style: GoogleFonts.poppins(fontSize: 14, color: isDark ? Colors.grey[500] : Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  query: FirebaseFirestore.instance.collection('chat').where("customerId", isEqualTo: FireStoreUtils.getCurrentUid()).orderBy('createdAt', descending: true),
                  viewType: ViewType.list,
                  initialLoader: Constant.loader(),
                  isLive: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

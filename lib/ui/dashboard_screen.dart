import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/controller/dash_board_controller.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:customer/ui/chat_screen/inbox_screen.dart';

class DashBoardScreen extends StatelessWidget {
  const DashBoardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetX<DashBoardController>(
        init: DashBoardController(),
        builder: (controller) {
          return Scaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: Container(
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
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  title: controller.selectedDrawerIndex.value != 0 &&
                          controller.selectedDrawerIndex.value != 6
                      ? Text(
                          controller
                              .drawerItems[controller.selectedDrawerIndex.value]
                              .title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            letterSpacing: 0.5,
                          ),
                        )
                      : const Text(""),
                  leading: Builder(builder: (context) {
                    return InkWell(
                      onTap: () {
                        Scaffold.of(context).openDrawer();
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 10, right: 20, top: 20, bottom: 20),
                        child: SvgPicture.asset('assets/icons/ic_humber.svg',
                            color: Colors.white),
                      ),
                    );
                  }),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined,
                          color: Colors.white),
                      onPressed: () {
                        Get.to(() => const InboxScreen());
                      },
                      tooltip: 'Notifications',
                    ),
                    controller.selectedDrawerIndex.value == 0
                        ? FutureBuilder<UserModel?>(
                            future: FireStoreUtils.getUserProfile(
                                FireStoreUtils.getCurrentUid()),
                            builder: (context, snapshot) {
                              switch (snapshot.connectionState) {
                                case ConnectionState.waiting:
                                  return Constant.loader();
                                case ConnectionState.done:
                                  if (snapshot.hasError) {
                                    return Text(snapshot.error.toString(),
                                        style: const TextStyle(
                                            color: Colors.white));
                                  } else {
                                    UserModel driverModel = snapshot.data!;
                                    return InkWell(
                                      onTap: () {
                                        controller.selectedDrawerIndex(8);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: CircleAvatar(
                                          radius: 18,
                                          backgroundColor:
                                              Colors.white.withOpacity(0.15),
                                          backgroundImage:
                                              driverModel.profilePic != null &&
                                                      driverModel.profilePic!
                                                          .isNotEmpty
                                                  ? NetworkImage(
                                                      driverModel.profilePic!)
                                                  : null,
                                          child:
                                              driverModel.profilePic == null ||
                                                      driverModel
                                                          .profilePic!.isEmpty
                                                  ? Icon(Icons.person,
                                                      color: Colors.white)
                                                  : null,
                                        ),
                                      ),
                                    );
                                  }
                                default:
                                  return Text('Error'.tr,
                                      style:
                                          const TextStyle(color: Colors.white));
                              }
                            })
                        : Container(),
                  ],
                ),
              ),
            ),
            drawer: buildAppDrawer(context, controller),
            body: WillPopScope(
                onWillPop: controller.onWillPop,
                child: controller
                    .getDrawerItemWidget(controller.selectedDrawerIndex.value)),
          );
        });
  }

  buildAppDrawer(BuildContext context, DashBoardController controller) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();
    var drawerOptions = <Widget>[];
    for (var i = 0; i < controller.drawerItems.length; i++) {
      var d = controller.drawerItems[i];
      final isSelected = i == controller.selectedDrawerIndex.value;
      drawerOptions.add(
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 1, end: isSelected ? 1.04 : 1),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          builder: (context, scale, child) => Transform.scale(
            scale: scale,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  if (d.status.isEmpty) {
                    controller.onSelectItem(i);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.teal.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: isSelected
                        ? Border.all(
                            color: Colors.teal.withOpacity(0.18), width: 1.5)
                        : Border.all(color: Colors.transparent, width: 1.5),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.teal.withOpacity(0.10),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        d.icon,
                        width: 26,
                        color: isSelected
                            ? const Color(0xFF20C9A6)
                            : const Color(0xFF26A69A),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                d.title,
                                style: GoogleFonts.poppins(
                                  color: isSelected
                                      ? const Color(0xFF20C9A6)
                                      : (isDark ? Colors.white : Colors.black),
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (d.status.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  d.status,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Drawer(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              child: FutureBuilder<UserModel?>(
                  future: FireStoreUtils.getUserProfile(
                      FireStoreUtils.getCurrentUid()),
                  builder: (context, snapshot) {
                    switch (snapshot.connectionState) {
                      case ConnectionState.waiting:
                        return Constant.loader();
                      case ConnectionState.done:
                        if (snapshot.hasError) {
                          return Text(snapshot.error.toString());
                        } else {
                          UserModel driverModel = snapshot.data!;
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor:
                                    AppColors.primary.withOpacity(0.08),
                                backgroundImage:
                                    driverModel.profilePic != null &&
                                            driverModel.profilePic!.isNotEmpty
                                        ? NetworkImage(driverModel.profilePic!)
                                        : null,
                                child: driverModel.profilePic == null ||
                                        driverModel.profilePic!.isEmpty
                                    ? Icon(Icons.person,
                                        color: AppColors.primary, size: 32)
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              Text(driverModel.fullName ?? '',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16)),
                              Text(driverModel.email ?? '',
                                  style: GoogleFonts.poppins(
                                      color: Colors.grey, fontSize: 13)),
                            ],
                          );
                        }
                      default:
                        return Text('Error'.tr);
                    }
                  }),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                children: drawerOptions,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

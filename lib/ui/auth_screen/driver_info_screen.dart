import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/controller/driver_info_controller.dart';
import 'package:driver/model/document_model.dart';
import 'package:driver/model/service_model.dart';
import 'package:driver/model/vehicle_type_model.dart';
import 'package:driver/model/zone_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/button_them.dart';
import 'package:driver/themes/text_field_them.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DriverInfoScreen extends StatelessWidget {
  const DriverInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<DriverInfoController>(
      init: DriverInfoController(),
      builder: (controller) {
        if (controller.isLoading.value) {
          return Scaffold(
            body: Center(child: Constant.loader(context)),
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            backgroundColor: themeChange.getThem()
                ? AppColors.darkBackground
                : AppColors.primary,
            title: Text(
              "Driver Information".tr,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            automaticallyImplyLeading: false,
            elevation: 0,
            actions: [
              if (controller.currentStep.value > 0)
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white, size: 24),
                  onPressed: controller.previousStep,
                ),
              if (controller.currentStep.value < 2)
                IconButton(
                  icon:
                      Icon(Icons.arrow_forward, color: Colors.white, size: 24),
                  onPressed: () {
                    if (controller.currentStep.value == 0) {
                      if (controller.validatePersonalInfo()) {
                        controller.nextStep();
                      }
                    } else if (controller.currentStep.value == 1) {
                      if (controller.validateVehicleInfo()) {
                        controller.nextStep();
                      }
                    }
                  },
                ),
            ],
          ),
          body: Column(
            children: [
              // Progress indicator
              Container(
                padding: const EdgeInsets.all(20),
                color: themeChange.getThem()
                    ? AppColors.darkBackground
                    : AppColors.primary,
                child: Row(
                  children: [
                    for (int i = 0; i < 3; i++) ...[
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: i <= controller.currentStep.value
                                ? AppColors.darkModePrimary
                                : Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      if (i < 2) const SizedBox(width: 10),
                    ],
                  ],
                ),
              ),
              Obx(() {
                if (controller.provinceValidationErrors.isNotEmpty &&
                    controller.selectedProvince.value.isNotEmpty) {
                  return Container(
                    padding: EdgeInsets.all(16),
                    color: Colors.orange[100],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Please fix the following requirements:",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[900],
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 12),
                        ...controller.provinceValidationErrors
                            .map((error) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    "• $error",
                                    style: GoogleFonts.poppins(
                                      color: Colors.orange[900],
                                      fontSize: 14,
                                    ),
                                  ),
                                )),
                      ],
                    ),
                  );
                }
                return SizedBox.shrink();
              }),

              // Step content
              Expanded(
                child: PageView(
                  controller: controller.pageController,
                  onPageChanged: (index) =>
                      controller.currentStep.value = index,
                  children: [
                    _buildPersonalInfoStep(context, controller, themeChange),
                    _buildVehicleInfoStep(context, controller, themeChange),
                    _buildDocumentsStep(context, controller, themeChange),
                  ],
                ),
              ),

              // Navigation buttons
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    if (controller.currentStep.value > 0)
                      Expanded(
                        child: ButtonThem.buildBorderButton(
                          context,
                          title: "Previous".tr,
                          onPress: controller.previousStep,
                        ),
                      ),
                    if (controller.currentStep.value > 0)
                      const SizedBox(width: 16),
                    Expanded(
                      child: Obx(() => ButtonThem.buildButton(
                            context,
                            title: controller.currentStep.value == 2
                                ? "Submit for Approval".tr
                                : "Next".tr,
                            onPress: controller.isSubmitting.value
                                ? () {}
                                : () {
                                    if (controller.currentStep.value == 0) {
                                      if (controller.validatePersonalInfo()) {
                                        controller.nextStep();
                                      }
                                    } else if (controller.currentStep.value ==
                                        1) {
                                      if (controller.validateVehicleInfo()) {
                                        controller.nextStep();
                                      }
                                    } else {
                                      controller.submitDriverInfo();
                                    }
                                  },
                          )),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPersonalInfoStep(BuildContext context,
      DriverInfoController controller, DarkThemeProvider themeChange) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Personal Information".tr,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tell us about yourself".tr,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 30),

          // Profile Image
          Center(
            child: GestureDetector(
              onTap: controller.pickProfileImage,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: themeChange.getThem()
                      ? AppColors.darkGray
                      : AppColors.lightGray,
                  border: Border.all(
                    color: themeChange.getThem()
                        ? AppColors.darkModePrimary
                        : AppColors.primary,
                    width: 3,
                  ),
                ),
                child: Obx(() {
                  if (controller.profileImagePath.value.isNotEmpty) {
                    return ClipOval(
                      child:
                          controller.profileImagePath.value.startsWith('http')
                              ? CachedNetworkImage(
                                  imageUrl: controller.profileImagePath.value,
                                  fit: BoxFit.cover,
                                  width: 120,
                                  height: 120,
                                )
                              : Image.file(
                                  File(controller.profileImagePath.value),
                                  fit: BoxFit.cover,
                                  width: 120,
                                  height: 120,
                                ),
                    );
                  }
                  return Icon(
                    Icons.add_a_photo,
                    size: 40,
                    color:
                        themeChange.getThem() ? Colors.white : Colors.grey[600],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Province Selection
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Province/Territory".tr,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: themeChange.getThem() ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: themeChange.getThem()
                        ? AppColors.darkTextField
                        : AppColors.textField,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  style: GoogleFonts.poppins(fontSize: 16),
                  value: controller.selectedProvince.value.isEmpty
                      ? null
                      : controller.selectedProvince.value,
                  items: controller.canadianProvinces.map((province) {
                    return DropdownMenuItem(
                      value: province['code'],
                      child: Text(
                        province['name']!,
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectedProvince.value = value;
                      controller.validateProvinceRequirements();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Age validation display
          Obx(() {
            if (controller.selectedProvince.value.isNotEmpty) {
              final minAge =
                  controller.selectedProvince.value == 'PE' ? 25 : 21;
              final driverAge = controller.calculateAge();
              return Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: driverAge != null && driverAge >= minAge
                      ? Colors.green[50]
                      : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: driverAge != null && driverAge >= minAge
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Age Requirement:".tr,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      "Minimum: $minAge years • Your age: ${driverAge ?? 'Not set'} years",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: driverAge != null && driverAge >= minAge
                            ? Colors.green[800]
                            : Colors.red[800],
                      ),
                    ),
                  ],
                ),
              );
            }
            return SizedBox.shrink();
          }),
          const SizedBox(height: 20),

          // Date of Birth
          _buildLabeledTextField(
            context: context,
            label: 'Date of Birth'.tr,
            controller: controller.dateOfBirthController.value,
            enabled: false,
            onTap: controller.selectDateOfBirth,
            themeChange: themeChange,
          ),
          const SizedBox(height: 20),

          // Full Name
          _buildLabeledTextField(
            context: context,
            label: 'Full Name'.tr,
            controller: controller.fullNameController.value,
            themeChange: themeChange,
          ),
          const SizedBox(height: 20),

          // License Class Dropdown
          Obx(() {
            if (controller.selectedProvince.value.isEmpty) {
              return Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Select a province first to see license requirements".tr,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              );
            }

            final availableClasses = controller.getAvailableLicenseClasses();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "License Class".tr,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: themeChange.getThem() ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: themeChange.getThem()
                          ? AppColors.darkTextField
                          : AppColors.textField,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    style: GoogleFonts.poppins(fontSize: 16),
                    value: controller.selectedLicenseClass.value.isEmpty &&
                            availableClasses.isNotEmpty
                        ? availableClasses.first
                        : controller.selectedLicenseClass.value,
                    items: availableClasses.map((licenseClass) {
                      return DropdownMenuItem(
                        value: licenseClass,
                        child: Text(
                          licenseClass,
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        controller.selectedLicenseClass.value = value;
                        controller.licenseClassController.value.text = value;
                        controller.validateProvinceRequirements();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Required for ${controller.canadianProvinces.firstWhere((p) => p['code'] == controller.selectedProvince.value, orElse: () => {
                        'name': 'this province'
                      })['name']}",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 20),

          // Email
          _buildLabeledTextField(
            context: context,
            label: 'Email Address'.tr,
            controller: controller.emailController.value,
            keyboardType: TextInputType.emailAddress,
            themeChange: themeChange,
          ),
          const SizedBox(height: 20),

          // Phone Number
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Phone Number".tr,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: themeChange.getThem() ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                child: TextFormField(
                  controller: controller.phoneController.value,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.poppins(
                    color: themeChange.getThem() ? Colors.white : Colors.black,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: themeChange.getThem()
                        ? AppColors.darkTextField
                        : AppColors.textField,
                    prefixIcon: CountryCodePicker(
                      onChanged: (value) {
                        controller.countryCode.value =
                            value.dialCode.toString();
                      },
                      initialSelection: controller.countryCode.value,
                      favorite: const ['+1', '+91', '+44'],
                      dialogBackgroundColor: themeChange.getThem()
                          ? AppColors.darkBackground
                          : AppColors.background,
                      textStyle: GoogleFonts.poppins(fontSize: 16),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        
        
        ],
      ),
    );
  }

  Widget _buildVehicleInfoStep(BuildContext context,
      DriverInfoController controller, DarkThemeProvider themeChange) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Vehicle Information".tr,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tell us about your vehicle".tr,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 30),

          // Vehicle age validation
          Obx(() {
            if (controller.selectedProvince.value.isNotEmpty) {
              final maxAge = controller.getMaxVehicleAge();
              return Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Vehicle Age Requirement:".tr,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      "Maximum: $maxAge years old".tr,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              );
            }
            return SizedBox.shrink();
          }),
          const SizedBox(height: 20),

          // Vehicle Manufacturing Year
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vehicle Manufacturing Year'.tr,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: themeChange.getThem() ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                child: DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: themeChange.getThem()
                        ? AppColors.darkTextField
                        : AppColors.textField,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  style: GoogleFonts.poppins(fontSize: 16),
                  value: controller.selectedVehicleYear.value == 0
                      ? DateTime.now().year
                      : controller.selectedVehicleYear.value,
                  items: controller.vehicleYearOptions.map((year) {
                    return DropdownMenuItem(
                      value: year,
                      child: Text(
                        year.toString(),
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectedVehicleYear.value = value;
                      controller.validateProvinceRequirements();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            if (controller.selectedProvince.value.isNotEmpty &&
                controller.selectedVehicleYear.value != 0) {
              final currentYear = DateTime.now().year;
              final vehicleAge =
                  currentYear - controller.selectedVehicleYear.value;
              final maxAge = controller.getMaxVehicleAge();

              return Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      vehicleAge <= maxAge ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: vehicleAge <= maxAge ? Colors.green : Colors.red,
                  ),
                ),
                child: Text(
                  "Vehicle age: $vehicleAge years (Max: $maxAge years)".tr,
                  style: GoogleFonts.poppins(
                    color: vehicleAge <= maxAge
                        ? Colors.green[800]
                        : Colors.red[800],
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              );
            }
            return SizedBox.shrink();
          }),
          const SizedBox(height: 20),

          // Vehicle Make
          _buildLabeledTextField(
            context: context,
            label: 'Vehicle Make'.tr,
            controller: controller.vehicleMakeController.value,
            themeChange: themeChange,
          ),
          const SizedBox(height: 20),

          // Vehicle Model
          _buildLabeledTextField(
            context: context,
            label: 'Vehicle Model'.tr,
            controller: controller.vehicleModelController.value,
            themeChange: themeChange,
          ),
          const SizedBox(height: 20),

          // Service Type
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Service Type".tr,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: themeChange.getThem() ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Obx(() => Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: controller.isServiceSelected.value
                          ? Colors.green[50]
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: controller.isServiceSelected.value
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                    child: Text(
                      controller.isServiceSelected.value
                          ? "Selected: ${controller.selectedService.value.title}"
                          : "Select Service Type".tr,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: controller.isServiceSelected.value
                            ? Colors.green[800]
                            : Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Obx(() {
              if (controller.serviceList.isEmpty) {
                return Center(child: CircularProgressIndicator());
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: controller.serviceList.length,
                itemBuilder: (context, index) {
                  ServiceModel service = controller.serviceList[index];
                  bool isSelected =
                      controller.selectedService.value.id == service.id;

                  return GestureDetector(
                    onTap: () => controller.selectService(service),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (themeChange.getThem()
                                ? AppColors.darkModePrimary
                                : AppColors.primary)
                            : (themeChange.getThem()
                                ? AppColors.darkGray
                                : AppColors.lightGray),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? (themeChange.getThem()
                                  ? AppColors.darkModePrimary
                                  : AppColors.primary)
                              : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CachedNetworkImage(
                            imageUrl: service.image ?? '',
                            width: 40,
                            height: 40,
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.directions_car),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            service.title ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? (themeChange.getThem()
                                      ? Colors.black
                                      : Colors.white)
                                  : (themeChange.getThem()
                                      ? Colors.white
                                      : Colors.black),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 20),

          // Vehicle Number
          _buildLabeledTextField(
            context: context,
            label: 'Vehicle Number'.tr,
            controller: controller.vehicleNumberController.value,
            themeChange: themeChange,
          ),
          const SizedBox(height: 20),

          // Vehicle Type
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Vehicle Type".tr,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: themeChange.getThem() ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                child: DropdownButtonFormField<VehicleTypeModel>(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: themeChange.getThem()
                        ? AppColors.darkTextField
                        : AppColors.textField,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  style: GoogleFonts.poppins(fontSize: 16),
                  value: controller.selectedVehicleType.value.id == null
                      ? null
                      : controller.selectedVehicleType.value,
                  items: controller.vehicleTypeList.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(
                        type.name ?? '',
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectedVehicleType.value = value;
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Vehicle Color
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Vehicle Color".tr,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: themeChange.getThem() ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: themeChange.getThem()
                        ? AppColors.darkTextField
                        : AppColors.textField,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  style: GoogleFonts.poppins(fontSize: 16),
                  value: controller.selectedVehicleColor.value.isEmpty
                      ? null
                      : controller.selectedVehicleColor.value,
                  items: controller.vehicleColors.map((color) {
                    return DropdownMenuItem(
                      value: color,
                      child: Text(
                        color,
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectedVehicleColor.value = value;
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Number of Seats
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Number of Seats".tr,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: themeChange.getThem() ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: themeChange.getThem()
                        ? AppColors.darkTextField
                        : AppColors.textField,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  style: GoogleFonts.poppins(fontSize: 16),
                  value: controller.seatsController.value.text.isEmpty
                      ? null
                      : controller.seatsController.value.text,
                  items: controller.seatOptions.map((seats) {
                    return DropdownMenuItem(
                      value: seats,
                      child: Text(
                        seats,
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.seatsController.value.text = value;
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Registration Date
          _buildLabeledTextField(
            context: context,
            label: 'Registration Date'.tr,
            controller: controller.registrationDateController.value,
            enabled: false,
            onTap: controller.selectRegistrationDate,
            themeChange: themeChange,
          ),
          const SizedBox(height: 20),

          // Zone Selection
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Operating Zones".tr,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: themeChange.getThem() ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () =>
                    _showZoneSelectionDialog(context, controller, themeChange),
                child: Obx(() => Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: themeChange.getThem()
                            ? AppColors.darkTextField
                            : AppColors.textField,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: controller.isZoneSelected.value
                              ? Colors.green
                              : AppColors.primary,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: controller.isZoneSelected.value
                                ? Colors.green
                                : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Operating Zones".tr,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  controller.isZoneSelected.value
                                      ? controller.selectedZoneNames.value
                                      : "Select zones".tr,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: controller.isZoneSelected.value
                                        ? (themeChange.getThem()
                                            ? Colors.white
                                            : Colors.black)
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (controller.selectedZoneIds.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                controller.selectedZoneIds.length.toString(),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_drop_down,
                            color: controller.isZoneSelected.value
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ],
                      ),
                    )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsStep(BuildContext context,
      DriverInfoController controller, DarkThemeProvider themeChange) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Required Documents".tr,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Upload your documents for verification".tr,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 30),

          // Documents list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.documentList.length,
            itemBuilder: (context, index) {
              DocumentModel document = controller.documentList[index];
              return _buildDocumentCard(
                  context, controller, document, themeChange);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(
      BuildContext context,
      DriverInfoController controller,
      DocumentModel document,
      DarkThemeProvider themeChange) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeChange.getThem()
            ? AppColors.darkContainerBackground
            : AppColors.containerBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeChange.getThem()
              ? AppColors.darkContainerBorder
              : AppColors.containerBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            document.title ?? '',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Document Number
          _buildLabeledTextField(
            context: context,
            label: '${document.title} Number'.tr,
            controller: controller.documentNumberControllers[document.id]!,
            themeChange: themeChange,
          ),
          const SizedBox(height: 16),

          // Expiry Date (if required)
          if (document.expireAt == true) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Expiry Date".tr,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: themeChange.getThem() ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () =>
                      controller.selectDocumentExpiryDate(document.id!),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themeChange.getThem()
                          ? AppColors.darkTextField
                          : AppColors.textField,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Obx(() {
                            DateTime? date =
                                controller.documentExpiryDates[document.id];
                            return Text(
                              date != null
                                  ? DateFormat("dd-MM-yyyy").format(date)
                                  : "Select Expiry Date".tr,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: date != null
                                    ? (themeChange.getThem()
                                        ? Colors.white
                                        : Colors.black)
                                    : Colors.grey[600],
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Front Side Image (if required)
          if (document.frontSide == true) ...[
            Text(
              "Front Side".tr,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            _buildImageUploadBox(
              context,
              controller,
              '${document.id}_front',
              "Upload front side".tr,
              themeChange,
            ),
            const SizedBox(height: 16),
          ],

          // Back Side Image (if required)
          if (document.backSide == true) ...[
            Text(
              "Back Side".tr,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            _buildImageUploadBox(
              context,
              controller,
              '${document.id}_back',
              "Upload back side".tr,
              themeChange,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageUploadBox(
      BuildContext context,
      DriverInfoController controller,
      String key,
      String hint,
      DarkThemeProvider themeChange) {
    return Obx(() {
      String? imagePath = controller.documentImages[key];

      return GestureDetector(
        onTap: () {
          String documentId = key.split('_')[0];
          bool isFrontSide = key.endsWith('_front');
          controller.pickDocumentImage(documentId, isFrontSide: isFrontSide);
        },
        child: Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: imagePath != null ? Colors.green : AppColors.primary,
              width: 2,
            ),
          ),
          child: imagePath != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: imagePath.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: imagePath,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 120,
                            )
                          : Image.file(
                              File(imagePath),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 120,
                            ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                )
              : DottedBorder(
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(12),
                  dashPattern: const [8, 4],
                  color: AppColors.primary,
                  strokeWidth: 2,
                  child: SizedBox(
                    width: double.infinity,
                    height: 120,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 40,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hint,
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      );
    });
  }

  // Helper method to create labeled text fields with better visibility
  Widget _buildLabeledTextField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text,
    required DarkThemeProvider themeChange,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: themeChange.getThem() ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary,
              width: 2,
            ),
          ),
          child: onTap != null
              ? GestureDetector(
                  onTap: onTap,
                  child: TextFieldThem.buildTextFiledWithSuffixIcon(
                    context,
                    hintText: label,
                    controller: controller,
                    enable: enabled,
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                )
              : TextFieldThem.buildTextFiled(
                  context,
                  hintText: label,
                  controller: controller,
                  keyBoardType: keyboardType,
                ),
        ),
      ],
    );
  }

  void _showZoneSelectionDialog(BuildContext context,
      DriverInfoController controller, DarkThemeProvider themeChange) {
    Get.dialog(
      Obx(() => AlertDialog(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select Operating Zones".tr,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${controller.selectedZoneIds.length} zones selected",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  // Select All / Deselect All buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            for (var zone in controller.zoneList) {
                              if (!controller.selectedZoneIds
                                  .contains(zone.id)) {
                                controller.toggleZoneSelection(zone.id!);
                              }
                            }
                          },
                          child: Text(
                            "Select All".tr,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            controller.selectedZoneIds.clear();
                            controller.isZoneSelected.value = false;
                            controller.updateSelectedZones();
                          },
                          child: Text(
                            "Deselect All".tr,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(),
                  Expanded(
                    child: controller.zoneList.isEmpty
                        ? Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            itemCount: controller.zoneList.length,
                            itemBuilder: (context, index) {
                              ZoneModel zone = controller.zoneList[index];
                              bool isSelected =
                                  controller.selectedZoneIds.contains(zone.id);

                              return CheckboxListTile(
                                value: isSelected,
                                onChanged: (bool? value) {
                                  controller.toggleZoneSelection(zone.id!);
                                },
                                title: Text(
                                  zone.name ?? '',
                                  style: GoogleFonts.poppins(fontSize: 16),
                                ),
                                secondary: Icon(
                                  Icons.location_on,
                                  color:
                                      isSelected ? Colors.green : Colors.grey,
                                ),
                                activeColor: AppColors.primary,
                                checkColor: Colors.white,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  "Cancel".tr,
                  style: GoogleFonts.poppins(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  "Apply".tr,
                  style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          )),
    );
  }
}

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/model/document_model.dart';
import 'package:driver/model/driver_document_model.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/service_model.dart';
import 'package:driver/model/vehicle_type_model.dart';
import 'package:driver/model/zone_model.dart';
import 'package:driver/ui/auth_screen/pending_approval_screen.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class DriverInfoController extends GetxController {
  // Page Controller for smooth tab navigation
  final PageController pageController = PageController(initialPage: 0);

  // Personal Information
  Rx<TextEditingController> fullNameController = TextEditingController().obs;
  Rx<TextEditingController> emailController = TextEditingController().obs;
  Rx<TextEditingController> phoneController = TextEditingController().obs;
  RxString countryCode = "+1".obs;
  RxString profileImagePath = "".obs;

  // Vehicle Information
  Rx<TextEditingController> vehicleNumberController =
      TextEditingController().obs;
  Rx<TextEditingController> registrationDateController =
      TextEditingController().obs;
  Rx<TextEditingController> seatsController = TextEditingController().obs;
  Rx<DateTime?> selectedRegistrationDate = Rx<DateTime?>(null);

  // Dropdowns
  Rx<ServiceModel> selectedService = ServiceModel().obs;
  Rx<VehicleTypeModel> selectedVehicleType = VehicleTypeModel().obs;
  RxString selectedVehicleColor = "".obs;
  RxList<String> selectedZoneIds = <String>[].obs;
  RxString selectedZoneNames = "".obs;

  // Document Upload
  RxMap<String, String> documentImages = <String, String>{}.obs;
  RxMap<String, TextEditingController> documentNumberControllers =
      <String, TextEditingController>{}.obs;
  RxMap<String, DateTime?> documentExpiryDates = <String, DateTime?>{}.obs;

  // Data Lists
  RxList<ServiceModel> serviceList = <ServiceModel>[].obs;
  RxList<VehicleTypeModel> vehicleTypeList = <VehicleTypeModel>[].obs;
  RxList<ZoneModel> zoneList = <ZoneModel>[].obs;
  RxList<DocumentModel> documentList = <DocumentModel>[].obs;

  // UI State
  RxInt currentStep = 0.obs;
  RxBool isLoading = true.obs;
  RxBool isSubmitting = false.obs;
  RxBool isServiceSelected = false.obs; // Track service selection state
  RxBool isZoneSelected = false.obs; // Track zone selection state

  // Constants
  final List<String> vehicleColors = [
    'Red',
    'Black',
    'White',
    'Blue',
    'Green',
    'Orange',
    'Silver',
    'Gray',
    'Yellow',
    'Brown',
    'Gold',
    'Beige',
    'Purple'
  ];

  final List<String> seatOptions = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15'
  ];

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  @override
  void onClose() {
    // Dispose all controllers to prevent memory leaks
    pageController.dispose();
    fullNameController.value.dispose();
    emailController.value.dispose();
    phoneController.value.dispose();
    vehicleNumberController.value.dispose();
    registrationDateController.value.dispose();
    seatsController.value.dispose();

    // Dispose document number controllers
    for (var controller in documentNumberControllers.values) {
      controller.dispose();
    }

    super.onClose();
  }

  Future<void> loadInitialData() async {
    try {
      isLoading.value = true;

      // Load current user data if exists
      DriverUserModel? currentUser =
          await FireStoreUtils.getDriverProfile(FireStoreUtils.getCurrentUid());
      if (currentUser != null) {
        _populateUserData(currentUser);
      }

      // Load all required dropdown data in parallel
      await Future.wait([
        _loadServices(),
        _loadVehicleTypes(),
        _loadZones(),
        _loadDocuments(),
      ]);

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      ShowToastDialog.showToast("Failed to load data: ${e.toString()}");
    }
  }

  void _populateUserData(DriverUserModel user) {
    fullNameController.value.text = user.fullName ?? '';
    emailController.value.text = user.email ?? '';
    phoneController.value.text = user.phoneNumber ?? '';
    countryCode.value = user.countryCode ?? '+1';
    profileImagePath.value = user.profilePic ?? '';

    if (user.vehicleInformation != null) {
      vehicleNumberController.value.text =
          user.vehicleInformation!.vehicleNumber ?? '';
      selectedVehicleColor.value = user.vehicleInformation!.vehicleColor ?? '';
      seatsController.value.text = user.vehicleInformation!.seats ?? '2';

      if (user.vehicleInformation!.registrationDate != null) {
        selectedRegistrationDate.value =
            user.vehicleInformation!.registrationDate!.toDate();
        registrationDateController.value.text =
            DateFormat("dd-MM-yyyy").format(selectedRegistrationDate.value!);
      }
    }

    if (user.zoneIds != null) {
      selectedZoneIds.value = List<String>.from(user.zoneIds!);
      isZoneSelected.value = selectedZoneIds.isNotEmpty;
      updateSelectedZones();
    }
  }

  Future<void> _loadServices() async {
    List<ServiceModel> services = await FireStoreUtils.getService();
    serviceList.value = services;
    if (services.isNotEmpty && selectedService.value.id == null) {
      selectedService.value = services.first;
      isServiceSelected.value = true;
    }
  }

  Future<void> _loadVehicleTypes() async {
    List<VehicleTypeModel>? types = await FireStoreUtils.getVehicleType();
    if (types != null) {
      vehicleTypeList.value = types;
      if (types.isNotEmpty && selectedVehicleType.value.id == null) {
        selectedVehicleType.value = types.first;
      }
    }
  }

  Future<void> _loadZones() async {
    List<ZoneModel>? zones = await FireStoreUtils.getZone();
    if (zones != null) {
      zoneList.value = zones;
    }
  }

  Future<void> _loadDocuments() async {
    List<DocumentModel> documents = await FireStoreUtils.getDocumentList();
    documentList.value = documents;

    // Initialize controllers and expiry dates for each document
    for (DocumentModel doc in documents) {
      documentNumberControllers[doc.id!] = TextEditingController();
      documentExpiryDates[doc.id!] = null;
    }
  }

  // Image picker methods
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> pickProfileImage() async {
    try {
      XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        profileImagePath.value = image.path;
        update(); // Force UI update
      }
    } on PlatformException catch (e) {
      ShowToastDialog.showToast("Failed to pick image: ${e.message}");
    }
  }

  Future<void> pickDocumentImage(String documentId,
      {bool isFrontSide = true}) async {
    try {
      XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        String key = isFrontSide ? '${documentId}_front' : '${documentId}_back';
        documentImages[key] = image.path;
        update(); // Force UI update
      }
    } on PlatformException catch (e) {
      ShowToastDialog.showToast("Failed to pick image: ${e.message}");
    }
  }

  // Date selection methods
  Future<void> selectRegistrationDate() async {
    DateTime? picked = await Constant.selectDate(Get.context!);
    if (picked != null) {
      selectedRegistrationDate.value = picked;
      registrationDateController.value.text =
          DateFormat("dd-MM-yyyy").format(picked);
      update(); // Force UI update
    }
  }

  Future<void> selectDocumentExpiryDate(String documentId) async {
    DateTime? picked = await Constant.selectFetureDate(Get.context!);
    if (picked != null) {
      documentExpiryDates[documentId] = picked;
      update(); // Force UI update
    }
  }

  // Service type selection with immediate feedback
  void selectService(ServiceModel service) {
    selectedService.value = service;
    isServiceSelected.value = true;
    update(); // Force UI update immediately
  }

  // Zone selection with immediate feedback
  void toggleZoneSelection(String zoneId) {
    if (selectedZoneIds.contains(zoneId)) {
      selectedZoneIds.remove(zoneId);
    } else {
      selectedZoneIds.add(zoneId);
    }
    isZoneSelected.value = selectedZoneIds.isNotEmpty;
    updateSelectedZones();
    update(); // Force UI update immediately
  }

  void updateSelectedZones() {
    List<String> zoneNames = [];
    for (String zoneId in selectedZoneIds) {
      ZoneModel? zone = zoneList.firstWhereOrNull((z) => z.id == zoneId);
      if (zone != null) {
        zoneNames.add(zone.name!);
      }
    }
    selectedZoneNames.value = zoneNames.join(', ');
  }

  // Step navigation with animation
  void nextStep() {
    if (currentStep.value < 2) {
      currentStep.value++;
      pageController.animateToPage(
        currentStep.value,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
      pageController.animateToPage(
        currentStep.value,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step <= 2) {
      currentStep.value = step;
      pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Validation methods
  bool validatePersonalInfo() {
    if (fullNameController.value.text.trim().isEmpty) {
      ShowToastDialog.showToast("Please enter your full name");
      return false;
    }
    if (emailController.value.text.trim().isEmpty) {
      ShowToastDialog.showToast("Please enter your email");
      return false;
    }
    if (!Constant.validateEmail(emailController.value.text.trim())!) {
      ShowToastDialog.showToast("Please enter a valid email");
      return false;
    }
    if (phoneController.value.text.trim().isEmpty) {
      ShowToastDialog.showToast("Please enter your phone number");
      return false;
    }
    if (profileImagePath.value.isEmpty) {
      ShowToastDialog.showToast("Please upload your profile photo");
      return false;
    }
    return true;
  }

  bool validateVehicleInfo() {
    if (!isServiceSelected.value) {
      ShowToastDialog.showToast("Please select a service type");
      return false;
    }
    if (vehicleNumberController.value.text.trim().isEmpty) {
      ShowToastDialog.showToast("Please enter vehicle number");
      return false;
    }
    if (selectedVehicleType.value.id == null) {
      ShowToastDialog.showToast("Please select vehicle type");
      return false;
    }
    if (selectedVehicleColor.value.isEmpty) {
      ShowToastDialog.showToast("Please select vehicle color");
      return false;
    }
    if (seatsController.value.text.trim().isEmpty) {
      ShowToastDialog.showToast("Please select number of seats");
      return false;
    }
    if (selectedRegistrationDate.value == null) {
      ShowToastDialog.showToast("Please select registration date");
      return false;
    }
    if (!isZoneSelected.value) {
      ShowToastDialog.showToast("Please select at least one zone");
      return false;
    }
    return true;
  }

  bool validateDocuments() {
    for (DocumentModel doc in documentList) {
      if (documentNumberControllers[doc.id]?.text.trim().isEmpty ?? true) {
        ShowToastDialog.showToast("Please enter ${doc.title} number");
        return false;
      }

      if (doc.frontSide == true &&
          !documentImages.containsKey('${doc.id}_front')) {
        ShowToastDialog.showToast("Please upload front side of ${doc.title}");
        return false;
      }

      if (doc.backSide == true &&
          !documentImages.containsKey('${doc.id}_back')) {
        ShowToastDialog.showToast("Please upload back side of ${doc.title}");
        return false;
      }

      if (doc.expireAt == true && documentExpiryDates[doc.id] == null) {
        ShowToastDialog.showToast("Please select expiry date for ${doc.title}");
        return false;
      }
    }
    return true;
  }

  // Main submission method
  Future<void> submitDriverInfo() async {
    // Validate all steps first
    if (!validatePersonalInfo()) {
      goToStep(0);
      return;
    }
    if (!validateVehicleInfo()) {
      goToStep(1);
      return;
    }
    if (!validateDocuments()) {
      goToStep(2);
      return;
    }

    try {
      isSubmitting.value = true;
      ShowToastDialog.showLoader("Submitting information...");

      // Start all upload operations in parallel
      final uploadFutures = <Future>[];

      // Profile image upload (if needed)
      String profileImageUrl = profileImagePath.value;
      if (profileImagePath.value.isNotEmpty &&
          !Constant.hasValidUrl(profileImagePath.value)) {
        uploadFutures.add(Constant.uploadUserImageToFireStorage(
                File(profileImagePath.value),
                "profileImages/${FireStoreUtils.getCurrentUid()}",
                "profile_${DateTime.now().millisecondsSinceEpoch}.jpg")
            .then((url) => profileImageUrl = url));
      }

      // Document images upload
      final uploadedDocumentUrls = <String, String>{};
      for (final entry in documentImages.entries) {
        if (!Constant.hasValidUrl(entry.value)) {
          uploadFutures.add(Constant.uploadUserImageToFireStorage(
                  File(entry.value),
                  "driverDocuments/${FireStoreUtils.getCurrentUid()}",
                  "${entry.key}_${DateTime.now().millisecondsSinceEpoch}.jpg")
              .then((url) => uploadedDocumentUrls[entry.key] = url));
        } else {
          uploadedDocumentUrls[entry.key] = entry.value;
        }
      }

      // Wait for all uploads to complete
      await Future.wait(uploadFutures);

      // Prepare vehicle information
      final vehicleInfo = VehicleInformation(
        vehicleNumber: vehicleNumberController.value.text.trim(),
        vehicleType: selectedVehicleType.value.name,
        vehicleTypeId: selectedVehicleType.value.id,
        vehicleColor: selectedVehicleColor.value,
        seats: seatsController.value.text.trim(),
        registrationDate: Timestamp.fromDate(selectedRegistrationDate.value!),
      );

      // Update driver profile
      final currentUser =
          await FireStoreUtils.getDriverProfile(FireStoreUtils.getCurrentUid());
      if (currentUser != null) {
        currentUser
          ..fullName = fullNameController.value.text.trim()
          ..email = emailController.value.text.trim()
          ..phoneNumber = phoneController.value.text.trim()
          ..countryCode = countryCode.value
          ..profilePic = profileImageUrl
          ..serviceId = selectedService.value.id
          ..vehicleInformation = vehicleInfo
          ..zoneIds = selectedZoneIds
          ..profileCompleted = true
          ..documentsSubmitted = true
          ..approvalStatus = 'pending';

        // Prepare documents for upload
        final documentsList = documentList.map((doc) {
          final document = Documents()
            ..documentId = doc.id
            ..documentNumber = documentNumberControllers[doc.id]?.text.trim()
            ..verified = false;

          if (doc.frontSide == true) {
            document.frontImage = uploadedDocumentUrls['${doc.id}_front'] ?? '';
          }

          if (doc.backSide == true) {
            document.backImage = uploadedDocumentUrls['${doc.id}_back'] ?? '';
          }

          if (doc.expireAt == true && documentExpiryDates[doc.id] != null) {
            document.expireAt =
                Timestamp.fromDate(documentExpiryDates[doc.id]!);
          }

          return document;
        }).toList();

        // Execute both updates in parallel
        await Future.wait([
          FireStoreUtils.updateDriverUser(currentUser),
          FirebaseFirestore.instance
              .collection('driver_document')
              .doc(FireStoreUtils.getCurrentUid())
              .set(DriverDocumentModel(
                id: FireStoreUtils.getCurrentUid(),
                documents: documentsList,
              ).toJson()),
        ]);
      }

      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Information submitted successfully!");

      Get.offAll(() => const PendingApprovalScreen());
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(
          "Failed to submit information: ${e.toString()}");
      rethrow; // Consider logging this error for debugging
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> _uploadDocuments(Map<String, String> uploadedUrls) async {
    List<Documents> documentsList = [];

    for (DocumentModel doc in documentList) {
      Documents document = Documents();
      document.documentId = doc.id;
      document.documentNumber = documentNumberControllers[doc.id]?.text.trim();
      document.verified = false;

      if (doc.frontSide == true) {
        document.frontImage = uploadedUrls['${doc.id}_front'] ?? '';
      }

      if (doc.backSide == true) {
        document.backImage = uploadedUrls['${doc.id}_back'] ?? '';
      }

      if (doc.expireAt == true && documentExpiryDates[doc.id] != null) {
        document.expireAt = Timestamp.fromDate(documentExpiryDates[doc.id]!);
      }

      documentsList.add(document);
    }

    DriverDocumentModel driverDocumentModel = DriverDocumentModel(
      id: FireStoreUtils.getCurrentUid(),
      documents: documentsList,
    );

    await FirebaseFirestore.instance
        .collection('driver_document')
        .doc(FireStoreUtils.getCurrentUid())
        .set(driverDocumentModel.toJson());
  }
}

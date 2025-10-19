import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/collection_name.dart';
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
  Rx<TextEditingController> dateOfBirthController = TextEditingController().obs;
  Rx<TextEditingController> licenseClassController =
      TextEditingController().obs;
  RxString countryCode = "+1".obs;
  RxString profileImagePath = "".obs;
  Rx<DateTime?> selectedDateOfBirth = Rx<DateTime?>(null);

  // Vehicle Information
  Rx<TextEditingController> vehicleNumberController =
      TextEditingController().obs;
  Rx<TextEditingController> registrationDateController =
      TextEditingController().obs;
  Rx<TextEditingController> seatsController = TextEditingController().obs;
  // REMOVED: Rx<TextEditingController> vehicleYearController = TextEditingController().obs;
  Rx<TextEditingController> vehicleMakeController = TextEditingController().obs;
  Rx<TextEditingController> vehicleModelController =
      TextEditingController().obs;
  Rx<DateTime?> selectedRegistrationDate = Rx<DateTime?>(null);

  // Vehicle Year - NEW APPROACH
  final List<int> vehicleYearOptions = List.generate(21, (index) {
    return DateTime.now().year - index;
  }).toList();
  RxInt selectedVehicleYear = 0.obs;

  // Province Information
  RxString selectedProvince = "".obs;
  RxMap<String, dynamic> provinceRequirements = <String, dynamic>{}.obs;
  RxBool meetsProvinceRequirements = false.obs;
  RxList<String> provinceValidationErrors = <String>[].obs;

  // Dropdowns
  Rx<ServiceModel> selectedService = ServiceModel().obs;
  Rx<VehicleTypeModel> selectedVehicleType = VehicleTypeModel().obs;
  RxString selectedVehicleColor = "".obs;
  RxList<String> selectedZoneIds = <String>[].obs;
  RxString selectedZoneNames = "".obs;

  // License Class
  RxString selectedLicenseClass = "".obs;

  // Document Upload
  RxMap<String, String> documentImages = <String, String>{}.obs;
  RxMap<String, TextEditingController> documentNumberControllers =
      <String, TextEditingController>{}.obs;
  RxMap<String, DateTime?> documentExpiryDates = <String, DateTime?>{}.obs;
  RxString gstNumber = "".obs;
  RxString qstNumber = "".obs;

  // Data Lists
  RxList<ServiceModel> serviceList = <ServiceModel>[].obs;
  RxList<VehicleTypeModel> vehicleTypeList = <VehicleTypeModel>[].obs;
  RxList<ZoneModel> zoneList = <ZoneModel>[].obs;
  RxList<DocumentModel> documentList = <DocumentModel>[].obs;

  // UI State
  RxInt currentStep = 0.obs;
  RxBool isLoading = true.obs;
  RxBool isSubmitting = false.obs;
  RxBool isServiceSelected = false.obs;
  RxBool isZoneSelected = false.obs;

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

  final List<Map<String, String>> canadianProvinces = [
    {'code': 'AB', 'name': 'Alberta'},
    {'code': 'BC', 'name': 'British Columbia'},
    {'code': 'MB', 'name': 'Manitoba'},
    {'code': 'NB', 'name': 'New Brunswick'},
    {'code': 'NL', 'name': 'Newfoundland and Labrador'},
    {'code': 'NS', 'name': 'Nova Scotia'},
    {'code': 'ON', 'name': 'Ontario'},
    {'code': 'PE', 'name': 'Prince Edward Island'},
    {'code': 'QC', 'name': 'Quebec'},
    {'code': 'SK', 'name': 'Saskatchewan'},
  ];

  final Map<String, List<String>> provinceLicenseOptions = {
    'AB': ['Class 1', 'Class 2', 'Class 4'],
    'BC': ['Class 1', 'Class 2', 'Class 4'],
    'MB': ['Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5F'],
    'NB': ['Class 4'],
    'NS': ['Class 1', 'Class 2', 'Class 4', 'Class 4A'],
    'ON': ['G Class'],
    'PE': ['Class 2', 'Class 4', 'Restricted Class 4'],
    'QC': ['Class 5'],
    'SK': ['Class 5'],
  };

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  @override
  void onClose() {
    pageController.dispose();
    fullNameController.value.dispose();
    emailController.value.dispose();
    phoneController.value.dispose();
    dateOfBirthController.value.dispose();
    licenseClassController.value.dispose();
    vehicleNumberController.value.dispose();
    registrationDateController.value.dispose();
    seatsController.value.dispose();
    vehicleMakeController.value.dispose();
    vehicleModelController.value.dispose();

    for (var controller in documentNumberControllers.values) {
      controller.dispose();
    }

    super.onClose();
  }

  Future<void> loadInitialData() async {
    try {
      isLoading.value = true;

      DriverUserModel? currentUser =
          await FireStoreUtils.getDriverProfile(FireStoreUtils.getCurrentUid());
      if (currentUser != null) {
        _populateUserData(currentUser);
      }

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
    selectedProvince.value = user.province ?? '';

    if (user.dateOfBirth != null) {
      selectedDateOfBirth.value = user.dateOfBirth!.toDate();
      dateOfBirthController.value.text =
          DateFormat("dd-MM-yyyy").format(selectedDateOfBirth.value!);
    }

    if (user.licenseClass != null) {
      licenseClassController.value.text = user.licenseClass!;
      selectedLicenseClass.value = user.licenseClass!;
    }

    if (user.vehicleInformation != null) {
      vehicleNumberController.value.text =
          user.vehicleInformation!.vehicleNumber ?? '';
      selectedVehicleColor.value = user.vehicleInformation!.vehicleColor ?? '';
      seatsController.value.text = user.vehicleInformation!.seats ?? '2';

      // FIXED: Use selectedVehicleYear
      if (user.vehicleInformation!.vehicleYear != null) {
        selectedVehicleYear.value = user.vehicleInformation!.vehicleYear!;
      }

      vehicleMakeController.value.text =
          user.vehicleInformation!.vehicleMake ?? '';
      vehicleModelController.value.text =
          user.vehicleInformation!.vehicleModel ?? '';

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

    if (selectedProvince.value.isNotEmpty) {
      validateProvinceRequirements();
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

    // print("Documents Loaded: ${documents}");

    for (DocumentModel doc in documents) {
      documentNumberControllers[doc.id!] = TextEditingController();
      documentExpiryDates[doc.id!] = null;
    }
  }

  // Get available license classes for current province
  List<String> getAvailableLicenseClasses() {
    if (selectedProvince.value.isEmpty) {
      return [];
    }
    return provinceLicenseOptions[selectedProvince.value] ?? ['Class 5'];
  }

  void updateLicenseClasses() {
    final availableClasses = getAvailableLicenseClasses();
    if (availableClasses.isNotEmpty &&
        !availableClasses.contains(selectedLicenseClass.value)) {
      selectedLicenseClass.value = availableClasses.first;
      licenseClassController.value.text = availableClasses.first;
    }
  }

  void validateProvinceRequirements() {
    if (selectedProvince.value.isEmpty) {
      meetsProvinceRequirements.value = false;
      provinceValidationErrors.value = ["Please select a province"];
      return;
    }

    final requirements = <String, dynamic>{};
    final errors = <String>[];
    bool meetsAllRequirements = true;

    // Age validation
    final int? driverAge = calculateAge();
    final int minAge = getMinimumAge();

    if (driverAge == null) {
      errors.add("Please enter your date of birth");
      meetsAllRequirements = false;
    } else if (driverAge < minAge) {
      errors
          .add("Minimum age requirement: $minAge years (Current: $driverAge)");
      meetsAllRequirements = false;
    }

    requirements['age'] = {
      'required': minAge,
      'actual': driverAge,
      'valid': driverAge != null && driverAge >= minAge
    };

    // License class validation
    final String licenseClass = selectedLicenseClass.value;
    final bool isLicenseValid = licenseClass.isNotEmpty;

    requirements['license'] = {
      'required': getAvailableLicenseClasses(),
      'actual': licenseClass,
      'valid': isLicenseValid
    };
    meetsAllRequirements = meetsAllRequirements && isLicenseValid;

    if (!isLicenseValid) {
      errors.add("Please select a license class");
    }

    // Vehicle year default to current year if unset
    final int currentYear = DateTime.now().year;
    final int vehicleYear = selectedVehicleYear.value == 0
        ? currentYear
        : selectedVehicleYear.value;
    final int maxVehicleAge = getMaxVehicleAge();

    // No longer checking for vehicleYear == 0
    if (currentYear - vehicleYear > maxVehicleAge) {
      errors.add(
          "Maximum vehicle age: $maxVehicleAge years (Your vehicle is ${currentYear - vehicleYear} years old)");
      meetsAllRequirements = false;
    }

    requirements['vehicle_age'] = {
      'required': maxVehicleAge,
      'actual': currentYear - vehicleYear,
      'valid': (currentYear - vehicleYear) <= maxVehicleAge
    };

    provinceRequirements.value = requirements;
    provinceValidationErrors.value = errors;
    meetsProvinceRequirements.value = meetsAllRequirements && errors.isEmpty;
  }

  int getMinimumAge() {
    switch (selectedProvince.value) {
      case 'PE':
        return 25;
      default:
        return 21;
    }
  }

  List<String> getRequiredLicenseClasses() {
    switch (selectedProvince.value) {
      case 'AB':
        return ['1', '2', '4'];
      case 'BC':
        return ['1', '2', '4'];
      case 'MB':
        return ['1', '2', '3', '4', '5F'];
      case 'NB':
        return ['4'];
      case 'NS':
        return ['1', '2', '4', '4A'];
      case 'ON':
        return ['G'];
      case 'PE':
        return ['4', '2', 'R4'];
      case 'QC':
        return ['5'];
      case 'SK':
        return ['5'];
      default:
        return ['5'];
    }
  }

  int getMaxVehicleAge() {
    switch (selectedProvince.value) {
      case 'BC':
        return 9;
      case 'ON':
        return 10;
      default:
        return 10;
    }
  }

  int? calculateAge() {
    if (selectedDateOfBirth.value == null) return null;
    final now = DateTime.now();
    final birthDate = selectedDateOfBirth.value!;
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // Date selection methods
  Future<void> selectDateOfBirth() async {
    DateTime? picked = await Constant.selectDate(Get.context!);
    if (picked != null) {
      selectedDateOfBirth.value = picked;
      dateOfBirthController.value.text =
          DateFormat("dd-MM-yyyy").format(picked);
      validateProvinceRequirements();
    }
  }

  Future<void> selectRegistrationDate() async {
    DateTime? picked = await Constant.selectDate(Get.context!);
    if (picked != null) {
      selectedRegistrationDate.value = picked;
      registrationDateController.value.text =
          DateFormat("dd-MM-yyyy").format(picked);
    }
  }

  Future<void> selectDocumentExpiryDate(String documentId) async {
    DateTime? picked = await Constant.selectFetureDate(Get.context!);
    if (picked != null) {
      documentExpiryDates[documentId] = picked;
      update();
    }
  }

  // Image picker methods
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> pickProfileImage() async {
    try {
      XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        profileImagePath.value = image.path;
        update();
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
        update();
      }
    } on PlatformException catch (e) {
      ShowToastDialog.showToast("Failed to pick image: ${e.message}");
    }
  }

  // Service and Zone selection
  void selectService(ServiceModel service) {
    selectedService.value = service;
    isServiceSelected.value = true;
    update();
  }

  void toggleZoneSelection(String zoneId) {
    if (selectedZoneIds.contains(zoneId)) {
      selectedZoneIds.remove(zoneId);
    } else {
      selectedZoneIds.add(zoneId);
    }
    isZoneSelected.value = selectedZoneIds.isNotEmpty;
    updateSelectedZones();
    update();
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

  // Step navigation
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
    if (selectedProvince.value.isEmpty) {
      ShowToastDialog.showToast("Please select your province");
      return false;
    }

    if (fullNameController.value.text.trim().isEmpty) {
      ShowToastDialog.showToast("Please enter your full name");
      return false;
    }

    if (dateOfBirthController.value.text.trim().isEmpty) {
      ShowToastDialog.showToast("Please enter your date of birth");
      return false;
    }

    if (licenseClassController.value.text.trim().isEmpty) {
      ShowToastDialog.showToast("Please enter your license class");
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

    // FIXED: Check selectedVehicleYear instead of the old controller
    if (selectedVehicleYear.value == 0) {
      ShowToastDialog.showToast("Please select vehicle manufacturing year");
      return false;
    }

    if (vehicleMakeController.value.text.trim().isEmpty) {
      ShowToastDialog.showToast("Please enter vehicle make");
      return false;
    }

    if (vehicleModelController.value.text.trim().isEmpty) {
      ShowToastDialog.showToast("Please enter vehicle model");
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

      // Get current user data first
      final currentUser =
          await FireStoreUtils.getDriverProfile(FireStoreUtils.getCurrentUid());
      if (currentUser == null) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("User not found");
        return;
      }

      // Upload profile image if needed (only if it's a new file)
      String profileImageUrl = profileImagePath.value;
      if (profileImagePath.value.isNotEmpty &&
          !Constant.hasValidUrl(profileImagePath.value) &&
          profileImagePath.value != currentUser.profilePic) {
        profileImageUrl = await Constant.uploadUserImageToFireStorage(
            File(profileImagePath.value),
            "profileImages/${FireStoreUtils.getCurrentUid()}",
            "profile_${DateTime.now().millisecondsSinceEpoch}.jpg");
      }

      // Upload document images in parallel
      final uploadedDocumentUrls = <String, String>{};
      final uploadFutures = <Future>[];

      for (final entry in documentImages.entries) {
        // Skip if already a URL or same as existing
        if (Constant.hasValidUrl(entry.value)) {
          uploadedDocumentUrls[entry.key] = entry.value;
          continue;
        }

        uploadFutures.add(Constant.uploadUserImageToFireStorage(
                File(entry.value),
                "driverDocuments/${FireStoreUtils.getCurrentUid()}",
                "${entry.key}_${DateTime.now().millisecondsSinceEpoch}.jpg")
            .then((url) => uploadedDocumentUrls[entry.key] = url));
      }

      // Wait for all uploads to complete with timeout
      await Future.wait(uploadFutures).timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          throw Exception("File upload timeout. Please try again.");
        },
      );

      // Prepare vehicle info
      final vehicleInfo = VehicleInformation(
        vehicleNumber: vehicleNumberController.value.text.trim(),
        vehicleType: selectedVehicleType.value.name,
        vehicleTypeId: selectedVehicleType.value.id,
        vehicleColor: selectedVehicleColor.value,
        vehicleYear: selectedVehicleYear.value,
        vehicleMake: vehicleMakeController.value.text.trim(),
        vehicleModel: vehicleModelController.value.text.trim(),
        seats: seatsController.value.text.trim(),
        registrationDate: Timestamp.fromDate(selectedRegistrationDate.value!),
      );

      // Update user data
      currentUser
        ..fullName = fullNameController.value.text.trim()
        ..email = emailController.value.text.trim()
        ..phoneNumber = phoneController.value.text.trim()
        ..countryCode = countryCode.value
        ..province = selectedProvince.value
        ..dateOfBirth = selectedDateOfBirth.value != null
            ? Timestamp.fromDate(selectedDateOfBirth.value!)
            : null
        ..licenseClass = licenseClassController.value.text.trim()
        ..profilePic = profileImageUrl
        ..serviceId = selectedService.value.id
        ..vehicleInformation = vehicleInfo
        ..zoneIds = selectedZoneIds
        ..gstNumber = gstNumber.value
        ..qstNumber = qstNumber.value
        ..profileCompleted = true
        ..documentsSubmitted = true
        ..approvalStatus = 'pending';

      // Prepare documents
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
          document.expireAt = Timestamp.fromDate(documentExpiryDates[doc.id]!);
        }

        return document;
      }).toList();

      // Batch Firestore operations
      final batch = FirebaseFirestore.instance.batch();

      // Update user document - FIXED: Use CollectionName.driverUsers
      final userRef = FirebaseFirestore.instance
          .collection(CollectionName.driverUsers)
          .doc(FireStoreUtils.getCurrentUid());
      batch.set(userRef, currentUser.toJson(), SetOptions(merge: true));

      // Update driver document
      final docRef = FirebaseFirestore.instance
          .collection(CollectionName.driverDocument)
          .doc(FireStoreUtils.getCurrentUid());
      batch.set(
          docRef,
          DriverDocumentModel(
            id: FireStoreUtils.getCurrentUid(),
            documents: documentsList,
          ).toJson());

      // Commit batch operation
      await batch.commit();

      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Information submitted successfully!");

      Get.offAll(() => const PendingApprovalScreen());
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(
          "Failed to submit information: ${e.toString()}");
      isSubmitting.value = false;
      rethrow;
    }
  }

  void setTaxNumbers(String gst, String qst) {
    gstNumber.value = gst;
    qstNumber.value = qst;
    validateProvinceRequirements();
  }
}

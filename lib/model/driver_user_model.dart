import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/model/driver_rules_model.dart';
import 'package:customer/model/order/location_lat_lng.dart';
import 'package:customer/model/order/positions.dart';

class DriverUserModel {
  String? phoneNumber;
  String? loginType;
  String? countryCode;
  String? profilePic;
  bool? documentVerification;
  String? fullName;
  bool? isOnline;
  String? id;
  String? serviceId;
  String? fcmToken;
  List<String>? fcmTokens;
  String? email;
  String? password;
  String? approvalStatus; // pending, approved, rejected
  bool? profileCompleted;
  bool? documentsSubmitted;
  VehicleInformation? vehicleInformation;
  String? reviewsCount;
  String? reviewsSum;
  String? walletAmount;
  LocationLatLng? location;
  double? rotation;
  Positions? position;
  Timestamp? createdAt;
  List<dynamic>? zoneIds;
  List<dynamic>? zoneId;
  String? province;
  Timestamp? dateOfBirth;
  String? licenseClass;
  String? gstNumber;
  String? qstNumber;
  bool? trainingCompleted;
  String? paymentMethod; // "commission" or "flat_rate"
  Timestamp? lastSwitched;
  Timestamp? flatRatePaidAt;
  bool? flatRateActive;

  DriverUserModel({
    this.phoneNumber,
    this.loginType,
    this.countryCode,
    this.profilePic,
    this.documentVerification,
    this.fullName,
    this.isOnline,
    this.id,
    this.serviceId,
    this.fcmToken,
    this.fcmTokens,
    this.email,
    this.password,
    this.approvalStatus,
    this.profileCompleted,
    this.documentsSubmitted,
    this.location,
    this.vehicleInformation,
    this.reviewsCount,
    this.reviewsSum,
    this.rotation,
    this.position,
    this.walletAmount,
    this.createdAt,
    this.zoneIds,
    this.zoneId,
    this.province,
    this.dateOfBirth,
    this.licenseClass,
    this.gstNumber,
    this.qstNumber,
    this.trainingCompleted,
    this.paymentMethod,
    this.lastSwitched,
    this.flatRatePaidAt,
    this.flatRateActive,
  });

  DriverUserModel.fromJson(Map<String, dynamic> json) {
    phoneNumber = json['phoneNumber'];
    loginType = json['loginType'];
    countryCode = json['countryCode'];
    profilePic = json['profilePic'] ?? '';
    documentVerification = json['documentVerification'] ?? false;
    fullName = json['fullName'];
    isOnline = json['isOnline'] ?? false;
    id = json['id'];
    serviceId = json['serviceId'];
    fcmToken = json['fcmToken'];
    fcmTokens = json['fcmTokens'] != null ? List<String>.from(json['fcmTokens']) : null;
    email = json['email'];
    password = json['password'];
    approvalStatus = json['approvalStatus'] ?? 'pending';
    profileCompleted = json['profileCompleted'] ?? false;
    documentsSubmitted = json['documentsSubmitted'] ?? false;
    vehicleInformation = json['vehicleInformation'] != null
        ? VehicleInformation.fromJson(json['vehicleInformation'])
        : null;
    reviewsCount = json['reviewsCount'] ?? '0.0';
    reviewsSum = json['reviewsSum'] ?? '0.0';
    rotation = json['rotation'];
    walletAmount = json['walletAmount'] ?? "0.0";
    location = json['location'] != null
        ? LocationLatLng.fromJson(json['location'])
        : null;
    position =
        json['position'] != null ? Positions.fromJson(json['position']) : null;
    createdAt = json['createdAt'];
    zoneIds = json['zoneIds'];
    zoneId = json['zoneId'];
    province = json['province'];
    dateOfBirth = json['dateOfBirth'];
    licenseClass = json['licenseClass'];
    gstNumber = json['gstNumber'];
    qstNumber = json['qstNumber'];
    trainingCompleted = json['trainingCompleted'];
    paymentMethod = json['paymentMethod'] ?? 'commission';
    lastSwitched = json['lastSwitched'];
    flatRatePaidAt = json['flatRatePaidAt'];
    flatRateActive = json['flatRateActive'] ?? false;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['phoneNumber'] = phoneNumber;
    data['loginType'] = loginType;
    data['countryCode'] = countryCode;
    data['profilePic'] = profilePic;
    data['documentVerification'] = documentVerification;
    data['fullName'] = fullName;
    data['isOnline'] = isOnline;
    data['id'] = id;
    data['serviceId'] = serviceId;
    data['fcmToken'] = fcmToken;
    data['fcmTokens'] = fcmTokens;
    data['email'] = email;
    data['password'] = password;
    data['approvalStatus'] = approvalStatus;
    data['profileCompleted'] = profileCompleted;
    data['documentsSubmitted'] = documentsSubmitted;
    data['rotation'] = rotation;
    data['createdAt'] = createdAt;
    if (vehicleInformation != null) {
      data['vehicleInformation'] = vehicleInformation!.toJson();
    }
    if (location != null) {
      data['location'] = location!.toJson();
    }
    data['reviewsCount'] = reviewsCount;
    data['reviewsSum'] = reviewsSum;
    data['walletAmount'] = walletAmount;
    data['zoneIds'] = zoneIds;
    data['zoneId'] = zoneId;
    data['province'] = province;
    data['dateOfBirth'] = dateOfBirth;
    data['licenseClass'] = licenseClass;
    data['gstNumber'] = gstNumber;
    data['qstNumber'] = qstNumber;
    data['trainingCompleted'] = trainingCompleted;
    data['paymentMethod'] = paymentMethod;
    data['lastSwitched'] = lastSwitched;
    data['flatRatePaidAt'] = flatRatePaidAt;
    data['flatRateActive'] = flatRateActive;
    if (position != null) {
      data['position'] = position!.toJson();
    }
    return data;
  }
}

class VehicleInformation {
  String? vehicleType;
  String? vehicleTypeId;
  Timestamp? registrationDate;
  String? vehicleColor;
  String? vehicleNumber;
  String? seats;
  List<DriverRulesModel>? driverRules;
  int? vehicleYear;
  String? vehicleMake;
  String? vehicleModel;

  VehicleInformation({
    this.vehicleType,
    this.vehicleTypeId,
    this.registrationDate,
    this.vehicleColor,
    this.vehicleNumber,
    this.seats,
    this.driverRules,
    this.vehicleYear,
    this.vehicleMake,
    this.vehicleModel,
  });

  VehicleInformation.fromJson(Map<String, dynamic> json) {
    vehicleType = json['vehicleType'];
    vehicleTypeId = json['vehicleTypeId'];
    registrationDate = json['registrationDate'];
    vehicleColor = json['vehicleColor'];
    vehicleNumber = json['vehicleNumber'];
    seats = json['seats'];
    vehicleYear = json['vehicleYear'];
    vehicleMake = json['vehicleMake'];
    vehicleModel = json['vehicleModel'];
    if (json['driverRules'] != null) {
      driverRules = <DriverRulesModel>[];
      json['driverRules'].forEach((v) {
        driverRules!.add(DriverRulesModel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['vehicleType'] = vehicleType;
    data['vehicleTypeId'] = vehicleTypeId;
    data['registrationDate'] = registrationDate;
    data['vehicleColor'] = vehicleColor;
    data['vehicleNumber'] = vehicleNumber;
    data['vehicleYear'] = vehicleYear;
    data['vehicleMake'] = vehicleMake;
    data['vehicleModel'] = vehicleModel;
    data['seats'] = seats;
    if (driverRules != null) {
      data['driverRules'] = driverRules!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

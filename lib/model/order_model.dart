import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/model/admin_commission.dart';
import 'package:customer/model/contact_model.dart';
import 'package:customer/model/coupon_model.dart';
import 'package:customer/model/order/location_lat_lng.dart';
import 'package:customer/model/order/positions.dart';
import 'package:customer/model/service_model.dart';
import 'package:customer/model/tax_model.dart';
import 'package:customer/model/zone_model.dart';

class OrderModel {
  String? sourceLocationName;
  String? destinationLocationName;
  String? paymentType;
  LocationLatLng? sourceLocationLAtLng;
  LocationLatLng? destinationLocationLAtLng;
  String? id;
  String? serviceId;
  String? userId;
  String? offerRate;
  String? finalRate;
  String? distance;
  String? distanceType;
  String? status;
  String? driverId;
  String? otp;
  List<dynamic>? acceptedDriverId;
  List<dynamic>? rejectedDriverId;
  Positions? position;
  Timestamp? createdDate;
  Timestamp? updateDate;
  bool? paymentStatus;
  List<TaxModel>? taxList;
  ContactModel? someOneElse;
  CouponModel? coupon;
  ServiceModel? service;
  AdminCommission? adminCommission;
  ZoneModel? zone;
  String? zoneId;
  String? paymentIntentId;
  String? preAuthAmount;
  String? paymentIntentStatus;
  Timestamp? preAuthCreatedAt;
  Timestamp? paymentCapturedAt;
  Timestamp? paymentCanceledAt;

  OrderModel(
      {this.position,
      this.serviceId,
      this.paymentType,
      this.sourceLocationName,
      this.destinationLocationName,
      this.sourceLocationLAtLng,
      this.destinationLocationLAtLng,
      this.id,
      this.userId,
      this.distance,
      this.distanceType,
      this.status,
      this.driverId,
      this.otp,
      this.offerRate,
      this.finalRate,
      this.paymentStatus,
      this.createdDate,
      this.updateDate,
      this.taxList,
      this.coupon,
      this.someOneElse,
      this.service,
      this.adminCommission,
      this.zone,
      this.zoneId,
      this.paymentIntentId,
      this.preAuthAmount,
      this.paymentIntentStatus,
      this.preAuthCreatedAt,
      this.paymentCapturedAt,
      this.paymentCanceledAt});

  OrderModel.fromJson(Map<String, dynamic> json) {
    serviceId = json['serviceId'];
    sourceLocationName = json['sourceLocationName'];
    paymentType = json['paymentType'];
    destinationLocationName = json['destinationLocationName'];
    sourceLocationLAtLng = json['sourceLocationLAtLng'] != null
        ? LocationLatLng.fromJson(json['sourceLocationLAtLng'])
        : null;
    destinationLocationLAtLng = json['destinationLocationLAtLng'] != null
        ? LocationLatLng.fromJson(json['destinationLocationLAtLng'])
        : null;
    coupon =
        json['coupon'] != null ? CouponModel.fromJson(json['coupon']) : null;
    someOneElse = json['someOneElse'] != null
        ? ContactModel.fromJson(json['someOneElse'])
        : null;
    id = json['id'];
    userId = json['userId'];
    offerRate = json['offerRate'];
    finalRate = json['finalRate'];
    distance = json['distance'];
    distanceType = json['distanceType'];
    status = json['status'];
    driverId = json['driverId'];
    otp = json['otp'];
    createdDate = json['createdDate'];
    updateDate = json['updateDate'];
    acceptedDriverId = json['acceptedDriverId'];
    rejectedDriverId = json['rejectedDriverId'];
    paymentStatus = json['paymentStatus'];
    position =
        json['position'] != null ? Positions.fromJson(json['position']) : null;
    service =
        json['service'] != null ? ServiceModel.fromJson(json['service']) : null;
    adminCommission = json['adminCommission'] != null
        ? AdminCommission.fromJson(json['adminCommission'])
        : null;
    zone = json['zone'] != null ? ZoneModel.fromJson(json['zone']) : null;
    zoneId = json['zoneId'];

    // 🔥 CRITICAL FIX: Ensure ALL payment fields are properly loaded with null checks
    paymentIntentId = json['paymentIntentId'];
    preAuthAmount = json['preAuthAmount'];
    paymentIntentStatus = json['paymentIntentStatus'];
    preAuthCreatedAt = json['preAuthCreatedAt'];
    paymentCapturedAt = json['paymentCapturedAt'];
    paymentCanceledAt = json['paymentCanceledAt'];
<<<<<<< HEAD

    // 🔍 ENHANCED DEBUGGING: Log what's actually being loaded
    print("💾 [ORDER FROMJSON] Payment fields loaded from JSON:");
    print("   paymentIntentId: $paymentIntentId");
    print("   preAuthAmount: $preAuthAmount");
    print("   paymentIntentStatus: $paymentIntentStatus");
    print("   paymentType: $paymentType");
    print("   preAuthCreatedAt: $preAuthCreatedAt");

    // Debug the raw JSON to see what's actually there
    print("🔍 [ORDER FROMJSON] Raw JSON payment fields:");
    print("   json['paymentIntentId']: ${json['paymentIntentId']}");
    print("   json['preAuthAmount']: ${json['preAuthAmount']}");
    print("   json['paymentIntentStatus']: ${json['paymentIntentStatus']}");

    // 🔥 CRITICAL: If payment type is Stripe but payment data is missing, log warning
  if ((paymentType?.toLowerCase().contains("stripe") == true) && 
      (paymentIntentId == null || paymentIntentId!.isEmpty)) {
    print("🚨 [ORDER FROMJSON] WARNING: Stripe payment but missing paymentIntentId!");
  }

=======
>>>>>>> c6685a3a6509a3a5ff5f9f2f2b56402e116d9616
    if (json['taxList'] != null) {
      taxList = <TaxModel>[];
      json['taxList'].forEach((v) {
        taxList!.add(TaxModel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['serviceId'] = serviceId;
    data['sourceLocationName'] = sourceLocationName;
    data['destinationLocationName'] = destinationLocationName;
    if (sourceLocationLAtLng != null) {
      data['sourceLocationLAtLng'] = sourceLocationLAtLng!.toJson();
    }
    if (coupon != null) {
      data['coupon'] = coupon!.toJson();
    }
    if (someOneElse != null) {
      data['someOneElse'] = someOneElse!.toJson();
    }
    if (destinationLocationLAtLng != null) {
      data['destinationLocationLAtLng'] = destinationLocationLAtLng!.toJson();
    }
    if (service != null) {
      data['service'] = service!.toJson();
    }
    if (adminCommission != null) {
      data['adminCommission'] = adminCommission!.toJson();
    }
    if (zone != null) {
      data['zone'] = zone!.toJson();
    }
    data['zoneId'] = zoneId;

    // 🔥 CRITICAL FIX: Ensure ALL payment fields are saved
    data['paymentIntentId'] = paymentIntentId;
    data['preAuthAmount'] = preAuthAmount;
    data['paymentIntentStatus'] = paymentIntentStatus;
    data['preAuthCreatedAt'] = preAuthCreatedAt;
    data['paymentCapturedAt'] = paymentCapturedAt;
    data['paymentCanceledAt'] = paymentCanceledAt;
<<<<<<< HEAD

=======
>>>>>>> c6685a3a6509a3a5ff5f9f2f2b56402e116d9616
    data['id'] = id;
    data['userId'] = userId;
    data['paymentType'] = paymentType;
    data['offerRate'] = offerRate;
    data['finalRate'] = finalRate;
    data['distance'] = distance;
    data['distanceType'] = distanceType;
    data['status'] = status;
    data['driverId'] = driverId;
    data['otp'] = otp;
    data['createdDate'] = createdDate;
    data['updateDate'] = updateDate;
    data['acceptedDriverId'] = acceptedDriverId;
    data['rejectedDriverId'] = rejectedDriverId;
    data['paymentStatus'] = paymentStatus;
    if (taxList != null) {
      data['taxList'] = taxList!.map((v) => v.toJson()).toList();
    }
    if (position != null) {
      data['position'] = position!.toJson();
    }

    // 🔍 ENHANCED DEBUGGING: Log what's being saved
    print("💾 [ORDER TOJSON] Payment fields being saved:");
    print("   paymentIntentId: $paymentIntentId");
    print("   preAuthAmount: $preAuthAmount");
    print("   paymentIntentStatus: $paymentIntentStatus");
    print("   paymentType: $paymentType");
    print("   preAuthCreatedAt: $preAuthCreatedAt");

    return data;
  }
}

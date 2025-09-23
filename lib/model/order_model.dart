import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/model/admin_commission.dart';
import 'package:driver/model/contact_model.dart';
import 'package:driver/model/coupon_model.dart';
import 'package:driver/model/order/location_lat_lng.dart';
import 'package:driver/model/order/positions.dart';
import 'package:driver/model/service_model.dart';
import 'package:driver/model/tax_model.dart';
import 'package:driver/model/zone_model.dart';

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
        this.zone,this.zoneId});

  OrderModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['userId'];
    serviceId = json['serviceId'];
    sourceLocationName = json['sourceLocationName'];
    destinationLocationName = json['destinationLocationName'];
    sourceLocationLAtLng = json['sourceLocationLAtLng'] != null ? LocationLatLng.fromJson(json['sourceLocationLAtLng']) : null;
    destinationLocationLAtLng = json['destinationLocationLAtLng'] != null ? LocationLatLng.fromJson(json['destinationLocationLAtLng']) : null;
    distance = json['distance'];
    distanceType = json['distanceType'];
    position = json['position'] != null ? Positions.fromJson(json['position']) : null;
    service = json['service'] != null ? ServiceModel.fromJson(json['service']) : ServiceModel(id: serviceId, kmCharge: "10");
    offerRate = json['offerRate'];
    finalRate = json['finalRate'];
    status = json['status'];
    otp = json['otp'];
    paymentType = json['paymentType'];
    paymentStatus = json['paymentStatus'];
    zoneId = json['zoneId'];
    acceptedDriverId = json['acceptedDriverId'];
    rejectedDriverId = json['rejectedDriverId'];
    createdDate = json['createdDate'];
    updateDate = json['updateDate'];
    if (json['taxList'] != null) {
      taxList = <TaxModel>[];
      json['taxList'].forEach((v) {
        taxList!.add(TaxModel.fromJson(v));
      });
    }
    if (json['adminCommission'] != null) {
      adminCommission = AdminCommission.fromJson(json['adminCommission']);
    }
    if (json['zone'] != null) {
      zone = ZoneModel.fromJson(json['zone']);
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['userId'] = userId;
    data['serviceId'] = serviceId;
    data['sourceLocationName'] = sourceLocationName;
    data['destinationLocationName'] = destinationLocationName;
    if (sourceLocationLAtLng != null) {
      data['sourceLocationLAtLng'] = sourceLocationLAtLng!.toJson();
    }
    if (destinationLocationLAtLng != null) {
      data['destinationLocationLAtLng'] = destinationLocationLAtLng!.toJson();
    }
    data['distance'] = distance;
    data['distanceType'] = distanceType;
    if (position != null) {
      data['position'] = position!.toJson();
    }
    data['offerRate'] = offerRate;
    data['finalRate'] = finalRate;
    data['status'] = status;
    data['otp'] = otp;
    data['paymentType'] = paymentType;
    data['paymentStatus'] = paymentStatus;
    data['zoneId'] = zoneId;
    data['acceptedDriverId'] = acceptedDriverId;
    data['rejectedDriverId'] = rejectedDriverId;
    data['createdDate'] = createdDate;
    data['updateDate'] = updateDate;
    if (taxList != null) {
      data['taxList'] = taxList!.map((v) => v.toJson()).toList();
    }
    if (adminCommission != null) {
      data['adminCommission'] = adminCommission!.toJson();
    }
    if (zone != null) {
      data['zone'] = zone!.toJson();
    }
    return data;
  }
}

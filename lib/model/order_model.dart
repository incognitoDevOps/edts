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

  OrderModel({
    this.position,
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
    this.acceptedDriverId,
    this.rejectedDriverId,
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
    this.paymentCanceledAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
  print("🔄 [ORDER FROM JSON] Parsing order from JSON");
  
  // 🔥 CRITICAL: MANUALLY PRESERVE PAYMENT DATA BEFORE ANY PARSING
  final preservedPaymentIntentId = json['paymentIntentId']?.toString();
  final preservedPreAuthAmount = json['preAuthAmount']?.toString();
  final preservedPaymentIntentStatus = json['paymentIntentStatus']?.toString();
  
  // MANUAL timestamp parsing - don't rely on _parseTimestamp
  Timestamp? preservedPreAuthCreatedAt;
  final preAuthCreatedAtData = json['preAuthCreatedAt'];
  if (preAuthCreatedAtData is Timestamp) {
    preservedPreAuthCreatedAt = preAuthCreatedAtData;
  } else if (preAuthCreatedAtData is Map) {
    final seconds = preAuthCreatedAtData['_seconds'] ?? preAuthCreatedAtData['seconds'];
    final nanoseconds = preAuthCreatedAtData['_nanoseconds'] ?? preAuthCreatedAtData['nanoseconds'] ?? 0;
    if (seconds != null) {
      preservedPreAuthCreatedAt = Timestamp(seconds, nanoseconds);
    }
  }

  // Now do normal parsing
  OrderModel order = OrderModel(
    serviceId: json['serviceId'],
    sourceLocationName: json['sourceLocationName'],
    paymentType: json['paymentType'],
    destinationLocationName: json['destinationLocationName'],
    sourceLocationLAtLng: json['sourceLocationLAtLng'] != null
        ? LocationLatLng.fromJson(json['sourceLocationLAtLng'])
        : null,
    destinationLocationLAtLng: json['destinationLocationLAtLng'] != null
        ? LocationLatLng.fromJson(json['destinationLocationLAtLng'])
        : null,
    coupon: json['coupon'] != null ? CouponModel.fromJson(json['coupon']) : null,
    someOneElse: json['someOneElse'] != null
        ? ContactModel.fromJson(json['someOneElse'])
        : null,
    id: json['id'],
    userId: json['userId'],
    offerRate: json['offerRate'],
    finalRate: json['finalRate'],
    distance: json['distance'],
    distanceType: json['distanceType'],
    status: json['status'],
    driverId: json['driverId'],
    otp: json['otp'],
    createdDate: json['createdDate'],
    updateDate: json['updateDate'],
    acceptedDriverId: json['acceptedDriverId'],
    rejectedDriverId: json['rejectedDriverId'],
    paymentStatus: json['paymentStatus'],
    position: json['position'] != null ? Positions.fromJson(json['position']) : null,
    service: json['service'] != null ? ServiceModel.fromJson(json['service']) : null,
    adminCommission: json['adminCommission'] != null
        ? AdminCommission.fromJson(json['adminCommission'])
        : null,
    zone: json['zone'] != null ? ZoneModel.fromJson(json['zone']) : null,
    zoneId: json['zoneId'],
    // 🔥 CRITICAL: Use preserved payment data instead of parsing
    paymentIntentId: preservedPaymentIntentId,
    preAuthAmount: preservedPreAuthAmount,
    paymentIntentStatus: preservedPaymentIntentStatus,
    preAuthCreatedAt: preservedPreAuthCreatedAt,
    paymentCapturedAt: json['paymentCapturedAt'],
    paymentCanceledAt: json['paymentCanceledAt'],
  );

  if (json['taxList'] != null) {
    order.taxList = <TaxModel>[];
    json['taxList'].forEach((v) {
      order.taxList!.add(TaxModel.fromJson(v));
    });
  }

  print("✅ [ORDER FROM JSON] Payment data preserved:");
  print("   paymentIntentId: ${order.paymentIntentId}");
  print("   preAuthAmount: ${order.preAuthAmount}");
  print("   preAuthCreatedAt: ${order.preAuthCreatedAt}");

  return order;
}
  // 🔥 CRITICAL: Helper method to parse timestamps safely from Firestore
  Timestamp? _parseTimestamp(dynamic timestampData) {
    if (timestampData == null) return null;

    // If it's already a Timestamp, return it directly
    if (timestampData is Timestamp) {
      print("✅ [TIMESTAMP] Already a Timestamp: ${timestampData.seconds}");
      return timestampData;
    }

    // If it's a Map (Firestore format), convert it to Timestamp
    if (timestampData is Map<String, dynamic>) {
      try {
        final seconds =
            timestampData['_seconds'] ?? timestampData['seconds'] ?? 0;
        final nanoseconds =
            timestampData['_nanoseconds'] ?? timestampData['nanoseconds'] ?? 0;

        print(
            "🔄 [TIMESTAMP] Converting from Map: seconds=$seconds, nanoseconds=$nanoseconds");

        if (seconds > 0) {
          final timestamp = Timestamp(seconds, nanoseconds);
          print("✅ [TIMESTAMP] Successfully converted: ${timestamp.seconds}");
          return timestamp;
        } else {
          print("⚠️  [TIMESTAMP] Invalid seconds value: $seconds");
        }
      } catch (e) {
        print("❌ [TIMESTAMP PARSE] Error parsing timestamp Map: $e");
        print("   Raw data: $timestampData");
      }
    }

    // If it's a number (seconds since epoch), convert it
    if (timestampData is int) {
      print("🔄 [TIMESTAMP] Converting from int: $timestampData");
      if (timestampData > 1000000000) {
        // Likely milliseconds
        return Timestamp.fromMillisecondsSinceEpoch(timestampData);
      } else {
        // Likely seconds
        return Timestamp(timestampData, 0);
      }
    }

    print(
        "❌ [TIMESTAMP] Could not parse timestamp: $timestampData (type: ${timestampData.runtimeType})");
    return null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['serviceId'] = serviceId;
    data['sourceLocationName'] = sourceLocationName;
    data['destinationLocationName'] = destinationLocationName;
    data['paymentType'] = paymentType;

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

    // Payment data
    data['paymentIntentId'] = paymentIntentId;
    data['preAuthAmount'] = preAuthAmount;
    data['paymentIntentStatus'] = paymentIntentStatus;
    data['preAuthCreatedAt'] = preAuthCreatedAt;
    data['paymentCapturedAt'] = paymentCapturedAt;
    data['paymentCanceledAt'] = paymentCanceledAt;

    data['id'] = id;
    data['userId'] = userId;
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

    return data;
  }

  /// Validates critical order data before saving
  bool validateForSave() {
    if (id == null || id!.isEmpty) {
      print("❌ Order validation failed: Missing ID");
      return false;
    }

    if (userId == null || userId!.isEmpty) {
      print("❌ Order validation failed: Missing userId");
      return false;
    }

    // For Stripe payments, payment intent is REQUIRED
    if (paymentType?.toLowerCase().contains("stripe") == true) {
      if (paymentIntentId == null || paymentIntentId!.isEmpty) {
        print(
            "❌ Order validation failed: Stripe payment missing paymentIntentId");
        print("   Current paymentIntentId: $paymentIntentId");
        return false;
      }
      if (preAuthAmount == null || preAuthAmount!.isEmpty) {
        print(
            "❌ Order validation failed: Stripe payment missing preAuthAmount");
        print("   Current preAuthAmount: $preAuthAmount");
        return false;
      }
      if (preAuthCreatedAt == null) {
        print(
            "❌ Order validation failed: Stripe payment missing preAuthCreatedAt timestamp");
        print("   Current preAuthCreatedAt: $preAuthCreatedAt");
        return false;
      }

      print("✅ Stripe payment validation passed:");
      print("   paymentIntentId: $paymentIntentId");
      print("   preAuthAmount: $preAuthAmount");
      print("   preAuthCreatedAt: $preAuthCreatedAt");
    } else {
      print("✅ Non-Stripe payment - no payment validation required");
    }

    print("✅ Order validation passed for order: $id");
    return true;
  }

  /// Enhanced debug helper to print complete order state
  void debugPrint() {
    print("📋 Order Debug Info:");
    print("   ID: $id");
    print("   User ID: $userId");
    print("   Driver ID: $driverId");
    print("   Status: $status");
    print("   Payment Type: $paymentType");
    print("   Payment Intent ID: $paymentIntentId");
    print("   Pre-auth Amount: $preAuthAmount");
    print("   Payment Intent Status: $paymentIntentStatus");
    print("   Pre-auth Created: $preAuthCreatedAt");
    print("   Payment Captured: $paymentCapturedAt");
    print("   Payment Canceled: $paymentCanceledAt");
    print("   Payment Status: $paymentStatus");
    print("   Created Date: $createdDate");
    print("   Update Date: $updateDate");
  }

  /// Debug method specifically for payment data
  void debugPaymentData() {
    print("🔍 [PAYMENT DEBUG] Order: $id");
    print("   Payment Type: $paymentType");
    print("   Payment Intent ID: $paymentIntentId");
    print("   Pre-auth Amount: $preAuthAmount");
    print("   Payment Intent Status: $paymentIntentStatus");
    print("   Pre-auth Created: $preAuthCreatedAt");
    print("   Pre-auth Created Type: ${preAuthCreatedAt?.runtimeType}");
    print("   Payment Captured: $paymentCapturedAt");
    print("   Payment Canceled: $paymentCanceledAt");
    print("   Payment Status: $paymentStatus");
  }

  /// Creates a deep copy to prevent reference issues
  OrderModel clone() {
    return OrderModel.fromJson(this.toJson());
  }

  /// Check if payment data is intact for Stripe payments
  bool hasValidPaymentData() {
    if (paymentType?.toLowerCase().contains("stripe") != true) {
      return true; // Non-Stripe payments don't need payment data
    }

    final hasPaymentData = paymentIntentId != null &&
        paymentIntentId!.isNotEmpty &&
        preAuthAmount != null &&
        preAuthAmount!.isNotEmpty &&
        preAuthCreatedAt != null;

    if (!hasPaymentData) {
      print("⚠️  [PAYMENT CHECK] Missing payment data for Stripe order:");
      print("   paymentIntentId: $paymentIntentId");
      print("   preAuthAmount: $preAuthAmount");
      print("   preAuthCreatedAt: $preAuthCreatedAt");
    }

    return hasPaymentData;
  }

  /// Restore payment data from another order (for recovery)
  void restorePaymentData(OrderModel sourceOrder) {
    print("🔄 [PAYMENT RESTORE] Restoring payment data from source order");
    paymentIntentId = sourceOrder.paymentIntentId;
    preAuthAmount = sourceOrder.preAuthAmount;
    paymentIntentStatus = sourceOrder.paymentIntentStatus;
    preAuthCreatedAt = sourceOrder.preAuthCreatedAt;
    paymentCapturedAt = sourceOrder.paymentCapturedAt;
    paymentCanceledAt = sourceOrder.paymentCanceledAt;

    print("✅ [PAYMENT RESTORE] Payment data restored:");
    print("   paymentIntentId: $paymentIntentId");
    print("   preAuthAmount: $preAuthAmount");
    print("   preAuthCreatedAt: $preAuthCreatedAt");
  }
}

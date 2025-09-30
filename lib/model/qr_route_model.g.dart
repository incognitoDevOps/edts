// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qr_route_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QrRouteModel _$QrRouteModelFromJson(Map<String, dynamic> json) => QrRouteModel(
      userId: json['userId'] as String,
      sourceLocationName: json['sourceLocationName'] as String,
      destinationLocationName: json['destinationLocationName'] as String,
      sourceLatitude: (json['sourceLatitude'] as num).toDouble(),
      sourceLongitude: (json['sourceLongitude'] as num).toDouble(),
      destLatitude: (json['destLatitude'] as num).toDouble(),
      destLongitude: (json['destLongitude'] as num).toDouble(),
      distance: json['distance'] as String,
      distanceType: json['distanceType'] as String,
      offerRate: json['offerRate'] as String,
      finalRate: json['finalRate'] as String,
      paymentType: json['paymentType'] as String,
      is_test_qr: json['is_test_qr'] as bool? ?? false,
    );

Map<String, dynamic> _$QrRouteModelToJson(QrRouteModel instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'sourceLocationName': instance.sourceLocationName,
      'destinationLocationName': instance.destinationLocationName,
      'sourceLatitude': instance.sourceLatitude,
      'sourceLongitude': instance.sourceLongitude,
      'destLatitude': instance.destLatitude,
      'destLongitude': instance.destLongitude,
      'distance': instance.distance,
      'distanceType': instance.distanceType,
      'offerRate': instance.offerRate,
      'finalRate': instance.finalRate,
      'paymentType': instance.paymentType,
      'is_test_qr': instance.is_test_qr,
    };

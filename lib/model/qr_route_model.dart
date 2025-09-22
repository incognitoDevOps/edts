import 'package:json_annotation/json_annotation.dart';

part 'qr_route_model.g.dart';

@JsonSerializable()
class QrRouteModel {
  final String userId;
  final String sourceLocationName;
  final String destinationLocationName;
  final double sourceLatitude;
  final double sourceLongitude;
  final double destLatitude;
  final double destLongitude;
  final String distance;
  final String distanceType;
  final String offerRate;
  final String finalRate;
  final String paymentType;
  @JsonKey(defaultValue: false)
  final bool is_test_qr;

  QrRouteModel({
    required this.userId,
    required this.sourceLocationName,
    required this.destinationLocationName,
    required this.sourceLatitude,
    required this.sourceLongitude,
    required this.destLatitude,
    required this.destLongitude,
    required this.distance,
    required this.distanceType,
    required this.offerRate,
    required this.finalRate,
    required this.paymentType,
    this.is_test_qr = false,
  });

  factory QrRouteModel.fromJson(Map<String, dynamic> json) => _$QrRouteModelFromJson(json);
  Map<String, dynamic> toJson() => _$QrRouteModelToJson(this);
} 
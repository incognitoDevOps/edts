import 'package:customer/model/admin_commission.dart';

class ServiceModel {
  String? image;
  bool? enable;
  bool? offerRate;
  bool? intercityType;
  String? id;
  String? title;
  String? kmCharge;
  AdminCommission? adminCommission;
  int? passengerCount;

  ServiceModel({this.image, this.enable, this.intercityType, this.offerRate, this.id, this.title, this.kmCharge,this.adminCommission, this.passengerCount});

  ServiceModel.fromJson(Map<String, dynamic> json) {
    image = json['image'];
    enable = json['enable'];
    offerRate = json['offerRate'];
    id = json['id'];
    title = json['title'];
    kmCharge = json['kmCharge'];
    intercityType = json['intercityType'];
    adminCommission = json['adminCommission'] != null ? AdminCommission.fromJson(json['adminCommission']) : AdminCommission(isEnabled: true,amount: "",type: "");
    if (json['passengerCount'] is String) {
      passengerCount = int.tryParse(json['passengerCount'] as String);
    } else if (json['passengerCount'] is int) {
      passengerCount = json['passengerCount'] as int?;
    } else {
      passengerCount = null;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['image'] = image;
    data['enable'] = enable;
    data['offerRate'] = offerRate;
    data['id'] = id;
    data['title'] = title;
    data['kmCharge'] = kmCharge;
    data['intercityType'] = intercityType;
    if (adminCommission != null) {
      data['adminCommission'] = adminCommission!.toJson();
    }
    data['passengerCount'] = passengerCount;
    return data;
  }
}

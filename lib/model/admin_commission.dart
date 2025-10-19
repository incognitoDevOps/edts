class AdminCommission {
  String? amount;
  bool? isEnabled;
  String? type;
  FlatRatePromotion? flatRatePromotion;

  AdminCommission({this.amount, this.isEnabled, this.type, this.flatRatePromotion});

  AdminCommission.fromJson(Map<String, dynamic> json) {
    amount = json['amount'];
    isEnabled = json['isEnabled'];
    type = json['type'];
    flatRatePromotion = json['flatRatePromotion'] != null 
        ? FlatRatePromotion.fromJson(json['flatRatePromotion']) 
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['amount'] = amount;
    data['isEnabled'] = isEnabled;
    data['type'] = type;
    if (flatRatePromotion != null) {
      data['flatRatePromotion'] = flatRatePromotion!.toJson();
    }
    return data;
  }

  /// Check if both commission and flat rate are enabled
  bool get hasBothPaymentMethods => 
      (isEnabled == true) && (flatRatePromotion?.isEnabled == true);

  /// Check if only commission is enabled
  bool get hasOnlyCommission => 
      (isEnabled == true) && (flatRatePromotion?.isEnabled != true);

  /// Check if only flat rate is enabled
  bool get hasOnlyFlatRate => 
      (isEnabled != true) && (flatRatePromotion?.isEnabled == true);

  /// Get the commission amount to charge
  double calculateCommissionAmount(double rideAmount) {
    if (type == "fix") {
      return double.parse(amount.toString());
    } else {
      return (rideAmount * double.parse(amount!.toString())) / 100;
    }
  }

  /// Get the flat rate amount to charge
  double getFlatRateAmount() {
    return flatRatePromotion?.amount ?? 0.0;
  }
}

class FlatRatePromotion {
  bool? isEnabled;
  double? amount;

  FlatRatePromotion({this.isEnabled, this.amount});

  FlatRatePromotion.fromJson(Map<String, dynamic> json) {
    isEnabled = json['isEnabled'];
    amount = json['amount']?.toDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['isEnabled'] = isEnabled;
    data['amount'] = amount;
    return data;
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String? id;
  String? fullName;
  String? email;
  String? loginType;
  String? profilePic;
  String? fcmToken;
  String? countryCode;
  String? phoneNumber;
  String? reviewsCount;
  String? reviewsSum;
  String? walletAmount;
  bool? isActive;
  Timestamp? createdAt;

  UserModel({
    this.id,
    this.fullName,
    this.email,
    this.loginType,
    this.profilePic,
    this.fcmToken,
    this.countryCode,
    this.phoneNumber,
    this.reviewsCount = "0.0",
    this.reviewsSum = "0.0",
    this.walletAmount = "0",
    this.isActive = true,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['fullName'],
      email: json['email'],
      loginType: json['loginType'],
      profilePic: json['profilePic'],
      fcmToken: json['fcmToken'],
      countryCode: json['countryCode'],
      phoneNumber: json['phoneNumber'],
      reviewsCount: json['reviewsCount'] ?? "0.0",
      reviewsSum: json['reviewsSum'] ?? "0.0",
      walletAmount: json['walletAmount'] ?? "0",
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'loginType': loginType,
      'profilePic': profilePic,
      'fcmToken': fcmToken,
      'countryCode': countryCode,
      'phoneNumber': phoneNumber,
      'reviewsCount': reviewsCount,
      'reviewsSum': reviewsSum,
      'walletAmount': walletAmount,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }

  // Add copyWith method
  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? loginType,
    String? profilePic,
    String? fcmToken,
    String? countryCode,
    String? phoneNumber,
    String? reviewsCount,
    String? reviewsSum,
    String? walletAmount,
    bool? isActive,
    Timestamp? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      loginType: loginType ?? this.loginType,
      profilePic: profilePic ?? this.profilePic,
      fcmToken: fcmToken ?? this.fcmToken,
      countryCode: countryCode ?? this.countryCode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      reviewsSum: reviewsSum ?? this.reviewsSum,
      walletAmount: walletAmount ?? this.walletAmount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
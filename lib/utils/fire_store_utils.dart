import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/send_notification.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/model/admin_commission.dart';
import 'package:customer/model/airport_model.dart';
import 'package:customer/model/banner_model.dart';
import 'package:customer/model/conversation_model.dart';
import 'package:customer/model/coupon_model.dart';
import 'package:customer/model/currency_model.dart';
import 'package:customer/model/driver_user_model.dart';
import 'package:customer/model/faq_model.dart';
import 'package:customer/model/freight_vehicle.dart';
import 'package:customer/model/inbox_model.dart';
import 'package:customer/model/intercity_order_model.dart';
import 'package:customer/model/intercity_service_model.dart';
import 'package:customer/model/language_model.dart';
import 'package:customer/model/on_boarding_model.dart';
import 'package:customer/model/order/driverId_accept_reject.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/model/payment_model.dart';
import 'package:customer/model/referral_model.dart';
import 'package:customer/model/review_model.dart';
import 'package:customer/model/service_model.dart';
import 'package:customer/model/sos_model.dart';
import 'package:customer/model/tax_model.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/model/wallet_transaction_model.dart';
import 'package:customer/model/zone_model.dart';
import 'package:customer/widget/geoflutterfire/src/geoflutterfire.dart';
import 'package:customer/widget/geoflutterfire/src/models/point.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class FireStoreUtils {
  static FirebaseFirestore fireStore = FirebaseFirestore.instance;

  static Future<bool> isLogin() async {
    bool isLogin = false;
    if (FirebaseAuth.instance.currentUser != null) {
      isLogin = await userExitOrNot(FirebaseAuth.instance.currentUser!.uid);
    } else {
      isLogin = false;
    }
    return isLogin;
  }

  static Future<void> getSettings() async {
    try {
      await fireStore
          .collection(CollectionName.settings)
          .doc("globalKey")
          .get()
          .then((value) {
        if (value.exists && value.data() != null) {
          Constant.mapAPIKey = value.data()!["googleMapKey"] ?? "";
        }
      });

      await fireStore
          .collection(CollectionName.settings)
          .doc("notification_setting")
          .get()
          .then((value) {
        if (value.exists && value.data() != null) {
          Constant.senderId =
              value.data()!['senderId']?.toString() ?? '116120217389';
          Constant.jsonNotificationFileURL =
              value.data()!['serviceJson']?.toString() ?? '';
        }
      });

      await fireStore
          .collection(CollectionName.settings)
          .doc("globalValue")
          .get()
          .then((value) {
        if (value.exists && value.data() != null) {
          final data = value.data()!;
          Constant.distanceType = data["distanceType"] ?? "Km";
          Constant.radius = data["radius"] ?? "10";
          Constant.mapType = data["mapType"] ?? "google";
          Constant.selectedMapType = data["selectedMapType"] ?? "osm";
          Constant.driverLocationUpdate = data["driverLocationUpdate"] ?? "10";
        }
      });

      await fireStore
          .collection(CollectionName.settings)
          .doc("global")
          .get()
          .then((value) {
        if (value.exists && value.data() != null) {
          final data = value.data()!;
          Constant.termsAndConditions = data["termsAndConditions"] ?? "";
          Constant.privacyPolicy = data["privacyPolicy"] ?? "";
          Constant.appVersion = data["appVersion"] ?? "1.0.0";
        }
      });

      // In your getSettings() method, update the commission loading section:
      await fireStore
          .collection(CollectionName.settings)
          .doc("adminCommission")
          .get()
          .then((value) {
        if (value.exists && value.data() != null) {
          print("🔄 Loading admin commission from Firebase...");
          print("   Raw data: ${value.data()}");

          try {
            AdminCommission adminCommission =
                AdminCommission.fromJson(value.data()!);
            print("   Parsed commission:");
            print("     amount: ${adminCommission.amount}");
            print("     isEnabled: ${adminCommission.isEnabled}");
            print("     type: ${adminCommission.type}");

            if (adminCommission.flatRatePromotion != null) {
              print(
                  "     flatRatePromotion.isEnabled: ${adminCommission.flatRatePromotion!.isEnabled}");
              print(
                  "     flatRatePromotion.amount: ${adminCommission.flatRatePromotion!.amount}");
            }

            // Set commission regardless of isEnabled status for debugging
            Constant.adminCommission = adminCommission;
            print("   ✅ Commission loaded successfully");
          } catch (e) {
            print("   ❌ Error parsing commission: $e");
          }
        } else {
          print("❌ Commission document not found or empty");
        }
      }).catchError((error) {
        print("❌ Error loading commission: $error");
      });

      await fireStore
          .collection(CollectionName.settings)
          .doc("referral")
          .get()
          .then((value) {
        if (value.exists && value.data() != null) {
          Constant.referralAmount = value.data()!["referralAmount"] ?? "0";
        }
      });

      await fireStore
          .collection(CollectionName.settings)
          .doc("contact_us")
          .get()
          .then((value) {
        if (value.exists && value.data() != null) {
          Constant.supportURL = value.data()!["supportURL"] ?? "";
        }
      });

      await fireStore
          .collection(CollectionName.settings)
          .doc("currency")
          .get()
          .then((value) {
        if (value.exists && value.data() != null) {
          Constant.currencyModel = CurrencyModel.fromJson(value.data()!);
          // Override symbol to C$ for Canadian Dollar
          if (Constant.currencyModel != null) {
            Constant.currencyModel!.symbol = "C\$";
          }
          print(
              "FirestoreUtils: Currency Loaded - Symbol: ${Constant.currencyModel?.symbol}");
        } else {
          print("FirestoreUtils: Currency document not found or data is null.");
          // Set default currency if not found
          Constant.currencyModel = CurrencyModel(
              id: "default",
              code: "CAD",
              decimalDigits: 2,
              enable: true,
              name: "Canadian Dollar",
              symbol: "C\$",
              symbolAtRight: false);
        }
      });
    } catch (error) {
      print("FirestoreUtils: Error loading settings - $error");
      // Set default values on error
      if (Constant.currencyModel == null) {
        Constant.currencyModel = CurrencyModel(
            id: "error_default",
            code: "CAD",
            decimalDigits: 2,
            enable: true,
            name: "Canadian Dollar",
            symbol: "C\$",
            symbolAtRight: false);
      }
    }
  }

  static String getCurrentUid() {
    return FirebaseAuth.instance.currentUser!.uid;
  }

  static Future updateReferralAmount(OrderModel orderModel) async {
    ReferralModel? referralModel;
    await fireStore
        .collection(CollectionName.referral)
        .doc(orderModel.userId)
        .get()
        .then((value) {
      if (value.data() != null) {
        referralModel = ReferralModel.fromJson(value.data()!);
      } else {
        return;
      }
    });
    if (referralModel != null) {
      if (referralModel!.referralBy != null &&
          referralModel!.referralBy!.isNotEmpty) {
        await fireStore
            .collection(CollectionName.users)
            .doc(referralModel!.referralBy)
            .get()
            .then((value) async {
          DocumentSnapshot<Map<String, dynamic>> userDocument = value;
          if (userDocument.data() != null && userDocument.exists) {
            try {
              print(userDocument.data());
              UserModel user = UserModel.fromJson(userDocument.data()!);
              user.walletAmount = (double.parse(user.walletAmount.toString()) +
                      double.parse(Constant.referralAmount.toString()))
                  .toString();
              updateUser(user);

              WalletTransactionModel transactionModel = WalletTransactionModel(
                  id: Constant.getUuid(),
                  amount: Constant.referralAmount.toString(),
                  createdDate: Timestamp.now(),
                  paymentType: "Wallet",
                  transactionId: orderModel.id,
                  userId: orderModel.driverId.toString(),
                  orderType: "city",
                  userType: "customer",
                  note: "Referral Amount");

              await FireStoreUtils.setWalletTransaction(transactionModel);
            } catch (error) {
              print(error);
            }
          }
        });
      } else {
        return;
      }
    }
  }

  static Future<bool> getIntercityFirstOrderOrNOt(
      InterCityOrderModel orderModel) async {
    bool isFirst = true;
    await fireStore
        .collection(CollectionName.ordersIntercity)
        .where('userId', isEqualTo: orderModel.userId)
        .get()
        .then((value) {
      if (value.size == 1) {
        isFirst = true;
      } else {
        isFirst = false;
      }
    });
    return isFirst;
  }

  static Future updateIntercityReferralAmount(
      InterCityOrderModel orderModel) async {
    ReferralModel? referralModel;
    await fireStore
        .collection(CollectionName.referral)
        .doc(orderModel.userId)
        .get()
        .then((value) {
      if (value.data() != null) {
        referralModel = ReferralModel.fromJson(value.data()!);
      } else {
        return;
      }
    });
    if (referralModel != null) {
      if (referralModel!.referralBy != null &&
          referralModel!.referralBy!.isNotEmpty) {
        await fireStore
            .collection(CollectionName.users)
            .doc(referralModel!.referralBy)
            .get()
            .then((value) async {
          DocumentSnapshot<Map<String, dynamic>> userDocument = value;
          if (userDocument.data() != null && userDocument.exists) {
            try {
              print(userDocument.data());
              UserModel user = UserModel.fromJson(userDocument.data()!);
              user.walletAmount = (double.parse(user.walletAmount.toString()) +
                      double.parse(Constant.referralAmount.toString()))
                  .toString();
              updateUser(user);

              WalletTransactionModel transactionModel = WalletTransactionModel(
                  id: Constant.getUuid(),
                  amount: Constant.referralAmount.toString(),
                  createdDate: Timestamp.now(),
                  paymentType: "Wallet",
                  transactionId: orderModel.id,
                  userId: orderModel.driverId.toString(),
                  orderType: "intercity",
                  userType: "customer",
                  note: "Referral Amount");

              await FireStoreUtils.setWalletTransaction(transactionModel);
            } catch (error) {
              print(error);
            }
          }
        });
      } else {
        return;
      }
    }
  }

  /// Enhanced getUserProfile with better error handling and caching
  static Future<UserModel?> getUserProfile(String uuid) async {
    if (uuid.isEmpty) {
      print("getUserProfile: Empty UUID provided");
      return null;
    }

    UserModel? userModel;
    try {
      await fireStore
          .collection(CollectionName.users)
          .doc(uuid)
          .get()
          .then((value) {
        if (value.exists && value.data() != null) {
          userModel = UserModel.fromJson(value.data()!);
          print("getUserProfile: Successfully loaded user $uuid");

          // Call commission debug when user profile is loaded
          _debugCommissionOnUserLoad();
        } else {
          print("getUserProfile: User document not found for $uuid");
        }
      });
    } catch (error) {
      print("getUserProfile: Failed to load user $uuid: $error");
      userModel = null;
    }
    return userModel;
  }

  /// Commission debug method called when user profile is loaded
  static Future<void> _debugCommissionOnUserLoad() async {
    try {
      print("\n=== COMMISSION DEBUG (Triggered by getUserProfile) ===");

      // 1. Check current commission state
      print("\n1️⃣ Current commission state:");
      if (Constant.adminCommission != null) {
        print("   ✅ Commission loaded in memory:");
        print("      Enabled: ${Constant.adminCommission!.isEnabled}");
        print("      Type: '${Constant.adminCommission!.type}'");
        print("      Amount: '${Constant.adminCommission!.amount}'");

        // Check flat rate promotion
        if (Constant.adminCommission!.flatRatePromotion != null) {
          print(
              "      Flat Rate Enabled: ${Constant.adminCommission!.flatRatePromotion!.isEnabled}");
          print(
              "      Flat Rate Amount: ${Constant.adminCommission!.flatRatePromotion!.amount}");
        } else {
          print("      Flat Rate: Not configured");
        }

        // Check payment methods
        print(
            "      Has Both Methods: ${Constant.adminCommission!.hasBothPaymentMethods}");
        print(
            "      Has Only Commission: ${Constant.adminCommission!.hasOnlyCommission}");
        print(
            "      Has Only Flat Rate: ${Constant.adminCommission!.hasOnlyFlatRate}");
      } else {
        print("   ❌ No commission loaded in memory");
      }

      // 2. Check Firebase directly
      print("\n2️⃣ Checking Firebase commission document...");
      final commissionDoc = await FirebaseFirestore.instance
          .collection(CollectionName.settings)
          .doc("adminCommission")
          .get();

      if (commissionDoc.exists && commissionDoc.data() != null) {
        print("   ✅ Commission document exists");
        final data = commissionDoc.data()!;

        // Show all available fields
        print("   Available fields in document:");
        data.forEach((key, value) {
          print("      $key: $value (${value.runtimeType})");
        });

        // Parse with your model's structure
        final commission = AdminCommission.fromJson(data);

        print("\n   Parsed AdminCommission:");
        print("      amount: '${commission.amount}'");
        print("      isEnabled: ${commission.isEnabled}");
        print("      type: '${commission.type}'");

        if (commission.flatRatePromotion != null) {
          print(
              "      flatRatePromotion.isEnabled: ${commission.flatRatePromotion!.isEnabled}");
          print(
              "      flatRatePromotion.amount: ${commission.flatRatePromotion!.amount}");
        } else {
          print("      flatRatePromotion: null");
        }

        // Test calculations
        final testAmount = 100.0;
        print("\n3️⃣ Test calculations with ride amount: \$$testAmount");

        if (commission.isEnabled == true &&
            commission.amount != null &&
            commission.type != null) {
          final commissionResult =
              commission.calculateCommissionAmount(testAmount);
          print(
              "   Commission calculation: \$${commissionResult.toStringAsFixed(2)}");

          if (commission.type == "fix") {
            print("   Type: Fixed amount (\$${commission.amount})");
          } else {
            print("   Type: Percentage (${commission.amount}%)");
          }
        } else {
          print("   ❌ Regular commission not enabled or configured");
        }

        if (commission.flatRatePromotion?.isEnabled == true) {
          final flatRateResult = commission.getFlatRateAmount();
          print("   Flat Rate amount: \$${flatRateResult.toStringAsFixed(2)}");
        } else {
          print("   ❌ Flat rate promotion not enabled");
        }

        // Test the Constant.calculateOrderAdminCommission function
        print("\n4️⃣ Testing Constant.calculateOrderAdminCommission():");
        final constantResult = Constant.calculateOrderAdminCommission(
          amount: testAmount.toString(),
          adminCommission: commission,
        );
        print("   Result: \$${constantResult.toStringAsFixed(2)}");
      } else {
        print("   ❌ Commission document does not exist or is empty");
        print("   Path: ${CollectionName.settings}/adminCommission");
      }

      print("\n=== END COMMISSION DEBUG ===");
    } catch (e) {
      print("❌ Commission debug error: $e");
      print("Stack trace: ${e.toString()}");
    }
  }

  /// Enhanced getDriver with better error handling and validation
  static Future<DriverUserModel?> getDriver(String uuid) async {
    if (uuid.isEmpty) {
      print("getDriver: Empty UUID provided");
      return null;
    }

    DriverUserModel? driverUserModel;
    try {
      await fireStore
          .collection(CollectionName.driverUsers)
          .doc(uuid)
          .get()
          .then((value) {
        if (value.exists && value.data() != null) {
          driverUserModel = DriverUserModel.fromJson(value.data()!);
          print("getDriver: Successfully loaded driver $uuid");

          // Validate critical driver fields
          if (driverUserModel!.fullName == null ||
              driverUserModel!.fullName!.isEmpty) {
            print("getDriver: Warning - Driver $uuid has no name");
          }
          if (driverUserModel!.phoneNumber == null ||
              driverUserModel!.phoneNumber!.isEmpty) {
            print("getDriver: Warning - Driver $uuid has no phone number");
          }
          if (driverUserModel!.vehicleInformation == null) {
            print(
                "getDriver: Warning - Driver $uuid has no vehicle information");
          }
        } else {
          print("getDriver: Driver document not found for $uuid");
        }
      });
    } catch (error) {
      print("getDriver: Failed to load driver $uuid: $error");
      driverUserModel = null;
    }
    return driverUserModel;
  }

  /// Enhanced method to get driver with retry mechanism
  static Future<DriverUserModel?> getDriverWithRetry(String uuid,
      {int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print("🔄 Attempt $attempt to load driver: $uuid");

        final doc = await fireStore
            .collection(CollectionName.driverUsers)
            .doc(uuid)
            .get()
            .timeout(const Duration(seconds: 10));

        if (doc.exists && doc.data() != null) {
          final driver = DriverUserModel.fromJson(doc.data()!);
          print("✅ Driver loaded successfully on attempt $attempt");
          return driver;
        } else {
          print("❌ Driver document not found on attempt $attempt");
        }
      } catch (e) {
        print("❌ Error loading driver on attempt $attempt: $e");
        if (attempt == maxRetries) {
          print("❌ All retry attempts failed for driver: $uuid");
          return null;
        }
        // Wait before retrying
        await Future.delayed(Duration(seconds: attempt));
      }
    }
    return null;
  }

  /// Debug method to analyze driver assignment issues
  Future<void> debugDriverAssignmentIssue(String orderId) async {
    try {
      print("🔍 DEBUGGING DRIVER ASSIGNMENT FOR ORDER: $orderId");

      // Check main order document
      final orderDoc =
          await fireStore.collection(CollectionName.orders).doc(orderId).get();
      if (orderDoc.exists) {
        final orderData = orderDoc.data();
        print(
            "📋 Order data: ${orderData?['driverId']} | Status: ${orderData?['status']}");
      }

      // Check accepted drivers subcollection
      final acceptedDrivers = await fireStore
          .collection(CollectionName.orders)
          .doc(orderId)
          .collection("acceptedDriver")
          .get();

      print("👥 Accepted drivers count: ${acceptedDrivers.size}");
      for (var doc in acceptedDrivers.docs) {
        print("   - Driver: ${doc.id} | Data: ${doc.data()}");
      }
    } catch (e) {
      print("❌ Error in debug analysis: $e");
    }
  }

  /// Method to recover driver assignment for orders
  static Future<bool> recoverDriverAssignment(String orderId) async {
    try {
      print("🔧 Attempting to recover driver assignment for order: $orderId");

      // Check if there are accepted drivers
      final acceptedDrivers = await fireStore
          .collection(CollectionName.orders)
          .doc(orderId)
          .collection("acceptedDriver")
          .get();

      if (acceptedDrivers.docs.isNotEmpty) {
        final driverId = acceptedDrivers.docs.first.id;
        print("🔧 Found accepted driver: $driverId");

        // Update the main order document
        await fireStore.collection(CollectionName.orders).doc(orderId).update({
          'driverId': driverId,
          'updateDate': FieldValue.serverTimestamp(),
        });

        print("✅ Driver assignment recovered successfully");
        return true;
      } else {
        print("❌ No accepted drivers found for recovery");
        return false;
      }
    } catch (e) {
      print("❌ Error recovering driver assignment: $e");
      return false;
    }
  }

  /// Validate order completion requirements
  static Future<bool> validateOrderCompletion(String orderId) async {
    try {
      final order = await getOrder(orderId);
      if (order == null) {
        print("❌ Order not found: $orderId");
        return false;
      }

      // Critical validation: Must have a driver assigned
      if (order.driverId == null || order.driverId!.isEmpty) {
        print("❌ CRITICAL: Cannot complete order without driver assignment!");
        print("   Order: $orderId");
        print("   Status: ${order.status}");

        // Attempt automatic recovery
        final recoverySuccess = await recoverDriverAssignment(orderId);
        return recoverySuccess;
      }

      print("✅ Order validation passed - Driver assigned: ${order.driverId}");
      return true;
    } catch (e) {
      print("❌ Order validation failed: $e");
      return false;
    }
  }

  static Future<bool> updateUser(UserModel userModel) async {
    bool isUpdate = false;
    try {
      await fireStore
          .collection(CollectionName.users)
          .doc(userModel.id)
          .set(userModel.toJson())
          .whenComplete(() {
        isUpdate = true;
      });
    } catch (error) {
      print("Failed to update user: $error");
      isUpdate = false;
    }
    return isUpdate;
  }

  static Future<bool> updateDriver(DriverUserModel userModel) async {
    bool isUpdate = false;
    try {
      await fireStore
          .collection(CollectionName.driverUsers)
          .doc(userModel.id)
          .set(userModel.toJson())
          .whenComplete(() {
        isUpdate = true;
      });
    } catch (error) {
      print("Failed to update driver: $error");
      isUpdate = false;
    }
    return isUpdate;
  }

  static Future<bool> getFirestOrderOrNOt(OrderModel orderModel) async {
    bool isFirst = true;
    await fireStore
        .collection(CollectionName.orders)
        .where('userId', isEqualTo: orderModel.userId)
        .get()
        .then((value) {
      if (value.size == 1) {
        isFirst = true;
      } else {
        isFirst = false;
      }
    });
    return isFirst;
  }

  static Future<bool?> rejectRide(
      OrderModel orderModel, DriverIdAcceptReject driverIdAcceptReject) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.orders)
        .doc(orderModel.id)
        .collection("rejectedDriver")
        .doc(driverIdAcceptReject.driverId)
        .set(driverIdAcceptReject.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      print("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<OrderModel?> getOrder(String orderId) async {
    OrderModel? orderModel;
    try {
      await fireStore
          .collection(CollectionName.orders)
          .doc(orderId)
          .get()
          .then((value) {
        if (value.exists && value.data() != null) {
          orderModel = OrderModel.fromJson(value.data()!);
        }
      });
    } catch (error) {
      print("getOrder: Error loading order $orderId: $error");
    }
    return orderModel;
  }

  static Future<InterCityOrderModel?> getInterCityOrder(String orderId) async {
    InterCityOrderModel? orderModel;
    try {
      await fireStore
          .collection(CollectionName.ordersIntercity)
          .doc(orderId)
          .get()
          .then((value) {
        if (value.exists && value.data() != null) {
          orderModel = InterCityOrderModel.fromJson(value.data()!);
        }
      });
    } catch (error) {
      print("getInterCityOrder: Error loading order $orderId: $error");
    }
    return orderModel;
  }

  static Future<bool> userExitOrNot(String uid) async {
    bool isExit = false;
    try {
      await fireStore
          .collection(CollectionName.users)
          .doc(uid)
          .get()
          .then((value) {
        if (value.exists) {
          isExit = true;
        } else {
          isExit = false;
        }
      });
    } catch (error) {
      print("Failed to check user existence: $error");
      isExit = false;
    }
    return isExit;
  }

  static Future<List<ServiceModel>> getService() async {
    List<ServiceModel> serviceList = [];
    try {
      await fireStore
          .collection(CollectionName.service)
          .where('enable', isEqualTo: true)
          .get()
          .then((value) {
        for (var element in value.docs) {
          ServiceModel documentModel = ServiceModel.fromJson(element.data());
          serviceList.add(documentModel);
        }
      });
    } catch (error) {
      print("getService error: $error");
    }
    return serviceList;
  }

  static Future<List<BannerModel>> getBanner() async {
    List<BannerModel> bannerList = [];
    try {
      await fireStore
          .collection(CollectionName.banner)
          .where('enable', isEqualTo: true)
          .where('isDeleted', isEqualTo: false)
          .orderBy('position', descending: false)
          .get()
          .then((value) {
        for (var element in value.docs) {
          BannerModel documentModel = BannerModel.fromJson(element.data());
          bannerList.add(documentModel);
        }
      });
    } catch (error) {
      print("getBanner error: $error");
    }
    return bannerList;
  }

  static Future<List<IntercityServiceModel>> getIntercityService() async {
    List<IntercityServiceModel> serviceList = [];
    try {
      await fireStore
          .collection(CollectionName.intercityService)
          .where('enable', isEqualTo: true)
          .get()
          .then((value) {
        for (var element in value.docs) {
          IntercityServiceModel documentModel =
              IntercityServiceModel.fromJson(element.data());
          serviceList.add(documentModel);
        }
      });
    } catch (error) {
      print("getIntercityService error: $error");
    }
    return serviceList;
  }

  static Future<List<FreightVehicle>> getFreightVehicle() async {
    List<FreightVehicle> freightVehicle = [];
    try {
      await fireStore
          .collection(CollectionName.freightVehicle)
          .where('enable', isEqualTo: true)
          .get()
          .then((value) {
        for (var element in value.docs) {
          FreightVehicle documentModel =
              FreightVehicle.fromJson(element.data());
          freightVehicle.add(documentModel);
        }
      });
    } catch (error) {
      print("getFreightVehicle error: $error");
    }
    return freightVehicle;
  }

  static Future<bool?> setOrder(OrderModel orderModel) async {
    bool isAdded = false;
    try {
      // CRITICAL FIX: Ensure commission data is always included
      if (orderModel.adminCommission == null) {
        print("💡 Adding missing admin commission to order before saving");
        if (Constant.adminCommission != null) {
          orderModel.adminCommission = Constant.adminCommission;
          print("✅ Commission added: ${Constant.adminCommission!.toJson()}");
        } else {
          print("❌ Cannot add commission: Constant.adminCommission is null");
          // Create a default commission to avoid null errors
          orderModel.adminCommission = AdminCommission(
              isEnabled: false,
              type: "percentage",
              amount: "0",
              flatRatePromotion:
                  FlatRatePromotion(isEnabled: false, amount: 0.0));
        }
      }

      await fireStore
          .collection(CollectionName.orders)
          .doc(orderModel.id)
          .set(orderModel.toJson())
          .then((value) {
        isAdded = true;
        print("setOrder: Successfully saved order ${orderModel.id}");

        // Debug: Verify commission was saved
        if (orderModel.adminCommission != null) {
          print("   Commission data saved:");
          print("     Enabled: ${orderModel.adminCommission!.isEnabled}");
          print("     Type: ${orderModel.adminCommission!.type}");
          print("     Amount: ${orderModel.adminCommission!.amount}");
        } else {
          print("   ⚠️ WARNING: No commission data in saved order");
        }
      });
    } catch (error) {
      print("setOrder: Failed to save order ${orderModel.id}: $error");
      isAdded = false;
    }
    return isAdded;
  }

  StreamController<List<DriverUserModel>>? getNearestOrderRequestController;

  Stream<List<DriverUserModel>> sendOrderData(OrderModel orderModel) async* {
    getNearestOrderRequestController ??=
        StreamController<List<DriverUserModel>>.broadcast();

    List<DriverUserModel> ordersList = [];
    Query<Map<String, dynamic>> query = fireStore
        .collection(CollectionName.driverUsers)
        .where('serviceId', isEqualTo: orderModel.serviceId)
        .where('zoneId', arrayContains: orderModel.zoneId)
        .where('isOnline', isEqualTo: true);
    GeoFirePoint center = Geoflutterfire().point(
        latitude: orderModel.sourceLocationLAtLng!.latitude ?? 0.0,
        longitude: orderModel.sourceLocationLAtLng!.longitude ?? 0.0);
    Stream<List<DocumentSnapshot>> stream = Geoflutterfire()
        .collection(collectionRef: query)
        .within(
            center: center,
            radius: double.parse(Constant.radius),
            field: 'position',
            strictMode: true);

    stream.listen((List<DocumentSnapshot> documentList) {
      ordersList.clear();
      if (getNearestOrderRequestController != null) {
        for (var document in documentList) {
          final data = document.data() as Map<String, dynamic>;
          DriverUserModel orderModel = DriverUserModel.fromJson(data);
          ordersList.add(orderModel);
        }

        if (!getNearestOrderRequestController!.isClosed) {
          getNearestOrderRequestController!.sink.add(ordersList);
        }
        closeStream();
      }
    });
    yield* getNearestOrderRequestController!.stream;
  }

  closeStream() {
    if (getNearestOrderRequestController != null) {
      getNearestOrderRequestController == null;
      getNearestOrderRequestController!.close();
    }
  }

  /// Enhanced method to find and notify nearby drivers
  static Stream<List<DriverUserModel>> findNearbyDrivers(
      OrderModel orderModel) {
    try {
      print("🔍 [DEBUG] Starting driver search with zone validation...");
      print("🎯 Search criteria:");
      print("   Service ID: ${orderModel.serviceId}");
      print("   Zone ID: ${orderModel.zoneId}");
      print(
          "   Source Location: ${orderModel.sourceLocationLAtLng?.latitude}, ${orderModel.sourceLocationLAtLng?.longitude}");

      // Create base query - REMOVE the zone filter from the query
      Query<Map<String, dynamic>> query = fireStore
          .collection(CollectionName.driverUsers)
          .where('isOnline', isEqualTo: true)
          .where('documentVerification', isEqualTo: true)
          .where('serviceId', isEqualTo: orderModel.serviceId);

      // DEBUG: Print the actual query being executed
      print("📋 Executing query with filters:");
      print("   - isOnline: true");
      print("   - documentVerification: true");
      print("   - serviceId: ${orderModel.serviceId}");

      return query.snapshots().map((querySnapshot) {
        print("📦 Query returned ${querySnapshot.size} drivers");

        List<DriverUserModel> availableDrivers = [];

        for (var doc in querySnapshot.docs) {
          try {
            final driver = DriverUserModel.fromJson(doc.data());
            print("👤 Found driver: ${driver.fullName} (${doc.id})");
            print("   Zones: ${driver.zoneIds}");

            // MANUAL ZONE VALIDATION - Check if driver has the required zone
            if (orderModel.zoneId != null &&
                orderModel.zoneId!.isNotEmpty &&
                driver.zoneIds != null &&
                driver.zoneIds!.contains(orderModel.zoneId)) {
              print("   ✅ Driver has required zone: ${orderModel.zoneId}");

              // Manual distance calculation
              if (driver.location?.latitude != null &&
                  driver.location?.longitude != null &&
                  orderModel.sourceLocationLAtLng?.latitude != null &&
                  orderModel.sourceLocationLAtLng?.longitude != null) {
                final double distance = _calculateDistance(
                  orderModel.sourceLocationLAtLng!.latitude!,
                  orderModel.sourceLocationLAtLng!.longitude!,
                  driver.location!.latitude!,
                  driver.location!.longitude!,
                );

                double searchRadius = double.tryParse(Constant.radius) ?? 10.0;

                if (distance <= searchRadius) {
                  availableDrivers.add(driver);
                  print(
                      "   ✅ Added driver: ${driver.fullName} - Distance: ${distance.toStringAsFixed(2)} km");
                } else {
                  print(
                      "   ❌ Driver too far: ${distance.toStringAsFixed(2)} km > $searchRadius km");
                }
              } else {
                print("   ⚠️  Skipping driver - missing location data");
              }
            } else {
              print("   ❌ Driver missing required zone: ${orderModel.zoneId}");
            }
          } catch (e) {
            print("❌ Error parsing driver document: $e");
          }
        }

        print("🎉 Final available drivers: ${availableDrivers.length}");
        return availableDrivers;
      });
    } catch (e) {
      print("❌ Error in findNearbyDrivers: $e");
      return Stream.value([]);
    }
  }

// Add this helper method to calculate distance
  static double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Send ride request to multiple drivers
  static Future<bool> sendRideRequestToDrivers(
      OrderModel orderModel, List<DriverUserModel> drivers) async {
    try {
      print("📤 Sending ride request to ${drivers.length} drivers");

      if (drivers.isEmpty) {
        print("❌ No drivers available to send request");
        return false;
      }

      // Save the order first
      bool orderSaved = await setOrder(orderModel) ?? false;
      if (!orderSaved) {
        print("❌ Failed to save order to Firebase");
        return false;
      }

      print("✅ Order saved successfully: ${orderModel.id}");

      // Send notifications to all available drivers
      List<Future> notificationFutures = [];

      for (DriverUserModel driver in drivers) {
        if (driver.fcmToken != null && driver.fcmToken!.isNotEmpty) {
          Map<String, dynamic> payload = {
            "type": "city_order",
            "orderId": orderModel.id,
            "sourceLatitude":
                orderModel.sourceLocationLAtLng?.latitude?.toString(),
            "sourceLongitude":
                orderModel.sourceLocationLAtLng?.longitude?.toString(),
            "destinationLatitude":
                orderModel.destinationLocationLAtLng?.latitude?.toString(),
            "destinationLongitude":
                orderModel.destinationLocationLAtLng?.longitude?.toString(),
            "sourceLocation": orderModel.sourceLocationName,
            "destinationLocation": orderModel.destinationLocationName,
            "offerRate": orderModel.offerRate,
            "distance": orderModel.distance,
            "paymentType": orderModel.paymentType,
          };

          notificationFutures.add(SendNotification.sendOneNotification(
            token: driver.fcmToken!,
            title: 'New Ride Available'.tr,
            body: 'A customer has placed a ride near your location.'.tr,
            payload: payload,
          ).then((success) {
            if (success) {
              print("✅ Notification sent to driver: ${driver.fullName}");
            } else {
              print(
                  "❌ Failed to send notification to driver: ${driver.fullName}");
            }
            return success;
          }).catchError((error) {
            print("❌ Error sending notification to ${driver.fullName}: $error");
            return false;
          }));
        } else {
          print("⚠️ Driver ${driver.fullName} has no FCM token");
        }
      }

      // Wait for all notifications to complete
      List<dynamic> results = await Future.wait(notificationFutures);
      int successCount = results.where((result) => result == true).length;

      print(
          "📊 Notification results: $successCount/${drivers.length} successful");

      return successCount > 0;
    } catch (e) {
      print("❌ Error in sendRideRequestToDrivers: $e");
      return false;
    }
  }

  /// Enhanced method to place a ride with better error handling and driver finding
  static Future<bool> placeRideRequest(OrderModel orderModel) async {
    try {
      print("🚀 [DEBUG] Starting ride request process...");

      await debugQueryResults(orderModel);

      // Validate order data
      if (orderModel.sourceLocationLAtLng?.latitude == null ||
          orderModel.sourceLocationLAtLng?.longitude == null) {
        ShowToastDialog.showToast("Invalid pickup location");
        print("❌ [DEBUG] Invalid pickup location coordinates");
        return false;
      }

      if (orderModel.destinationLocationLAtLng?.latitude == null ||
          orderModel.destinationLocationLAtLng?.longitude == null) {
        ShowToastDialog.showToast("Invalid destination location");
        print("❌ [DEBUG] Invalid destination location coordinates");
        return false;
      }

      if (orderModel.serviceId == null || orderModel.serviceId!.isEmpty) {
        ShowToastDialog.showToast("Please select a service type");
        print("❌ [DEBUG] No service ID specified");
        return false;
      }

      print("✅ [DEBUG] Order validation passed");
      ShowToastDialog.showLoader("Finding nearby drivers...");

      // Find nearby drivers
      bool driversFound = false;
      List<DriverUserModel> availableDrivers = [];

      // Listen to the stream for a limited time
      StreamSubscription? driverSubscription;
      Completer<bool> completer = Completer<bool>();

      Timer timeoutTimer = Timer(const Duration(seconds: 15), () {
        if (!completer.isCompleted) {
          print("⏰ [DEBUG] Driver search timeout after 15 seconds");
          completer.complete(false);
        }
      });

      print("🔍 [DEBUG] Starting driver search stream...");
      driverSubscription = findNearbyDrivers(orderModel).listen(
        (List<DriverUserModel> drivers) {
          print("📦 [DEBUG] Received ${drivers.length} drivers from stream");
          if (!completer.isCompleted && drivers.isNotEmpty) {
            availableDrivers = drivers;
            driversFound = true;
            print("✅ [DEBUG] Drivers found successfully");
            completer.complete(true);
          } else if (!completer.isCompleted) {
            print("⚠️ [DEBUG] Empty driver list received");
          }
        },
        onError: (error) {
          print("❌ [DEBUG] Error in driver stream: $error");
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
        onDone: () {
          print("🏁 [DEBUG] Driver stream completed");
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      );

      // Wait for drivers to be found or timeout
      driversFound = await completer.future;

      // Clean up
      timeoutTimer.cancel();
      await driverSubscription?.cancel();

      ShowToastDialog.closeLoader();

      if (!driversFound || availableDrivers.isEmpty) {
        print("❌ [DEBUG] No drivers available after search");

        // Debug: Check what's in the database
        print("🔍 [DEBUG] Checking database for potential issues...");

        // Check if there are any online drivers at all
        final onlineDrivers = await fireStore
            .collection(CollectionName.driverUsers)
            .where('isOnline', isEqualTo: true)
            .limit(5)
            .get();

        print(
            "👥 [DEBUG] Total online drivers in database: ${onlineDrivers.size}");

        if (onlineDrivers.size > 0) {
          onlineDrivers.docs.forEach((doc) {
            final driver = DriverUserModel.fromJson(doc.data());
            print("👤 [DEBUG] Online driver: ${driver.fullName}");
            print(
                "📍 [DEBUG] Location: ${driver.location?.latitude}, ${driver.location?.longitude}");
            print("🗺️ [DEBUG] Zone IDs: ${driver.zoneIds}");
            print("🚗 [DEBUG] Service ID: ${driver.serviceId}");

            // Calculate distance from order location
            if (driver.location?.latitude != null &&
                driver.location?.longitude != null) {
              final distance = _calculateDistance(
                orderModel.sourceLocationLAtLng!.latitude!,
                orderModel.sourceLocationLAtLng!.longitude!,
                driver.location!.latitude!,
                driver.location!.longitude!,
              );
              print(
                  "📏 [DEBUG] Distance from order: ${distance.toStringAsFixed(2)} km");
            }
          });
        }

        ShowToastDialog.showToast(
            "No drivers available in your area. Please try again later.");
        return false;
      }

      // Send ride request to found drivers
      print(
          "📤 [DEBUG] Sending ride request to ${availableDrivers.length} drivers");
      bool requestSent =
          await sendRideRequestToDrivers(orderModel, availableDrivers);

      if (requestSent) {
        ShowToastDialog.showToast("Ride request sent! Looking for a driver...");
        return true;
      } else {
        ShowToastDialog.showToast(
            "Failed to send ride request. Please try again.");
        return false;
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      print("❌ [DEBUG] Error in placeRideRequest: $e");
      print("📋 [DEBUG] Stack trace: ${e.toString()}");
      ShowToastDialog.showToast(
          "Failed to place ride request: ${e.toString()}");
      return false;
    }
  }

  /// Monitor ride status and driver updates
  static Stream<OrderModel?> monitorRideStatus(String orderId) {
    return fireStore
        .collection(CollectionName.orders)
        .doc(orderId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return OrderModel.fromJson(snapshot.data()!);
      }
      return null;
    });
  }

  /// Get driver location updates for live tracking
  static Stream<DriverUserModel?> getDriverLocationUpdates(String driverId) {
    return fireStore
        .collection(CollectionName.driverUsers)
        .doc(driverId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return DriverUserModel.fromJson(snapshot.data()!);
      }
      return null;
    });
  }

  static Future<bool?> setInterCityOrder(InterCityOrderModel orderModel) async {
    bool isAdded = false;
    try {
      await fireStore
          .collection(CollectionName.ordersIntercity)
          .doc(orderModel.id)
          .set(orderModel.toJson())
          .then((value) {
        isAdded = true;
      });
    } catch (error) {
      print("Failed to save intercity order: $error");
      isAdded = false;
    }
    return isAdded;
  }

  static Future<DriverIdAcceptReject?> getAcceptedOrders(
      String orderId, String driverId) async {
    DriverIdAcceptReject? driverIdAcceptReject;
    try {
      await fireStore
          .collection(CollectionName.orders)
          .doc(orderId)
          .collection("acceptedDriver")
          .doc(driverId)
          .get()
          .then((value) async {
        if (value.exists && value.data() != null) {
          driverIdAcceptReject = DriverIdAcceptReject.fromJson(value.data()!);
        }
      });
    } catch (error) {
      print("getAcceptedOrders: Failed to load accepted order: $error");
      driverIdAcceptReject = null;
    }
    return driverIdAcceptReject;
  }

  static Future<DriverIdAcceptReject?> getInterCItyAcceptedOrders(
      String orderId, String driverId) async {
    DriverIdAcceptReject? driverIdAcceptReject;
    try {
      await fireStore
          .collection(CollectionName.ordersIntercity)
          .doc(orderId)
          .collection("acceptedDriver")
          .doc(driverId)
          .get()
          .then((value) async {
        if (value.exists && value.data() != null) {
          driverIdAcceptReject = DriverIdAcceptReject.fromJson(value.data()!);
        }
      });
    } catch (error) {
      print(
          "getInterCItyAcceptedOrders: Failed to load accepted order: $error");
      driverIdAcceptReject = null;
    }
    return driverIdAcceptReject;
  }

  static Future<OrderModel?> getOrderById(String orderId) async {
    OrderModel? orderModel;
    try {
      await fireStore
          .collection(CollectionName.orders)
          .doc(orderId)
          .get()
          .then((value) async {
        if (value.exists && value.data() != null) {
          orderModel = OrderModel.fromJson(value.data()!);
        }
      });
    } catch (error) {
      print("getOrderById: Failed to load order $orderId: $error");
      orderModel = null;
    }
    return orderModel;
  }

  Future<PaymentModel?> getPayment() async {
    try {
      PaymentModel? paymentModel;
      await fireStore
          .collection(CollectionName.settings)
          .doc("payment")
          .get()
          .then((value) {
        if (value.exists && value.data() != null) {
          paymentModel = PaymentModel.fromJson(value.data()!);
        }
      });
      return paymentModel;
    } catch (e) {
      print("Error getting payment data: $e");
      return null;
    }
  }

  Future<CurrencyModel?> getCurrency() async {
    CurrencyModel? currencyModel;
    try {
      await fireStore
          .collection(CollectionName.currency)
          .where("enable", isEqualTo: true)
          .get()
          .then((value) {
        if (value.docs.isNotEmpty) {
          currencyModel = CurrencyModel.fromJson(value.docs.first.data());
        }
      });
    } catch (error) {
      print("getCurrency error: $error");
    }
    return currencyModel;
  }

  Future<List<TaxModel>?> getTaxList() async {
    List<TaxModel> taxList = [];
    try {
      await fireStore
          .collection(CollectionName.tax)
          .where('country', isEqualTo: Constant.country)
          .where('enable', isEqualTo: true)
          .get()
          .then((value) {
        for (var element in value.docs) {
          TaxModel taxModel = TaxModel.fromJson(element.data());
          taxList.add(taxModel);
        }
      });
    } catch (error) {
      print("getTaxList error: $error");
    }
    return taxList;
  }

  Future<List<CouponModel>?> getCoupon() async {
    List<CouponModel> couponModel = [];
    try {
      await fireStore
          .collection(CollectionName.coupon)
          .where('enable', isEqualTo: true)
          .where("isPublic", isEqualTo: true)
          .where('isDeleted', isEqualTo: false)
          .where('validity', isGreaterThanOrEqualTo: Timestamp.now())
          .get()
          .then((value) {
        for (var element in value.docs) {
          CouponModel taxModel = CouponModel.fromJson(element.data());
          couponModel.add(taxModel);
        }
      });
    } catch (error) {
      print("getCoupon error: $error");
    }
    return couponModel;
  }

  static Future<bool?> setReview(ReviewModel reviewModel) async {
    bool isAdded = false;
    try {
      await fireStore
          .collection(CollectionName.reviewDriver)
          .doc(reviewModel.id)
          .set(reviewModel.toJson())
          .then((value) {
        isAdded = true;
      });
    } catch (error) {
      print("Failed to set review: $error");
      isAdded = false;
    }
    return isAdded;
  }

  static Future<ReviewModel?> getReview(String orderId) async {
    ReviewModel? reviewModel;
    try {
      await fireStore
          .collection(CollectionName.reviewDriver)
          .doc(orderId)
          .get()
          .then((value) {
        if (value.exists && value.data() != null) {
          reviewModel = ReviewModel.fromJson(value.data()!);
        }
      });
    } catch (error) {
      print("getReview error: $error");
    }
    return reviewModel;
  }

  static Future<List<WalletTransactionModel>?> getWalletTransaction() async {
    List<WalletTransactionModel> walletTransactionModel = [];
    try {
      await fireStore
          .collection(CollectionName.walletTransaction)
          .where('userId', isEqualTo: FireStoreUtils.getCurrentUid())
          .orderBy('createdDate', descending: true)
          .get()
          .then((value) {
        for (var element in value.docs) {
          WalletTransactionModel taxModel =
              WalletTransactionModel.fromJson(element.data());
          walletTransactionModel.add(taxModel);
        }
      });
    } catch (error) {
      print("getWalletTransaction error: $error");
    }
    return walletTransactionModel;
  }

  static Future<bool?> setWalletTransaction(
      WalletTransactionModel walletTransactionModel) async {
    bool isAdded = false;
    try {
      await fireStore
          .collection(CollectionName.walletTransaction)
          .doc(walletTransactionModel.id)
          .set(walletTransactionModel.toJson())
          .then((value) {
        isAdded = true;
      });
    } catch (error) {
      print("Failed to set wallet transaction: $error");
      isAdded = false;
    }
    return isAdded;
  }

  static Future<bool?> updateUserWallet({required String amount}) async {
    bool isAdded = false;
    try {
      await getUserProfile(FireStoreUtils.getCurrentUid()).then((value) async {
        if (value != null) {
          UserModel userModel = value;
          userModel.walletAmount =
              (double.parse(userModel.walletAmount.toString()) +
                      double.parse(amount))
                  .toString();
          await FireStoreUtils.updateUser(userModel).then((value) {
            isAdded = value;
          });
        }
      });
    } catch (error) {
      print("updateUserWallet error: $error");
    }
    return isAdded;
  }

  static Future<bool?> updateDriverWallet(
      {required String driverId, required String amount}) async {
    bool isAdded = false;
    try {
      await getDriver(driverId).then((value) async {
        if (value != null) {
          DriverUserModel userModel = value;
          userModel.walletAmount =
              (double.parse(userModel.walletAmount.toString()) +
                      double.parse(amount))
                  .toString();
          await FireStoreUtils.updateDriver(userModel).then((value) {
            isAdded = value;
          });
        }
      });
    } catch (error) {
      print("updateDriverWallet error: $error");
    }
    return isAdded;
  }

  static Future<List<LanguageModel>?> getLanguage() async {
    List<LanguageModel> languageList = [];
    try {
      await fireStore.collection(CollectionName.languages).get().then((value) {
        for (var element in value.docs) {
          LanguageModel taxModel = LanguageModel.fromJson(element.data());
          languageList.add(taxModel);
        }
      });
    } catch (error) {
      print("getLanguage error: $error");
    }
    return languageList;
  }

  static Future<ReferralModel?> getReferral() async {
    ReferralModel? referralModel;
    try {
      await fireStore
          .collection(CollectionName.referral)
          .doc(FireStoreUtils.getCurrentUid())
          .get()
          .then((value) {
        if (value.exists && value.data() != null) {
          referralModel = ReferralModel.fromJson(value.data()!);
        }
      });
    } catch (error) {
      print("getReferral error: $error");
      referralModel = null;
    }
    return referralModel;
  }

  static Future<bool?> checkReferralCodeValidOrNot(String referralCode) async {
    bool? isExit;
    try {
      await fireStore
          .collection(CollectionName.referral)
          .where("referralCode", isEqualTo: referralCode)
          .get()
          .then((value) {
        if (value.size > 0) {
          isExit = true;
        } else {
          isExit = false;
        }
      });
    } catch (e, s) {
      print('checkReferralCodeValidOrNot error: $e $s');
      return false;
    }
    return isExit;
  }

  static Future<ReferralModel?> getReferralUserByCode(
      String referralCode) async {
    ReferralModel? referralModel;
    try {
      await fireStore
          .collection(CollectionName.referral)
          .where("referralCode", isEqualTo: referralCode)
          .get()
          .then((value) {
        if (value.docs.isNotEmpty) {
          referralModel = ReferralModel.fromJson(value.docs.first.data());
        }
      });
    } catch (e, s) {
      print('getReferralUserByCode error: $e $s');
      return null;
    }
    return referralModel;
  }

  static Future<String?> referralAdd(ReferralModel ratingModel) async {
    try {
      await fireStore
          .collection(CollectionName.referral)
          .doc(ratingModel.id)
          .set(ratingModel.toJson());
    } catch (e, s) {
      print('referralAdd error: $e $s');
      return null;
    }
    return null;
  }

  static Future<List<OnBoardingModel>> getOnBoardingList() async {
    List<OnBoardingModel> onBoardingModel = [];
    try {
      await fireStore
          .collection(CollectionName.onBoarding)
          .where("type", isEqualTo: "customerApp")
          .get()
          .then((value) {
        for (var element in value.docs) {
          OnBoardingModel documentModel =
              OnBoardingModel.fromJson(element.data());
          onBoardingModel.add(documentModel);
        }
      });
    } catch (error) {
      print("getOnBoardingList error: $error");
    }
    return onBoardingModel;
  }

  static Future addInBox(InboxModel inboxModel) async {
    try {
      return await fireStore
          .collection("chat")
          .doc(inboxModel.orderId)
          .set(inboxModel.toJson())
          .then((document) {
        return inboxModel;
      });
    } catch (error) {
      print("addInBox error: $error");
      return null;
    }
  }

  static Future addChat(ConversationModel conversationModel) async {
    try {
      return await fireStore
          .collection("chat")
          .doc(conversationModel.orderId)
          .collection("thread")
          .doc(conversationModel.id)
          .set(conversationModel.toJson())
          .then((document) {
        return conversationModel;
      });
    } catch (error) {
      print("addChat error: $error");
      return null;
    }
  }

  static Future<List<FaqModel>> getFaq() async {
    List<FaqModel> faqModel = [];
    try {
      await fireStore
          .collection(CollectionName.faq)
          .where('enable', isEqualTo: true)
          .get()
          .then((value) {
        for (var element in value.docs) {
          FaqModel documentModel = FaqModel.fromJson(element.data());
          faqModel.add(documentModel);
        }
      });
    } catch (error) {
      print("getFaq error: $error");
    }
    return faqModel;
  }

  static Future<bool?> deleteUser() async {
    bool? isDelete;
    try {
      await fireStore
          .collection(CollectionName.users)
          .doc(FireStoreUtils.getCurrentUid())
          .delete();
      await FirebaseAuth.instance.currentUser!.delete().then((value) {
        isDelete = true;
      });
    } catch (e, s) {
      print('deleteUser error: $e $s');
      return false;
    }
    return isDelete;
  }

  static Future<bool?> setSOS(SosModel sosModel) async {
    bool isAdded = false;
    try {
      await fireStore
          .collection(CollectionName.sos)
          .doc(sosModel.id)
          .set(sosModel.toJson())
          .then((value) {
        isAdded = true;
      });
    } catch (error) {
      print("Failed to set SOS: $error");
      isAdded = false;
    }
    return isAdded;
  }

  static Future<SosModel?> getSOS(String orderId) async {
    SosModel? sosModel;
    try {
      await fireStore
          .collection(CollectionName.sos)
          .where("orderId", isEqualTo: orderId)
          .get()
          .then((value) {
        if (value.docs.isNotEmpty) {
          sosModel = SosModel.fromJson(value.docs.first.data());
        }
      });
    } catch (e, s) {
      print('getSOS error: $e $s');
      return null;
    }
    return sosModel;
  }

  Future<List<AriPortModel>?> getAirports() async {
    List<AriPortModel> airPortList = [];
    try {
      await fireStore
          .collection(CollectionName.airPorts)
          .where('cityLocation', isEqualTo: Constant.city)
          .get()
          .then((value) {
        for (var element in value.docs) {
          AriPortModel ariPortModel = AriPortModel.fromJson(element.data());
          airPortList.add(ariPortModel);
        }
      });
    } catch (error) {
      print("getAirports error: $error");
    }
    return airPortList;
  }

  static Future<bool> paymentStatusCheck() async {
    ShowToastDialog.showLoader("Please wait");
    bool isFirst = false;
    try {
      await fireStore
          .collection(CollectionName.orders)
          .where('userId', isEqualTo: FireStoreUtils.getCurrentUid())
          .where("status", isEqualTo: Constant.rideComplete)
          .where("paymentStatus", isEqualTo: false)
          .get()
          .then((value) {
        ShowToastDialog.closeLoader();
        if (value.size >= 1) {
          isFirst = true;
        } else {
          isFirst = false;
        }
      });
    } catch (error) {
      ShowToastDialog.closeLoader();
      print("paymentStatusCheck error: $error");
    }
    return isFirst;
  }

  static Future<bool> paymentStatusCheckIntercity() async {
    ShowToastDialog.showLoader("Please wait");
    bool isFirst = false;
    try {
      await fireStore
          .collection(CollectionName.ordersIntercity)
          .where('userId', isEqualTo: FireStoreUtils.getCurrentUid())
          .where("status", isEqualTo: Constant.rideComplete)
          .where("paymentStatus", isEqualTo: false)
          .get()
          .then((value) {
        ShowToastDialog.closeLoader();
        print(value.size);
        if (value.size >= 1) {
          isFirst = true;
        } else {
          isFirst = false;
        }
      });
    } catch (error) {
      ShowToastDialog.closeLoader();
      print("paymentStatusCheckIntercity error: $error");
    }
    return isFirst;
  }

  Future<List<ZoneModel>?> getZone() async {
    List<ZoneModel> airPortList = [];
    try {
      await fireStore
          .collection(CollectionName.zone)
          .where('publish', isEqualTo: true)
          .get()
          .then((value) {
        for (var element in value.docs) {
          ZoneModel ariPortModel = ZoneModel.fromJson(element.data());
          airPortList.add(ariPortModel);
        }
      });
    } catch (error) {
      print("getZone error: $error");
    }
    return airPortList;
  }

  static Future<bool> phoneNumberExists(String fullPhoneNumber) async {
    try {
      final result = await fireStore
          .collection(CollectionName.users)
          .where('phoneNumber', isEqualTo: fullPhoneNumber)
          .limit(1)
          .get();
      return result.docs.isNotEmpty;
    } catch (e) {
      print("phoneNumberExists error: $e");
      return false;
    }
  }

  /// FIX: Properly assign driver to order when they accept
  static Future<bool> assignDriverToOrder(
      String orderId, String driverId) async {
    try {
      print("🔧 FIX: Assigning driver $driverId to order $orderId");

      // Get the driver acceptance data
      final acceptanceDoc = await FirebaseFirestore.instance
          .collection(CollectionName.orders)
          .doc(orderId)
          .collection("acceptedDriver")
          .doc(driverId)
          .get();

      if (!acceptanceDoc.exists) {
        print("❌ Driver acceptance record not found");
        return false;
      }

      // Update the main order document with driver assignment
      await FirebaseFirestore.instance
          .collection(CollectionName.orders)
          .doc(orderId)
          .update({
        'driverId': driverId,
        'updateDate': FieldValue.serverTimestamp(),
        'acceptedDriverId': FieldValue.arrayUnion([driverId]),
        'status': 'Driver Accepted', // Or appropriate status
      });

      print("✅ Order successfully updated with driver assignment");
      return true;
    } catch (e) {
      print("❌ Error assigning driver to order: $e");
      return false;
    }
  }

  /// CORRECT method to handle driver acceptance
  static Future<bool> handleDriverAcceptance(
      String orderId, String driverId) async {
    try {
      print("✅ Driver $driverId accepted order $orderId");

      // 1. First, save to acceptedDriver subcollection (you're already doing this)
      await FirebaseFirestore.instance
          .collection(CollectionName.orders)
          .doc(orderId)
          .collection("acceptedDriver")
          .doc(driverId)
          .set({
        'driverId': driverId,
        'acceptedRejectTime': FieldValue.serverTimestamp(),
        'offerAmount':
            0, // TODO: Replace 0 with actual offer amount if available
      });

      // 2. ✅ CRITICAL FIX: Update the main order document
      await FirebaseFirestore.instance
          .collection(CollectionName.orders)
          .doc(orderId)
          .update({
        'driverId': driverId, // ← THIS IS WHAT WAS MISSING
        'acceptedDriverId': FieldValue.arrayUnion([driverId]), // ← ALSO THIS
        'updateDate': FieldValue.serverTimestamp(),
        'status': 'Driver Accepted', // Or whatever status you use
      });

      print("✅ Order $orderId successfully updated with driver $driverId");
      return true;
    } catch (e) {
      print("❌ Error in driver acceptance: $e");
      return false;
    }
  }

  /// SAFE method to recover driver assignment without corrupting data
  static Future<bool> safeRecoverDriverAssignment(String orderId) async {
    try {
      print("🔍 SAFELY recovering driver for order: $orderId");

      // 1. Check accepted drivers subcollection
      final acceptedDrivers = await FirebaseFirestore.instance
          .collection(CollectionName.orders)
          .doc(orderId)
          .collection("acceptedDriver")
          .get();

      if (acceptedDrivers.docs.isEmpty) {
        print("❌ No accepted drivers found for order: $orderId");
        return false;
      }

      // 2. Get the first driver who accepted
      final driverId = acceptedDrivers.docs.first.id;
      final acceptanceData = acceptedDrivers.docs.first.data();

      print("✅ Found accepted driver: $driverId");

      // 3. Verify the driver exists and has valid data
      final driver = await getDriver(driverId);
      if (driver == null) {
        print("❌ Driver $driverId no longer exists");
        return false;
      }

      // 4. SAFELY update ONLY the order document (not driver document!)
      await FirebaseFirestore.instance
          .collection(CollectionName.orders)
          .doc(orderId)
          .update({
        'driverId': driverId,
        'acceptedDriverId': FieldValue.arrayUnion([driverId]),
        'updateDate': FieldValue.serverTimestamp(),
      });

      print("✅ Order $orderId safely updated with driver: ${driver.fullName}");
      return true;
    } catch (e) {
      print("❌ Safe recovery failed: $e");
      return false;
    }
  }

  /// Enhanced debug method to see WHY the query returns 0 results
  static Future<void> debugQueryResults(OrderModel orderModel) async {
    try {
      print("🔍 [QUERY DEBUG] Analyzing why query returns 0 results...");

      // Test each filter individually
      print("\n1️⃣ Testing isOnline filter only:");
      var onlineOnly = await fireStore
          .collection(CollectionName.driverUsers)
          .where('isOnline', isEqualTo: true)
          .get();
      print("   Found ${onlineOnly.size} online drivers");

      print("\n2️⃣ Testing isOnline + documentVerification:");
      var onlineVerified = await fireStore
          .collection(CollectionName.driverUsers)
          .where('isOnline', isEqualTo: true)
          .where('documentVerification', isEqualTo: true)
          .get();
      print("   Found ${onlineVerified.size} online & verified drivers");

      print("\n3️⃣ Testing isOnline + documentVerification + serviceId:");
      var withService = await fireStore
          .collection(CollectionName.driverUsers)
          .where('isOnline', isEqualTo: true)
          .where('documentVerification', isEqualTo: true)
          .where('serviceId', isEqualTo: orderModel.serviceId)
          .get();
      print(
          "   Found ${withService.size} drivers with service ${orderModel.serviceId}");

      // Check each driver from the full query
      for (var doc in withService.docs) {
        final driver = DriverUserModel.fromJson(doc.data());
        print("   👤 ${driver.fullName} - zones: ${driver.zoneIds}");

        // Check if this driver has the required zone
        if (driver.zoneIds != null &&
            driver.zoneIds!.contains(orderModel.zoneId)) {
          print("   ✅ HAS REQUIRED ZONE: ${orderModel.zoneId}");
        } else {
          print("   ❌ MISSING ZONE: ${orderModel.zoneId}");
        }
      }

      print("\n4️⃣ Testing full query with zone filter:");
      try {
        var fullQuery = await fireStore
            .collection(CollectionName.driverUsers)
            .where('isOnline', isEqualTo: true)
            .where('documentVerification', isEqualTo: true)
            .where('serviceId', isEqualTo: orderModel.serviceId)
            .where('zoneIds', arrayContains: orderModel.zoneId)
            .get();
        print("   Full query found ${fullQuery.size} drivers");
      } catch (e) {
        print("   ❌ Full query failed: $e");
      }
    } catch (e) {
      print("❌ Query debug failed: $e");
    }
  }

  static Future<DocumentSnapshot> getAdminCommission() async {
    return await FirebaseFirestore.instance
        .collection(
            CollectionName.settings) // FIXED: Use the correct collection name
        .doc("adminCommission")
        .get();
  }

  /// Comprehensive commission debugging method
  static Future<void> debugCommissionIssue() async {
    try {
      print("=== COMMISSION DEBUG ANALYSIS ===");

      // 1. First check if we already have commission data loaded
      print("\n1️⃣ Currently loaded commission in Constant:");
      if (Constant.adminCommission != null) {
        print("   ✅ Commission loaded in memory:");
        print("      Enabled: ${Constant.adminCommission!.isEnabled}");
        print("      Type: ${Constant.adminCommission!.type}");
        print("      Amount: ${Constant.adminCommission!.amount}");
      } else {
        print("   ❌ No commission loaded in memory");
      }

      // 2. Check what's actually in Firebase
      print("\n2️⃣ Checking Firebase commission document...");
      final commissionDoc = await FirebaseFirestore.instance
          .collection(CollectionName.settings)
          .doc("adminCommission")
          .get();

      if (commissionDoc.exists) {
        print("   ✅ Commission document exists in Firebase");
        print("   Raw data: ${commissionDoc.data()}");

        // Parse the data to see what fields are available
        final data = commissionDoc.data()!;
        print("   Available fields:");
        data.forEach((key, value) {
          print("      $key: $value (${value.runtimeType})");
        });

        // Check for common field name variations
        final isEnabled =
            data['isEnabled'] ?? data['enable'] ?? data['enabled'] ?? false;
        final type = data['type']?.toString() ?? '';
        final amount =
            data['amount']?.toString() ?? data['commission']?.toString() ?? '';

        print("\n   Parsed values:");
        print("      isEnabled: $isEnabled");
        print("      type: $type");
        print("      amount: $amount");

        // Test the calculation
        if (isEnabled && type.isNotEmpty && amount.isNotEmpty) {
          final testAmount = "100.0";
          final commission = AdminCommission(
            isEnabled: isEnabled,
            type: type,
            amount: amount,
          );

          final result = Constant.calculateOrderAdminCommission(
            amount: testAmount,
            adminCommission: commission,
          );

          print("\n3️⃣ Test calculation with amount: $testAmount");
          print("   Commission result: $result");

          if (type.toLowerCase() == "percent" ||
              type.toLowerCase() == "percentage") {
            final expected =
                (double.parse(testAmount) * double.parse(amount)) / 100;
            print("   Expected (${amount}% of $testAmount): $expected");
          } else if (type.toLowerCase() == "fix") {
            print("   Expected (fixed $amount): $amount");
          }
        } else {
          print("   ❌ Commission configuration incomplete in Firebase");
          print("      isEnabled: $isEnabled");
          print("      type: '$type'");
          print("      amount: '$amount'");
        }
      } else {
        print("   ❌ Commission document does NOT exist in Firebase");
        print("   Path: ${CollectionName.settings}/adminCommission");
      }

      // 3. Check if the commission is being loaded during settings initialization
      print("\n4️⃣ Checking settings initialization...");
      await getSettings(); // Reload settings to see the process

      print("   After reloading settings:");
      if (Constant.adminCommission != null) {
        print("   ✅ Commission loaded successfully:");
        print("      Enabled: ${Constant.adminCommission!.isEnabled}");
        print("      Type: ${Constant.adminCommission!.type}");
        print("      Amount: ${Constant.adminCommission!.amount}");
      } else {
        print("   ❌ Commission still not loaded after getSettings()");
      }

      print("\n=== END COMMISSION DEBUG ===");
    } catch (e) {
      print("❌ Error in commission debug: $e");
      print("Stack trace: ${e.toString()}");
    }
  }

  /// Verify that commission data was saved with the order
  static Future<void> verifyOrderCommission(String orderId) async {
    try {
      final orderDoc = await FirebaseFirestore.instance
          .collection(CollectionName.orders)
          .doc(orderId)
          .get();

      if (orderDoc.exists) {
        final orderData = orderDoc.data();
        print("🔍 Verifying commission data for order $orderId:");

        if (orderData != null && orderData.containsKey('adminCommission')) {
          final commissionData = orderData['adminCommission'];
          print("   ✅ Commission data found in Firestore:");
          print("      Type: ${commissionData['type']}");
          print("      Amount: ${commissionData['amount']}");
          print("      Enabled: ${commissionData['isEnabled']}");

          if (commissionData['flatRatePromotion'] != null) {
            print(
                "      Flat Rate Enabled: ${commissionData['flatRatePromotion']['isEnabled']}");
            print(
                "      Flat Rate Amount: ${commissionData['flatRatePromotion']['amount']}");
          }
        } else {
          print("   ❌ Commission data missing from Firestore order");
        }
      }
    } catch (e) {
      print("❌ Error verifying order commission: $e");
    }
  }
}

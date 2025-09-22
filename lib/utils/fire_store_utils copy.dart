import 'dart:async';
import 'dart:developer';

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
    await fireStore.collection(CollectionName.settings).doc("globalKey").get().then((value) {
      if (value.exists) {
        Constant.mapAPIKey = value.data()!["googleMapKey"];
      }
    });

    await fireStore.collection(CollectionName.settings).doc("notification_setting").get().then((value) {
      if (value.exists) {
        if (value.data() != null) {
          Constant.senderId = value.data()!['senderId'].toString();
          Constant.jsonNotificationFileURL = value.data()!['serviceJson'].toString();
        }
      }
    });

    await fireStore.collection(CollectionName.settings).doc("globalValue").get().then((value) {
      if (value.exists) {
        Constant.distanceType = value.data()!["distanceType"];
        Constant.radius = value.data()!["radius"];
        Constant.mapType = value.data()!["mapType"];
        Constant.selectedMapType = value.data()!["selectedMapType"];
        Constant.driverLocationUpdate = value.data()!["driverLocationUpdate"];
      }
    });

    await fireStore.collection(CollectionName.settings).doc("global").get().then((value) {
      if (value.exists) {
        Constant.termsAndConditions = value.data()!["termsAndConditions"];
        Constant.privacyPolicy = value.data()!["privacyPolicy"];
        Constant.appVersion = value.data()!["appVersion"];
      }
    });

    await fireStore.collection(CollectionName.settings).doc("adminCommission").get().then((value) {
      if (value.exists && value.data() != null) {
        AdminCommission adminCommission = AdminCommission.fromJson(value.data()!);
        if (adminCommission.isEnabled == true) {
          Constant.adminCommission = adminCommission;
        }
      }
    });

    await fireStore.collection(CollectionName.settings).doc("referral").get().then((value) {
      if (value.exists) {
        Constant.referralAmount = value.data()!["referralAmount"];
      }
    });

    await fireStore.collection(CollectionName.settings).doc("contact_us").get().then((value) {
      if (value.exists) {
        Constant.supportURL = value.data()!["supportURL"];
      }
    });

    await fireStore.collection(CollectionName.settings).doc("currency").get().then((value) {
      if (value.exists && value.data() != null) {
        Constant.currencyModel = CurrencyModel.fromJson(value.data()!);
        print("FirestoreUtils: Currency Loaded - Symbol: ${Constant.currencyModel?.symbol}");
      } else {
        print("FirestoreUtils: Currency document not found or data is null.");
        // Set default currency if not found
        Constant.currencyModel = CurrencyModel(
          id: "default", 
          code: "USD", 
          decimalDigits: 2, 
          enable: true, 
          name: "US Dollar", 
          symbol: "\$", 
          symbolAtRight: false
        );
      }
    }).catchError((error) {
      print("FirestoreUtils: Error loading currency - $error");
      // Set default currency on error
      Constant.currencyModel = CurrencyModel(
        id: "error_default", 
        code: "USD", 
        decimalDigits: 2, 
        enable: true, 
        name: "US Dollar", 
        symbol: "\$", 
        symbolAtRight: false
      );
    });
  }

  static String getCurrentUid() {
    return FirebaseAuth.instance.currentUser!.uid;
  }

  static Future updateReferralAmount(OrderModel orderModel) async {
    ReferralModel? referralModel;
    await fireStore.collection(CollectionName.referral).doc(orderModel.userId).get().then((value) {
      if (value.data() != null) {
        referralModel = ReferralModel.fromJson(value.data()!);
      } else {
        return;
      }
    });
    if (referralModel != null) {
      if (referralModel!.referralBy != null && referralModel!.referralBy!.isNotEmpty) {
        await fireStore.collection(CollectionName.users).doc(referralModel!.referralBy).get().then((value) async {
          DocumentSnapshot<Map<String, dynamic>> userDocument = value;
          if (userDocument.data() != null && userDocument.exists) {
            try {
              print(userDocument.data());
              UserModel user = UserModel.fromJson(userDocument.data()!);
              user.walletAmount = (double.parse(user.walletAmount.toString()) + double.parse(Constant.referralAmount.toString())).toString();
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

  static Future<bool> getIntercityFirstOrderOrNOt(InterCityOrderModel orderModel) async {
    bool isFirst = true;
    await fireStore.collection(CollectionName.ordersIntercity).where('userId', isEqualTo: orderModel.userId).get().then((value) {
      if (value.size == 1) {
        isFirst = true;
      } else {
        isFirst = false;
      }
    });
    return isFirst;
  }

  static Future updateIntercityReferralAmount(InterCityOrderModel orderModel) async {
    ReferralModel? referralModel;
    await fireStore.collection(CollectionName.referral).doc(orderModel.userId).get().then((value) {
      if (value.data() != null) {
        referralModel = ReferralModel.fromJson(value.data()!);
      } else {
        return;
      }
    });
    if (referralModel != null) {
      if (referralModel!.referralBy != null && referralModel!.referralBy!.isNotEmpty) {
        await fireStore.collection(CollectionName.users).doc(referralModel!.referralBy).get().then((value) async {
          DocumentSnapshot<Map<String, dynamic>> userDocument = value;
          if (userDocument.data() != null && userDocument.exists) {
            try {
              print(userDocument.data());
              UserModel user = UserModel.fromJson(userDocument.data()!);
              user.walletAmount = (double.parse(user.walletAmount.toString()) + double.parse(Constant.referralAmount.toString())).toString();
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

  static Future<UserModel?> getUserProfile(String uuid) async {
    UserModel? userModel;
    await fireStore.collection(CollectionName.users).doc(uuid).get().then((value) {
      if (value.exists) {
        userModel = UserModel.fromJson(value.data()!);
      }
    }).catchError((error) {
      log("Failed to update user: $error");
      userModel = null;
    });
    return userModel;
  }

  static Future<DriverUserModel?> getDriver(String uuid) async {
    DriverUserModel? driverUserModel;
    await fireStore.collection(CollectionName.driverUsers).doc(uuid).get().then((value) {
      if (value.exists) {
        driverUserModel = DriverUserModel.fromJson(value.data()!);
      }
    }).catchError((error) {
      log("Failed to update user: $error");
      driverUserModel = null;
    });
    return driverUserModel;
  }

  static Future<bool> updateUser(UserModel userModel) async {
    bool isUpdate = false;
    await fireStore.collection(CollectionName.users).doc(userModel.id).set(userModel.toJson()).whenComplete(() {
      isUpdate = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isUpdate = false;
    });
    return isUpdate;
  }

  static Future<bool> updateDriver(DriverUserModel userModel) async {
    bool isUpdate = false;
    await fireStore.collection(CollectionName.driverUsers).doc(userModel.id).set(userModel.toJson()).whenComplete(() {
      isUpdate = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isUpdate = false;
    });
    return isUpdate;
  }

  static Future<bool> getFirestOrderOrNOt(OrderModel orderModel) async {
    bool isFirst = true;
    await fireStore.collection(CollectionName.orders).where('userId', isEqualTo: orderModel.userId).get().then((value) {
      if (value.size == 1) {
        isFirst = true;
      } else {
        isFirst = false;
      }
    });
    return isFirst;
  }

  static Future<bool?> rejectRide(OrderModel orderModel, DriverIdAcceptReject driverIdAcceptReject) async {
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
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<OrderModel?> getOrder(String orderId) async {
    OrderModel? orderModel;
    await fireStore.collection(CollectionName.orders).doc(orderId).get().then((value) {
      if (value.data() != null) {
        orderModel = OrderModel.fromJson(value.data()!);
      }
    });
    return orderModel;
  }

  static Future<InterCityOrderModel?> getInterCityOrder(String orderId) async {
    InterCityOrderModel? orderModel;
    await fireStore.collection(CollectionName.ordersIntercity).doc(orderId).get().then((value) {
      if (value.data() != null) {
        orderModel = InterCityOrderModel.fromJson(value.data()!);
      }
    });
    return orderModel;
  }

  static Future<bool> userExitOrNot(String uid) async {
    bool isExit = false;

    await fireStore.collection(CollectionName.users).doc(uid).get().then(
      (value) {
        if (value.exists) {
          isExit = true;
        } else {
          isExit = false;
        }
      },
    ).catchError((error) {
      log("Failed to update user: $error");
      isExit = false;
    });
    return isExit;
  }

  static Future<List<ServiceModel>> getService() async {
    List<ServiceModel> serviceList = [];
    await fireStore.collection(CollectionName.service).where('enable', isEqualTo: true).get().then((value) {
      for (var element in value.docs) {
        ServiceModel documentModel = ServiceModel.fromJson(element.data());
        serviceList.add(documentModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return serviceList;
  }

  static Future<List<BannerModel>> getBanner() async {
    List<BannerModel> bannerList = [];
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
    }).catchError((error) {
      log(error.toString());
    });
    return bannerList;
  }

  static Future<List<IntercityServiceModel>> getIntercityService() async {
    List<IntercityServiceModel> serviceList = [];
    await fireStore.collection(CollectionName.intercityService).where('enable', isEqualTo: true).get().then((value) {
      for (var element in value.docs) {
        IntercityServiceModel documentModel = IntercityServiceModel.fromJson(element.data());
        serviceList.add(documentModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return serviceList;
  }

  static Future<List<FreightVehicle>> getFreightVehicle() async {
    List<FreightVehicle> freightVehicle = [];
    await fireStore.collection(CollectionName.freightVehicle).where('enable', isEqualTo: true).get().then((value) {
      for (var element in value.docs) {
        FreightVehicle documentModel = FreightVehicle.fromJson(element.data());
        freightVehicle.add(documentModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return freightVehicle;
  }

  static Future<bool?> setOrder(OrderModel orderModel) async {
    bool isAdded = false;
    await fireStore.collection(CollectionName.orders).doc(orderModel.id).set(orderModel.toJson()).then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  StreamController<List<DriverUserModel>>? getNearestOrderRequestController;

  Stream<List<DriverUserModel>> sendOrderData(OrderModel orderModel) async* {
    getNearestOrderRequestController ??= StreamController<List<DriverUserModel>>.broadcast();

    List<DriverUserModel> ordersList = [];
    Query<Map<String, dynamic>> query = fireStore
        .collection(CollectionName.driverUsers)
        .where('serviceId', isEqualTo: orderModel.serviceId)
        .where('zoneId', arrayContains: orderModel.zoneId)
        .where('isOnline', isEqualTo: true);
    GeoFirePoint center = Geoflutterfire().point(latitude: orderModel.sourceLocationLAtLng!.latitude ?? 0.0, longitude: orderModel.sourceLocationLAtLng!.longitude ?? 0.0);
    Stream<List<DocumentSnapshot>> stream =
        Geoflutterfire().collection(collectionRef: query).within(center: center, radius: double.parse(Constant.radius), field: 'position', strictMode: true);

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
  static Stream<List<DriverUserModel>> findNearbyDrivers(OrderModel orderModel) {
    try {
      print("🔍 Finding drivers for order: ${orderModel.id}");
      print("📍 Source location: ${orderModel.sourceLocationLAtLng?.latitude}, ${orderModel.sourceLocationLAtLng?.longitude}");
      print("🚗 Service ID: ${orderModel.serviceId}");
      print("🗺️ Zone ID: ${orderModel.zoneId}");
      
      // Create base query for drivers
      Query<Map<String, dynamic>> query = fireStore
          .collection(CollectionName.driverUsers)
          .where('serviceId', isEqualTo: orderModel.serviceId)
          .where('isOnline', isEqualTo: true)
          .where('documentVerification', isEqualTo: true);
      
      // Add zone filter if zone is specified
      if (orderModel.zoneId != null && orderModel.zoneId!.isNotEmpty) {
        // query = query.where('zoneIds', arrayContains: orderModel.zoneId);
      }
      
      // Create geo query for location-based search
      if (orderModel.sourceLocationLAtLng?.latitude != null && 
          orderModel.sourceLocationLAtLng?.longitude != null) {
        
        GeoFirePoint center = Geoflutterfire().point(
          latitude: orderModel.sourceLocationLAtLng!.latitude!, 
          longitude: orderModel.sourceLocationLAtLng!.longitude!
        );
        
        double searchRadius = double.tryParse(Constant.radius) ?? 10.0;
        print("🎯 Search radius: ${searchRadius}km");
        
        return Geoflutterfire()
            .collection(collectionRef: query)
            .within(
              center: center, 
              radius: searchRadius, 
              field: 'position', 
              strictMode: true
            )
            .map((List<DocumentSnapshot> documentList) {
              List<DriverUserModel> availableDrivers = [];
              
              print("📋 Found ${documentList.length} potential drivers");
              
              for (var document in documentList) {
                try {
                  final data = document.data() as Map<String, dynamic>?;
                  if (data != null) {
                    DriverUserModel driver = DriverUserModel.fromJson(data);
                    
                    // Additional validation
                    if (driver.isOnline == true && 
                        driver.documentVerification == true &&
                        driver.location?.latitude != null &&
                        driver.location?.longitude != null) {
                      
                      // Check if driver has already been notified for this order
                      if (orderModel.acceptedDriverId?.contains(driver.id) != true &&
                          orderModel.rejectedDriverId?.contains(driver.id) != true) {
                        availableDrivers.add(driver);
                        print("✅ Added driver: ${driver.fullName} (${driver.id})");
                      } else {
                        print("⏭️ Skipping driver ${driver.fullName} - already notified");
                      }
                    } else {
                      print("❌ Driver ${driver.fullName} failed validation");
                    }
                  }
                } catch (e) {
                  print("❌ Error parsing driver document: $e");
                }
              }
              
              print("🎉 Final available drivers count: ${availableDrivers.length}");
              return availableDrivers;
            });
      } else {
        print("❌ Invalid source location coordinates");
        return Stream.value([]);
      }
    } catch (e) {
      print("❌ Error in findNearbyDrivers: $e");
      return Stream.value([]);
    }
  }
  
  /// Send ride request to multiple drivers
  static Future<bool> sendRideRequestToDrivers(OrderModel orderModel, List<DriverUserModel> drivers) async {
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
            "sourceLatitude": orderModel.sourceLocationLAtLng?.latitude?.toString(),
            "sourceLongitude": orderModel.sourceLocationLAtLng?.longitude?.toString(),
            "destinationLatitude": orderModel.destinationLocationLAtLng?.latitude?.toString(),
            "destinationLongitude": orderModel.destinationLocationLAtLng?.longitude?.toString(),
            "sourceLocation": orderModel.sourceLocationName,
            "destinationLocation": orderModel.destinationLocationName,
            "offerRate": orderModel.offerRate,
            "distance": orderModel.distance,
            "paymentType": orderModel.paymentType,
          };
          
          notificationFutures.add(
            SendNotification.sendOneNotification(
              token: driver.fcmToken!,
              title: 'New Ride Available'.tr,
              body: 'A customer has placed a ride near your location.'.tr,
              payload: payload,
            ).then((success) {
              if (success) {
                print("✅ Notification sent to driver: ${driver.fullName}");
              } else {
                print("❌ Failed to send notification to driver: ${driver.fullName}");
              }
              return success;
            }).catchError((error) {
              print("❌ Error sending notification to ${driver.fullName}: $error");
              return false;
            })
          );
        } else {
          print("⚠️ Driver ${driver.fullName} has no FCM token");
        }
      }
      
      // Wait for all notifications to complete
      List<dynamic> results = await Future.wait(notificationFutures);
      int successCount = results.where((result) => result == true).length;
      
      print("📊 Notification results: $successCount/${drivers.length} successful");
      
      return successCount > 0;
      
    } catch (e) {
      print("❌ Error in sendRideRequestToDrivers: $e");
      return false;
    }
  }
  
  /// Enhanced method to place a ride with better error handling and driver finding
  static Future<bool> placeRideRequest(OrderModel orderModel) async {
    try {
      print("🚀 Starting ride request process...");
      
      // Validate order data
      if (orderModel.sourceLocationLAtLng?.latitude == null ||
          orderModel.sourceLocationLAtLng?.longitude == null) {
        ShowToastDialog.showToast("Invalid pickup location");
        return false;
      }
      
      if (orderModel.destinationLocationLAtLng?.latitude == null ||
          orderModel.destinationLocationLAtLng?.longitude == null) {
        ShowToastDialog.showToast("Invalid destination location");
        return false;
      }
      
      if (orderModel.serviceId == null || orderModel.serviceId!.isEmpty) {
        ShowToastDialog.showToast("Please select a service type");
        return false;
      }
      
      ShowToastDialog.showLoader("Finding nearby drivers...");
      
      // Find nearby drivers
      bool driversFound = false;
      List<DriverUserModel> availableDrivers = [];
      
      // Listen to the stream for a limited time
      StreamSubscription? driverSubscription;
      Completer<bool> completer = Completer<bool>();
      
      Timer timeoutTimer = Timer(const Duration(seconds: 10), () {
        if (!completer.isCompleted) {
          print("⏰ Driver search timeout");
          completer.complete(false);
        }
      });
      
      driverSubscription = findNearbyDrivers(orderModel).listen(
        (List<DriverUserModel> drivers) {
          print("📦 Received ${drivers.length} drivers from stream.");
          if (!completer.isCompleted && drivers.isNotEmpty) {
            availableDrivers = drivers;
            driversFound = true;
            completer.complete(true);
          }
        },
        onError: (error) {
          print("❌ Error in driver stream: $error");
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
        ShowToastDialog.showToast("No drivers available in your area. Please try again later.");
        return false;
      }
      
      // Send ride request to found drivers
      bool requestSent = await sendRideRequestToDrivers(orderModel, availableDrivers);
      
      if (requestSent) {
        ShowToastDialog.showToast("Ride request sent! Looking for a driver...");
        return true;
      } else {
        ShowToastDialog.showToast("Failed to send ride request. Please try again.");
        return false;
      }
      
    } catch (e) {
      ShowToastDialog.closeLoader();
      print("❌ Error in placeRideRequest: $e");
      ShowToastDialog.showToast("Failed to place ride request: ${e.toString()}");
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
    await fireStore.collection(CollectionName.ordersIntercity).doc(orderModel.id).set(orderModel.toJson()).then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<DriverIdAcceptReject?> getAcceptedOrders(String orderId, String driverId) async {
    DriverIdAcceptReject? driverIdAcceptReject;
    await fireStore.collection(CollectionName.orders).doc(orderId).collection("acceptedDriver").doc(driverId).get().then((value) async {
      if (value.exists) {
        driverIdAcceptReject = DriverIdAcceptReject.fromJson(value.data()!);
      }
    }).catchError((error) {
      log("Failed to update user: $error");
      driverIdAcceptReject = null;
    });
    return driverIdAcceptReject;
  }

  static Future<DriverIdAcceptReject?> getInterCItyAcceptedOrders(String orderId, String driverId) async {
    DriverIdAcceptReject? driverIdAcceptReject;
    await fireStore.collection(CollectionName.ordersIntercity).doc(orderId).collection("acceptedDriver").doc(driverId).get().then((value) async {
      if (value.exists) {
        driverIdAcceptReject = DriverIdAcceptReject.fromJson(value.data()!);
      }
    }).catchError((error) {
      log("Failed to update user: $error");
      driverIdAcceptReject = null;
    });
    return driverIdAcceptReject;
  }

  static Future<OrderModel?> getOrderById(String orderId) async {
    OrderModel? orderModel;
    await fireStore.collection(CollectionName.orders).doc(orderId).get().then((value) async {
      if (value.exists) {
        orderModel = OrderModel.fromJson(value.data()!);
      }
    }).catchError((error) {
      log("Failed to update user: $error");
      orderModel = null;
    });
    return orderModel;
  }

  Future<PaymentModel?> getPayment() async {
    try {
      PaymentModel? paymentModel;
      await fireStore.collection(CollectionName.settings).doc("payment").get().then((value) {
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
    await fireStore.collection(CollectionName.currency).where("enable", isEqualTo: true).get().then((value) {
      if (value.docs.isNotEmpty) {
        currencyModel = CurrencyModel.fromJson(value.docs.first.data());
      }
    });
    return currencyModel;
  }

  Future<List<TaxModel>?> getTaxList() async {
    List<TaxModel> taxList = [];

    await fireStore.collection(CollectionName.tax).where('country', isEqualTo: Constant.country).where('enable', isEqualTo: true).get().then((value) {
      for (var element in value.docs) {
        TaxModel taxModel = TaxModel.fromJson(element.data());
        taxList.add(taxModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return taxList;
  }

  Future<List<CouponModel>?> getCoupon() async {
    List<CouponModel> couponModel = [];

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
    }).catchError((error) {
      log(error.toString());
    });
    return couponModel;
  }

  static Future<bool?> setReview(ReviewModel reviewModel) async {
    bool isAdded = false;
    await fireStore.collection(CollectionName.reviewDriver).doc(reviewModel.id).set(reviewModel.toJson()).then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<ReviewModel?> getReview(String orderId) async {
    ReviewModel? reviewModel;
    await fireStore.collection(CollectionName.reviewDriver).doc(orderId).get().then((value) {
      if (value.data() != null) {
        reviewModel = ReviewModel.fromJson(value.data()!);
      }
    });
    return reviewModel;
  }

  static Future<List<WalletTransactionModel>?> getWalletTransaction() async {
    List<WalletTransactionModel> walletTransactionModel = [];

    await fireStore
        .collection(CollectionName.walletTransaction)
        .where('userId', isEqualTo: FireStoreUtils.getCurrentUid())
        .orderBy('createdDate', descending: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        WalletTransactionModel taxModel = WalletTransactionModel.fromJson(element.data());
        walletTransactionModel.add(taxModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return walletTransactionModel;
  }

  static Future<bool?> setWalletTransaction(WalletTransactionModel walletTransactionModel) async {
    bool isAdded = false;
    await fireStore.collection(CollectionName.walletTransaction).doc(walletTransactionModel.id).set(walletTransactionModel.toJson()).then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<bool?> updateUserWallet({required String amount}) async {
    bool isAdded = false;
    await getUserProfile(FireStoreUtils.getCurrentUid()).then((value) async {
      if (value != null) {
        UserModel userModel = value;
        userModel.walletAmount = (double.parse(userModel.walletAmount.toString()) + double.parse(amount)).toString();
        await FireStoreUtils.updateUser(userModel).then((value) {
          isAdded = value;
        });
      }
    });
    return isAdded;
  }

  static Future<bool?> updateDriverWallet({required String driverId, required String amount}) async {
    bool isAdded = false;
    await getDriver(driverId).then((value) async {
      if (value != null) {
        DriverUserModel userModel = value;
        userModel.walletAmount = (double.parse(userModel.walletAmount.toString()) + double.parse(amount)).toString();
        await FireStoreUtils.updateDriver(userModel).then((value) {
          isAdded = value;
        });
      }
    });
    return isAdded;
  }

  static Future<List<LanguageModel>?> getLanguage() async {
    List<LanguageModel> languageList = [];

    await fireStore.collection(CollectionName.languages).get().then((value) {
      for (var element in value.docs) {
        LanguageModel taxModel = LanguageModel.fromJson(element.data());
        languageList.add(taxModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return languageList;
  }

  static Future<ReferralModel?> getReferral() async {
    ReferralModel? referralModel;
    await fireStore.collection(CollectionName.referral).doc(FireStoreUtils.getCurrentUid()).get().then((value) {
      if (value.exists) {
        referralModel = ReferralModel.fromJson(value.data()!);
      }
    }).catchError((error) {
      log("Failed to update user: $error");
      referralModel = null;
    });
    return referralModel;
  }

  static Future<bool?> checkReferralCodeValidOrNot(String referralCode) async {
    bool? isExit;
    try {
      await fireStore.collection(CollectionName.referral).where("referralCode", isEqualTo: referralCode).get().then((value) {
        if (value.size > 0) {
          isExit = true;
        } else {
          isExit = false;
        }
      });
    } catch (e, s) {
      log('FireStoreUtils.firebaseCreateNewUser $e $s');
      return false;
    }
    return isExit;
  }

  static Future<ReferralModel?> getReferralUserByCode(String referralCode) async {
    ReferralModel? referralModel;
    try {
      await fireStore.collection(CollectionName.referral).where("referralCode", isEqualTo: referralCode).get().then((value) {
        referralModel = ReferralModel.fromJson(value.docs.first.data());
      });
    } catch (e, s) {
      log('FireStoreUtils.firebaseCreateNewUser $e $s');
      return null;
    }
    return referralModel;
  }

  static Future<String?> referralAdd(ReferralModel ratingModel) async {
    try {
      await fireStore.collection(CollectionName.referral).doc(ratingModel.id).set(ratingModel.toJson());
    } catch (e, s) {
      log('FireStoreUtils.firebaseCreateNewUser $e $s');
      return null;
    }
    return null;
  }

  static Future<List<OnBoardingModel>> getOnBoardingList() async {
    List<OnBoardingModel> onBoardingModel = [];
    await fireStore.collection(CollectionName.onBoarding).where("type", isEqualTo: "customerApp").get().then((value) {
      for (var element in value.docs) {
        OnBoardingModel documentModel = OnBoardingModel.fromJson(element.data());
        onBoardingModel.add(documentModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return onBoardingModel;
  }

  static Future addInBox(InboxModel inboxModel) async {
    return await fireStore.collection("chat").doc(inboxModel.orderId).set(inboxModel.toJson()).then((document) {
      return inboxModel;
    });
  }

  static Future addChat(ConversationModel conversationModel) async {
    return await fireStore.collection("chat").doc(conversationModel.orderId).collection("thread").doc(conversationModel.id).set(conversationModel.toJson()).then((document) {
      return conversationModel;
    });
  }

  static Future<List<FaqModel>> getFaq() async {
    List<FaqModel> faqModel = [];
    await fireStore.collection(CollectionName.faq).where('enable', isEqualTo: true).get().then((value) {
      for (var element in value.docs) {
        FaqModel documentModel = FaqModel.fromJson(element.data());
        faqModel.add(documentModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return faqModel;
  }

  static Future<bool?> deleteUser() async {
    bool? isDelete;
    try {
      await fireStore.collection(CollectionName.users).doc(FireStoreUtils.getCurrentUid()).delete();

      // delete user  from firebase auth
      await FirebaseAuth.instance.currentUser!.delete().then((value) {
        isDelete = true;
      });
    } catch (e, s) {
      log('FireStoreUtils.firebaseCreateNewUser $e $s');
      return false;
    }
    return isDelete;
  }

  static Future<bool?> setSOS(SosModel sosModel) async {
    bool isAdded = false;
    await fireStore.collection(CollectionName.sos).doc(sosModel.id).set(sosModel.toJson()).then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<SosModel?> getSOS(String orderId) async {
    SosModel? sosModel;
    try {
      await fireStore.collection(CollectionName.sos).where("orderId", isEqualTo: orderId).get().then((value) {
        sosModel = SosModel.fromJson(value.docs.first.data());
      });
    } catch (e, s) {
      log('FireStoreUtils.firebaseCreateNewUser $e $s');
      return null;
    }
    return sosModel;
  }

  Future<List<AriPortModel>?> getAirports() async {
    List<AriPortModel> airPortList = [];

    await fireStore.collection(CollectionName.airPorts).where('cityLocation', isEqualTo: Constant.city).get().then((value) {
      for (var element in value.docs) {
        AriPortModel ariPortModel = AriPortModel.fromJson(element.data());
        airPortList.add(ariPortModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return airPortList;
  }

  static Future<bool> paymentStatusCheck() async {
    ShowToastDialog.showLoader("Please wait");
    bool isFirst = false;
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
    return isFirst;
  }

  static Future<bool> paymentStatusCheckIntercity() async {
    ShowToastDialog.showLoader("Please wait");
    bool isFirst = false;
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
    return isFirst;
  }

  Future<List<ZoneModel>?> getZone() async {
    List<ZoneModel> airPortList = [];
    await fireStore.collection(CollectionName.zone).where('publish', isEqualTo: true).get().then((value) {
      for (var element in value.docs) {
        ZoneModel ariPortModel = ZoneModel.fromJson(element.data());
        airPortList.add(ariPortModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return airPortList;
  }

  static Future<bool> phoneNumberExists(String fullPhoneNumber) async {
  // TODO: implement your logic here. For now, return false as placeholder.
  return false;
}

}
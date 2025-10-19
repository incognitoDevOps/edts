import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/model/admin_commission.dart';
import 'package:driver/model/bank_details_model.dart';
import 'package:driver/model/conversation_model.dart';
import 'package:driver/model/currency_model.dart';
import 'package:driver/model/document_model.dart';
import 'package:driver/model/driver_document_model.dart';
import 'package:driver/model/driver_rules_model.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/inbox_model.dart';
import 'package:driver/model/intercity_order_model.dart';
import 'package:driver/model/language_model.dart';
import 'package:driver/model/on_boarding_model.dart';
import 'package:driver/model/order/driverId_accept_reject.dart';
import 'package:driver/model/order_model.dart';
import 'package:driver/model/payment_model.dart';
import 'package:driver/model/referral_model.dart';
import 'package:driver/model/review_model.dart';
import 'package:driver/model/service_model.dart';
import 'package:driver/model/user_model.dart';
import 'package:driver/model/vehicle_type_model.dart';
import 'package:driver/model/wallet_transaction_model.dart';
import 'package:driver/model/withdraw_model.dart';
import 'package:driver/model/zone_model.dart';
import 'package:driver/widget/geoflutterfire/src/geoflutterfire.dart';
import 'package:driver/widget/geoflutterfire/src/models/point.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  getGoogleAPIKey() async {
    await fireStore
        .collection(CollectionName.settings)
        .doc("globalKey")
        .get()
        .then((value) {
      if (value.exists) {
        Constant.mapAPIKey = value.data()!["googleMapKey"];
      }
    });
  }

  getSettings() async {
    await getGoogleAPIKey();

    await fireStore
        .collection(CollectionName.settings)
        .doc("notification_setting")
        .get()
        .then((value) {
      if (value.exists) {
        if (value.data() != null) {
          Constant.senderId = value.data()!['senderId'].toString();
          Constant.jsonNotificationFileURL =
              value.data()!['serviceJson'].toString();
        }
      }
    });

    await fireStore
        .collection(CollectionName.settings)
        .doc("globalValue")
        .get()
        .then((value) {
      if (value.exists) {
        Constant.distanceType = value.data()!["distanceType"];
        Constant.radius = value.data()!["radius"];
        Constant.minimumAmountToWithdrawal =
            value.data()!["minimumAmountToWithdrawal"];
        Constant.minimumDepositToRideAccept =
            value.data()!["minimumDepositToRideAccept"];
        Constant.mapType = value.data()!["mapType"];
        Constant.selectedMapType = value.data()!["selectedMapType"];
        Constant.driverLocationUpdate = value.data()!["driverLocationUpdate"];
      }
    });

    await fireStore
        .collection(CollectionName.settings)
        .doc("referral")
        .get()
        .then((value) {
      if (value.exists) {
        Constant.referralAmount = value.data()!["referralAmount"];
      }
    });

    await fireStore
        .collection(CollectionName.settings)
        .doc("global")
        .get()
        .then((value) {
      if (value.exists) {
        Constant.termsAndConditions = value.data()!["termsAndConditions"];
        Constant.privacyPolicy = value.data()!["privacyPolicy"];
        Constant.appVersion = value.data()!["appVersion"];
      }
    });

    await fireStore
        .collection(CollectionName.settings)
        .doc("contact_us")
        .get()
        .then((value) {
      if (value.exists) {
        Constant.supportURL = value.data()!["supportURL"];
      }
    });
  }

  static String getCurrentUid() {
    return FirebaseAuth.instance.currentUser!.uid;
  }

  static Future<DriverUserModel?> getDriverProfile(String uuid) async {
    DriverUserModel? driverModel;
    await fireStore
        .collection(CollectionName.driverUsers)
        .doc(uuid)
        .get()
        .then((value) {
      if (value.exists) {
        driverModel = DriverUserModel.fromJson(value.data()!);
      }
    }).catchError((error) {
      log("Failed to update user: $error");
      driverModel = null;
    });
    return driverModel;
  }

  static Future<UserModel?> getCustomer(String uuid) async {
    UserModel? userModel;
    await fireStore
        .collection(CollectionName.users)
        .doc(uuid)
        .get()
        .then((value) {
      if (value.exists) {
        userModel = UserModel.fromJson(value.data()!);
      }
    }).catchError((error) {
      log("Failed to update user: $error");
      userModel = null;
    });
    return userModel;
  }

  static Future<bool> updateUser(UserModel userModel) async {
    bool isUpdate = false;
    await fireStore
        .collection(CollectionName.users)
        .doc(userModel.id)
        .set(userModel.toJson())
        .whenComplete(() {
      isUpdate = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isUpdate = false;
    });
    return isUpdate;
  }

  Future<PaymentModel?> getPayment() async {
    PaymentModel? paymentModel;
    await fireStore
        .collection(CollectionName.settings)
        .doc("payment")
        .get()
        .then((value) {
      paymentModel = PaymentModel.fromJson(value.data()!);
    });
    return paymentModel;
  }

  Future<CurrencyModel?> getCurrency() async {
    CurrencyModel? currencyModel;
    await fireStore
        .collection(CollectionName.currency)
        .where("enable", isEqualTo: true)
        .get()
        .then((value) {
      if (value.docs.isNotEmpty) {
        currencyModel = CurrencyModel.fromJson(value.docs.first.data());
      }
    });
    return currencyModel;
  }

  /// SAFE version: Update driver with field-specific updates
  static Future<bool> updateDriverUser(DriverUserModel userModel) async {
    try {
      // Convert to JSON and remove null values to avoid overwriting fields with null
      Map<String, dynamic> data = userModel.toJson();
      data.removeWhere((key, value) => value == null);

      await fireStore
          .collection(CollectionName.driverUsers)
          .doc(userModel.id)
          .set(data, SetOptions(merge: true));
      return true;
    } catch (e) {
      log("Failed to update user: $e");
      return false;
    }
  }

  /// Even better: Add safe field-specific update methods
  static Future<bool> updateDriverFields({
    required String driverId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await fireStore
          .collection(CollectionName.driverUsers)
          .doc(driverId)
          .set(updates, SetOptions(merge: true));
      return true;
    } catch (e) {
      log("Failed to update driver fields: $e");
      return false;
    }
  }

  /// Safe location update method
  static Future<bool> updateDriverLocation({
    required String driverId,
    required double latitude,
    required double longitude,
    required double? heading,
  }) async {
    try {
      GeoFirePoint position =
          Geoflutterfire().point(latitude: latitude, longitude: longitude);

      await fireStore
          .collection(CollectionName.driverUsers)
          .doc(driverId)
          .update({
        'location': {'latitude': latitude, 'longitude': longitude},
        'position': {'geoPoint': position.geoPoint, 'geohash': position.hash},
        'rotation': heading,
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      log("Failed to update driver location: $e");
      return false;
    }
  }

  static Future<DriverIdAcceptReject?> getAcceptedOrders(
      String orderId, String driverId) async {
    DriverIdAcceptReject? driverIdAcceptReject;
    await fireStore
        .collection(CollectionName.orders)
        .doc(orderId)
        .collection("acceptedDriver")
        .doc(driverId)
        .get()
        .then((value) async {
      if (value.exists) {
        driverIdAcceptReject = DriverIdAcceptReject.fromJson(value.data()!);
      }
    }).catchError((error) {
      log("Failed to update user: $error");
      driverIdAcceptReject = null;
    });
    return driverIdAcceptReject;
  }

  static Future<DriverIdAcceptReject?> getInterCItyAcceptedOrders(
      String orderId, String driverId) async {
    DriverIdAcceptReject? driverIdAcceptReject;
    await fireStore
        .collection(CollectionName.ordersIntercity)
        .doc(orderId)
        .collection("acceptedDriver")
        .doc(driverId)
        .get()
        .then((value) async {
      if (value.exists) {
        driverIdAcceptReject = DriverIdAcceptReject.fromJson(value.data()!);
      }
    }).catchError((error) {
      log("Failed to update user: $error");
      driverIdAcceptReject = null;
    });
    return driverIdAcceptReject;
  }

  static Future<bool> userExitOrNot(String uid) async {
    bool isExit = false;

    await fireStore.collection(CollectionName.driverUsers).doc(uid).get().then(
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

  static Future<List<DocumentModel>> getDocumentList() async {
    List<DocumentModel> documentList = [];
    await fireStore
        .collection(CollectionName.documents)
        .where('enable', isEqualTo: true)
        .where('isDeleted', isEqualTo: false)
        .get()
        .then((value) {
      for (var element in value.docs) {
        DocumentModel documentModel = DocumentModel.fromJson(element.data());
        documentList.add(documentModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return documentList;
  }

  static Future<List<ServiceModel>> getService() async {
    List<ServiceModel> serviceList = [];
    await fireStore
        .collection(CollectionName.service)
        .where('enable', isEqualTo: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        ServiceModel documentModel = ServiceModel.fromJson(element.data());
        serviceList.add(documentModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return serviceList;
  }

  static Future<DriverDocumentModel?> getDocumentOfDriver() async {
    DriverDocumentModel? driverDocumentModel;
    await fireStore
        .collection(CollectionName.driverDocument)
        .doc(getCurrentUid())
        .get()
        .then((value) async {
      if (value.exists) {
        driverDocumentModel = DriverDocumentModel.fromJson(value.data()!);
      }
    });
    return driverDocumentModel;
  }

  static Future<bool> uploadDriverDocument(Documents documents) async {
    bool isAdded = false;
    DriverDocumentModel driverDocumentModel = DriverDocumentModel();
    List<Documents> documentsList = [];
    await fireStore
        .collection(CollectionName.driverDocument)
        .doc(getCurrentUid())
        .get()
        .then((value) async {
      if (value.exists) {
        DriverDocumentModel newDriverDocumentModel =
            DriverDocumentModel.fromJson(value.data()!);
        documentsList = newDriverDocumentModel.documents!;
        var contain = newDriverDocumentModel.documents!
            .where((element) => element.documentId == documents.documentId);
        if (contain.isEmpty) {
          documentsList.add(documents);

          driverDocumentModel.id = getCurrentUid();
          driverDocumentModel.documents = documentsList;
        } else {
          var index = newDriverDocumentModel.documents!.indexWhere(
              (element) => element.documentId == documents.documentId);

          driverDocumentModel.id = getCurrentUid();
          documentsList.removeAt(index);
          documentsList.insert(index, documents);
          driverDocumentModel.documents = documentsList;
          isAdded = false;
          ShowToastDialog.showToast("Document is under verification");
        }
      } else {
        documentsList.add(documents);
        driverDocumentModel.id = getCurrentUid();
        driverDocumentModel.documents = documentsList;
      }
    });

    await fireStore
        .collection(CollectionName.driverDocument)
        .doc(getCurrentUid())
        .set(driverDocumentModel.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      isAdded = false;
      log(error.toString());
    });

    return isAdded;
  }

  static Future<List<VehicleTypeModel>?> getVehicleType() async {
    List<VehicleTypeModel> vehicleList = [];
    await fireStore
        .collection(CollectionName.vehicleType)
        .where('enable', isEqualTo: true)
        .get()
        .then((value) async {
      for (var element in value.docs) {
        VehicleTypeModel vehicleModel =
            VehicleTypeModel.fromJson(element.data());
        vehicleList.add(vehicleModel);
      }
    });
    return vehicleList;
  }

  static Future<List<DriverRulesModel>?> getDriverRules() async {
    List<DriverRulesModel> driverRulesModel = [];
    await fireStore
        .collection(CollectionName.driverRules)
        .where('enable', isEqualTo: true)
        .where('isDeleted', isEqualTo: false)
        .get()
        .then((value) async {
      for (var element in value.docs) {
        DriverRulesModel vehicleModel =
            DriverRulesModel.fromJson(element.data());
        driverRulesModel.add(vehicleModel);
      }
    });
    return driverRulesModel;
  }

  StreamController<List<OrderModel>>? getNearestOrderRequestController;

  Stream<List<OrderModel>> getOrders(DriverUserModel driverUserModel,
      double? latitude, double? longLatitude) async* {
    getNearestOrderRequestController =
        StreamController<List<OrderModel>>.broadcast();
    List<OrderModel> ordersList = [];

    Query<Map<String, dynamic>> query;

    // Debug zone information
    print("🔍 Driver zones: ${driverUserModel.zoneIds}");
    print("📍 Driver location: $latitude, $longLatitude");

    // Handle cases where driver has no zones or zoneIds is null
    if (driverUserModel.zoneIds == null || driverUserModel.zoneIds!.isEmpty) {
      print("⚠️ Driver has no zones assigned - using fallback query");
      query = fireStore
          .collection(CollectionName.orders)
          .where('status', isEqualTo: Constant.ridePlaced);
    } else {
      query = fireStore
          .collection(CollectionName.orders)
          .where('serviceId', isEqualTo: driverUserModel.serviceId)
          .where('zoneId', whereIn: driverUserModel.zoneIds)
          .where('status', isEqualTo: Constant.ridePlaced);
    }

    // Handle case where location is null
    if (latitude == null || longLatitude == null) {
      print(
          "⚠️ Driver location is null - using simple query without geo filtering");

      query.snapshots().listen((querySnapshot) {
        ordersList.clear();
        for (var doc in querySnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          OrderModel orderModel = OrderModel.fromJson(data);

          // Check if driver can accept this order
          if (_canDriverAcceptOrder(orderModel, driverUserModel.id!)) {
            ordersList.add(orderModel);
          }
        }
        getNearestOrderRequestController!.sink.add(ordersList);
      });
    } else {
      // Use geo query
      GeoFirePoint center =
          Geoflutterfire().point(latitude: latitude, longitude: longLatitude);
      Stream<List<DocumentSnapshot>> stream = Geoflutterfire()
          .collection(collectionRef: query)
          .within(
              center: center,
              radius: double.parse(Constant.radius),
              field: 'position',
              strictMode: true);

      stream.listen((List<DocumentSnapshot> documentList) {
        ordersList.clear();
        for (var document in documentList) {
          final data = document.data() as Map<String, dynamic>;
          OrderModel orderModel = OrderModel.fromJson(data);

          if (_canDriverAcceptOrder(orderModel, driverUserModel.id!)) {
            ordersList.add(orderModel);
          }
        }
        getNearestOrderRequestController!.sink.add(ordersList);
      });
    }

    yield* getNearestOrderRequestController!.stream;
  }

  /// Helper method to check if driver can accept order
  bool _canDriverAcceptOrder(OrderModel orderModel, String driverId) {
    // If order has accepted drivers, check if this driver is already there
    if (orderModel.acceptedDriverId != null &&
        orderModel.acceptedDriverId!.isNotEmpty) {
      return !orderModel.acceptedDriverId!.contains(driverId);
    }

    // If no accepted drivers yet, driver can accept
    return true;
  }

  StreamController<List<InterCityOrderModel>>?
      getNearestFreightOrderRequestController;

  Stream<List<InterCityOrderModel>> getFreightOrders(
      double? latitude, double? longLatitude) async* {
    getNearestFreightOrderRequestController =
        StreamController<List<InterCityOrderModel>>.broadcast();
    List<InterCityOrderModel> ordersList = [];
    Query<Map<String, dynamic>> query = fireStore
        .collection(CollectionName.ordersIntercity)
        .where('intercityServiceId', isEqualTo: "Kn2VEnPI3ikF58uK8YqY")
        .where('status', isEqualTo: Constant.ridePlaced);
    GeoFirePoint center = Geoflutterfire()
        .point(latitude: latitude ?? 0.0, longitude: longLatitude ?? 0.0);
    Stream<List<DocumentSnapshot>> stream = Geoflutterfire()
        .collection(collectionRef: query)
        .within(
            center: center,
            radius: double.parse(Constant.radius),
            field: 'position',
            strictMode: true);

    stream.listen((List<DocumentSnapshot> documentList) {
      ordersList.clear();
      for (var document in documentList) {
        final data = document.data() as Map<String, dynamic>;
        InterCityOrderModel orderModel = InterCityOrderModel.fromJson(data);
        if (orderModel.acceptedDriverId != null &&
            orderModel.acceptedDriverId!.isNotEmpty) {
          if (!orderModel.acceptedDriverId!
              .contains(FireStoreUtils.getCurrentUid())) {
            ordersList.add(orderModel);
          }
        } else {
          ordersList.add(orderModel);
        }
      }
      getNearestFreightOrderRequestController!.sink.add(ordersList);
    });

    yield* getNearestFreightOrderRequestController!.stream;
  }

  closeStream() {
    if (getNearestOrderRequestController != null) {
      getNearestOrderRequestController!.close();
    }
  }

  closeFreightStream() {
    if (getNearestFreightOrderRequestController != null) {
      getNearestFreightOrderRequestController!.close();
    }
  }

  static Future<bool?> setOrder(OrderModel orderModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.orders)
        .doc(orderModel.id)
        .set(orderModel.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<bool?> bankDetailsIsAvailable() async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.bankDetails)
        .doc(FireStoreUtils.getCurrentUid())
        .get()
        .then((value) {
      if (value.exists) {
        isAdded = true;
      } else {
        isAdded = false;
      }
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<OrderModel?> getOrder(String orderId) async {
    OrderModel? orderModel;
    await fireStore
        .collection(CollectionName.orders)
        .doc(orderId)
        .get()
        .then((value) {
      if (value.data() != null) {
        orderModel = OrderModel.fromJson(value.data()!);
      }
    });
    return orderModel;
  }

  static Future<InterCityOrderModel?> getInterCityOrder(String orderId) async {
    InterCityOrderModel? orderModel;
    await fireStore
        .collection(CollectionName.ordersIntercity)
        .doc(orderId)
        .get()
        .then((value) {
      if (value.data() != null) {
        orderModel = InterCityOrderModel.fromJson(value.data()!);
      }
    });
    return orderModel;
  }

  static Future<bool?> acceptRide(
      OrderModel orderModel, DriverIdAcceptReject driverIdAcceptReject) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.orders)
        .doc(orderModel.id)
        .collection("acceptedDriver")
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

  static Future<bool?> setReview(ReviewModel reviewModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.reviewCustomer)
        .doc(reviewModel.id)
        .set(reviewModel.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<ReviewModel?> getReview(String orderId) async {
    ReviewModel? reviewModel;
    await fireStore
        .collection(CollectionName.reviewCustomer)
        .doc(orderId)
        .get()
        .then((value) {
      if (value.data() != null) {
        reviewModel = ReviewModel.fromJson(value.data()!);
      }
    });
    return reviewModel;
  }

  static Future<bool?> setInterCityOrder(InterCityOrderModel orderModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.ordersIntercity)
        .doc(orderModel.id)
        .set(orderModel.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<bool?> acceptInterCityRide(InterCityOrderModel orderModel,
      DriverIdAcceptReject driverIdAcceptReject) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.ordersIntercity)
        .doc(orderModel.id)
        .collection("acceptedDriver")
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

  static Future<List<WalletTransactionModel>?> getWalletTransaction() async {
    List<WalletTransactionModel> walletTransactionModel = [];

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
    }).catchError((error) {
      log(error.toString());
    });
    return walletTransactionModel;
  }

  static Future<bool?> setWalletTransaction(
      WalletTransactionModel walletTransactionModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.walletTransaction)
        .doc(walletTransactionModel.id)
        .set(walletTransactionModel.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<bool?> updatedDriverWallet({required String amount}) async {
    bool isAdded = false;
    await getDriverProfile(FireStoreUtils.getCurrentUid()).then((value) async {
      if (value != null) {
        DriverUserModel userModel = value;
        userModel.walletAmount =
            (double.parse(userModel.walletAmount.toString()) +
                    double.parse(amount))
                .toString();
        await FireStoreUtils.updateDriverUser(userModel).then((value) {
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

  static Future<List<OnBoardingModel>> getOnBoardingList() async {
    List<OnBoardingModel> onBoardingModel = [];
    await fireStore
        .collection(CollectionName.onBoarding)
        .where("type", isEqualTo: "driverApp")
        .get()
        .then((value) {
      for (var element in value.docs) {
        OnBoardingModel documentModel =
            OnBoardingModel.fromJson(element.data());
        onBoardingModel.add(documentModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return onBoardingModel;
  }

  static Future addInBox(InboxModel inboxModel) async {
    return await fireStore
        .collection(CollectionName.chat)
        .doc(inboxModel.orderId)
        .set(inboxModel.toJson())
        .then((document) {
      return inboxModel;
    });
  }

  static Future addChat(ConversationModel conversationModel) async {
    return await fireStore
        .collection(CollectionName.chat)
        .doc(conversationModel.orderId)
        .collection("thread")
        .doc(conversationModel.id)
        .set(conversationModel.toJson())
        .then((document) {
      return conversationModel;
    });
  }

  static Future<BankDetailsModel?> getBankDetails() async {
    BankDetailsModel? bankDetailsModel;
    await fireStore
        .collection(CollectionName.bankDetails)
        .doc(FireStoreUtils.getCurrentUid())
        .get()
        .then((value) {
      if (value.data() != null) {
        bankDetailsModel = BankDetailsModel.fromJson(value.data()!);
      }
    });
    return bankDetailsModel;
  }

  static Future<bool?> updateBankDetails(
      BankDetailsModel bankDetailsModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.bankDetails)
        .doc(bankDetailsModel.userId)
        .set(bankDetailsModel.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<bool?> setWithdrawRequest(WithdrawModel withdrawModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.withdrawalHistory)
        .doc(withdrawModel.id)
        .set(withdrawModel.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<List<WithdrawModel>> getWithDrawRequest() async {
    List<WithdrawModel> withdrawalList = [];
    await fireStore
        .collection(CollectionName.withdrawalHistory)
        .where('userId', isEqualTo: getCurrentUid())
        .orderBy('createdDate', descending: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        WithdrawModel documentModel = WithdrawModel.fromJson(element.data());
        withdrawalList.add(documentModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return withdrawalList;
  }

  static Future<bool?> deleteUser() async {
    bool? isDelete;
    try {
      await fireStore
          .collection(CollectionName.driverUsers)
          .doc(FireStoreUtils.getCurrentUid())
          .delete();

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
            } catch (error) {}
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

  static Future<List<ZoneModel>?> getZone() async {
    List<ZoneModel> airPortList = [];
    await fireStore
        .collection(CollectionName.zone)
        .where('publish', isEqualTo: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        ZoneModel ariPortModel = ZoneModel.fromJson(element.data());
        airPortList.add(ariPortModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return airPortList;
  }

  /// Get admin commission settings
  static Future<AdminCommission?> getAdminCommission() async {
    AdminCommission? adminCommission;
    try {
      final doc = await fireStore
          .collection(CollectionName.settings)
          .doc('adminCommission')
          .get();

      if (doc.exists && doc.data() != null) {
        adminCommission = AdminCommission.fromJson(doc.data()!);
      }
    } catch (e) {
      log('Error getting admin commission: $e');
    }
    return adminCommission;
  }

  // debugging................................................................................................

  /// Debug method to check driver's current status
  static Future<void> debugDriverStatus(String driverId) async {
    try {
      final driver = await getDriverProfile(driverId);
      if (driver != null) {
        print("🔍 DRIVER DEBUG STATUS:");
        print("   - ID: ${driver.id}");
        print("   - Name: ${driver.fullName}");
        print("   - Online: ${driver.isOnline}");
        print(
            "   - FCM Token: ${driver.fcmToken != null ? 'EXISTS' : 'MISSING'}");
        print("   - Verified: ${driver.documentVerification}");
        print("   - Approved: ${driver.approvalStatus}");
        print("   - Service ID: ${driver.serviceId}");
        print("   - Zone IDs: ${driver.zoneIds}");
        print(
            "   - Location: ${driver.location?.latitude},${driver.location?.longitude}");

        // Check if driver can receive orders
        if (driver.fcmToken == null) {
          print("❌ CANNOT RECEIVE ORDERS: No FCM token");
        }
        if (driver.isOnline != true) {
          print("❌ CANNOT RECEIVE ORDERS: Not online");
        }
        if (driver.documentVerification != true) {
          print("❌ CANNOT RECEIVE ORDERS: Documents not verified");
        }
        if (driver.approvalStatus != "approved") {
          print("❌ CANNOT RECEIVE ORDERS: Not approved");
        }
      }
    } catch (e) {
      print("❌ Error debugging driver status: $e");
    }
  }

  /// Check if driver can go online
  static Future<bool> canDriverGoOnline(String driverId) async {
    final driver = await getDriverProfile(driverId);
    if (driver == null) return false;

    return driver.fcmToken != null &&
        driver.fcmToken!.isNotEmpty &&
        driver.documentVerification == true &&
        driver.approvalStatus == "approved";
  }

  // ========== PAYMENT DATA PROTECTION METHODS ==========

  /// 🔥 CRITICAL: Safe order update for drivers that preserves payment data
  static Future<bool> safeDriverOrderUpdate(OrderModel orderModel) async {
    try {
      print(
          "🛡️  [DRIVER SAFE UPDATE] Starting safe update for order: ${orderModel.id}");

      // Debug payment data before update
      orderModel.debugPaymentData();

      // Validate that we're not overwriting payment data for Stripe orders
      if (orderModel.paymentType?.toLowerCase().contains("stripe") == true &&
          !orderModel.hasValidPaymentData()) {
        print(
            "🚨 [DRIVER SAFE UPDATE] CRITICAL: Attempting to save Stripe order with missing payment data!");

        // Try to recover payment data from Firestore first
        final currentOrder = await getOrder(orderModel.id!);
        if (currentOrder != null && currentOrder.hasValidPaymentData()) {
          print(
              "🔄 [DRIVER SAFE UPDATE] Recovering payment data from Firestore");
          orderModel.paymentIntentId = currentOrder.paymentIntentId;
          orderModel.preAuthAmount = currentOrder.preAuthAmount;
          orderModel.paymentIntentStatus = currentOrder.paymentIntentStatus;
          orderModel.preAuthCreatedAt = currentOrder.preAuthCreatedAt;
          orderModel.paymentCapturedAt = currentOrder.paymentCapturedAt;
          orderModel.paymentCanceledAt = currentOrder.paymentCanceledAt;
        } else {
          print(
              "❌ [DRIVER SAFE UPDATE] Cannot save - payment data permanently lost");
          return false;
        }
      }

      // Convert to JSON and remove null payment fields to prevent overwriting
      final orderJson = orderModel.toJson();

      // Remove null payment fields to prevent overwriting existing payment data
      orderJson.removeWhere((key, value) =>
          value == null &&
          [
            'paymentIntentId',
            'preAuthAmount',
            'paymentIntentStatus',
            'preAuthCreatedAt',
            'paymentCapturedAt',
            'paymentCanceledAt'
          ].contains(key));

      print("💾 [DRIVER SAFE UPDATE] Final data to save:");
      print("   status: ${orderJson['status']}");
      print("   paymentIntentId: ${orderJson['paymentIntentId']}");
      print("   preAuthAmount: ${orderJson['preAuthAmount']}");

      // Save with merge to preserve untouched fields
      await fireStore
          .collection(CollectionName.orders)
          .doc(orderModel.id)
          .set(orderJson, SetOptions(merge: true));

      print(
          "✅ [DRIVER SAFE UPDATE] Order updated successfully with payment data preserved");

      // Quick verification
      await Future.delayed(Duration(milliseconds: 300));
      final quickVerify = await fireStore
          .collection(CollectionName.orders)
          .doc(orderModel.id)
          .get();

      if (quickVerify.exists) {
        final data = quickVerify.data();
        print("🔍 [DRIVER SAFE UPDATE] Quick verification:");
        print("   paymentIntentId: ${data?['paymentIntentId']}");
        print("   preAuthAmount: ${data?['preAuthAmount']}");
      }

      return true;
    } catch (error) {
      print(
          "❌ [DRIVER SAFE UPDATE] Failed to update order ${orderModel.id}: $error");
      return false;
    }
  }

  /// 🔥 CRITICAL: Universal safe update method for drivers - PRESERVES PAYMENT DATA
  static Future<bool> safeDriverOrderUpdateFields(
      String orderId, Map<String, dynamic> updates) async {
    try {
      print(
          "🛡️  [DRIVER SAFE UPDATE FIELDS] Starting safe field update for order: $orderId");
      print("   Requested updates: $updates");

      // 🔥 STEP 1: Get current order state from Firestore
      final currentDoc =
          await fireStore.collection(CollectionName.orders).doc(orderId).get();

      if (!currentDoc.exists) {
        print("❌ [DRIVER SAFE UPDATE FIELDS] Order $orderId not found");
        return false;
      }

      final currentData = currentDoc.data()!;

      // 🔥 STEP 2: Extract and preserve payment data
      final preservedPaymentData = {
        'paymentIntentId': currentData['paymentIntentId'],
        'preAuthAmount': currentData['preAuthAmount'],
        'paymentIntentStatus': currentData['paymentIntentStatus'],
        'preAuthCreatedAt': currentData['preAuthCreatedAt'],
        'paymentCapturedAt': currentData['paymentCapturedAt'],
        'paymentCanceledAt': currentData['paymentCanceledAt'],
        'paymentType': currentData['paymentType'],
      };

      print("🔒 [DRIVER SAFE UPDATE FIELDS] Preserved payment data:");
      print("   paymentIntentId: ${preservedPaymentData['paymentIntentId']}");
      print("   preAuthAmount: ${preservedPaymentData['preAuthAmount']}");

      // 🔥 STEP 3: Merge updates with preserved payment data
      final safeUpdateData = {
        ...updates,
        ...preservedPaymentData, // This OVERRIDES any payment fields in updates
        'updateDate': FieldValue.serverTimestamp(),
      };

      // Remove any null values that might overwrite existing data
      safeUpdateData.removeWhere((key, value) => value == null);

      print("💾 [DRIVER SAFE UPDATE FIELDS] Final safe update data:");
      safeUpdateData.forEach((key, value) {
        print("   $key: $value");
      });

      // 🔥 STEP 4: Perform the update
      await fireStore
          .collection(CollectionName.orders)
          .doc(orderId)
          .update(safeUpdateData);

      print(
          "✅ [DRIVER SAFE UPDATE FIELDS] Order updated safely with payment data preserved");

      // 🔥 STEP 5: Verify the update
      await Future.delayed(Duration(milliseconds: 500));
      final verifyDoc =
          await fireStore.collection(CollectionName.orders).doc(orderId).get();

      if (verifyDoc.exists) {
        final verifiedData = verifyDoc.data()!;
        final paymentStillValid = verifiedData['paymentIntentId'] != null &&
            verifiedData['paymentIntentId'] ==
                preservedPaymentData['paymentIntentId'];

        if (paymentStillValid) {
          print(
              "✅ [DRIVER SAFE UPDATE FIELDS] Payment data verified - still intact");
          return true;
        } else {
          print(
              "🚨 [DRIVER SAFE UPDATE FIELDS] WARNING: Payment data may have been affected");
          return false;
        }
      }

      return true;
    } catch (error) {
      print("❌ [DRIVER SAFE UPDATE FIELDS] Error: $error");
      return false;
    }
  }

  /// 🔥 CRITICAL: Safe OTP verification that preserves payment data
  static Future<bool> safeUpdateAfterOTPVerification(
      String orderId, String enteredOTP) async {
    try {
      print(
          "🛡️  [DRIVER SAFE OTP] Starting safe OTP update for order: $orderId");

      // Get current order first
      final currentOrder = await getOrder(orderId);
      if (currentOrder == null) {
        print("❌ [DRIVER SAFE OTP] Order $orderId not found");
        return false;
      }

      // Validate OTP
      if (currentOrder.otp != enteredOTP) {
        print("❌ [DRIVER SAFE OTP] Invalid OTP");
        return false;
      }

      print("🔍 [DRIVER SAFE OTP] Before OTP verification - Payment state:");
      currentOrder.debugPaymentData();

      // Use safe field update method
      return await safeDriverOrderUpdateFields(orderId, {
        'status': Constant.rideInProgress,
        'updateDate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("❌ [DRIVER SAFE OTP] Error: $e");
      return false;
    }
  }

  /// 🔥 CRITICAL: Safe ride completion that preserves payment data
  static Future<bool> safeCompleteRide(String orderId) async {
    try {
      print(
          "🛡️  [DRIVER SAFE COMPLETE] Starting safe ride completion for order: $orderId");

      // Get current order first
      final currentOrder = await getOrder(orderId);
      if (currentOrder == null) {
        print("❌ [DRIVER SAFE COMPLETE] Order $orderId not found");
        return false;
      }

      print("🔍 [DRIVER SAFE COMPLETE] Before completion - Payment state:");
      currentOrder.debugPaymentData();

      // Use safe field update method
      return await safeDriverOrderUpdateFields(orderId, {
        'status': Constant.rideComplete,
        'updateDate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("❌ [DRIVER SAFE COMPLETE] Error: $e");
      return false;
    }
  }

  /// 🔥 CRITICAL: Enhanced setOrder with payment data protection
  static Future<bool> setOrderWithPaymentProtection(
      OrderModel orderModel) async {
    try {
      print(
          "🛡️  [DRIVER SET ORDER PROTECTED] Saving order ${orderModel.id} with payment protection");

      // Debug payment data before save
      orderModel.debugPaymentData();

      // Convert to JSON and remove null payment fields
      final orderJson = orderModel.toJson();

      // Remove null payment fields to prevent overwriting existing payment data
      orderJson.removeWhere((key, value) =>
          value == null &&
          [
            'paymentIntentId',
            'preAuthAmount',
            'paymentIntentStatus',
            'preAuthCreatedAt',
            'paymentCapturedAt',
            'paymentCanceledAt'
          ].contains(key));

      // Save with merge to preserve untouched fields
      await fireStore
          .collection(CollectionName.orders)
          .doc(orderModel.id)
          .set(orderJson, SetOptions(merge: true));

      print(
          "✅ [DRIVER SET ORDER PROTECTED] Order saved successfully with payment protection");

      // Quick verification
      await Future.delayed(Duration(milliseconds: 300));
      final quickVerify = await fireStore
          .collection(CollectionName.orders)
          .doc(orderModel.id)
          .get();

      if (quickVerify.exists) {
        final data = quickVerify.data();
        print("🔍 [DRIVER SET ORDER PROTECTED] Quick verification:");
        print("   paymentIntentId: ${data?['paymentIntentId']}");
        print("   preAuthAmount: ${data?['preAuthAmount']}");
      }

      return true;
    } catch (error) {
      print(
          "❌ [DRIVER SET ORDER PROTECTED] Failed to save order ${orderModel.id}: $error");
      return false;
    }
  }

  /// Emergency recovery for lost payment data
  static Future<bool> emergencyPaymentRecovery(String orderId) async {
    try {
      print(
          "🆘 [EMERGENCY RECOVERY] Attempting payment data recovery for order: $orderId");

      // Get the current corrupted order
      final currentOrder = await getOrder(orderId);
      if (currentOrder == null) {
        print("❌ [EMERGENCY RECOVERY] Order not found");
        return false;
      }

      // Check if recovery is needed
      if (currentOrder.hasValidPaymentData()) {
        print("✅ [EMERGENCY RECOVERY] Order already has valid payment data");
        return true;
      }

      // Try to find the original payment data from order history or logs
      print("🔍 [EMERGENCY RECOVERY] Searching for original payment data...");

      // For now, we'll log the issue and return false
      print(
          "🚨 [EMERGENCY RECOVERY] CRITICAL: Payment data permanently lost for order: $orderId");
      print("   This requires manual intervention with Stripe dashboard");
      print("   Order ID: $orderId");
      print("   Contact support with this information");

      return false;
    } catch (e) {
      print("❌ [EMERGENCY RECOVERY] Error: $e");
      return false;
    }
  }

  /// Validate payment data before critical operations
  static Future<bool> validatePaymentDataBeforeUpdate(String orderId) async {
    try {
      final order = await getOrder(orderId);
      if (order == null) {
        print("❌ [PAYMENT VALIDATION] Order $orderId not found");
        return false;
      }

      if (order.paymentType?.toLowerCase().contains("stripe") == true) {
        if (!order.hasValidPaymentData()) {
          print(
              "🚨 [PAYMENT VALIDATION] Payment data missing for Stripe order $orderId");
          print("   Payment Type: ${order.paymentType}");
          print("   Payment Intent ID: ${order.paymentIntentId}");
          print("   Pre-auth Amount: ${order.preAuthAmount}");
          return false;
        } else {
          print(
              "✅ [PAYMENT VALIDATION] Payment data validated for order $orderId");
          return true;
        }
      }

      // Non-Stripe payments don't need validation
      return true;
    } catch (e) {
      print("❌ [PAYMENT VALIDATION] Error: $e");
      return false;
    }
  }

  /// Enhanced getOrder with payment data validation
  static Future<OrderModel?> getOrderWithPaymentValidation(
      String orderId) async {
    try {
      final order = await getOrder(orderId);
      if (order == null) {
        print("❌ [GET ORDER VALIDATED] Order $orderId not found");
        return null;
      }

      // Validate payment data for Stripe orders
      if (order.paymentType?.toLowerCase().contains("stripe") == true &&
          !order.hasValidPaymentData()) {
        print(
            "🚨 [GET ORDER VALIDATED] WARNING: Payment data missing for Stripe order $orderId");
        print("   This may cause payment processing issues");
      }

      return order;
    } catch (e) {
      print("❌ [GET ORDER VALIDATED] Error: $e");
      return null;
    }
  }
}

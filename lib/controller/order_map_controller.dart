import 'dart:async';
import 'dart:math';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/order_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart' as prefix;
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class OrderMapController extends GetxController {
  final Completer<GoogleMapController> mapController = Completer<GoogleMapController>();
  Rx<TextEditingController> enterOfferRateController = TextEditingController().obs;

  RxBool isLoading = true.obs;
  RxString errorMessage = ''.obs;

  @override
  void onInit() {
    if (Constant.selectedMapType == 'osm') {
      ShowToastDialog.showLoader("Please wait");
      mapOsmController = MapController(
        initPosition: GeoPoint(latitude: 20.9153, longitude: -100.7439),
        useExternalTracking: false,
      );
    }
    addMarkerSetup();
    getArgument();
    super.onInit();
  }

  @override
  void onClose() {
    ShowToastDialog.closeLoader();
    super.onClose();
  }

  Rx<OrderModel?> orderModel = Rx<OrderModel?>(null);
  Rx<DriverUserModel?> driverModel = Rx<DriverUserModel?>(null);

  RxString newAmount = "0.0".obs;

  getArgument() async {
    try {
      dynamic argumentData = Get.arguments;
      if (argumentData != null && argumentData['orderModel'] != null) {
        String orderId = argumentData['orderModel'];
        await getData(orderId);
        
        if (orderModel.value != null) {
          newAmount.value = orderModel.value!.offerRate?.toString() ?? "0.0";
          enterOfferRateController.value.text = orderModel.value!.offerRate?.toString() ?? "0.0";
          
          // Debug print to check the location data
          debugPrint("Source Location: ${orderModel.value!.sourceLocationLAtLng?.toJson()}");
          debugPrint("Destination Location: ${orderModel.value!.destinationLocationLAtLng?.toJson()}");
          
          if (Constant.selectedMapType == 'google') {
            getPolyline();
          } else if (Constant.selectedMapType == 'osm') {
            // You'll need to pass themeChange somehow, maybe through Get.find or parameters
            getOSMPolyline(false); // Default to light theme for now
          }
        }
      }

      FireStoreUtils.fireStore
          .collection(CollectionName.driverUsers)
          .doc(FireStoreUtils.getCurrentUid())
          .snapshots()
          .listen((event) {
        if (event.exists && event.data() != null) {
          driverModel.value = DriverUserModel.fromJson(event.data()!);
        }
      });
      
      isLoading.value = false;
    } catch (e) {
      errorMessage.value = "Error loading data: $e";
      isLoading.value = false;
      ShowToastDialog.closeLoader();
    }
  }

  getData(String id) async {
    try {
      OrderModel? value = await FireStoreUtils.getOrder(id);
      if (value != null) {
        orderModel.value = value;
        
        // Check if we have valid coordinates
        if (value.sourceLocationLAtLng == null || value.destinationLocationLAtLng == null) {
          errorMessage.value = "Missing location coordinates in order data";
          debugPrint("Order data missing coordinates: ${value.toJson()}");
        }
      } else {
        errorMessage.value = "Order not found";
      }
    } catch (e) {
      errorMessage.value = "Error fetching order: $e";
    }
  }

  BitmapDescriptor? departureIcon;
  BitmapDescriptor? destinationIcon;

  addMarkerSetup() async {
    try {
      if (Constant.selectedMapType == 'google') {
        final Uint8List departure = await Constant.getBytesFromAsset('assets/images/pickup.png', 100);
        final Uint8List destination = await Constant.getBytesFromAsset('assets/images/dropoff.png', 100);
        departureIcon = BitmapDescriptor.fromBytes(departure);
        destinationIcon = BitmapDescriptor.fromBytes(destination);
      } else {
        departureOsmIcon = Image.asset("assets/images/pickup.png", width: 30, height: 30);
        destinationOsmIcon = Image.asset("assets/images/dropoff.png", width: 30, height: 30);
      }
    } catch (e) {
      debugPrint("Error setting up markers: $e");
    }
  }

  RxMap<MarkerId, Marker> markers = <MarkerId, Marker>{}.obs;
  RxMap<PolylineId, Polyline> polyLines = <PolylineId, Polyline>{}.obs;
  PolylinePoints polylinePoints = PolylinePoints();

  void getPolyline() async {
    try {
      // Check if we have valid coordinates (note the uppercase LAtLng)
      if (orderModel.value?.sourceLocationLAtLng != null && 
          orderModel.value?.destinationLocationLAtLng != null) {
        
        movePosition();
        List<LatLng> polylineCoordinates = [];
        
        PolylineRequest polylineRequest = PolylineRequest(
          origin: PointLatLng(
            orderModel.value!.sourceLocationLAtLng!.latitude ?? 0.0, 
            orderModel.value!.sourceLocationLAtLng!.longitude ?? 0.0
          ),
          destination: PointLatLng(
            orderModel.value!.destinationLocationLAtLng!.latitude ?? 0.0, 
            orderModel.value!.destinationLocationLAtLng!.longitude ?? 0.0
          ),
          mode: TravelMode.driving,
        );
        
        PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
          googleApiKey: Constant.mapAPIKey,
          request: polylineRequest,
        );
        
        if (result.points.isNotEmpty) {
          for (var point in result.points) {
            polylineCoordinates.add(LatLng(point.latitude, point.longitude));
          }
        } else {
          debugPrint("Polyline error: ${result.errorMessage}");
          errorMessage.value = "Could not calculate route: ${result.errorMessage}";
        }
        
        _addPolyLine(polylineCoordinates);
        
        // Add markers with null safety
        if (departureIcon != null) {
          addMarker(
            LatLng(
              orderModel.value!.sourceLocationLAtLng!.latitude ?? 0.0, 
              orderModel.value!.sourceLocationLAtLng!.longitude ?? 0.0
            ), 
            "Source", 
            departureIcon!
          );
        }
        
        if (destinationIcon != null) {
          addMarker(
            LatLng(
              orderModel.value!.destinationLocationLAtLng!.latitude ?? 0.0, 
              orderModel.value!.destinationLocationLAtLng!.longitude ?? 0.0
            ), 
            "Destination", 
            destinationIcon!
          );
        }
      } else {
        errorMessage.value = "Missing location coordinates for route calculation";
        debugPrint("Missing coordinates for polyline");
      }
    } catch (e) {
      errorMessage.value = "Error calculating route: $e";
      debugPrint("Error getting polyline: $e");
    }
  }

  double zoomLevel = 0;

  movePosition() async {
    try {
      if (orderModel.value?.sourceLocationLAtLng != null && 
          orderModel.value?.destinationLocationLAtLng != null) {
        
        double distance = double.parse(
          (prefix.Geolocator.distanceBetween(
            orderModel.value!.sourceLocationLAtLng!.latitude ?? 0.0,
            orderModel.value!.sourceLocationLAtLng!.longitude ?? 0.0,
            orderModel.value!.destinationLocationLAtLng!.latitude ?? 0.0,
            orderModel.value!.destinationLocationLAtLng!.longitude ?? 0.0,
          ) / 1609.32).toString()
        );
        
        LatLng center = LatLng(
          ((orderModel.value!.sourceLocationLAtLng!.latitude ?? 0.0) + 
           (orderModel.value!.destinationLocationLAtLng!.latitude ?? 0.0)) / 2,
          ((orderModel.value!.sourceLocationLAtLng!.longitude ?? 0.0) + 
           (orderModel.value!.destinationLocationLAtLng!.longitude ?? 0.0)) / 2,
        );

        double radiusElevated = (distance / 2) + ((distance / 2) / 2);
        double scale = radiusElevated / 500;
        zoomLevel = 5 - log(scale) / log(2);

        final GoogleMapController controller = await mapController.future;
        controller.moveCamera(CameraUpdate.newLatLngZoom(center, zoomLevel));
      }
    } catch (e) {
      debugPrint("Error moving position: $e");
    }
  }

  _addPolyLine(List<LatLng> polylineCoordinates) {
    try {
      PolylineId id = const PolylineId("poly");
      Polyline polyline = Polyline(
        polylineId: id,
        points: polylineCoordinates,
        width: 6,
        color: Colors.blue,
      );
      polyLines[id] = polyline;
    } catch (e) {
      debugPrint("Error adding polyline: $e");
    }
  }

  addMarker(LatLng position, String id, BitmapDescriptor descriptor) {
    try {
      MarkerId markerId = MarkerId(id);
      Marker marker = Marker(
        markerId: markerId, 
        icon: descriptor, 
        position: position,
        infoWindow: InfoWindow(title: id),
      );
      markers[markerId] = marker;
    } catch (e) {
      debugPrint("Error adding marker: $e");
    }
  }

  // OSM
  late MapController mapOsmController;
  Rx<RoadInfo> roadInfo = RoadInfo().obs;
  Map<String, GeoPoint> osmMarkers = <String, GeoPoint>{};
  Image? departureOsmIcon;
  Image? destinationOsmIcon;

  void getOSMPolyline(bool themeChange) async {
    try {
      if (orderModel.value?.sourceLocationLAtLng != null && 
          orderModel.value?.destinationLocationLAtLng != null) {
        
        setOsmMarker(
          departure: GeoPoint(
            latitude: orderModel.value!.sourceLocationLAtLng?.latitude ?? 0.0, 
            longitude: orderModel.value!.sourceLocationLAtLng?.longitude ?? 0.0
          ),
          destination: GeoPoint(
            latitude: orderModel.value!.destinationLocationLAtLng?.latitude ?? 0.0, 
            longitude: orderModel.value!.destinationLocationLAtLng?.longitude ?? 0.0
          ),
        );
        
        await mapOsmController.removeLastRoad();
        
        roadInfo.value = await mapOsmController.drawRoad(
          GeoPoint(
            latitude: orderModel.value!.sourceLocationLAtLng?.latitude ?? 0.0, 
            longitude: orderModel.value!.sourceLocationLAtLng?.longitude ?? 0.0
          ),
          GeoPoint(
            latitude: orderModel.value!.destinationLocationLAtLng?.latitude ?? 0.0, 
            longitude: orderModel.value!.destinationLocationLAtLng?.longitude ?? 0.0
          ),
          roadType: RoadType.car,
          roadOption: RoadOption(
            roadWidth: 15,
            roadColor: themeChange ? AppColors.darkModePrimary : AppColors.primary,
            zoomInto: false,
          ),
        );

        updateCameraLocation(
          source: GeoPoint(
            latitude: orderModel.value!.sourceLocationLAtLng?.latitude ?? 0.0, 
            longitude: orderModel.value!.sourceLocationLAtLng?.longitude ?? 0.0
          ),
          destination: GeoPoint(
            latitude: orderModel.value!.destinationLocationLAtLng?.latitude ?? 0.0, 
            longitude: orderModel.value!.destinationLocationLAtLng?.longitude ?? 0.0
          ),
        );
      }
    } catch (e) {
      errorMessage.value = "Error drawing OSM route: $e";
      debugPrint('Error in OSM polyline: $e');
    }
  }

  Future<void> updateCameraLocation({required GeoPoint source, required GeoPoint destination}) async {
    try {
      BoundingBox bounds;

      if (source.latitude > destination.latitude && source.longitude > destination.longitude) {
        bounds = BoundingBox(
          north: source.latitude,
          south: destination.latitude,
          east: source.longitude,
          west: destination.longitude,
        );
      } else if (source.longitude > destination.longitude) {
        bounds = BoundingBox(
          north: destination.latitude,
          south: source.latitude,
          east: source.longitude,
          west: destination.longitude,
        );
      } else if (source.latitude > destination.latitude) {
        bounds = BoundingBox(
          north: source.latitude,
          south: destination.latitude,
          east: destination.longitude,
          west: source.longitude,
        );
      } else {
        bounds = BoundingBox(
          north: destination.latitude,
          south: source.latitude,
          east: destination.longitude,
          west: source.longitude,
        );
      }

      await mapOsmController.zoomToBoundingBox(bounds, paddinInPixel: 300);
    } catch (e) {
      debugPrint("Error updating camera location: $e");
    }
  }

  setOsmMarker({required GeoPoint departure, required GeoPoint destination}) async {
    try {
      if (osmMarkers.containsKey('Source')) {
        await mapOsmController.removeMarker(osmMarkers['Source']!);
      }
      
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await mapOsmController
            .addMarker(
              departure,
              markerIcon: MarkerIcon(iconWidget: departureOsmIcon),
              angle: pi / 3,
              iconAnchor: IconAnchor(anchor: Anchor.top),
            )
            .then((v) {
          osmMarkers['Source'] = departure;
        });

        if (osmMarkers.containsKey('Destination')) {
          await mapOsmController.removeMarker(osmMarkers['Destination']!);
        }

        await mapOsmController
            .addMarker(
              destination,
              markerIcon: MarkerIcon(iconWidget: destinationOsmIcon),
              angle: pi / 3,
              iconAnchor: IconAnchor(anchor: Anchor.top),
            )
            .then((v) {
          osmMarkers['Destination'] = destination;
        });
      });
    } catch (e) {
      debugPrint("Error setting OSM markers: $e");
    }
  }
}
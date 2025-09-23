import 'dart:async';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/model/order/location_lat_lng.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();
  LocationService._();

  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _locationRetryTimer;
  int _retryCount = 0;
  static const int maxRetries = 3;

  /// Get current location with high accuracy and proper error handling
  Future<LocationLatLng?> getCurrentLocation({bool showLoader = true}) async {
    try {
      if (showLoader) {
        ShowToastDialog.showLoader("Getting location...");
      }

      // Check and request permissions
      bool hasPermission = await _checkAndRequestPermissions();
      if (!hasPermission) {
        if (showLoader) ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Location permission is required");
        return null;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (showLoader) ShowToastDialog.closeLoader();
        bool opened = await Geolocator.openLocationSettings();
        if (!opened) {
          ShowToastDialog.showToast("Please enable location services");
          return null;
        }
        // Wait a bit for settings to be applied
        await Future.delayed(const Duration(seconds: 2));
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          ShowToastDialog.showToast("Location services are still disabled");
          return null;
        }
      }

      // Get current position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      LocationLatLng location = LocationLatLng(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      Constant.currentLocation = location;
      
      if (showLoader) ShowToastDialog.closeLoader();
      _retryCount = 0; // Reset retry count on success
      
      return location;

    } catch (e) {
      if (showLoader) ShowToastDialog.closeLoader();
      
      // Handle specific errors
      if (e is LocationServiceDisabledException) {
        ShowToastDialog.showToast("Location services are disabled");
        return await _retryWithFallback();
      } else if (e is PermissionDeniedException) {
        ShowToastDialog.showToast("Location permission denied");
        return null;
      } else if (e is TimeoutException) {
        ShowToastDialog.showToast("Location request timed out");
        return await _retryWithFallback();
      } else {
        ShowToastDialog.showToast("Failed to get location: ${e.toString()}");
        return await _retryWithFallback();
      }
    }
  }

  /// Retry getting location with fallback to lower accuracy
  Future<LocationLatLng?> _retryWithFallback() async {
    if (_retryCount >= maxRetries) {
      ShowToastDialog.showToast("Unable to get precise location after multiple attempts");
      return null;
    }

    _retryCount++;
    
    try {
      // Try with lower accuracy and longer timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: _retryCount == 1 
            ? LocationAccuracy.medium 
            : LocationAccuracy.low,
        timeLimit: Duration(seconds: 10 + (_retryCount * 5)),
      );

      LocationLatLng location = LocationLatLng(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      Constant.currentLocation = location;
      return location;

    } catch (e) {
      if (_retryCount < maxRetries) {
        // Wait before retrying
        await Future.delayed(Duration(seconds: _retryCount * 2));
        return await _retryWithFallback();
      }
      return null;
    }
  }

  /// Check and request location permissions
  Future<bool> _checkAndRequestPermissions() async {
    // Check location permission
    PermissionStatus locationStatus = await Permission.location.status;
    
    if (locationStatus.isDenied) {
      locationStatus = await Permission.location.request();
    }

    if (locationStatus.isPermanentlyDenied) {
      // Show dialog to open app settings
      bool shouldOpenSettings = await _showPermissionDialog();
      if (shouldOpenSettings) {
        await openAppSettings();
      }
      return false;
    }

    return locationStatus.isGranted;
  }

  /// Show permission dialog
  Future<bool> _showPermissionDialog() async {
    return await Get.dialog<bool>(
      AlertDialog(
        title: Text("Location Permission Required".tr),
        content: Text(
          "This app needs location permission to show nearby rides and track your location during trips.".tr,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text("Cancel".tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text("Open Settings".tr),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Start continuous location tracking for drivers
  Future<void> startLocationTracking({
    required Function(LocationLatLng) onLocationUpdate,
    int intervalSeconds = 10,
  }) async {
    // Stop any existing tracking
    stopLocationTracking();

    try {
      bool hasPermission = await _checkAndRequestPermissions();
      if (!hasPermission) return;

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      );

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          LocationLatLng location = LocationLatLng(
            latitude: position.latitude,
            longitude: position.longitude,
          );
          
          Constant.currentLocation = location;
          onLocationUpdate(location);
        },
        onError: (error) {
          print("Location tracking error: $error");
          // Try to restart tracking after a delay
          _locationRetryTimer = Timer(const Duration(seconds: 30), () {
            startLocationTracking(
              onLocationUpdate: onLocationUpdate,
              intervalSeconds: intervalSeconds,
            );
          });
        },
      );

    } catch (e) {
      print("Failed to start location tracking: $e");
    }
  }

  /// Stop location tracking
  void stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _locationRetryTimer?.cancel();
    _locationRetryTimer = null;
  }

  /// Check if location services are available
  Future<bool> isLocationServiceAvailable() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();
    
    return serviceEnabled && 
           (permission == LocationPermission.always || 
            permission == LocationPermission.whileInUse);
  }

  /// Get distance between two points in kilometers
  static double getDistanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    ) / 1000; // Convert to kilometers
  }

  /// Format distance for display
  static String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return "${(distanceInKm * 1000).round()} m";
    } else {
      return "${distanceInKm.toStringAsFixed(1)} km";
    }
  }
}
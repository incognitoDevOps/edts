import 'dart:async';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/utils.dart';
import 'package:customer/widget/osm_map_search_place.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:get/get.dart';
import 'package:osm_nominatim/osm_nominatim.dart';
import 'package:provider/provider.dart';

class LocationPicker extends StatefulWidget {
  final bool isSource;
  const LocationPicker({super.key, this.isSource = true});

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  GeoPoint? selectedLocation;
  late MapController mapController;
  Place? place;
  TextEditingController textController = TextEditingController();
  List<GeoPoint> _markers = [];
  bool _isLoading = false;
  Timer? _regionChangeDebounce;

  @override
  void initState() {
    super.initState();
    mapController = MapController(
      initMapWithUserPosition: const UserTrackingOption(enableTracking: false, unFollowUser: true),
    );
    // Listen for map movement and update marker/address
    mapController.listenerMapSingleTapping.addListener(() async {
      if (mapController.listenerMapSingleTapping.value != null) {
        setState(() {
          _isLoading = true;
        });
        GeoPoint position = mapController.listenerMapSingleTapping.value!;
        await addMarker(position);
        setState(() {
          _isLoading = false;
        });
      }
    });
    mapController.listenerMapLongTapping.addListener(() async {
      if (mapController.listenerMapLongTapping.value != null) {
        setState(() {
          _isLoading = true;
        });
        GeoPoint position = mapController.listenerMapLongTapping.value!;
        await addMarker(position);
        setState(() {
          _isLoading = false;
        });
      }
    });
    mapController.listenerRegionIsChanging.addListener(() async {
      // Called when the map is being moved
      // We only want to update when the movement stops, so debounce
      if (_regionChangeDebounce != null) {
        _regionChangeDebounce!.cancel();
      }
      _regionChangeDebounce = Timer(const Duration(milliseconds: 500), () async {
        final center = await mapController.centerMap;
        setState(() {
          _isLoading = true;
        });
        await addMarker(center);
        setState(() {
          _isLoading = false;
        });
      });
    });
  }

  _listerTapPosition() async {
    mapController.listenerMapSingleTapping.addListener(() async {
      if (mapController.listenerMapSingleTapping.value != null) {
      setState(() {
          _isLoading = true;
      });
        GeoPoint position = mapController.listenerMapSingleTapping.value!;
        await addMarker(position);
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  addMarker(GeoPoint? position) async {
    if (position != null) {
      for (var marker in _markers) {
        await mapController.removeMarker(marker);
      }
      setState(() {
        _markers.clear();
      });

      // Add marker to the map
      await mapController
          .addMarker(position,
                markerIcon: const MarkerIcon(
                  icon: Icon(Icons.location_on, size: 26),
                ))
            .then((v) {
          _markers.add(position);
        });

      // Fetch location data with a timeout
    try {
        place = await Nominatim.reverseSearch(
          lat: position.latitude,
          lon: position.longitude,
          zoom: 14,
          addressDetails: true,
          extraTags: true,
          nameDetails: true,
        ).timeout(const Duration(seconds: 5), onTimeout: () {
          throw Exception('Location search timed out');
      });
        setState(() {});
    } catch (e) {
        print("Error fetching location: $e");
        // Set a default placeholder if reverse geocoding fails
        place = Place(
          placeId: 0, // fallback id as int
          osmId: 0, // fallback OSM id
          osmType: "unknown", // fallback type
          displayName: "Selected location",
          lat: position.latitude, // as double
          lon: position.longitude, // as double
          boundingBox: [
            position.latitude.toString(),
            position.latitude.toString(),
            position.longitude.toString(),
            position.longitude.toString(),
          ],
          placeRank: 0, // fallback rank
          category: "unknown", // fallback category
          type: "unknown", // fallback type
          importance: 0.0, // fallback importance
    );
        setState(() {});
  }

      mapController.moveTo(position, animate: true);
    }
  }

  Future<void> _setUserLocation() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final locationData = await Utils.getCurrentLocation();
      selectedLocation = GeoPoint(
        latitude: locationData.latitude,
        longitude: locationData.longitude,
    );
      await addMarker(selectedLocation!);
      mapController.moveTo(selectedLocation!, animate: true);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error getting location: $e");
      // Handle error (e.g., show a snackbar to the user)
  }
}

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Picker'),
      ),
      body: Stack(
        children: [
          OSMFlutter(
            controller: mapController,
            mapIsLoading: const Center(child: CircularProgressIndicator()),
            osmOption: OSMOption(
              userLocationMarker: UserLocationMaker(
                  personMarker: MarkerIcon(iconWidget: Image.asset("assets/images/pickup.png")),
                  directionArrowMarker: MarkerIcon(iconWidget: Image.asset("assets/images/pickup.png"))),
              isPicker: true,
              zoomOption: const ZoomOption(initZoom: 14),
            ),
            onMapIsReady: (active) {
              if (active) {
                _setUserLocation();
                _listerTapPosition();
              }
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          if (place?.displayName != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(bottom: 100, left: 40, right: 40),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        place?.displayName ?? '',
                        style: const TextStyle(fontSize: 16,color: Colors.black),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: (_isLoading || (place?.displayName == null || place!.displayName!.isEmpty))
                          ? null
                          : () {
                              Get.back(result: place);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (_isLoading || (place?.displayName == null || place!.displayName!.isEmpty))
                            ? Colors.grey[400]
                            : (themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: Text(
                        widget.isSource ? 'Confirm Pickup' : 'Confirm Destination',
                        style: TextStyle(
                          color: (_isLoading || (place?.displayName == null || place!.displayName!.isEmpty))
                              ? Colors.white.withOpacity(0.7)
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 00),
                  child: InkWell(
                    onTap: () async {
                      Get.to(const OsmSearchPlacesApi())?.then((value) async {
                        if (value != null) {
                          setState(() {
                            _isLoading = true;
                          });
                          SearchInfo place = value;
                          textController = TextEditingController(text: place.address.toString());
                          await addMarker(place.point);
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      });
                    },
                    child: buildTextField(
                      title: "Search Address".tr,
                      textController: textController,
                    ),
                  ),
                )),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _setUserLocation,
        child: Icon(Icons.my_location, color: themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary),
      ),
    );
  }

  Widget buildTextField({required title, required TextEditingController textController}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: TextField(
        controller: textController,
        textInputAction: TextInputAction.done,
        style: TextStyle(color: Colors.black),
        decoration: InputDecoration(
          prefixIcon: IconButton(
            icon: const Icon(Icons.location_on,color: Colors.black,),
            onPressed: () {},
          ),
          fillColor: Colors.white,
          filled: true,
          hintText: title,
          hintStyle: TextStyle(color: Colors.black),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          enabled: false,
        ),
      ),
    );
  }
}

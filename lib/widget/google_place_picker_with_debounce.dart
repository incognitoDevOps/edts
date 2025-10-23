import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';

class GooglePlacePickerWithDebounce extends StatefulWidget {
  final String apiKey;
  final LatLng initialPosition;
  final bool isSource;
  final Function(PickResult) onPlacePicked;
  final bool useCurrentLocation;

  const GooglePlacePickerWithDebounce({
    Key? key,
    required this.apiKey,
    required this.initialPosition,
    required this.isSource,
    required this.onPlacePicked,
    this.useCurrentLocation = true,
  }) : super(key: key);

  @override
  State<GooglePlacePickerWithDebounce> createState() =>
      _GooglePlacePickerWithDebounceState();
}

class _GooglePlacePickerWithDebounceState
    extends State<GooglePlacePickerWithDebounce> {
  final ValueNotifier<bool> _isButtonEnabled = ValueNotifier(false);
  final ValueNotifier<bool> _isLoading = ValueNotifier(true);
  PickResult? _currentPlace;
  Timer? _debounceTimer;
  bool _isCameraMoving = false;
  PickResult? _lastSelectedPlace;
  late GooglePlace _googlePlace;
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _googlePlace = GooglePlace(widget.apiKey);
    _currentLocation = widget.initialPosition;
    debugPrint("[Init] Google Place Picker initialized with initial position: ${widget.initialPosition}");
    
    // Simulate a small delay to show loading state
    Future.delayed(const Duration(milliseconds: 500), () {
      _isLoading.value = false;
    });
  }

  void _debounceEnableButton(PickResult? place) async {
    _isButtonEnabled.value = false;
    _debounceTimer?.cancel();
    debugPrint("[Debounce] Start debounce for: ${place?.formattedAddress}");

    _debounceTimer = Timer(const Duration(seconds: 1), () async {
      if (place == null || (place.formattedAddress?.isEmpty ?? true)) {
        debugPrint("[Debounce] Invalid or empty place.");
        return;
      }

      LatLng? resolvedLatLng;

      if (place.geometry?.location != null) {
        final lat = place.geometry!.location.lat;
        final lng = place.geometry!.location.lng;
        resolvedLatLng = LatLng(lat, lng);
        _currentLocation = resolvedLatLng;
        debugPrint("[Debounce] Found geometry locally: ($lat, $lng)");
      } else if (place.placeId != null) {
        debugPrint("[Debounce] Missing geometry, fetching place details...");
        try {
          final details = await _googlePlace.details.get(place.placeId!);
          final location = details?.result?.geometry?.location;
          if (location != null) {
            resolvedLatLng = LatLng(location.lat!, location.lng!);
            _currentLocation = resolvedLatLng;
            debugPrint(
                "[Debounce] Fetched geometry from API: (${location.lat}, ${location.lng})");
          } else {
            debugPrint("[Debounce] Place details returned no location.");
          }
        } catch (e) {
          debugPrint("[Debounce] Error fetching place details: $e");
        }
      }

      if (resolvedLatLng != null && place != _lastSelectedPlace) {
        _isButtonEnabled.value = true;
        _lastSelectedPlace = place;
        debugPrint("[Debounce] Confirm button enabled.");
      } else {
        debugPrint("[Debounce] Coordinates still missing or place is same.");
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _isButtonEnabled.dispose();
    _isLoading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: _isLoading,
          builder: (context, isLoading, _) {
            return isLoading
                ? const Center(child: CircularProgressIndicator())
                : PlacePicker(
                    apiKey: widget.apiKey,
                    initialPosition: _currentLocation ?? widget.initialPosition,
                    useCurrentLocation: widget.useCurrentLocation,
                    selectInitialPosition: true,
                    usePinPointingSearch: true,
                    usePlaceDetailSearch: true,
                    zoomGesturesEnabled: true,
                    zoomControlsEnabled: true,
                    resizeToAvoidBottomInset: false,
                    onMapCreated: (controller) {
                      debugPrint("[Map] Map created with initial position: $_currentLocation");
                    },
                    onPlacePicked: (place) {
                      debugPrint("[Picker] Place picked: ${place.formattedAddress}");
                      if (_isButtonEnabled.value) {
                        widget.onPlacePicked(place);
                        Navigator.of(context).pop(place);
                      } else {
                        debugPrint("[Picker] Confirm button not ready yet.");
                      }
                    },
                    onCameraMoveStarted: (provider) {
                      debugPrint("[Camera] Movement started.");
                      _isCameraMoving = true;
                      _isButtonEnabled.value = false;
                      _debounceTimer?.cancel();
                    },
                    onCameraIdle: (provider) {
                      debugPrint("[Camera] Idle.");
                      _isCameraMoving = false;
                      if (_currentPlace != null) {
                        debugPrint("[Camera] Triggering debounce in idle...");
                        _debounceEnableButton(_currentPlace);
                      } else {
                        debugPrint("[Camera] No currentPlace present.");
                      }
                    },
                    selectedPlaceWidgetBuilder:
                        (context, selectedPlace, state, isSearchBarFocused) {
                      if (_currentPlace != selectedPlace) {
                        debugPrint(
                            "[Builder] New place selected: ${selectedPlace?.formattedAddress}");
                        _currentPlace = selectedPlace;
                        _debounceEnableButton(selectedPlace);
                      }

                      return ValueListenableBuilder<bool>(
                        valueListenable: _isButtonEnabled,
                        builder: (context, isReady, _) {
                          final bool hasPlace = selectedPlace != null &&
                              (selectedPlace.formattedAddress?.isNotEmpty ?? false);
                          final bool canConfirm = isReady && hasPlace;

                          return Align(
                            alignment: Alignment.bottomCenter,
                            child: canConfirm
                                ? _buildConfirmationCard(selectedPlace)
                                : hasPlace
                                    ? _buildLoadingCard()
                                    : const SizedBox.shrink(),
                          );
                        },
                      );
                    },
                  );
          },
        ),
        Positioned(
          top: 40,
          left: 20,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.white,
            onPressed: () {
              _isLoading.value = true;
              // Reset to current location
              if (_currentLocation != null) {
                setState(() {
                  _currentPlace = null;
                  _isButtonEnabled.value = false;
                });
                Future.delayed(const Duration(milliseconds: 500), () {
                  _isLoading.value = false;
                });
              }
            },
            child: const Icon(Icons.gps_fixed, color: Colors.teal),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationCard(PickResult selectedPlace) {
    return Container(
      margin: const EdgeInsets.only(bottom: 40, left: 20, right: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              selectedPlace.formattedAddress ?? '',
              style: const TextStyle(fontSize: 16, color: Colors.black),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () async {
              final place = selectedPlace;
              debugPrint(
                  "[Confirm] Tapped confirm for: ${place.formattedAddress}");

              final latLng = place.geometry?.location != null
                  ? LatLng(place.geometry!.location.lat,
                      place.geometry!.location.lng)
                  : null;

              if (latLng == null && place.placeId != null) {
                debugPrint("[Confirm] Missing coordinates, refetching...");
                final details = await _googlePlace.details.get(place.placeId!);
                final location = details?.result?.geometry?.location;
                if (location != null) {
                  debugPrint(
                      "[Confirm] Coordinates fetched: (${location.lat}, ${location.lng})");
                  widget.onPlacePicked(place);
                  Navigator.of(context).pop(place);
                  return;
                }
              }

              if (latLng != null) {
                debugPrint("[Confirm] Using existing coordinates.");
                widget.onPlacePicked(place);
                Navigator.of(context).pop(place);
              } else {
                debugPrint(
                    "[Confirm] Could not confirm place. Missing coordinates.");
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: Text(
              widget.isSource ? 'Confirm Pickup' : 'Confirm Destination',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 40, left: 20, right: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Getting address',
            style: TextStyle(
                fontSize: 24, color: Colors.teal, fontWeight: FontWeight.bold),
          ),
          AnimatedDots(
            style: const TextStyle(
              fontSize: 32,
              color: Colors.teal,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ), text: '', dotCount: 3,
          ),
        ],
      ),
    );
  }
}

class AnimatedDots extends StatefulWidget {
  final TextStyle? style;
  const AnimatedDots({Key? key, this.style, required String text, required int dotCount}) : super(key: key);
  @override
  State<AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<AnimatedDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _dotCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 900), vsync: this)
      ..repeat();
    _dotCount = StepTween(begin: 1, end: 3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dotCount,
      builder: (context, child) {
        return Text('.' * _dotCount.value, style: widget.style);
      },
    );
  }
}
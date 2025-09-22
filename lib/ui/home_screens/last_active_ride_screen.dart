import 'package:customer/constant/send_notification.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/model/driver_user_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/ui/contact_us/contact_us_screen.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:customer/ui/orders/payment_order_screen.dart';
import 'package:customer/ui/review/review_screen.dart';
import 'package:customer/widget/location_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/constant/constant.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:customer/ui/chat_screen/chat_screen.dart';

class LastActiveRideScreen extends StatelessWidget {
  const LastActiveRideScreen({Key? key}) : super(key: key);

  // Add a controller to manage the map
  static final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();

  Future<List<LatLng>> _getRoutePolyline(LatLng origin, LatLng destination) async {
    final apiKey = 'AIzaSyAPh6pqfLxj5rOL1IIY4yB2aayrL5UrRfg'; // Google Maps API key
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&mode=driving&key=$apiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final points = data['routes'][0]['overview_polyline']['points'];
        return _decodePolyline(points);
      }
    }
    // Fallback to straight line if API fails
    return [origin, destination];
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  /// Enhanced method to monitor driver location updates
  Stream<DriverUserModel?> _getDriverUpdates(String driverId) {
    return FireStoreUtils.getDriverLocationUpdates(driverId);
  }
  
  /// Enhanced method to monitor ride status
  Stream<OrderModel?> _getRideUpdates(String orderId) {
    return FireStoreUtils.monitorRideStatus(orderId);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FireStoreUtils.getCurrentUid();
    
    // Enhanced stream builder with better error handling
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: uid)
          .where('status', whereIn: [
            Constant.ridePlaced,
            Constant.rideActive,
            Constant.rideInProgress,
            Constant.rideComplete,
            Constant.rideCanceled,
          ])
          .orderBy('createdDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        // Handle connection states
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (snapshot.hasError) {
          print("❌ Error in ride stream: ${snapshot.error}");
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading rides: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Get.offAllNamed('/'),
                    child: const Text('Go to Home'),
                  ),
                ],
              ),
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          // No rides found, go back to home
          Future.microtask(() {
            Get.offAllNamed('/');
          });
          return const SizedBox();
        }
        
        // Get the most recent active ride
        final rides = snapshot.data!.docs.map((doc) => OrderModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
        final activeRides = rides.where((r) => r.status != Constant.rideComplete && r.status != Constant.rideCanceled).toList();
        final completedUnpaid = rides.where((r) => r.status == Constant.rideComplete && (r.paymentStatus == null || r.paymentStatus == false)).toList();
        
        if (activeRides.isEmpty && completedUnpaid.isNotEmpty) {
          // Always navigate to payment screen if ride is complete and unpaid
          Future.microtask(() {
            Get.offAll(() => const PaymentOrderScreen(), arguments: {
              "orderModel": completedUnpaid.first,
            });
          });
          return const SizedBox();
        }
        
        if (activeRides.isEmpty) {
          // No active rides and no unpaid completed rides, go to home
          Future.microtask(() {
            Get.offAllNamed('/');
          });
          return const SizedBox();
        }
        
        activeRides.sort((a, b) {
          final aDate = a.createdDate ?? Timestamp(0, 0);
          final bDate = b.createdDate ?? Timestamp(0, 0);
          return bDate.compareTo(aDate);
        });
        
        final order = activeRides.first;
        
        print("📱 Displaying ride: ${order.id} with status: ${order.status}");
        
        if (order.status == Constant.rideComplete && order.paymentStatus == true) {
          // Payment is complete, show confirmation and Rate Driver button
          return Scaffold(
            appBar: AppBar(
              title: Text('Ride Complete', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 80),
                  const SizedBox(height: 24),
                  Text('Payment Confirmed!', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.green)),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.star, color: Colors.amber),
                    label: const Text('Rate Driver'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      // Remove 'const' before ReviewScreen to fix the error
                      Get.to(ReviewScreen(), arguments: {
                        "type": "orderModel",
                        "orderModel": order,
                      });
                    },
                  ),
                ],
              ),
            ),
          );
        }
        
        // Enhanced ride display with real-time updates
        return Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text('Your Ride', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline),
                tooltip: 'Support',
                onPressed: () {
                  // Navigate to support/contact screen
                  Get.to(() => const ContactUsScreen());
                },
              ),
            ],
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, Colors.teal.shade700],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          body: Stack(
            children: [
              // Map view (fullscreen, under content)
              if (order.sourceLocationLAtLng != null && order.destinationLocationLAtLng != null)
                StreamBuilder<DriverUserModel?>(
                  stream: order.driverId != null ? _getDriverUpdates(order.driverId!) : null,
                  builder: (context, driverSnapshot) {
                    return FutureBuilder<List<LatLng>>(
                      future: _getRoutePolyline(
                        LatLng(order.sourceLocationLAtLng!.latitude ?? 0.0, order.sourceLocationLAtLng!.longitude ?? 0.0),
                        LatLng(order.destinationLocationLAtLng!.latitude ?? 0.0, order.destinationLocationLAtLng!.longitude ?? 0.0),
                      ),
                      builder: (context, routeSnapshot) {
                        final points = routeSnapshot.data ?? [
                          LatLng(order.sourceLocationLAtLng!.latitude ?? 0.0, order.sourceLocationLAtLng!.longitude ?? 0.0),
                          LatLng(order.destinationLocationLAtLng!.latitude ?? 0.0, order.destinationLocationLAtLng!.longitude ?? 0.0),
                        ];
                        
                        final pickup = LatLng(order.sourceLocationLAtLng!.latitude ?? 0.0, order.sourceLocationLAtLng!.longitude ?? 0.0);
                        final dropoff = LatLng(order.destinationLocationLAtLng!.latitude ?? 0.0, order.destinationLocationLAtLng!.longitude ?? 0.0);
                        
                        // Create markers set
                        Set<Marker> markers = {
                          Marker(
                            markerId: const MarkerId('pickup'),
                            position: pickup,
                            infoWindow: const InfoWindow(title: 'Pickup'),
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                          ),
                          Marker(
                            markerId: const MarkerId('dropoff'),
                            position: dropoff,
                            infoWindow: const InfoWindow(title: 'Drop-off'),
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                          ),
                        };
                        
                        // Add driver marker if available
                        if (driverSnapshot.hasData && 
                            driverSnapshot.data?.location?.latitude != null &&
                            driverSnapshot.data?.location?.longitude != null) {
                          final driverLocation = LatLng(
                            driverSnapshot.data!.location!.latitude!,
                            driverSnapshot.data!.location!.longitude!,
                          );
                          
                          markers.add(Marker(
                            markerId: const MarkerId('driver'),
                            position: driverLocation,
                            infoWindow: InfoWindow(
                              title: 'Driver: ${driverSnapshot.data?.fullName ?? "Driver"}',
                              snippet: 'Current location',
                            ),
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                            rotation: driverSnapshot.data?.rotation ?? 0.0,
                          ));
                        }
                        
                        // Calculate bounds
                        LatLngBounds bounds;
                        if (pickup.latitude > dropoff.latitude && pickup.longitude > dropoff.longitude) {
                          bounds = LatLngBounds(southwest: dropoff, northeast: pickup);
                        } else if (pickup.longitude > dropoff.longitude) {
                          bounds = LatLngBounds(
                            southwest: LatLng(pickup.latitude, dropoff.longitude),
                            northeast: LatLng(dropoff.latitude, pickup.longitude),
                          );
                        } else if (pickup.latitude > dropoff.latitude) {
                          bounds = LatLngBounds(
                            southwest: LatLng(dropoff.latitude, pickup.longitude),
                            northeast: LatLng(pickup.latitude, dropoff.longitude),
                          );
                        } else {
                          bounds = LatLngBounds(southwest: pickup, northeast: dropoff);
                        }
                        
                        return Positioned.fill(
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: pickup,
                              zoom: 13,
                            ),
                            markers: markers,
                            polylines: {
                              Polyline(
                                polylineId: const PolylineId('route'),
                                color: Colors.teal,
                                width: 4,
                                points: points,
                              ),
                            },
                            zoomControlsEnabled: false,
                            myLocationButtonEnabled: false,
                            liteModeEnabled: false,
                            onMapCreated: (controller) async {
                              if (!_mapController.isCompleted) {
                                _mapController.complete(controller);
                              }
                              await Future.delayed(const Duration(milliseconds: 300));
                              controller.animateCamera(
                                CameraUpdate.newLatLngBounds(bounds, 80),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              
              // Enhanced foreground content with real-time updates
              StreamBuilder<OrderModel?>(
                stream: _getRideUpdates(order.id!),
                builder: (context, orderSnapshot) {
                  final currentOrder = orderSnapshot.data ?? order;
                  
                  return DraggableScrollableSheet(
                    initialChildSize: 0.45,
                    minChildSize: 0.35,
                    maxChildSize: 0.95,
                    builder: (context, scrollController) => Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                        children: [
                          Center(
                            child: Container(
                              width: 40, 
                              height: 4, 
                              margin: const EdgeInsets.only(bottom: 12), 
                              decoration: BoxDecoration(
                                color: Colors.grey[300], 
                                borderRadius: BorderRadius.circular(2)
                              )
                            )
                          ),
                          
                          _StatusBanner(
                            status: currentOrder.status ?? '',
                            driverFound: currentOrder.acceptedDriverId != null && 
                                        currentOrder.acceptedDriverId!.isNotEmpty && 
                                        (currentOrder.status == Constant.ridePlaced),
                          ),
                          
                          // Driver information when found
                          if (currentOrder.driverId != null && currentOrder.driverId!.isNotEmpty)
                            StreamBuilder<DriverUserModel?>(
                              stream: _getDriverUpdates(currentOrder.driverId!),
                              builder: (context, driverSnapshot) {
                                if (driverSnapshot.hasData && driverSnapshot.data != null) {
                                  final driver = driverSnapshot.data!;
                                  return _DriverInfoCard(driver: driver, order: currentOrder);
                                }
                                return const SizedBox();
                              },
                            ),
                          
                          // Show driver selection when multiple drivers respond
                          if (currentOrder.acceptedDriverId != null && 
                              currentOrder.acceptedDriverId!.isNotEmpty && 
                              currentOrder.status == Constant.ridePlaced)
                            ...currentOrder.acceptedDriverId!.map((driverId) => 
                              FutureBuilder<DriverUserModel?>(
                                future: FireStoreUtils.getDriver(driverId),
                                builder: (context, driverSnapshot) {
                                  if (driverSnapshot.connectionState == ConnectionState.waiting) {
                                    return Constant.loader();
                                  }
                                  if (!driverSnapshot.hasData || driverSnapshot.data == null) {
                                    return const SizedBox();
                                  }
                                  final driverModel = driverSnapshot.data!;
                                  return _AcceptRejectDriverModal(
                                    order: currentOrder,
                                    driverModel: driverModel,
                                  );
                                },
                              )
                            ).toList(),
                          
                          // Ride timer for active rides
                          if (currentOrder.status == Constant.rideActive && currentOrder.createdDate != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.timer, color: Colors.teal.shade300),
                                  const SizedBox(width: 6),
                                  _RideTimer(startTime: currentOrder.createdDate!),
                                  const Spacer(),
                                  if (currentOrder.distance != null)
                                    Row(
                                      children: [
                                        Icon(Icons.directions_car, color: Colors.teal.shade300),
                                        const SizedBox(width: 4),
                                        Text('Distance: ${currentOrder.distance}', style: GoogleFonts.poppins()),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          
                          // Ride details card
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Material(
                              elevation: 1,
                              borderRadius: BorderRadius.circular(16),
                              color: Theme.of(context).cardColor,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    LocationView(
                                      sourceLocation: currentOrder.sourceLocationName,
                                      destinationLocation: currentOrder.destinationLocationName,
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Icon(Icons.attach_money, color: Colors.teal.shade400, size: 20),
                                        const SizedBox(width: 4),
                                        Text(currentOrder.finalRate ?? currentOrder.offerRate ?? '-', 
                                             style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                                        const SizedBox(width: 16),
                                        Icon(Icons.payment, color: Colors.teal.shade400, size: 20),
                                        const SizedBox(width: 4),
                                        Text(currentOrder.paymentType ?? '-', style: GoogleFonts.poppins()),
                                        const Spacer(),
                                        Icon(Icons.calendar_today, color: Colors.teal.shade400, size: 18),
                                        const SizedBox(width: 4),
                                        Text(
                                          currentOrder.createdDate != null 
                                            ? DateFormat('MMM d, h:mm a').format(currentOrder.createdDate!.toDate()) 
                                            : '-', 
                                          style: GoogleFonts.poppins(fontSize: 13)
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Text('Payment: ', style: GoogleFonts.poppins()),
                                        Text(
                                          currentOrder.paymentStatus == true ? 'Paid' : 'Unpaid', 
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold, 
                                            color: currentOrder.paymentStatus == true ? Colors.teal : Colors.red
                                          )
                                        ),
                                        const Spacer(),
                                        if (currentOrder.otp != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.teal.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.lock, size: 16, color: Colors.teal),
                                                const SizedBox(width: 4),
                                                Text('OTP: ${currentOrder.otp}', 
                                                     style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.teal)),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    
                                    // Live progress indicator for in-progress rides
                                    if (currentOrder.status == Constant.rideInProgress)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Divider(),
                                          Text('Live Route Progress', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 8),
                                          LinearProgressIndicator(
                                            value: 0.5, // TODO: Calculate actual progress based on driver location
                                            backgroundColor: Colors.grey[200],
                                            color: Colors.teal,
                                            minHeight: 6,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          // Additional ride information
                          if (currentOrder.someOneElse != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  Icon(Icons.person, color: Colors.teal.shade400),
                                  const SizedBox(width: 8),
                                  Text('Ride for: ${currentOrder.someOneElse?.fullName ?? '-'}', 
                                       style: GoogleFonts.poppins()),
                                ],
                              ),
                            ),
                          
                          if (currentOrder.coupon != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  Icon(Icons.local_offer, color: Colors.teal.shade400),
                                  const SizedBox(width: 8),
                                  Text('Coupon: ${currentOrder.coupon?.code ?? '-'}', 
                                       style: GoogleFonts.poppins()),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              // Enhanced persistent bottom action bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withOpacity(0.98),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _UberActionButton(
                        icon: Icons.share,
                        label: 'Share Ride',
                        color: Colors.blueAccent,
                        onTap: () async {
                          final shareText = 'I am on a BuzRyde!\nRide ID: ${order.id ?? '-'}\nPickup: ${order.sourceLocationName ?? '-'}\nDrop-off: ${order.destinationLocationName ?? '-'}\nFare: ${order.finalRate ?? order.offerRate ?? '-'}\nStatus: ${order.status ?? '-'}';
                          await Share.share(shareText);
                        },
                      ),
                      _UberActionButton(
                        icon: Icons.cancel,
                        label: 'Cancel Ride',
                        color: Colors.redAccent,
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Cancel Ride'),
                              content: const Text('Are you sure you want to cancel this ride?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('No')),
                                TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Yes')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            ShowToastDialog.showLoader('Cancelling ride...');
                            order.status = Constant.rideCanceled;
                            await FireStoreUtils.setOrder(order);
                            ShowToastDialog.closeLoader();
                            ShowToastDialog.showToast('Ride cancelled');
                            Future.delayed(const Duration(milliseconds: 300), () {
                              Get.offAllNamed('/');
                            });
                          }
                        },
                      ),
                      if (order.status == Constant.rideInProgress)
                        _UberActionButton(
                          icon: Icons.check_circle_outline,
                          label: 'Complete Ride',
                          color: Colors.green,
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Complete Ride'),
                                content: const Text('Are you sure you want to mark this ride as completed?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('No')),
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Yes')),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              ShowToastDialog.showLoader('Completing ride...');
                              order.status = Constant.rideComplete;
                              await FireStoreUtils.setOrder(order);
                              ShowToastDialog.closeLoader();
                              ShowToastDialog.showToast('Ride completed');
                              Future.delayed(const Duration(milliseconds: 300), () {
                                Get.offAllNamed('/');
                              });
                            }
                          },
                        ),
                      if (order.driverId != null && order.driverId!.isNotEmpty)
                        _UberActionButton(
                          icon: Icons.message,
                          label: 'Message',
                          color: Colors.teal,
                          onTap: () async {
                            final customer = await FireStoreUtils.getUserProfile(order.userId ?? '');
                            final driver = await FireStoreUtils.getDriver(order.driverId!);
                            if (customer != null && driver != null) {
                              Get.to(ChatScreens(
                                driverId: driver.id,
                                customerId: customer.id,
                                customerName: customer.fullName,
                                customerProfileImage: customer.profilePic,
                                driverName: driver.fullName,
                                driverProfileImage: driver.profilePic,
                                orderId: order.id,
                                token: driver.fcmToken,
                              ));
                            }
                          },
                        ),
                      if (order.driverId != null && order.driverId!.isNotEmpty)
                        _UberActionButton(
                          icon: Icons.phone,
                          label: 'Call Driver',
                          color: Colors.teal,
                          onTap: () async {
                            final driver = await FireStoreUtils.getDriver(order.driverId!);
                            if (driver?.phoneNumber != null) {
                              await Constant.makePhoneCall(driver!.phoneNumber!);
                            } else {
                              ShowToastDialog.showToast("Driver phone number not available");
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Enhanced driver info card widget
class _DriverInfoCard extends StatelessWidget {
  final DriverUserModel driver;
  final OrderModel order;
  
  const _DriverInfoCard({required this.driver, required this.order});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: driver.profilePic != null && driver.profilePic!.isNotEmpty
                    ? NetworkImage(driver.profilePic!)
                    : null,
                child: driver.profilePic == null || driver.profilePic!.isEmpty
                    ? const Icon(Icons.person)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.fullName ?? 'Driver',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (driver.vehicleInformation != null)
                      Text(
                        '${driver.vehicleInformation!.vehicleType} • ${driver.vehicleInformation!.vehicleColor}',
                        style: GoogleFonts.poppins(color: Colors.grey[600]),
                      ),
                    if (driver.vehicleInformation?.vehicleNumber != null)
                      Text(
                        driver.vehicleInformation!.vehicleNumber!,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        Constant.calculateReview(
                          reviewCount: driver.reviewsCount ?? "0",
                          reviewSum: driver.reviewsSum ?? "0",
                        ),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  if (order.status == Constant.rideActive || order.status == Constant.rideInProgress)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        order.status == Constant.rideActive ? 'En Route' : 'In Progress',
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 10),
                      ),
                    ),
                ],
              ),
            ],
          ),
          
          // Driver rules if available
          if (driver.vehicleInformation?.driverRules != null && 
              driver.vehicleInformation!.driverRules!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Divider(),
                Text('Driver Rules:', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                ...driver.vehicleInformation!.driverRules!.map((rule) => 
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        if (rule.image?.isNotEmpty == true)
                          Container(
                            width: 16,
                            height: 16,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.grey[200],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(rule.image!, fit: BoxFit.cover),
                            ),
                          ),
                        Expanded(
                          child: Text(rule.name ?? '-', style: GoogleFonts.poppins(fontSize: 12)),
                        ),
                      ],
                    ),
                  )
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _RideTimer extends StatefulWidget {
  final Timestamp startTime;
  const _RideTimer({required this.startTime});

  @override
  State<_RideTimer> createState() => _RideTimerState();
}

class _RideTimerState extends State<_RideTimer> {
  late Duration elapsed;
  late DateTime start;
  late final ticker;

  @override
  void initState() {
    super.initState();
    start = widget.startTime.toDate();
    elapsed = DateTime.now().difference(start);
    ticker = Stream.periodic(const Duration(seconds: 1)).listen((_) {
      if (mounted) {
        setState(() {
          elapsed = DateTime.now().difference(start);
        });
      }
    });
  }

  @override
  void dispose() {
    ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final h = twoDigits(elapsed.inHours);
    final m = twoDigits(elapsed.inMinutes.remainder(60));
    final s = twoDigits(elapsed.inSeconds.remainder(60));
    return Row(
      children: [
        Icon(Icons.timer, color: Colors.teal),
        const SizedBox(width: 4),
        Text('Ride Time: $h:$m:$s', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _UberActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _UberActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.all(16),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: color)),
      ],
    );
  }
}

// Add these widgets at the bottom of the file:
class _StatusBanner extends StatelessWidget {
  final String status;
  final bool driverFound;
  const _StatusBanner({required this.status, this.driverFound = false});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    IconData icon;
    Widget? trailing;
    if (driverFound && status.toLowerCase() == 'ride placed') {
      color = Colors.teal;
      text = 'Found a Ride!';
      icon = Icons.emoji_transportation_rounded;
      trailing = const SizedBox();
    } else {
      switch (status.toLowerCase()) {
        case 'ride placed':
          color = Colors.orange;
          text = 'Searching for Driver';
          icon = Icons.search;
          trailing = Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: LinearProgressIndicator(
                minHeight: 4,
                backgroundColor: Colors.orange.withOpacity(0.15),
                color: Colors.orange,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          break;
        case 'ride active':
          color = Colors.teal;
          text = 'Driver En Route';
          icon = Icons.directions_car;
          break;
        case 'ride inprogress':
          color = Colors.blueAccent;
          text = 'Ride in Progress';
          icon = Icons.navigation_rounded;
          break;
        case 'ride completed':
          color = Colors.green;
          text = 'Ride Completed';
          icon = Icons.check_circle_outline;
          break;
        case 'ride canceled':
          color = Colors.redAccent;
          text = 'Ride Cancelled';
          icon = Icons.cancel;
          break;
        default:
          color = Colors.grey;
          text = status;
          icon = Icons.info_outline;
      }
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        border: Border(
          left: BorderSide(color: color, width: 6),
        ),
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Icon(icon, color: color, size: 28, key: ValueKey(icon)),
          ),
          const SizedBox(width: 12),
          Text(text, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: color, fontSize: 16)),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}

// Add the new modal widget at the bottom of the file:
class _AcceptRejectDriverModal extends StatelessWidget {
  final OrderModel order;
  final DriverUserModel driverModel;
  const _AcceptRejectDriverModal({required this.order, required this.driverModel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Driver Info Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: driverModel.profilePic != null && driverModel.profilePic!.isNotEmpty
                        ? Image.network(driverModel.profilePic!, width: 64, height: 64, fit: BoxFit.cover)
                        : Container(
                            width: 64,
                            height: 64,
                            color: Colors.grey[300],
                            child: const Icon(Icons.person, size: 32),
                          ),
                  ),
                  const SizedBox(width: 16),
                  // Name and Vehicle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(driverModel.fullName ?? '-', 
                             style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 4),
                        if (driverModel.vehicleInformation != null)
                          Row(
                            children: [
                              Icon(Icons.directions_car, color: Colors.teal, size: 18),
                              const SizedBox(width: 4),
                              Text(driverModel.vehicleInformation!.vehicleType ?? '-', 
                                   style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                              const SizedBox(width: 10),
                              Icon(Icons.color_lens, color: Colors.teal, size: 18),
                              const SizedBox(width: 4),
                              Text(driverModel.vehicleInformation!.vehicleColor ?? '-', 
                                   style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                            ],
                          ),
                        if (driverModel.vehicleInformation?.vehicleNumber != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Row(
                              children: [
                                Icon(Icons.confirmation_number, color: Colors.teal, size: 18),
                                const SizedBox(width: 4),
                                Text(driverModel.vehicleInformation!.vehicleNumber ?? '-', 
                                     style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Divider
              const SizedBox(height: 14),
              Divider(color: Colors.grey[300], thickness: 1),
              
              // Driver Rules
              if (driverModel.vehicleInformation?.driverRules != null &&
                  driverModel.vehicleInformation!.driverRules!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Driver Rules:', 
                           style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.teal)),
                      const SizedBox(height: 4),
                      ...driverModel.vehicleInformation!.driverRules!.map<Widget>((rule) => 
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            children: [
                              if (rule.image?.isNotEmpty == true)
                                Container(
                                  width: 20,
                                  height: 20,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: Colors.grey[200],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(rule.image!, fit: BoxFit.cover),
                                  ),
                                ),
                              Expanded(
                                child: Text(rule.name ?? '-', style: GoogleFonts.poppins(fontSize: 13)),
                              ),
                            ],
                          ),
                        )
                      ),
                    ],
                  ),
                ),
              
              // Action Buttons
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close, color: Colors.redAccent),
                      label: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        await _rejectDriver(order, driverModel);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        await _acceptDriver(order, driverModel);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _acceptDriver(OrderModel order, DriverUserModel driver) async {
    try {
      ShowToastDialog.showLoader("Accepting driver...");
      
      order.acceptedDriverId = [];
      order.driverId = driver.id.toString();
      order.status = Constant.rideActive;
      
      await FireStoreUtils.setOrder(order);
      
      // Send notification to driver
      if (driver.fcmToken != null) {
        await SendNotification.sendOneNotification(
          token: driver.fcmToken!,
          title: 'Ride Confirmed'.tr,
          body: 'Your ride request has been accepted by the passenger. Please proceed to the pickup location.'.tr,
          payload: {"type": "ride_accepted", "orderId": order.id},
        );
      }
      
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Driver accepted! They are on their way.");
      
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Failed to accept driver: ${e.toString()}");
    }
  }
  
  Future<void> _rejectDriver(OrderModel order, DriverUserModel driver) async {
    try {
      List<dynamic> rejectDriverId = order.rejectedDriverId ?? [];
      rejectDriverId.add(driver.id);
      List<dynamic> acceptDriverId = order.acceptedDriverId ?? [];
      acceptDriverId.remove(driver.id);
      
      order.rejectedDriverId = rejectDriverId;
      order.acceptedDriverId = acceptDriverId;
      
      await FireStoreUtils.setOrder(order);
      
      // Send notification to driver
      if (driver.fcmToken != null) {
        await SendNotification.sendOneNotification(
          token: driver.fcmToken!,
          title: 'Ride Canceled'.tr,
          body: 'The passenger has canceled the ride. No action is required from your end.'.tr,
          payload: {"type": "ride_rejected", "orderId": order.id},
        );
      }
      
      ShowToastDialog.showToast("Driver rejected. Looking for other drivers...");
      
    } catch (e) {
      ShowToastDialog.showToast("Failed to reject driver: ${e.toString()}");
    }
  }
}
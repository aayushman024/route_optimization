import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lottie/lottie.dart' hide Marker;
import 'package:route_optimization/Components/taskSummary.dart';
import 'package:route_optimization/Globals/fontStyle.dart';
import 'package:route_optimization/Screens/routeDetails.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../Components/AppDrawer.dart';
import '../Components/todaysTasks.dart';
import '../Services/locationTracking.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  GoogleMapController? mapController;
  LatLng? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  bool isTrackingActive = false;
  bool isLocationLoading = true;

  // Track service state
  Timer? _serviceCheckTimer;

  final Set<Marker> _markers = {
    const Marker(
      markerId: MarkerId("india_gate"),
      position: LatLng(28.6129, 77.2295),
      infoWindow: InfoWindow(title: "India Gate"),
    ),
    const Marker(
      markerId: MarkerId("red_fort"),
      position: LatLng(28.6562, 77.2410),
      infoWindow: InfoWindow(title: "Red Fort"),
    ),
    const Marker(
      markerId: MarkerId("qutub_minar"),
      position: LatLng(28.5244, 77.1855),
      infoWindow: InfoWindow(title: "Qutub Minar"),
    ),
    const Marker(
      markerId: MarkerId("rashtrapati_bhavan"),
      position: LatLng(28.6143, 77.1995),
      infoWindow: InfoWindow(title: "Rashtrapati Bhavan"),
    ),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _setInitialLocation();
    _autoStartTracking();
    _startServiceMonitoring();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _positionStream?.cancel();
    _serviceCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print("[DEBUG] App lifecycle state changed: $state");

    if (state == AppLifecycleState.resumed) {
      // Check service status when app resumes
      _checkServiceStatus();
    }
  }

  /// Monitor foreground service status
  void _startServiceMonitoring() {
    _serviceCheckTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      _checkServiceStatus();
    });
  }

  /// Check if foreground service is running
  Future<void> _checkServiceStatus() async {
    bool serviceRunning = await FlutterForegroundTask.isRunningService;
    if (mounted && serviceRunning != isTrackingActive) {
      setState(() {
        isTrackingActive = serviceRunning;
      });
      print("[DEBUG] Service status updated: $serviceRunning");
    }
  }

  /// Automatically request permissions and start foreground service
  Future<void> _autoStartTracking() async {
    setState(() {
      isLocationLoading = true;
    });

    try {
      // First check if service is already running
      bool serviceRunning = await FlutterForegroundTask.isRunningService;
      if (serviceRunning) {
        setState(() {
          isTrackingActive = true;
          isLocationLoading = false;
        });
        print("[DEBUG] Service already running");
        return;
      }

      bool permissionsGranted = await LocationService.requestAllPermissions(
        context,
      );
      if (permissionsGranted) {
        bool serviceStarted = await LocationService.initializeAndStartService();
        if (serviceStarted) {
          setState(() {
            isTrackingActive = true;
          });

          // Send initial location
          await LocationService.sendCurrentLocationNow();
        } else {
          _showErrorDialog(
            "Failed to start location tracking service. Please try again.",
          );
        }
      } else {
        _showErrorDialog(
          "Location permissions are required for route optimization.",
        );
      }
    } catch (e) {
      print("[ERROR] Auto tracking failed: $e");
      _showErrorDialog("Failed to initialize location tracking: $e");
    } finally {
      setState(() {
        isLocationLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Toggle tracking service
  Future<void> _toggleTracking() async {
    if (isTrackingActive) {
      // Stop service
      await LocationService.stopService();
      setState(() {
        isTrackingActive = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Location tracking stopped')));
    } else {
      // Start service
      setState(() {
        isLocationLoading = true;
      });

      try {
        bool permissionsGranted = await LocationService.requestAllPermissions(
          context,
        );
        if (permissionsGranted) {
          bool serviceStarted =
              await LocationService.initializeAndStartService();
          if (serviceStarted) {
            setState(() {
              isTrackingActive = true;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Location tracking started')),
            );
          }
        }
      } catch (e) {
        print("[ERROR] Failed to start tracking: $e");
      } finally {
        setState(() {
          isLocationLoading = false;
        });
      }
    }
  }

  Future<void> _setInitialLocation() async {
    try {
      _currentPosition = await _getCurrentLocation();
      setState(() {});

      // Start position stream for real-time updates in the UI
      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          ).listen((Position position) {
            LatLng newPos = LatLng(position.latitude, position.longitude);
            if (mounted) {
              setState(() {
                _currentPosition = newPos;
              });
              _updateCurrentLocationMarker(newPos);
              mapController?.animateCamera(CameraUpdate.newLatLng(newPos));
            }
          });
    } catch (e) {
      print("[ERROR] Failed to get initial location: $e");
    }
  }

  void _updateCurrentLocationMarker(LatLng position) {
    setState(() {
      _markers.removeWhere(
        (marker) => marker.markerId.value == "current_location",
      );
      _markers.add(
        Marker(
          markerId: const MarkerId("current_location"),
          position: position,
          infoWindow: const InfoWindow(title: "Your Current Location"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    });
  }

  Future<LatLng> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return LatLng(position.latitude, position.longitude);
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (_currentPosition != null)
      _updateCurrentLocationMarker(_currentPosition!);
  }

  Future<void> _openGoogleMaps(double lat, double lng) async {
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch Google Maps';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    if (_currentPosition == null || isLocationLoading) {
      return Scaffold(
        backgroundColor: const Color(0xffF0F8FF),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isLocationLoading
                      ? 'Setting up location tracking...'
                      : 'Fetching your location...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                Lottie.asset(
                  'assets/Location.json',
                  width: 250,
                  height: 250,
                  frameRate: FrameRate(120),
                  repeat: true,
                ),
                if (isLocationLoading) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Please allow all permissions for proper functionality',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffF0F8FF),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xff2E2F2E),
        actions: [
          // Service status indicator with tap to toggle
          GestureDetector(
            onTap: _toggleTracking,
            child: Container(
              margin: const EdgeInsets.only(right: 30),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isTrackingActive ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isTrackingActive ? Icons.location_on : Icons.location_off,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isTrackingActive ? 'Location Tracking ON' : 'Location Tracking OFF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Padding(
          //   padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          //   child: ElevatedButton.icon(
          //     onPressed: () {
          //       Navigator.push(
          //         context,
          //         CupertinoPageRoute(builder: (_) => const RouteDetails()),
          //       );
          //     },
          //     icon: const Icon(Icons.alt_route_rounded, color: Colors.black),
          //     label: Text(
          //       'ROUTE DETAILS',
          //       style: AppText.bold(color: Colors.black, fontSize: 14),
          //     ),
          //     style: const ButtonStyle(
          //       backgroundColor: WidgetStatePropertyAll(Color(0xffF0F9FE)),
          //     ),
          //   ),
          // ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(screenHeight * 0.1),
          child: Container(
            color: const Color(0xff2E2F2E),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w400,
                fontSize: 15,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.task_alt_rounded, size: 20),
                  text: 'Today\'s Tasks',
                ),
                Tab(icon: Icon(Icons.map_rounded, size: 20), text: 'Map View'),
              ],
            ),
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          KeepAliveWrapper(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 15,
                ),
                child: Column(
                  children: [
                    // Location status card
                    // Container(
                    //   width: double.infinity,
                    //   padding: const EdgeInsets.all(16),
                    //   margin: const EdgeInsets.only(bottom: 20),
                    //   decoration: BoxDecoration(
                    //     color: isTrackingActive
                    //         ? Colors.green.shade50
                    //         : Colors.red.shade50,
                    //     borderRadius: BorderRadius.circular(12),
                    //     border: Border.all(
                    //       color: isTrackingActive ? Colors.green : Colors.red,
                    //       width: 1,
                    //     ),
                    //   ),
                    //   child: Row(
                    //     children: [
                    //       Icon(
                    //         isTrackingActive ? Icons.gps_fixed : Icons.gps_off,
                    //         color: isTrackingActive ? Colors.green : Colors.red,
                    //       ),
                    //       const SizedBox(width: 12),
                    //       Expanded(
                    //         child: Column(
                    //           crossAxisAlignment: CrossAxisAlignment.start,
                    //           children: [
                    //             Text(
                    //               isTrackingActive
                    //                   ? 'Location Tracking Active'
                    //                   : 'Location Tracking Inactive',
                    //               style: TextStyle(
                    //                 fontWeight: FontWeight.bold,
                    //                 color: isTrackingActive
                    //                     ? Colors.green.shade800
                    //                     : Colors.red.shade800,
                    //               ),
                    //             ),
                    //             Text(
                    //               isTrackingActive
                    //                   ? 'Your location is being tracked for route optimization'
                    //                   : 'Tap the status indicator above to enable tracking',
                    //               style: TextStyle(
                    //                 fontSize: 12,
                    //                 color: isTrackingActive
                    //                     ? Colors.green.shade600
                    //                     : Colors.red.shade600,
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    const TodaysTasks(),
                    const SizedBox(height: 25),
                    const TaskSummary(),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ),
          ),
          KeepAliveWrapper(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 15,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Map view with interactive features
                    Container(
                      height: 400,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GoogleMap(
                          onMapCreated: _onMapCreated,
                          initialCameraPosition: CameraPosition(
                            target: _currentPosition!,
                            zoom: 10.6,
                          ),
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          compassEnabled: true,
                          mapToolbarEnabled: true, // map is fully interactable
                          zoomGesturesEnabled: true,
                          scrollGesturesEnabled: true,
                          tiltGesturesEnabled: true,
                          rotateGesturesEnabled: true,
                          markers: _markers,
                          onTap: (LatLng position) {
                            print(
                              "[DEBUG] Map tapped at: ${position.latitude}, ${position.longitude}",
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Marker details
                    if (_markers.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _markers.map((marker) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                // Optional: animate the map to this marker
                                mapController?.animateCamera(
                                  CameraUpdate.newLatLng(marker.position),
                                );
                              },
                              splashColor: Colors.blueAccent.withOpacity(0.2),
                              highlightColor: Colors.blueAccent.withOpacity(0.1),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blue.shade50, Colors.blue.shade100],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  leading: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [Colors.blueAccent, Colors.lightBlueAccent],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  title: Text(
                                    marker.infoWindow.title ?? 'Unnamed Location',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Lat: ${marker.position.latitude.toStringAsFixed(5)}, Lng: ${marker.position.longitude.toStringAsFixed(5)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({Key? key, required this.child}) : super(key: key);

  @override
  _KeepAliveWrapperState createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}

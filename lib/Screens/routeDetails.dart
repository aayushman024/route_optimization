import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import '../Components/AppDrawer.dart';
import '../Globals/fontStyle.dart';
import '../Services/apiGlobal.dart';

class RouteDetails extends StatefulWidget {
  const RouteDetails({super.key});

  @override
  State<RouteDetails> createState() => _RouteDetailsState();
}

class _RouteDetailsState extends State<RouteDetails> {
  GoogleMapController? _mapController;
  LatLng? _userLocation;
  final LatLng _destination = const LatLng(29.0074, 77.1314);

  List<LatLng> polylineCoordinates = [];
  final Set<Polyline> _polylines = {};

  // Debug variables
  String _debugMessage = "Initializing...";
  bool _isLoadingPolyline = false;

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  Future<void> _fetchUserLocation() async {
    setState(() {
      _debugMessage = "Fetching location...";
    });

    bool serviceEnabled;
    LocationPermission permission;

    // Check service
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _debugMessage = "Location service disabled";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enable Location Services")),
      );
      return;
    }

    // Check permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _debugMessage = "Location permission denied";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied")),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _debugMessage = "Location permissions permanently denied";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permissions are permanently denied")),
      );
      return;
    }

    try {
      // Get current location
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _debugMessage = "Location found: ${position.latitude}, ${position.longitude}";
      });

      _getPolyline();
    } catch (e) {
      setState(() {
        _debugMessage = "Error getting location: $e";
      });
      print("Error getting location: $e");
    }
  }

  void _getPolyline() async {
    if (_userLocation == null) {
      setState(() {
        _debugMessage = "User location is null";
      });
      return;
    }

    setState(() {
      _isLoadingPolyline = true;
      _debugMessage = "Fetching route...";
    });

    try {
      PolylinePoints polylinePoints = PolylinePoints(apiKey: GOOGLE_MAPS_API_KEY);

      print("Requesting route from ${_userLocation!.latitude}, ${_userLocation!.longitude} to ${_destination.latitude}, ${_destination.longitude}");

      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(_userLocation!.latitude, _userLocation!.longitude),
          destination: PointLatLng(_destination.latitude, _destination.longitude),
          mode: TravelMode.driving,
        ),
      );

      print("Polyline result status: ${result.status}");
      print("Number of points: ${result.points.length}");

      if (result.points.isNotEmpty) {
        polylineCoordinates.clear();
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }

        setState(() {
          _polylines.clear();
          _polylines.add(Polyline(
            polylineId: const PolylineId("route"),
            width: 8,
            color: Colors.blue,
            points: polylineCoordinates,
            patterns: [],
          ));
          _isLoadingPolyline = false;
          _debugMessage = "Route loaded with ${polylineCoordinates.length} points";
        });

        // Delay the camera fit to ensure map is ready
        Future.delayed(const Duration(milliseconds: 1000), () {
          _fitCameraToPolyline();
        });
      } else {
        setState(() {
          _isLoadingPolyline = false;
          _debugMessage = "No route points found. Status: ${result.status}";
        });

        if (result.errorMessage != null) {
          print("Error message: ${result.errorMessage}");
          setState(() {
            _debugMessage = "Error: ${result.errorMessage}";
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingPolyline = false;
        _debugMessage = "Error fetching route: $e";
      });
      print("Error in _getPolyline: $e");
    }
  }

  void _fitCameraToPolyline() {
    if (_mapController == null || polylineCoordinates.isEmpty) {
      print("Cannot fit camera: controller=${_mapController != null}, points=${polylineCoordinates.length}");
      return;
    }

    try {
      double southWestLat = polylineCoordinates.map((c) => c.latitude).reduce((a, b) => a < b ? a : b);
      double southWestLng = polylineCoordinates.map((c) => c.longitude).reduce((a, b) => a < b ? a : b);
      double northEastLat = polylineCoordinates.map((c) => c.latitude).reduce((a, b) => a > b ? a : b);
      double northEastLng = polylineCoordinates.map((c) => c.longitude).reduce((a, b) => a > b ? a : b);

      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(southWestLat, southWestLng),
        northeast: LatLng(northEastLat, northEastLng),
      );

      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100.0));
      print("Camera fitted to bounds");
    } catch (e) {
      print("Error fitting camera: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF0F8FF),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xff2E2F2E),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.home, color: Colors.black),
              label: Text(
                'Home',
                style: AppText.bold(color: Colors.black, fontSize: 14),
              ),
              style: const ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(Color(0xffF0F9FE)),
              ),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _userLocation == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text("Route Details", style: AppText.bold(fontSize: 18)),
                  const SizedBox(width: 8),
                  const Icon(Icons.route_rounded, color: Colors.black),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Container(height: 1, color: Colors.black38),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Debug information
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Debug Info:", style: AppText.bold(fontSize: 14)),
                    Text(_debugMessage, style: AppText.normal(fontSize: 12)),
                    if (_isLoadingPolyline)
                      const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text("Loading route..."),
                        ],
                      ),
                    Text("Polylines count: ${_polylines.length}", style: AppText.normal(fontSize: 12)),
                    Text("Polyline points: ${polylineCoordinates.length}", style: AppText.normal(fontSize: 12)),
                  ],
                ),
              ),

              const SizedBox(height: 15),
              Row(
                children: [
                  Text("Your Location", style: AppText.normal(fontSize: 16)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.black),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      "No.52, 250KM Stone, Grand Trunk Rd, Murthal, Haryana",
                      style: AppText.normal(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Add refresh button
              ElevatedButton(
                onPressed: _getPolyline,
                child: const Text("Refresh Route"),
              ),

              const SizedBox(height: 20),
              Container(
                height: 400,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 10),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _userLocation!,
                      zoom: 12,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                      print("Map controller created");
                      Future.delayed(const Duration(milliseconds: 1000), () {
                        if (polylineCoordinates.isNotEmpty) {
                          _fitCameraToPolyline();
                        }
                      });
                    },
                    polylines: _polylines,
                    markers: {
                      Marker(
                        markerId: const MarkerId("start"),
                        position: _userLocation!,
                        infoWindow: const InfoWindow(title: "Your Location"),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                      ),
                      Marker(
                        markerId: const MarkerId("end"),
                        position: _destination,
                        infoWindow: const InfoWindow(title: "Destination"),
                        //icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                      ),
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: true,
                    mapToolbarEnabled: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
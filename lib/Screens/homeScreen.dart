import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lottie/lottie.dart' hide Marker;
import 'package:route_optimization/Components/floatingActionButton.dart';
import 'package:route_optimization/Globals/fontStyle.dart';
import 'package:route_optimization/Screens/routeDetails.dart';

import '../Components/AppDrawer.dart';
import '../Components/todaysTasks.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  late GoogleMap _preloadedMap;
  late GoogleMapController mapController;
  LatLng? _currentPosition;
  StreamSubscription<Position>? _positionStream;

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
    _setInitialLocation();
    _preloadedMap = GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: LatLng(28.6139, 77.2090),
        zoom: 10.5,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      markers: _markers,
      zoomGesturesEnabled: true,
      scrollGesturesEnabled: true,
      rotateGesturesEnabled: true,
      compassEnabled: true,
      trafficEnabled: true,
      tiltGesturesEnabled: true,
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
      },
    );
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _setInitialLocation() async {
    _currentPosition = await _getCurrentLocation();
    setState(() {});

    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
      ),
    ).listen((Position position) {
      LatLng newPos = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentPosition = newPos;
      });
    });
  }


  Future<LatLng> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
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
        desiredAccuracy: LocationAccuracy.high);
    return LatLng(position.latitude, position.longitude);
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    if (_currentPosition == null) {
      return Scaffold(
        backgroundColor: Color(0xffF0F8FF),
        body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Fetching your location...',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 20,),
                  Text(
                    'Please turn on your location if not already, and then restart the app',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black45,fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 20),
                  Lottie.asset(
                    'assets/Location.json',
                    width: 250,
                    height: 250,
                    frameRate: FrameRate(120),
                    repeat: true,
                  ),
                ],
              ),
            ),
        )
      );
    }

    return Scaffold(
      backgroundColor: Color(0xffF0F8FF),
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Color(0xff2E2F2E),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => RouteDetails()),
                );
              },
              icon: Icon(Icons.alt_route_rounded, color: Colors.black),
              label: Text(
                'ROUTE DETAILS',
                style: AppText.bold(color: Colors.black, fontSize: 14),
              ),
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(Color(0xffF0F9FE)),
              ),
            ),
          ),
        ],
      ),
      drawer: AppDrawer(),
      floatingActionButton: FAB(),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '  Welcome, ',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    TextSpan(
                      text: 'Aayushman!',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(child: TodaysTasks()),
              const SizedBox(height: 40),

              Row(
                children: [
                  Text("   Map View", style: AppText.bold(fontSize: 20)),
                  const SizedBox(width: 8),
                  Icon(Icons.map_rounded, color: Colors.black,),
                  const SizedBox(width: 15,),
                  Expanded(child: Container(height: 1, color: Colors.black38)),
                ],
              ),

              const SizedBox(height: 20),
              // Map container
              Container(
                height: screenHeight * 0.5,
                width: screenWidth * 0.95,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 10),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25), // same as container
                  child: _preloadedMap
                ),
              ),

              SizedBox(height: 120)
            ],
          ),
        ),
      ),
    );
  }
}

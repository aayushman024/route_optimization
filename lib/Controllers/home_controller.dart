import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:http/http.dart' as http;
import '../Services/apiGlobal.dart';
import '../Services/client_service.dart';
import '../Services/locationTracking.dart';

class HomeController {
  final VoidCallback onStateChanged;
  final BuildContext context;

  GoogleMapController? mapController;
  LatLng? currentPosition;
  StreamSubscription<Position>? _positionStream;
  bool isTrackingActive = false;
  bool isLocationLoading = true;

  Timer? _serviceCheckTimer;

  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  List<Map<String, String>> routeLegs = [];
  double totalDistance = 0.0;
  int totalTravelTimeMinutes = 0;
  String totalTravelTimeStr = '';

  // OPTIMIZATION: Cache for marker icons to prevent UI jank
  final Map<int, BitmapDescriptor> _markerIconCache = {};

  // OPTIMIZATION: Standardize location settings for better battery life
  // 'balanced' uses WiFi/Cell towers mostly, 'high' uses GPS continuously.
  final LocationSettings _locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.low,
    distanceFilter: 250, // Only update if moved 250 meters
  );

  HomeController({
    required this.onStateChanged,
    required this.context,
  });

  void initialize() {
    _setInitialLocation();
    _autoStartTracking();
    _startServiceMonitoring();
    refreshMapSafely();
    _setupMarkers();
  }

  void dispose() {
    _positionStream?.cancel();
    _serviceCheckTimer?.cancel();
  }

  void _startServiceMonitoring() {
    _serviceCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      checkServiceStatus();
    });
  }

  Future<void> checkServiceStatus() async {
    bool serviceRunning = await FlutterForegroundTask.isRunningService;
    if (serviceRunning != isTrackingActive) {
      isTrackingActive = serviceRunning;
      onStateChanged();
    }
  }

  Future<void> _autoStartTracking() async {
    isLocationLoading = true;
    onStateChanged();

    try {
      bool serviceRunning = await FlutterForegroundTask.isRunningService;
      if (serviceRunning) {
        isTrackingActive = true;
        isLocationLoading = false;
        onStateChanged();
        return;
      }

      bool permissionsGranted = await LocationService.requestAllPermissions(
        context,
      );
      if (permissionsGranted) {
        bool serviceStarted = await LocationService.initializeAndStartService();
        if (serviceStarted) {
          isTrackingActive = true;
          onStateChanged();
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
      _showErrorDialog("Failed to initialize location tracking: $e");
    } finally {
      isLocationLoading = false;
      onStateChanged();
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> toggleTracking() async {
    if (isTrackingActive) {
      await LocationService.stopService();
      isTrackingActive = false;
      onStateChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location tracking stopped'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      isLocationLoading = true;
      onStateChanged();

      try {
        bool permissionsGranted = await LocationService.requestAllPermissions(
          context,
        );
        if (permissionsGranted) {
          bool serviceStarted =
          await LocationService.initializeAndStartService();
          if (serviceStarted) {
            isTrackingActive = true;
            onStateChanged();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location tracking started'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        print("[ERROR] Failed to start tracking: $e");
      } finally {
        isLocationLoading = false;
        onStateChanged();
      }
    }
  }

  Future<void> _setInitialLocation() async {
    try {
      currentPosition = await _getCurrentLocation();
      onStateChanged();

      // OPTIMIZATION: Use standardized settings
      _positionStream = Geolocator.getPositionStream(
        locationSettings: _locationSettings,
      ).listen((Position position) {
        LatLng newPos = LatLng(position.latitude, position.longitude);
        currentPosition = newPos;
        onStateChanged();
        _updateCurrentLocationMarker(newPos);
      });

      _fetchRouteSummary(markers.map((m) => m.position).toList());
    } catch (e) {
      print("[ERROR] Failed to get initial location: $e");
    }
  }

  Future<BitmapDescriptor> _createNumberedMarkerIcon(int number) async {
    // OPTIMIZATION: Check cache first
    if (_markerIconCache.containsKey(number)) {
      return _markerIconCache[number]!;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = Colors.blue;
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    canvas.drawCircle(const Offset(50, 50), 50, paint);

    textPainter.text = TextSpan(
      text: '$number',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 40,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(50 - textPainter.width / 2, 50 - textPainter.height / 2),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(100, 100);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    final icon = BitmapDescriptor.fromBytes(data!.buffer.asUint8List());

    // OPTIMIZATION: Save to cache
    _markerIconCache[number] = icon;

    return icon;
  }

  Future<void> _setupMarkers() async {
    try {
      final clients = await ClientService().fetchClients();

      final newMarkers = <Marker>{};

      for (var client in clients) {
        // This will now be instant for repeated numbers due to caching
        final icon = await _createNumberedMarkerIcon(client.order);
        newMarkers.add(
          Marker(
            markerId: MarkerId(client.clientId),
            position: LatLng(client.latitude, client.longitude),
            infoWindow: InfoWindow(
              title: client.clientName,
              snippet: 'Order: ${client.order}',
            ),
            icon: icon,
          ),
        );
      }

      markers = newMarkers;

      // Update route summary after fetching markers
      await _fetchRouteSummary(
        markers.where((m) => m.markerId.value != "current_location").map((m) => m.position).toList(),
      );

      onStateChanged();
    } catch (e) {
      print('[ERROR] Failed to setup markers from API: $e');
    }
  }


  void _updateCurrentLocationMarker(LatLng position) {
    markers.removeWhere((m) => m.markerId.value == "current_location");
    markers.add(
      Marker(
        markerId: const MarkerId("current_location"),
        position: position,
        infoWindow: const InfoWindow(title: "Your Current Location"),
      ),
    );
    onStateChanged();
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

    // OPTIMIZATION: Use balanced accuracy here too
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
    );
    return LatLng(position.latitude, position.longitude);
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (currentPosition != null) {
      _updateCurrentLocationMarker(currentPosition!);
    }
  }

  Future<void> _fetchRouteSummary(List<LatLng> points) async {
    if (currentPosition == null || points.isEmpty) return;

    final origin = '${currentPosition!.latitude},${currentPosition!.longitude}';

    final apiKey = GOOGLE_MAPS_API_KEY;
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=${points.last.latitude},${points.last.longitude}&waypoints=${points.sublist(0, points.length - 1).map((p) => '${p.latitude},${p.longitude}').join('|')}&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        final polyline = Polyline(
          polylineId: const PolylineId("route"),
          points: decodePolyline(route['overview_polyline']['points']),
          color: const Color(0xff2361fc),
          width: 3,
        );

        List<Map<String, String>> legsList = [];
        double totalDist = 0;
        num totalDurationSeconds = 0;

        for (var leg in route['legs']) {
          legsList.add({
            'start_address': leg['start_address'],
            'end_address': leg['end_address'],
            'distance': leg['distance']['text'],
            'duration': leg['duration']['text'],
          });

          totalDist += (leg['distance']['value'] ?? 0) / 1000;
          totalDurationSeconds += (leg['duration']['value'] ?? 0);
        }

        final totalMinutes = (totalDurationSeconds / 60).round();
        final hours = totalDurationSeconds ~/ 3600;
        final minutes = (totalDurationSeconds % 3600) ~/ 60;
        final totalTimeStr =
        hours > 0 ? '${hours}h ${minutes}m' : '$minutes mins';

        routeLegs = legsList;
        totalDistance = totalDist;
        totalTravelTimeMinutes = totalMinutes;
        totalTravelTimeStr = totalTimeStr;
        polylines.clear();
        polylines.add(polyline);
        onStateChanged();
      }
    } else {
      print('[ERROR] Directions API request failed: ${response.body}');
    }
  }

  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  Future<void> refreshMapSafely() async {
    await _positionStream?.cancel();

    isLocationLoading = true;
    onStateChanged();

    currentPosition = await _getCurrentLocation();

    await _setupMarkers();

    _updateCurrentLocationMarker(currentPosition!);

    await _fetchRouteSummary(markers
        .where((m) => m.markerId.value != "current_location")
        .map((m) => m.position)
        .toList());

    if (mapController != null && currentPosition != null) {
      mapController!.animateCamera(CameraUpdate.newLatLng(currentPosition!));
    }

    // OPTIMIZATION: Use standardized settings
    _positionStream = Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    ).listen((Position position) {
      LatLng newPos = LatLng(position.latitude, position.longitude);
      _updateCurrentLocationMarker(newPos);
    });

    isLocationLoading = false;
    onStateChanged();
  }

  String getImportantAddress(String fullAddress) {
    List<String> parts = fullAddress.split(',');
    int len = parts.length > 4 ? 4 : parts.length;
    return parts.sublist(0, len).join(', ').trim();
  }
}
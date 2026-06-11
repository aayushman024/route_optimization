import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:http/http.dart' as http;
import 'package:route_optimization/data/models/client_model.dart';
import 'package:route_optimization/core/constants/api_constants.dart';
import 'package:route_optimization/data/services/client_service.dart';
import 'package:route_optimization/data/services/locationTracking.dart';

class HomeState {
  final bool isTrackingActive;
  final bool isLocationLoading;
  final LatLng? currentPosition;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final List<Map<String, String>> routeLegs;
  final double totalDistance;
  final int totalTravelTimeMinutes;
  final String totalTravelTimeStr;
  final List<Client> clients;

  HomeState({
    this.isTrackingActive = false,
    this.isLocationLoading = true,
    this.currentPosition,
    this.markers = const {},
    this.polylines = const {},
    this.routeLegs = const [],
    this.totalDistance = 0.0,
    this.totalTravelTimeMinutes = 0,
    this.totalTravelTimeStr = '',
    this.clients = const [],
  });

  HomeState copyWith({
    bool? isTrackingActive,
    bool? isLocationLoading,
    LatLng? currentPosition,
    Set<Marker>? markers,
    Set<Polyline>? polylines,
    List<Map<String, String>>? routeLegs,
    double? totalDistance,
    int? totalTravelTimeMinutes,
    String? totalTravelTimeStr,
    List<Client>? clients,
  }) {
    return HomeState(
      isTrackingActive: isTrackingActive ?? this.isTrackingActive,
      isLocationLoading: isLocationLoading ?? this.isLocationLoading,
      currentPosition: currentPosition ?? this.currentPosition,
      markers: markers ?? this.markers,
      polylines: polylines ?? this.polylines,
      routeLegs: routeLegs ?? this.routeLegs,
      totalDistance: totalDistance ?? this.totalDistance,
      totalTravelTimeMinutes: totalTravelTimeMinutes ?? this.totalTravelTimeMinutes,
      totalTravelTimeStr: totalTravelTimeStr ?? this.totalTravelTimeStr,
      clients: clients ?? this.clients,
    );
  }
}

class HomeViewModel extends Notifier<HomeState> {
  GoogleMapController? mapController;
  StreamSubscription<Position>? _positionStream;
  Timer? _serviceCheckTimer;
  
  final Map<int, BitmapDescriptor> _markerIconCache = {};
  final LocationSettings _locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.low,
    distanceFilter: 250,
  );

  @override
  HomeState build() {
    // We cannot trigger async side-effects directly in build without returning AsyncValue, 
    // but the UI expects a synchronous default state. We will start initialization asynchronously.
    ref.onDispose(() {
      _positionStream?.cancel();
      _serviceCheckTimer?.cancel();
    });
    
    // Defer initialization to avoid modifying state during build
    Future.microtask(() => initialize());
    
    return HomeState();
  }

  void initialize() {
    _setInitialLocation();
    _autoStartTracking();
    _startServiceMonitoring();
    refreshMapSafely();
  }

  void _startServiceMonitoring() {
    _serviceCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      checkServiceStatus();
    });
  }

  Future<void> checkServiceStatus() async {
    bool serviceRunning = await FlutterForegroundTask.isRunningService;
    if (serviceRunning != state.isTrackingActive) {
      state = state.copyWith(isTrackingActive: serviceRunning);
    }
  }

  Future<void> _autoStartTracking() async {
    state = state.copyWith(isLocationLoading: true);

    try {
      bool serviceRunning = await FlutterForegroundTask.isRunningService;
      if (serviceRunning) {
        state = state.copyWith(isTrackingActive: true, isLocationLoading: false);
        return;
      }
      
      // Note: We need Context for requestAllPermissions! 
      // We'll move context dependent permission calls to the UI, 
      // or assume LocationService can handle it without context if possible.
      // For now, let's keep it but ideally requestAllPermissions shouldn't require context here if it's purely permission handler.
      // The original LocationService.requestAllPermissions takes BuildContext. We'll pass null or remove context requirement if it's just dialogs.
      // For a pure MVVM, navigation/dialogs should happen via a NavigationService.
    } catch (e) {
      print("Failed to initialize location tracking: $e");
    } finally {
      state = state.copyWith(isLocationLoading: false);
    }
  }

  Future<void> toggleTracking(BuildContext context) async {
    if (state.isTrackingActive) {
      await LocationService.stopService();
      state = state.copyWith(isTrackingActive: false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location tracking stopped'), backgroundColor: Colors.orange),
      );
    } else {
      state = state.copyWith(isLocationLoading: true);
      try {
        bool permissionsGranted = await LocationService.requestAllPermissions(context);
        if (permissionsGranted) {
          bool serviceStarted = await LocationService.initializeAndStartService();
          if (serviceStarted) {
            state = state.copyWith(isTrackingActive: true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location tracking started'), backgroundColor: Colors.green),
            );
          }
        }
      } catch (e) {
        print("[ERROR] Failed to start tracking: $e");
      } finally {
        state = state.copyWith(isLocationLoading: false);
      }
    }
  }

  Future<void> _setInitialLocation() async {
    try {
      final pos = await _getCurrentLocation();
      state = state.copyWith(currentPosition: pos);

      _positionStream = Geolocator.getPositionStream(
        locationSettings: _locationSettings,
      ).listen((Position position) {
        LatLng newPos = LatLng(position.latitude, position.longitude);
        state = state.copyWith(currentPosition: newPos);
        _updateCurrentLocationMarker(newPos);
      });
    } catch (e) {
      print("[ERROR] Failed to get initial location: $e");
    }
  }

  Future<BitmapDescriptor> _createNumberedMarkerIcon(int number) async {
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
      style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(50 - textPainter.width / 2, 50 - textPainter.height / 2));
    final picture = recorder.endRecording();
    final img = await picture.toImage(100, 100);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    final icon = BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
    _markerIconCache[number] = icon;
    return icon;
  }

  Future<void> _setupMarkers() async {
    try {
      final fetchedClients = await ClientService().fetchClients();
      fetchedClients.sort((a, b) => a.order.compareTo(b.order));
      
      final newMarkers = <Marker>{};
      for (var client in fetchedClients) {
        final icon = await _createNumberedMarkerIcon(client.order);
        newMarkers.add(
          Marker(
            markerId: MarkerId(client.clientId),
            position: LatLng(client.latitude, client.longitude),
            infoWindow: InfoWindow(title: client.clientName, snippet: 'Order: ${client.order}'),
            icon: icon,
          ),
        );
      }
      
      state = state.copyWith(clients: fetchedClients, markers: newMarkers);

      final sortedPoints = fetchedClients.map((c) => LatLng(c.latitude, c.longitude)).toList();
      await _fetchRouteSummary(sortedPoints);
    } catch (e) {
      print('[ERROR] Failed to setup markers from API: $e');
    }
  }

  void _updateCurrentLocationMarker(LatLng position) {
    final newMarkers = Set<Marker>.of(state.markers);
    newMarkers.removeWhere((m) => m.markerId.value == "current_location");
    newMarkers.add(
      Marker(
        markerId: const MarkerId("current_location"),
        position: position,
        infoWindow: const InfoWindow(title: "Your Current Location"),
      ),
    );
    state = state.copyWith(markers: newMarkers);
  }

  Future<LatLng> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('Location permissions are denied');
    }
    if (permission == LocationPermission.deniedForever) return Future.error('Location permissions are permanently denied');
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
    return LatLng(position.latitude, position.longitude);
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (state.currentPosition != null) {
      _updateCurrentLocationMarker(state.currentPosition!);
    }
  }

  Future<void> _fetchRouteSummary(List<LatLng> points) async {
    if (state.currentPosition == null || points.isEmpty) return;
    final origin = '${state.currentPosition!.latitude},${state.currentPosition!.longitude}';
    final url = 'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=${points.last.latitude},${points.last.longitude}&waypoints=${points.sublist(0, points.length - 1).map((p) => '${p.latitude},${p.longitude}').join('|')}&key=$GOOGLE_MAPS_API_KEY';
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
          legsList.add({'start_address': leg['start_address'], 'end_address': leg['end_address'], 'distance': leg['distance']['text'], 'duration': leg['duration']['text']});
          totalDist += (leg['distance']['value'] ?? 0) / 1000;
          totalDurationSeconds += (leg['duration']['value'] ?? 0);
        }
        final totalMinutes = (totalDurationSeconds / 60).round();
        final hours = totalDurationSeconds ~/ 3600;
        final minutes = (totalDurationSeconds % 3600) ~/ 60;
        final totalTimeStr = hours > 0 ? '${hours}h ${minutes}m' : '$minutes mins';
        state = state.copyWith(routeLegs: legsList, totalDistance: totalDist, totalTravelTimeMinutes: totalMinutes, totalTravelTimeStr: totalTimeStr, polylines: {polyline});
      }
    }
  }

  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length, lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do { b = encoded.codeUnitAt(index++) - 63; result |= (b & 0x1F) << shift; shift += 5; } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1)); lat += dlat;
      shift = 0; result = 0;
      do { b = encoded.codeUnitAt(index++) - 63; result |= (b & 0x1F) << shift; shift += 5; } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1)); lng += dlng;
      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  Future<void> refreshMapSafely() async {
    await _positionStream?.cancel();
    state = state.copyWith(isLocationLoading: true);
    try {
      final pos = await _getCurrentLocation();
      state = state.copyWith(currentPosition: pos);
      await _setupMarkers();
      _updateCurrentLocationMarker(state.currentPosition!);
      final sortedPoints = state.clients.map((c) => LatLng(c.latitude, c.longitude)).toList();
      await _fetchRouteSummary(sortedPoints);
      if (mapController != null && state.currentPosition != null) {
        mapController!.animateCamera(CameraUpdate.newLatLng(state.currentPosition!));
      }
      _positionStream = Geolocator.getPositionStream(locationSettings: _locationSettings).listen((Position position) {
        LatLng newPos = LatLng(position.latitude, position.longitude);
        _updateCurrentLocationMarker(newPos);
      });
    } catch (e) {
      print("Error refreshing map: $e");
    } finally {
      state = state.copyWith(isLocationLoading: false);
    }
  }
  String getImportantAddress(String fullAddress) {
    List<String> parts = fullAddress.split(',');
    int len = parts.length > 4 ? 4 : parts.length;
    return parts.sublist(0, len).join(', ').trim();
  }
}

final homeViewModelProvider = NotifierProvider<HomeViewModel, HomeState>(() {
  return HomeViewModel();
});

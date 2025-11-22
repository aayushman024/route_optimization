import 'dart:isolate';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:battery_plus/battery_plus.dart';

// Import model types to check success/failure
import 'package:flutter_foreground_task/models/service_request_result.dart';

import 'package:route_optimization/Services/auth_api.dart';

import 'apiGlobal.dart';

class LocationService {
  static Position? lastSentPosition;
  static DateTime? lastSentTime;
  static StreamSubscription<Position>? _locationStream;
  static const int POLLING_INTERVAL_SEC = 600;
  static const double POLLING_DISTANCE_M = 250;


  // Request all necessary permissions
  static Future<bool> requestAllPermissions(BuildContext context) async {
    print("[DEBUG] Starting permission requests...");

    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("[DEBUG] Location services disabled");
      _showLocationServiceDialog(context);
      return false;
    }

    // Request notification permission first (Android 13+)
    await _requestNotificationPermission();

    // Request location permissions
    bool locationGranted = await _requestLocationPermissions(context);
    if (!locationGranted) return false;

    // Request battery optimization exemption
    await _requestBatteryOptimization(context);

    // Request phone state permission (required for some Android versions)
    await _requestPhoneStatePermission();

    print("[DEBUG] All permissions granted successfully");
    return true;
  }

  static Future<void> _requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      print("[DEBUG] Requesting notification permission");
      await Permission.notification.request();
    }
  }

  static Future<void> _requestPhoneStatePermission() async {
    if (await Permission.phone.isDenied) {
      print("[DEBUG] Requesting phone state permission");
      await Permission.phone.request();
    }
  }

  static Future<bool> _requestLocationPermissions(BuildContext context) async {
    LocationPermission permission = await Geolocator.checkPermission();
    print("[DEBUG] Current permission: $permission");

    // Request basic location permission
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("[DEBUG] Location permission denied");
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("[DEBUG] Location permission permanently denied");
      _showSettingsDialog(context,
          "Location permission is permanently denied. Please enable it in settings.");
      return false;
    }

    // For Android 10+ (API 29+), we need background location permission
    // This should be requested AFTER getting foreground permission
    if (permission == LocationPermission.whileInUse) {
      print("[DEBUG] Has foreground permission, requesting background...");

      bool userAccepts = await _showBackgroundLocationDialog(context);
      if (!userAccepts) return false;

      // Use permission_handler for background location (more reliable)
      var backgroundStatus = await Permission.locationAlways.request();
      if (backgroundStatus != PermissionStatus.granted) {
        print("[DEBUG] Background location denied");
        _showSettingsDialog(context,
            "Background location access is required for continuous tracking. Please enable 'Allow all the time' in settings.");
        return false;
      }
    }

    return true;
  }

  static Future<void> _requestBatteryOptimization(BuildContext context) async {
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      bool userAccepts = await _showBatteryOptimizationDialog(context);
      if (userAccepts) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    }
  }

  static Future<bool> _showBackgroundLocationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Background Location Permission'),
          content: Text(
            'This app needs access to your location even when not in use to provide continuous route tracking. '
                'This helps optimize your routes and provide better service.\n\n'
                'Please select "Allow all the time" in the next screen.',
          ),
          actions: [
            TextButton(
              child: Text('Deny'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Allow'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ) ?? false;
  }

  static Future<bool> _showBatteryOptimizationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Battery Optimization'),
          content: Text(
            'To ensure location tracking continues working in the background, '
                'please disable battery optimization for this app.',
          ),
          actions: [
            TextButton(
              child: Text('Skip'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Allow'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ) ?? false;
  }

  static void _showLocationServiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Services Disabled'),
          content: Text('Please enable location services to use this feature.'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openLocationSettings();
              },
            ),
          ],
        );
      },
    );
  }

  static void _showSettingsDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Permission Required'),
          content: Text(message),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  // Initialize and start foreground service
  static Future<bool> initializeAndStartService() async {
    try {
      print("[DEBUG] Initializing foreground service...");

      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'location_service_channel',
          channelName: 'Location Service',
          channelDescription: 'Tracks your location for route optimization',
          channelImportance: NotificationChannelImportance.MIN,
          priority: NotificationPriority.MIN,
        ),
        iosNotificationOptions: IOSNotificationOptions(
          showNotification: true,
          playSound: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          autoRunOnBoot: true,
          autoRunOnMyPackageReplaced: true,
          allowWakeLock: true,
          allowWifiLock: true,
          // Reduced interval for more frequent updates
          eventAction: ForegroundTaskEventAction.repeat(POLLING_INTERVAL_SEC*1000), // 60 seconds
        ),
      );

      ServiceRequestResult result = await FlutterForegroundTask.startService(
        notificationTitle: 'Location Tracking Active',
        notificationText: 'Optimizing your route in the background',
        callback: startCallback,
      );

      if (result is ServiceRequestSuccess) {
        print("[DEBUG] Foreground service started successfully.");
        return true;
      } else {
        print("[DEBUG] Foreground service failed to start: $result");
        return false;
      }
    } catch (e) {
      print("[DEBUG] Error starting foreground service: $e");
      return false;
    }
  }

  // Stop foreground service
  static Future<void> stopService() async {
    await FlutterForegroundTask.stopService();
    _locationStream?.cancel();
    _locationStream = null;
    print("[DEBUG] Foreground service stopped");
  }

  // Send current location immediately (for widgets/manual triggers)
  static Future<void> sendCurrentLocationNow() async {
    try {
      print("[DEBUG] Getting current location...");

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("[DEBUG] Location services are disabled.");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print("[DEBUG] Location permission denied.");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );

      print("[DEBUG] Current position: Lat=${position.latitude}, Long=${position.longitude}");
      await sendLocationToServer(position);
    } catch (e) {
      print("[DEBUG] Error sending current location: $e");
    }
  }

  // Send location to server with retry mechanism
  static Future<void> sendLocationToServer(Position pos) async {
    print("[DEBUG] Sending location to server...");

    // Check if we should throttle requests (don't send if last position is too close and recent)
    if (lastSentPosition != null && lastSentTime != null) {
      double distanceInMeters = Geolocator.distanceBetween(
        lastSentPosition!.latitude,
        lastSentPosition!.longitude,
        pos.latitude,
        pos.longitude,
      );

      Duration timeSinceLastSent = DateTime.now().difference(lastSentTime!);

      if (distanceInMeters < POLLING_DISTANCE_M && timeSinceLastSent.inSeconds < POLLING_INTERVAL_SEC) {
        print("[DEBUG] Skipping location update - too close/recent");
        return;
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        print("[DEBUG] No JWT token found");
        return;
      }

      // Get Battery Level
      final int batteryLevel = await Battery().batteryLevel;
    //  final int batteryLevel = await battery.batteryLevel;
      print("[DEBUG] Battery level: $batteryLevel%");

      final url = Uri.parse("$apiBaseURL/api/route-plan/update-current-location");
      print("[DEBUG] Sending POST request to $url");

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'long': pos.longitude,
          'lat': pos.latitude,
          'batteryPercentage': batteryLevel,
        }),
      ).timeout(Duration(seconds: 30));

      print("[DEBUG] Server response status: ${response.statusCode}");
      print("[DEBUG] Server response body: ${response.body}");

      if (response.statusCode == 200) {
        print("[DEBUG] Location sent successfully");
        lastSentPosition = pos;
        lastSentTime = DateTime.now();
      } else {
        print("[DEBUG] Failed to send location: ${response.statusCode}");
      }
    } catch (e) {
      print("[DEBUG] Error sending location: $e");
    }
  }

  // Start location stream (more reliable than periodic updates)
  static Future<void> startLocationStream() async {
    try {
      print("[DEBUG] Starting location stream...");

      _locationStream?.cancel(); // Cancel existing stream

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 250,
      );

      _locationStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
            (Position position) async {
          print("[DEBUG] Location stream update: ${position.latitude}, ${position.longitude}");
          await sendLocationToServer(position);
        },
        onError: (error) {
          print("[DEBUG] Location stream error: $error");
        },
        cancelOnError: false,
      );
    } catch (e) {
      print("[DEBUG] Error starting location stream: $e");
    }
  }

  // Internal helper to check and send location (used by foreground service)
  static Future<void> _checkAndSendLocation() async {
    try {
      print("[DEBUG] Checking location for background send...");

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("[DEBUG] Location services disabled");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print("[DEBUG] Location permission denied");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 60),
      );

      print("[DEBUG] Background location: ${position.latitude}, ${position.longitude}");
      await sendLocationToServer(position);
    } catch (e) {
      print("[DEBUG] Error in _checkAndSendLocation: $e");
    }
  }
}

// Callback function for foreground service
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

class LocationTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print("[DEBUG] TaskHandler onStart at $timestamp");

    // Start location stream when service starts
    await LocationService.startLocationStream();
    final istTimestamp = timestamp.add(const Duration(hours: 5, minutes: 30));
    FlutterForegroundTask.updateService(
      notificationTitle: 'Location Tracking Active',
      notificationText: 'Started tracking at ${istTimestamp.hour}:${istTimestamp.minute}',
    );
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    // Convert to IST (GMT+5:30)
    final istTimestamp = timestamp.add(const Duration(hours: 5, minutes: 30));

    print("[DEBUG] onRepeatEvent fired at $istTimestamp");

    // Fallback: also send location periodically in case stream fails
    await LocationService._checkAndSendLocation();

    FlutterForegroundTask.updateService(
      notificationTitle: 'Location Tracking Active',
      notificationText: 'Last Updated: ${istTimestamp.hour}:${istTimestamp.minute.toString().padLeft(2, '0')}',
    );
  }


  @override
  void onButtonPressed(String id) {
    print("[DEBUG] Notification button pressed: $id");
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool bySystem) async {
    print("[DEBUG] TaskHandler destroyed at $timestamp by ${bySystem ? 'system' : 'user'}");

    FlutterForegroundTask.updateService(
      notificationTitle: 'Location Tracking Stopped',
      notificationText: 'Stopped at ${timestamp.hour}:${timestamp.minute}',
    );
  }

  @override
  void onNotificationPressed() {
    print("[DEBUG] Notification pressed");
    FlutterForegroundTask.launchApp();
  }
}
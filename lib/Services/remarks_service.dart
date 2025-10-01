import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'apiGlobal.dart';

class RemarksService {
  // Fetch current location
  static Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  // Get human-readable address
  static Future<String> getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks =
      await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isEmpty) {
        return "Lat: ${position.latitude}, Lng: ${position.longitude}";
      }

      final place = placemarks.first;
      List<String?> components = [
        place.name,
        place.street,
        place.subLocality,
        place.locality,
        place.administrativeArea,
        place.country
      ].where((e) => e != null && e.isNotEmpty).toList();

      return components.join(', ');
    } catch (e) {
      return "Lat: ${position.latitude}, Lng: ${position.longitude}";
    }
  }

  // Add remark API
  static Future<bool> addRemark({
    required String clientId,
    required String comment,
    required Position position,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final payload = {
      "clientId": clientId,
      "remarksByFE": comment,
      "markCommentLocation": {
        "coordinates": [position.longitude, position.latitude]
      }
    };

    try {
      final response = await http.post(
        Uri.parse("$apiBaseURL/api/route-plan/add-remarks"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}

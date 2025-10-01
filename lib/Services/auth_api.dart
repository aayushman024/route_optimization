import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import 'apiGlobal.dart';

class AuthService {
  final String baseUrl = apiBaseURL;

  final Duration timeout = Duration(seconds: 30);


  void _handleHttpError(http.Response response, String operation) {
    if (response.statusCode >= 500) {
      throw Exception('Server error. Please try again later.');
    } else if (response.statusCode == 404) {
      throw Exception('Service not found. Please check your connection.');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized. Please try again.');
    } else if (response.statusCode >= 400) {
      // Try to parse error message from response
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? errorData['error'] ??
            'Request failed';
        throw Exception(errorMessage);
      } catch (e) {
        throw Exception('Request failed with status ${response.statusCode}');
      }
    }
  }

  /// 1. Generate JWT token and store it
  Future<String?> generateJwt(String contactNumber) async {
    try {
      final url = Uri.parse('$baseUrl/auth/generate-jwt');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'contactNumber': contactNumber}),
      ).timeout(timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['token'] == null) {
          return null;
        }
        final token = data['token'] as String;
        final feName = data['feName'] as String;
        final feContactNumber = data['contactNumber'] as String;

        // Store token in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setString('feName', feName);
        await prefs.setString('contactNumber', feContactNumber);

        return token;
      } else {
        _handleHttpError(response, 'Generate JWT');
        return null;
      }
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on HttpException {
      throw Exception('Network error occurred. Please try again.');
    } on FormatException {
      throw Exception('Invalid server response. Please try again.');
    } catch (e) {
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
            'Cannot connect to server. Please check if the server is running.');
      }
      rethrow;
    }
  }

  /// 2. Send OTP (requires token)
  Future<bool> sendOtp(String contactNumber, String token) async {
    try {
      final url = Uri.parse('$baseUrl/auth/send-otp');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'contactNumber': contactNumber}),
      ).timeout(timeout);
      if (response.statusCode == 200) {
        return true;
      } else {
        _handleHttpError(response, 'Send OTP');
        return false;
      }
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on HttpException {
      throw Exception('Network error occurred. Please try again.');
    } on FormatException {
      throw Exception('Invalid server response. Please try again.');
    } catch (e) {
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
            'Cannot connect to server. Please check if the server is running.');
      }
      rethrow;
    }
  }

  /// 3. Validate OTP (requires token)
  Future<bool> validateOtp(String otp, String token) async {
    try {
      final url = Uri.parse('$baseUrl/auth/validate-otp');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'otp': otp}),
      ).timeout(timeout);
      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
        } catch (e) {}
        return true;
      } else {
        _handleHttpError(response, 'Validate OTP');
        return false;
      }
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on HttpException {
      throw Exception('Network error occurred. Please try again.');
    } on FormatException {
      throw Exception('Invalid server response. Please try again.');
    } catch (e) {
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
            'Cannot connect to server. Please check if the server is running.');
      }
      rethrow;
    }
  }

  Future<String?> getStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('jwt_token');
    } catch (e) {
      return null;
    }
  }
}

//   Future<void> clearStoredToken() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.remove('jwt_token');
//       await prefs.remove('is_logged_in');
//     } catch (e) {
//       print('Error clearing stored token: $e');
//     }
//   }
//
//   Future<bool> isLoggedIn() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       return prefs.getBool('is_logged_in') ?? false;
//     } catch (e) {
//       return false;
//     }
//   }

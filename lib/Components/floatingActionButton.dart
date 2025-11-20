import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart'; // <-- Added import
import 'package:http/http.dart' as http;
import 'package:route_optimization/Globals/fontStyle.dart';
import 'package:route_optimization/Services/task_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Services/apiGlobal.dart';
import '../Services/auth_api.dart';

class FAB extends StatefulWidget {
  const FAB({super.key});

  @override
  State<FAB> createState() => _FABState();
}

class _FABState extends State<FAB> {
  List<Map<String, String>> _clients = [];

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    final tasks = await TaskApi.fetchTasks();
    setState(() {
      _clients = tasks
          .map((task) => {
        "id": task.clientId,
        "name": "Task - ${task.order}, ${task.clientName}"
      })
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.large(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          // DARK MODE CHANGE: Dark modal background
          backgroundColor: const Color(0xFF1E1E1E),
          builder: (context) => CommentBottomSheet(clients: _clients),
        );
      },
      // This is already dark-mode compliant
      backgroundColor: const Color(0xff292929),
      tooltip: 'Add Comment',
      child: const Icon(Icons.add, color: Colors.white, size: 60),
    );
  }
}

class CommentBottomSheet extends StatefulWidget {
  final List<Map<String, String>> clients;

  const CommentBottomSheet({super.key, required this.clients});

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  String _currentAddress = "Fetching location...";
  bool _isLoadingLocation = true;
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  String? _selectedClientId;
  Position? _currentPosition;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _locationController.text = _currentAddress;
    _getCurrentPosition();
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _currentAddress = "Location services are disabled";
        _locationController.text = _currentAddress;
        _isLoadingLocation = false;
      });
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _currentAddress = "Location permissions are denied";
          _locationController.text = _currentAddress;
          _isLoadingLocation = false;
        });
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _currentAddress = "Location permissions are permanently denied";
        _locationController.text = _currentAddress;
        _isLoadingLocation = false;
      });
      return false;
    }

    return true;
  }

  Future<void> _getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;

    setState(() {
      _isLoadingLocation = true;
      _currentAddress = "Fetching location...";
      _locationController.text = _currentAddress;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _currentPosition = position;
      await _getAddressFromLatLng(position);
    } catch (e) {
      setState(() {
        _currentAddress = "Failed to get location: ${e.toString()}";
        _locationController.text = _currentAddress;
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        List<String> addressComponents = [];

        if (place.name != null && place.name!.isNotEmpty) {
          addressComponents.add(place.name!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressComponents.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressComponents.add(place.locality!);
        }
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          addressComponents.add(place.administrativeArea!);
        }
        if (place.country != null && place.country!.isNotEmpty) {
          addressComponents.add(place.country!);
        }

        String finalAddress = addressComponents.join(', ');
        if (finalAddress.isEmpty) {
          finalAddress =
          "Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}";
        }

        setState(() {
          _currentAddress = finalAddress;
          _locationController.text = _currentAddress;
          _isLoadingLocation = false;
        });
      } else {
        setState(() {
          _currentAddress =
          "Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}";
          _locationController.text = _currentAddress;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress = "Failed to get address: ${e.toString()}";
        _locationController.text = _currentAddress;
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _submitForm(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (_formKey.currentState!.validate()) {
      if (_currentPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location not available")),
        );
        return;
      }

      final payload = {
        "clientId": _selectedClientId,
        "remarksByFE": _commentController.text.trim(),
        "markCommentLocation": {
          "coordinates": [
            _currentPosition!.longitude,
            _currentPosition!.latitude
          ]
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

        if (response.statusCode == 200 || response.statusCode == 201) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Comment submitted successfully"),
              backgroundColor: Colors.green[800],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed: ${response.body}")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding:
      EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //Disclaimer
                Container(
                  width: screenWidth,
                  padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      border: Border.all(color: Colors.orange.shade700),
                      borderRadius: BorderRadius.circular(15)),
                  child: Text(
                    'Adding a comment for any task/client will mark it as "Pending".',
                    style: AppText.bold(color: Colors.orange.shade300),
                  ),
                ),

                // Location
                Row(
                  children: [
                    Text("Your Location",
                        style:
                        AppText.normal(fontSize: 16, color: Colors.white)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Container(height: 1, color: Colors.grey[700])),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  controller: _locationController,
                  enabled: false,
                  maxLines: null,
                  decoration: InputDecoration(
                    suffixIcon: _isLoadingLocation
                        ? Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.grey.shade400),
                        ),
                      ),
                    )
                        : null,
                    hintText: "Fetching location...",
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Select Client
                Row(
                  children: [
                    Text("Select Client",
                        style:
                        AppText.normal(fontSize: 16, color: Colors.white)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Container(height: 1, color: Colors.grey[700])),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  style: const TextStyle(color: Colors.white),
                  value: _selectedClientId,
                  decoration: InputDecoration(
                    hintText: 'Client Name',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownColor: Colors.grey[900],
                  items: widget.clients
                      .map((client) => DropdownMenuItem(
                    value: client["id"],
                    child: Text(
                      client["name"] ?? "",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedClientId = value;
                    });
                  },
                  validator: (value) =>
                  value == null ? "Please select a client" : null,
                ),
                const SizedBox(height: 24),

                // Add Comment
                Row(
                  children: [
                    Text("Add Comment",
                        style:
                        AppText.normal(fontSize: 16, color: Colors.white)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Container(height: 1, color: Colors.grey[700])),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  style: const TextStyle(color: Colors.white),
                  controller: _commentController,
                  maxLines: 6,
                  validator: (value) => value == null || value.isEmpty
                      ? "Please enter a comment"
                      : null,
                  decoration: InputDecoration(
                    hintText: "Enter your comment here...",
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit
                SizedBox(
                  width: screenWidth,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      // THEME CHANGE: Use green accent color from TodaysTasks
                      backgroundColor: Colors.green[800],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _submitForm(context),
                    child: Text(
                      "Submit Comment",
                      style: GoogleFonts.poppins(
                          color: Colors.green[100],
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    _commentController.dispose();
    super.dispose();
  }
}
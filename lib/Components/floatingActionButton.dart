import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:route_optimization/Globals/fontStyle.dart';

class FAB extends StatefulWidget {
  const FAB({super.key});

  @override
  State<FAB> createState() => _FABState();
}

class _FABState extends State<FAB> {
  String _currentAddress = "Fetching location...";
  bool _isLoadingLocation = true;
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  String? _selectedClient;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _locationController.text = _currentAddress;
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
        if (place.street != null && place.street!.isNotEmpty) {
          addressComponents.add(place.street!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressComponents.add(place.subLocality!);
        }
        if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
          addressComponents.add(place.thoroughfare!);
        }
        if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
          addressComponents.add(place.subThoroughfare!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressComponents.add(place.locality!);
        }
        if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
          addressComponents.add(place.subAdministrativeArea!);
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          addressComponents.add(place.administrativeArea!);
        }
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          addressComponents.add(place.postalCode!);
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

  void _resetFields() {
    setState(() {
      _locationController.clear();
      _commentController.clear();
      _selectedClient = null;
      _currentAddress = "Fetching location...";
      _isLoadingLocation = false;
    });
  }

  void _submitForm(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context);
      _resetFields();
    }
  }

  Widget _buildBottomSheetContent(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  children: [
                    Text("Your Location", style: AppText.normal(fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(child: Container(height: 1, color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  style: const TextStyle(color: Colors.black),
                  controller: _locationController,
                  enabled: false,
                  maxLines: null,
                  decoration: InputDecoration(
                    suffixIcon: _isLoadingLocation
                        ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                        ),
                      ),
                    )
                        : null,
                    hintText: "Fetching location...",
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "Location refreshes automatically when this screen opens",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- Select Client ---
                Row(
                  children: [
                    Text("Select Client", style: AppText.normal(fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(child: Container(height: 1, color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedClient,
                  decoration: InputDecoration(
                    hintText: 'Client Name',
                    filled: true,
                    fillColor: Colors.white,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue, width: 2),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  dropdownColor: const Color(0xffF0F8FF),
                  items: const [
                    DropdownMenuItem(value: "Client A", child: Text("Client A")),
                    DropdownMenuItem(value: "Client B", child: Text("Client B")),
                    DropdownMenuItem(value: "Client C", child: Text("Client C")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedClient = value;
                    });
                  },
                  validator: (value) => value == null ? "Please select a client" : null,
                ),
                const SizedBox(height: 24),

                // --- Add Comment ---
                Row(
                  children: [
                    Text("Add Comment", style: AppText.normal(fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(child: Container(height: 1, color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _commentController,
                  maxLines: 6,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                  decoration: InputDecoration(
                    hintText: "Enter your comment here...",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.blue, width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                  validator: (value) =>
                  value == null || value.trim().isEmpty ? "Please enter a comment" : null,
                ),
                const SizedBox(height: 24),

                // --- Submit Button ---
                SizedBox(
                  width: screenWidth,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff292929),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _submitForm(context),
                    child: const Text(
                      "Submit",
                      style: TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
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
          backgroundColor: const Color(0xffF0F8FF),
          builder: (context) {
            Future.microtask(() => _getCurrentPosition());
            return _buildBottomSheetContent(context);
          },
        ).whenComplete(() {
          _resetFields(); // reset when modal closes
        });
      },
      backgroundColor: const Color(0xff292929),
      tooltip: 'Add Comment',
      child: const Icon(Icons.add, color: Colors.white, size: 60),
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    _commentController.dispose();
    super.dispose();
  }
}

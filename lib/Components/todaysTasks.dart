import 'dart:convert';
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:route_optimization/Screens/homeScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../Globals/userDetails.dart';
import '../Models/task_model.dart';
import '../Services/apiGlobal.dart';
import '../Services/task_api.dart';
import '../DialogBoxes/modalBottomSheet.dart';
import '../Globals/fontStyle.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';

class TodaysTasks extends StatefulWidget {
  const TodaysTasks({super.key});

  @override
  State<TodaysTasks> createState() => _TodaysTasksState();
}

class _TodaysTasksState extends State<TodaysTasks> {
  late Future<List<TaskModel>> futureTasks;

  @override
  void initState() {
    super.initState();
    print("[DEBUG] initState() called — fetching today's tasks...");
    futureTasks = TaskApi.fetchTasks();
  }

  Future<void> _refreshTasks() async {
    print("[DEBUG] Pull-to-refresh triggered...");
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => HomeScreen(),
      ),
          (route) => false,
    );
  }

  Future<Position?> _getCurrentLocation() async {
    print("[DEBUG] Getting current location...");
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("[DEBUG] Location services disabled.");
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      print("[DEBUG] Location permission denied, requesting permission...");
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("[DEBUG] Location permission denied again.");
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("[DEBUG] Location permission permanently denied.");
      return null;
    }

    final position = await Geolocator.getCurrentPosition();
    print("[DEBUG] Current location: Lat=${position.latitude}, Lng=${position.longitude}");
    return position;
  }

  Future<void> _showRemarksModal(BuildContext context, String clientId, String taskId) async {
    final TextEditingController remarksController = TextEditingController();
    print("[DEBUG] Opening remarks modal for clientId=$clientId, taskId=$taskId");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // to add rounded corners with shadow
      builder: (BuildContext sheetContext) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 24,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 15,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient
              Container(
                width: 60,
                height: 6,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade500,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Text(
                'Mark Task as Completed?',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: remarksController,
                decoration: InputDecoration(
                  hintText: 'Enter your remarks (optional)',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                maxLines: 4,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      print("[DEBUG] Modal cancelled.");
                      Navigator.of(sheetContext).pop();
                    },
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 30),
                  ElevatedButton(
                    onPressed: () async {
                      print("[DEBUG] Remarks submitted: '${remarksController.text.trim()}'");
                      Navigator.of(sheetContext).pop();
                      await _submitCompletion(
                          context, clientId, taskId, remarksController.text.trim()
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 5,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    child: Text(
                      'Submit',
                      style: GoogleFonts.poppins(
                        color: Colors.green.shade900,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }



  Future<void> _submitCompletion(BuildContext context, String clientId, String taskId, String remarks) async {
    print("[DEBUG] Submitting completion for clientId=$clientId, visitId=$taskId");
    print("[DEBUG] Remarks: '$remarks'");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    print("[DEBUG] Retrieved JWT token: ${token != null ? 'Available' : 'Null'}");

    final position = await _getCurrentLocation();
    if (position == null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Location not available. Please enable location services."),
          backgroundColor: Colors.red,
        ),
      );
      print("[DEBUG] Task completion aborted — no location available.");
      return;
    }

    final payload = {
      "clientId": clientId,
      "visitId": taskId,
      "remarksByFE": remarks,
      "markCommentLocation": {
        "coordinates": [position.longitude, position.latitude]
      }
    };
    print("[DEBUG] API Payload: $payload");

    final url = Uri.parse("$apiBaseURL/api/route-plan/mark-completed");
    print("[DEBUG] Sending POST request to: $url");

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      print("[DEBUG] Response Status Code: ${response.statusCode}");
      print("[DEBUG] Response Body: ${response.body}");

      Navigator.of(context).pop();

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("[DEBUG] Task completion successful.");

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Lottie.asset(
                'assets/Success.json',
                repeat: false,
                width: 180,
                height: 180,
              ),
            );
          },
        );

        await Future.delayed(const Duration(seconds: 3));
        Navigator.of(context).pop();

        setState(() {
          _refreshTasks();
          print("[DEBUG] Refetching task list after successful completion...");
        });
      }
      else {
        print("[DEBUG] Task completion failed — response: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed: ${response.body}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      print("[DEBUG] Exception during API call: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> launchDialer(String phoneNumber) async {
    print("[DEBUG] Launching dialer for $phoneNumber");
    final String formatted = phoneNumber.startsWith("+") ? phoneNumber : "+91$phoneNumber";

    if (Platform.isAndroid) {
      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.DIAL',
          data: 'tel:$formatted',
        );
        await intent.launch();
        print("[DEBUG] Dialer intent launched successfully.");
      } catch (e) {
        print("[DEBUG] Error launching dialer: $e");
      }
    } else {
      final Uri uri = Uri(scheme: 'tel', path: formatted);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print("[DEBUG] Dialer opened using URL launcher.");
      } else {
        print("[DEBUG] Unable to launch dialer URL.");
      }
    }
  }

  Future<void> launchMaps(String url) async {
    print("[DEBUG] Launching map: $url");
    final Uri mapUri = Uri.parse(url);
    if (await canLaunchUrl(mapUri)) {
      await launchUrl(mapUri, mode: LaunchMode.externalApplication);
      print("[DEBUG] Map opened successfully.");
    } else {
      print("[DEBUG] Failed to open map URL.");
    }
  }

  String formatTimeRange(DateTime start, DateTime end) {
    final formatter = DateFormat("hh:mm a");
    return "${formatter.format(start)} - ${formatter.format(end)}";
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TaskModel>>(
      future: futureTasks,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          print("[DEBUG] Loading tasks...");
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          print("[DEBUG] Error fetching tasks: ${snapshot.error}");
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          print("[DEBUG] No tasks available for today.");
          return Center(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade100, Colors.blue.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assignment_turned_in_outlined,
                      size: 60, color: Colors.blue.shade600),
                  const SizedBox(height: 16),
                  Text(
                    "No tasks assigned for today",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Check back later for updates.",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final tasks = snapshot.data!;
        print("[DEBUG] Loaded ${tasks.length} tasks.");

        return RefreshIndicator(
          color: Colors.blue,
          onRefresh: _refreshTasks,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade700, Colors.blue.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: AppText.normal(fontSize: 18, color: Colors.white),
                        children: [
                          const TextSpan(text: 'Welcome, '),
                          TextSpan(
                            text: name,
                            style: AppText.bold(fontSize: 18, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Text(" Today's Tasks", style: AppText.bold(fontSize: 20)),
                      const SizedBox(width: 15),
                      Expanded(child: Container(height: 1, color: Colors.black26)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...tasks.map((task) => _buildTaskItem(task)).toList(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskItem(TaskModel task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.blue.shade100, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xff2E2F2E),
                child: Text(
                  task.order.toString(),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.clientName,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.purposeOfVisit,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xff1976D2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  formatTimeRange(task.availabilityStart, task.availabilityEnd),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xffF0F8FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xff1976D2).withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade50,
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: Color(0xff1976D2)),
                    const SizedBox(width: 8),
                    Text(
                      "Client Address",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  task.visitingAddress,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      print("[DEBUG] Navigate button tapped for task ${task.taskId}");
                      launchMaps(task.locationString);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.blue.shade600, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.navigation_rounded, color: Color(0xff1976D2)),
                    label: Text(
                      "Navigate",
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff1976D2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SwipeButton.expand(
                  thumb: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.arrow_forward_ios_rounded, color: Colors.white),
                  ),
                  activeThumbColor: Colors.green,
                  activeTrackColor: Colors.green.shade100,
                  inactiveThumbColor: Colors.green.shade50,
                  inactiveTrackColor: Colors.green.shade100,
                  elevationThumb: 10,
                  height: 50,
                  borderRadius: BorderRadius.circular(12),
                  child: Text(
                    '      Mark as Completed',
                    style: GoogleFonts.poppins(
                      color: const Color(0xff2E7D32),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onSwipe: () async {
                    print("[DEBUG] Swipe complete for taskId=${task.taskId}");
                    await _showRemarksModal(context, task.clientId, task.taskId);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: () {
                    print("[DEBUG] Call button tapped for ${task.clientContact}");
                    launchDialer(task.clientContact);
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.green.shade50,
                    side: BorderSide(color: Colors.green.shade600, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Icon(Icons.call, color: Color(0xff2E7D32)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

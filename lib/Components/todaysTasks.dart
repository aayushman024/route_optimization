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
import 'package:icons_plus/icons_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';

import '../Globals/userDetails.dart';
import '../Models/task_model.dart';
import '../Services/apiGlobal.dart';
import '../Services/task_api.dart';
import '../DialogBoxes/modalBottomSheet.dart';
import '../Globals/fontStyle.dart';

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
      MaterialPageRoute(builder: (context) => HomeScreen()),
          (route) => false,
    );
  }

  Future<Position?> _getCurrentLocation() async {
    print("[DEBUG] Getting current location...");
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;
    return await Geolocator.getCurrentPosition();
  }

  Future<void> _showRemarksModal(BuildContext context, String clientId, String taskId) async {
    final TextEditingController remarksController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 24,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border(top: BorderSide(color: Colors.grey[800]!, width: 1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 25),
              Text(
                'Task Completed?',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add any remarks or notes below.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 25),
              TextField(
                controller: remarksController,
                decoration: InputDecoration(
                  hintText: '(OPTIONAL)',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  filled: true,
                  fillColor: Colors.black38,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[800]!),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                maxLines: 3,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(sheetContext).pop();
                        await _submitCompletion(
                          context,
                          clientId,
                          taskId,
                          remarksController.text.trim(),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade900,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Submit & Complete',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitCompletion(BuildContext context, String clientId, String taskId, String remarks) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Center(child: CircularProgressIndicator(color: Colors.blue)),
    );

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final position = await _getCurrentLocation();

    if (position == null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Location not available."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final payload = {
      "clientId": clientId,
      "visitId": taskId,
      "remarksByFE": remarks,
      "markCommentLocation": {
        "coordinates": [position.longitude, position.latitude],
      },
    };

    try {
      final response = await http.post(
        Uri.parse("$apiBaseURL/api/route-plan/mark-completed"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      Navigator.of(context).pop();

      if (response.statusCode == 200 || response.statusCode == 201) {
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
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed: ${response.body}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> launchDialer(String phoneNumber) async {
    final String formatted = phoneNumber.startsWith("+") ? phoneNumber : "+91$phoneNumber";
    final Uri uri = Uri(scheme: 'tel', path: formatted);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> launchMaps(String url) async {
    final Uri mapUri = Uri.parse(url);
    if (await canLaunchUrl(mapUri))
      await launchUrl(mapUri, mode: LaunchMode.externalApplication);
  }

  String formatTimeRange(DateTime start, DateTime end) {
    final formatter = DateFormat("hh:mm a");
    return "${formatter.format(start)} - ${formatter.format(end)}";
  }

  // --- PRIORITY HELPER ---
  Map<String, dynamic> _getPriorityInfo(int priority) {
    switch (priority) {
      case 1:
        return {'label': 'Highest', 'color': Colors.redAccent};
      case 2:
        return {'label': 'High', 'color': Colors.orangeAccent};
      case 3:
        return {'label': 'Medium', 'color': Colors.yellowAccent};
      case 4:
        return {'label': 'Low', 'color': Colors.greenAccent};
      case 5:
        return {'label': 'Lowest', 'color': Colors.lightBlueAccent};
      default:
        return {'label': 'Normal', 'color': Colors.grey};
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TaskModel>>(
      future: futureTasks,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Colors.blue[400]));
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error loading tasks",
              style: TextStyle(color: Colors.grey[500]),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        final tasks = snapshot.data!;

        return RefreshIndicator(
          color: Colors.blue,
          backgroundColor: Colors.grey[900],
          onRefresh: _refreshTasks,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: [
              _buildWelcomeHeader(),
              const SizedBox(height: 25),
              Row(
                children: [
                  Text(
                    " Today's Schedule",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Divider(color: Colors.grey[800], thickness: 1.5),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...tasks.map((task) => _buildModernTaskCard(task)).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade900, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: RichText(
        text: TextSpan(
          style: AppText.light(fontSize: 18, color: Colors.white),
          children: [
            const TextSpan(text: 'Welcome, '),
            TextSpan(
              text: name,
              style: AppText.bold(fontSize: 18, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.task_alt, size: 70, color: Colors.grey[800]),
          const SizedBox(height: 20),
          Text(
            "All Caught Up!",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTaskCard(TaskModel task) {
    // Get Priority Info
    final priorityInfo = _getPriorityInfo(task.priority);
    final Color priorityColor = priorityInfo['color'];
    final String priorityLabel = priorityInfo['label'];

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER: Badge + Name
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Order Badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Center(
                    child: Text(
                      task.order.toString(),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Client Name
                Expanded(
                  child: Text(
                    task.clientName,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 2. PURPOSE OF VISIT - Enhanced and Prominent
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade900.withOpacity(0),
                    const Color(0xFF2C2C2C),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.15),
                  width: 1.5,
                ),
                // boxShadow: [
                //   BoxShadow(
                //     color: Colors.blue.withOpacity(0.08),
                //     blurRadius: 12,
                //     offset: const Offset(0, 4),
                //   ),
                // ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade700.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.assignment_outlined,
                          color: Colors.blue.shade200,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Purpose of Visit",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade200,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    task.purposeOfVisit,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.5,
                      //letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 3. DETAILS: Time & Priority Pills
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            child: Row(
              children: [
                // Time Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[900]!.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_filled_rounded,
                        size: 16,
                        color: Colors.blue[300],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatTimeRange(task.availabilityStart, task.availabilityEnd),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[100],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Priority Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: priorityColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flag_rounded, size: 16, color: priorityColor),
                      const SizedBox(width: 8),
                      Text(
                        priorityLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: priorityColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. ADDRESS SECTION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: Colors.blue[400],
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Visiting Address",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  // Address Text
                  Text(
                    task.visitingAddress,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 25),
                  // Navigate Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => launchMaps(task.locationString),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.blue[400]!, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: Icon(
                        Icons.navigation_rounded,
                        color: Colors.blue[400],
                        size: 20,
                      ),
                      label: Text(
                        "Navigate",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[400],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 5. ACTION ROW: Swipe & Call
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: SwipeButton.expand(
                    thumb: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.green.shade900,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    activeThumbColor: Colors.green.shade900,
                    activeTrackColor: const Color(0xFF2E7D32),
                    inactiveThumbColor: Colors.green.shade900,
                    inactiveTrackColor: const Color(0xFF1B3A20),
                    elevationThumb: 4,
                    height: 58,
                    borderRadius: BorderRadius.circular(18),
                    child: Text(
                      '           Slide to Complete',
                      style: GoogleFonts.poppins(
                        color: Colors.green[100],
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    onSwipe: () async {
                      await _showRemarksModal(context, task.clientId, task.taskId);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 58,
                    child: OutlinedButton(
                      onPressed: () => launchDialer(task.clientContact),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        side: BorderSide(
                          color: Colors.green.shade300,
                          width: 0.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Icon(
                        Icons.call,
                        color: Colors.green.shade400,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
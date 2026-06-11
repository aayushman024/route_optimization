import 'dart:convert';
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:route_optimization/features/tasks/views/homeScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import 'package:image_picker/image_picker.dart';

import 'package:route_optimization/core/managers/userDetails.dart';
import 'package:route_optimization/data/models/task_model.dart';
import 'package:route_optimization/core/constants/api_constants.dart';
import 'package:route_optimization/data/network/task_api.dart';
import 'package:route_optimization/core/dialogs/modalBottomSheet.dart';
import 'package:route_optimization/core/theme/fontStyle.dart';
import 'package:route_optimization/core/utils/dimensions.dart';

class TodaysTasks extends StatefulWidget {
  final Future<void> Function()? onRefresh;
  const TodaysTasks({super.key, this.onRefresh});

  @override
  State<TodaysTasks> createState() => TodaysTasksState();
}

class TodaysTasksState extends State<TodaysTasks> {
  late Future<List<TaskModel>> futureTasks;

  String? _formattedAdditionalAddressDetails(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  @override
  void initState() {
    super.initState();
    print("[DEBUG] initState() called — fetching today's tasks...");
    futureTasks = TaskApi.fetchTasks();
  }

  Future<void> refresh() async {
    print("[DEBUG] Refreshing tasks in-place...");
    setState(() {
      futureTasks = TaskApi.fetchTasks();
    });
    await futureTasks;
  }

  Future<void> _refreshTasks() async {
    print("[DEBUG] Pull-to-refresh triggered inside TodaysTasksState...");
    if (widget.onRefresh != null) {
      await widget.onRefresh!();
    } else {
      await refresh();
    }
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
    List<File> selectedImages = [];
    final ImagePicker picker = ImagePicker();

    Future<void> pickImage(StateSetter setState) async {
      if (selectedImages.length >= 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 10 images allowed'), backgroundColor: Colors.red),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            backgroundColor: const Color(0xFF2C2C2C),
            title: Text('Select Image Source', style: GoogleFonts.poppins(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.blue),
                  title: Text('Camera', style: GoogleFonts.poppins(color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(dialogContext);
                    final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                    if (image != null) {
                      setState(() {
                        selectedImages.add(File(image.path));
                      });
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.green),
                  title: Text('Gallery', style: GoogleFonts.poppins(color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(dialogContext);
                    final List<XFile> images = await picker.pickMultiImage(imageQuality: 70);
                    if (images.isNotEmpty) {
                      setState(() {
                        if (selectedImages.length + images.length > 10) {
                          final int remaining = 10 - selectedImages.length;
                          selectedImages.addAll(images.take(remaining).map((image) => File(image.path)));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added $remaining images. Limit is 10.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        } else {
                          selectedImages.addAll(images.map((image) => File(image.path)));
                        }
                      });
                    }
                  },
                ),
              ],
            ),
          );
        },
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext dialogContext, StateSetter setState) {
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
              const SizedBox(height: 20),
              // Image Attach Button & List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Attachments (${selectedImages.length}/10)',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[400],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => pickImage(setState),
                    icon: const Icon(Icons.add_a_photo, size: 18, color: Colors.blue),
                    label: Text(
                      'Add Image',
                      style: GoogleFonts.poppins(color: Colors.blue, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              if (selectedImages.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: selectedImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[700]!),
                              image: DecorationImage(
                                image: FileImage(selectedImages[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: -5,
                            right: 5,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedImages.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
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
                          selectedImages,
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
      },
    );
  }

  Future<void> _submitCompletion(BuildContext context, String clientId, String taskId, String remarks, List<File> images) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Center(child: CircularProgressIndicator(color: Colors.blue)),
    );

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final position = await _getCurrentLocation();

    if (position == null) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Location not available."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final String markCommentLocationJson = jsonEncode({
      "coordinates": [position.longitude, position.latitude]
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$apiBaseURL/api/route-plan/mark-completed"),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      request.fields['clientId'] = clientId;
      request.fields['visitId'] = taskId;
      request.fields['remarksByFE'] = remarks;
      request.fields['markCommentLocation'] = markCommentLocationJson;

      for (int i = 0; i < images.length; i++) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'completionImages',
            images[i].path,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (context.mounted) {
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
        }

        await Future.delayed(const Duration(seconds: 3));
        if (context.mounted) {
          Navigator.of(context).pop();
        }
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
      if (context.mounted) {
        Navigator.of(context).pop();
      }
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

  String formatTimeRange(DateTime start, DateTime end, bool canGoAnytime) {
    if(canGoAnytime){
      return "Anytime";
    }
    final formatter = DateFormat("hh:mm a");
    final istOffset = const Duration(hours: 5, minutes: 30);

    // Convert to UTC first, then add the IST offset
    final startIst = start.toUtc().add(istOffset);
    final endIst = end.toUtc().add(istOffset);

    return "${formatter.format(startIst)} - ${formatter.format(endIst)}";
  }

  // --- PRIORITY HELPER ---
  Map<String, dynamic> _getPriorityInfo(int priority) {
    switch (priority) {
      case 1:
        return {'label': 'High', 'color': Colors.redAccent};
      case 2:
        return {'label': 'Normal', 'color': Colors.blueAccent};
      case 3:
        return {'label': 'Low', 'color': Colors.greenAccent};
      default:
        return {'label': 'Normal', 'color': Colors.grey};
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeUtil.init(context);
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
              SizedBox(height: 10.sdp),
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


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.task_alt, size: 70, color: Colors.grey[800]),
          const SizedBox(height: 20),
          Text(
            "No Tasks Assigned!",
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
    final additionalAddressDetails =
        _formattedAdditionalAddressDetails(task.additionalAddressDetails);

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
                        formatTimeRange(task.availabilityStart, task.availabilityEnd, task.canGoAnytime),
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
                  if (additionalAddressDetails != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      additionalAddressDetails,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[400],
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Navigate Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => launchMaps(task.locationString),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1E8E6E), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(
                        Icons.navigation_rounded,
                        color: Color(0xFF1E8E6E),
                      ),
                      label: Text(
                        "Navigate",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E8E6E),
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
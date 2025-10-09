import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../Models/task_model.dart';
import '../Services/task_api.dart';
import '../DialogBoxes/modalBottomSheet.dart';
import '../Globals/fontStyle.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';

class CompletedTasksContainer extends StatefulWidget {
  const CompletedTasksContainer({super.key});

  @override
  State<CompletedTasksContainer> createState() => _CompletedTasksContainerState();
}

class _CompletedTasksContainerState extends State<CompletedTasksContainer> {
  late Future<List<TaskModel>> futureTasks;

  @override
  void initState() {
    super.initState();
    futureTasks = TaskApi.fetchTasks();
  }

  Future<void> launchDialer(String phoneNumber) async {
    final String formatted = phoneNumber.startsWith("+")
        ? phoneNumber
        : "+91$phoneNumber";

    if (Platform.isAndroid) {
      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.DIAL',
          data: 'tel:$formatted',
        );
        await intent.launch();
      } catch (e) {
        print("Error launching dialer: $e");
      }
    } else {
      final Uri uri = Uri(scheme: 'tel', path: formatted);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> launchMaps(String url) async {
    final Uri mapUri = Uri.parse(url);
    if (await canLaunchUrl(mapUri)) {
      await launchUrl(mapUri, mode: LaunchMode.externalApplication);
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
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                    "No Completed Tasks",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // Filter only completed tasks
        final completedTasks =
        snapshot.data!.where((task) => task.isCompleted == true).toList();

        if (completedTasks.isEmpty) {
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
                    "You have not completed any task today yet",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...completedTasks.map((task) => _buildTaskItem(task)).toList(),
              ],
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
        border: Border.all(color: Colors.green.shade600, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
            ],
          ),

          const SizedBox(height: 20),

          // Address + Navigate
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xff1976D2).withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: Color(0xff1976D2),
                    ),
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
                const SizedBox(height: 10),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Swipe + Call
          Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: () => launchMaps(task.locationString),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.blue.shade600, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(
                    Icons.navigation_rounded,
                    color: Color(0xff1976D2),
                  ),
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
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: () => launchDialer(task.clientContact),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.green.shade50,
                    side:
                    BorderSide(color: Colors.green.shade600, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  label: Text('Call Client',
                  style: AppText.bold(
                    color: Color(0xff2E7D32)
                  ),),
                  icon: const Icon(
                    Icons.call_rounded,
                    color: Color(0xff2E7D32),
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
import '../Globals/dimensions.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';

class CompletedTasksContainer extends StatefulWidget {
  const CompletedTasksContainer({super.key});

  @override
  State<CompletedTasksContainer> createState() => _CompletedTasksContainerState();
}

class _CompletedTasksContainerState extends State<CompletedTasksContainer> {
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
    futureTasks = TaskApi.fetchTasks();
  }

  Future<void> launchDialer(String phoneNumber) async {
    final String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final String formatted;
    if (cleaned.startsWith("+")) {
      formatted = cleaned;
    } else if (cleaned.startsWith("91") && cleaned.length == 12) {
      formatted = "+$cleaned";
    } else {
      formatted = "+91$cleaned";
    }

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
    SizeUtil.init(context);
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
              margin: EdgeInsets.all(20.sdp),
              padding: EdgeInsets.all(24.sdp),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade100, Colors.blue.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.sdp),
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
                      size: 60.sdp, color: Colors.blue.shade600),
                  SizedBox(height: 16.sdp),
                  Text(
                    "No Completed Tasks",
                    style: GoogleFonts.poppins(
                      fontSize: 18.ssp,
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
              margin: EdgeInsets.all(20.sdp),
              padding: EdgeInsets.all(24.sdp),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade100, Colors.blue.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.sdp),
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
                      size: 60.sdp, color: Colors.blue.shade600),
                  SizedBox(height: 16.sdp),
                  Text(
                    "You have not completed any task today yet",
                    style: GoogleFonts.poppins(
                      fontSize: 18.ssp,
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
            padding: EdgeInsets.symmetric(vertical: 20.sdp, horizontal: 12.sdp),
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
    final additionalAddressDetails =
        _formattedAdditionalAddressDetails(task.additionalAddressDetails);
    return Container(
      margin: EdgeInsets.only(bottom: 24.sdp),
      padding: EdgeInsets.all(16.sdp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.sdp),
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
                radius: 18.sdp,
                backgroundColor: const Color(0xff2E2F2E),
                child: Text(
                  task.order.toString(),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16.ssp,
                  ),
                ),
              ),
              SizedBox(width: 16.sdp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.clientName,
                      style: GoogleFonts.poppins(
                        fontSize: 18.ssp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4.sdp),
                    Text(
                      task.purposeOfVisit,
                      style: GoogleFonts.poppins(
                        fontSize: 15.ssp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 20.sdp),

          // Address + Navigate
          Container(
            padding: EdgeInsets.all(14.sdp),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.sdp),
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
                    SizedBox(width: 8.sdp),
                    Text(
                      "Client Address",
                      style: GoogleFonts.poppins(
                        fontSize: 14.ssp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.sdp),
                Text(
                  task.visitingAddress,
                  style: GoogleFonts.poppins(
                    fontSize: 15.ssp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                if (additionalAddressDetails != null) ...[
                  SizedBox(height: 8.sdp),
                  Text(
                    additionalAddressDetails,
                    style: GoogleFonts.poppins(
                      fontSize: 13.ssp,
                      fontWeight: FontWeight.w400,
                      color: Colors.black54,
                      height: 1.35,
                    ),
                  ),
                ],
                SizedBox(height: 10.sdp),
              ],
            ),
          ),

          SizedBox(height: 20.sdp),

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
                      borderRadius: BorderRadius.circular(12.sdp),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14.sdp),
                  ),
                  icon: const Icon(
                    Icons.navigation_rounded,
                    color: Color(0xff1976D2),
                  ),
                  label: Text(
                    "Navigate",
                    style: GoogleFonts.poppins(
                      fontSize: 15.ssp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff1976D2),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.sdp),
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: () => launchDialer(task.clientContact),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.green.shade50,
                    side:
                    BorderSide(color: Colors.green.shade600, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.sdp),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14.sdp),
                  ),
                  label: Text('Call Client',
                  style: AppText.bold(
                    color: const Color(0xff2E7D32)
                  ),),
                  icon: Icon(
                    Icons.call_rounded,
                    color: const Color(0xff2E7D32),
                    size: 22.sdp,
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

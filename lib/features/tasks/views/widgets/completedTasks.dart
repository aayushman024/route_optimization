import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:android_intent_plus/android_intent.dart';

import 'package:route_optimization/data/models/task_model.dart';
import 'package:route_optimization/data/network/task_api.dart';
import 'package:route_optimization/core/theme/fontStyle.dart';
import 'package:route_optimization/core/utils/dimensions.dart';

class CompletedTasksContainer extends StatefulWidget {
  const CompletedTasksContainer({super.key});

  @override
  State<CompletedTasksContainer> createState() => _CompletedTasksContainerState();
}

class _CompletedTasksContainerState extends State<CompletedTasksContainer> {
  late Future<List<TaskModel>> futureCompletedTasks;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _refreshTasks();
  }

  void _refreshTasks() {
    setState(() {
      futureCompletedTasks = TaskApi.fetchCompletedTasks();
    });
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

  String formatTimeRange(DateTime start, DateTime end, bool canGoAnytime) {
    if (canGoAnytime) {
      return "Anytime";
    }
    final formatter = DateFormat("hh:mm a");
    final istOffset = const Duration(hours: 5, minutes: 30);
    final startIst = start.toUtc().add(istOffset);
    final endIst = end.toUtc().add(istOffset);
    return "${formatter.format(startIst)} - ${formatter.format(endIst)}";
  }

  Color _getVisitTypeColor(String? type) {
    switch (type) {
      case 'Collection':
        return Colors.orangeAccent;
      case 'Handover':
        return Colors.tealAccent;
      case 'Exchange':
        return Colors.purpleAccent;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _getVisitTypeIcon(String? type) {
    switch (type) {
      case 'Collection':
        return Icons.download_rounded;
      case 'Handover':
        return Icons.upload_rounded;
      case 'Exchange':
        return Icons.sync_rounded;
      default:
        return Icons.business_center_rounded;
    }
  }

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

  String? _formattedAdditionalAddressDetails(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    SizeUtil.init(context);
    return FutureBuilder<List<TaskModel>>(
      future: futureCompletedTasks,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Colors.blue[400]));
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error loading completed tasks",
              style: TextStyle(color: Colors.grey[500]),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        final tasks = snapshot.data!;
        final filteredTasks = tasks.where((task) {
          if (searchQuery.isEmpty) return true;
          final query = searchQuery.toLowerCase();

          final clientName = task.clientName.toLowerCase();
          final purpose = task.purposeOfVisit.toLowerCase();
          final address = task.visitingAddress.toLowerCase();
          final additionalAddress = task.additionalAddressDetails?.toLowerCase() ?? "";

          final priorityInfo = _getPriorityInfo(task.priority);
          final priorityLabel = (priorityInfo['label'] as String).toLowerCase();

          final dateStr = task.completedAtTime != null
              ? DateFormat('dd MMM yyyy dd-MM-yyyy').format(task.completedAtTime!.toLocal()).toLowerCase()
              : "";

          return clientName.contains(query) ||
              purpose.contains(query) ||
              address.contains(query) ||
              additionalAddress.contains(query) ||
              priorityLabel.contains(query) ||
              dateStr.contains(query);
        }).toList();

        return RefreshIndicator(
          color: Colors.blue,
          backgroundColor: Colors.grey[900],
          onRefresh: () async {
            _refreshTasks();
            await futureCompletedTasks;
          },
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
                    " Completed Tasks",
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
              const SizedBox(height: 25),
              // Search Bar
              TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search client name, date, purpose, priority, address...",
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 13.ssp),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 25),
              if (filteredTasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      "No matching completed tasks found!",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                )
              else
                ...filteredTasks.map((task) => _buildCompletedTaskCard(task)).toList(),
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
          Icon(Icons.assignment_turned_in_outlined, size: 70, color: Colors.grey[800]),
          const SizedBox(height: 20),
          Text(
            "No Completed Tasks found!",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedTaskCard(TaskModel task) {
    final priorityInfo = _getPriorityInfo(task.priority);
    final Color priorityColor = priorityInfo['color'];
    final String priorityLabel = priorityInfo['label'];
    final additionalAddressDetails = _formattedAdditionalAddressDetails(task.additionalAddressDetails);

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

          // 2. PURPOSE OF VISIT
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
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
                // Visit Type Pill
                if (task.visitType != null && task.visitType!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getVisitTypeColor(task.visitType).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getVisitTypeColor(task.visitType).withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getVisitTypeIcon(task.visitType),
                          size: 16,
                          color: _getVisitTypeColor(task.visitType),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          task.visitType!,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _getVisitTypeColor(task.visitType),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                // Completed At Pill
                if (task.completedAtTime != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green[900]!.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: Colors.green[300],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Completed: ${DateFormat('hh:mm a, dd MMM yyyy').format(task.completedAtTime!.toLocal())}",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[100],
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

          // 5. COMMENTS SECTION
          if (task.feComments.isNotEmpty) ...[
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.comment_rounded, color: Colors.blue[300], size: 18),
                      const SizedBox(width: 8),
                      Text(
                        "FE Comments",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...task.feComments.map((comment) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment.text,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "By: ${comment.byName}",
                              style: GoogleFonts.poppins(
                                color: Colors.grey[500],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (comment.createdAt != null)
                              Text(
                                DateFormat('dd MMM yyyy, hh:mm a').format(comment.createdAt!.toLocal()),
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
          ],

          // 6. COMPLETION IMAGES
          if (task.completionImages.isNotEmpty) ...[
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.photo_library_rounded, color: Colors.blue[300], size: 18),
                      const SizedBox(width: 8),
                      Text(
                        "Completion Images",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: task.completionImages.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FullScreenImageViewer(
                                  images: task.completionImages,
                                  initialIndex: index,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                              image: DecorationImage(
                                image: NetworkImage(task.completionImages[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "${_currentIndex + 1} / ${widget.images.length}",
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                widget.images[index],
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: Colors.blue));
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

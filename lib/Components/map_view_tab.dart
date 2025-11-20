import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../Controllers/home_controller.dart';

class MapViewTab extends StatelessWidget {
  final HomeController controller;

  const MapViewTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    // Assuming the Scaffold background is dark, like in homeScreen.dart
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMapContainer(),
            const SizedBox(height: 20),
            if (controller.routeLegs.isNotEmpty) _buildRouteSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildMapContainer() {
    return Container(
      height: 500,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: controller.onMapCreated,
              initialCameraPosition: CameraPosition(
                target: controller.currentPosition!,
                zoom: 10.6,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              compassEnabled: true,
              mapToolbarEnabled: true,
              trafficEnabled: true,
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
              tiltGesturesEnabled: true,
              rotateGesturesEnabled: true,
              markers: controller.markers,
              polylines: controller.polylines,
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer()),
              },
            ),
            Positioned(
              top: 12,
              left: 12,
              child: FloatingActionButton(
                mini: true,
                onPressed: controller.refreshMapSafely,
                // DARK MODE CHANGE: Consistent dark FAB
                backgroundColor: Colors.black,
                child: const Icon(
                  Icons.refresh,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '  Route Summary',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            // DARK MODE CHANGE: Light text
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            // DARK MODE CHANGE: Nested dark grey
            color: const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(16),
            // DARK MODE CHANGE: Use themed border
            border: Border.all(
              color: Colors.blue[800]!.withOpacity(0.5),
            ),
            // DARK MODE CHANGE: Remove shadow
            boxShadow: [],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // DARK MODE CHANGE: Themed accent
                  Icon(Icons.location_on, color: Colors.blue[400]),
                  const SizedBox(width: 10),
                  Text(
                    'Total Distance: ${controller.totalDistance.toStringAsFixed(2)} km',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      // DARK MODE CHANGE: Light text
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  // DARK MODE CHANGE: Themed accent
                  Icon(Icons.schedule_rounded, color: Colors.blue[400]),
                  const SizedBox(width: 10),
                  Text(
                    'Total Travel Time: ${controller.totalTravelTimeStr}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      // DARK MODE CHANGE: Light text
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        ...controller.routeLegs.asMap().entries.map((entry) {
          return _buildRouteLegItem(entry.key, entry.value);
        }).toList(),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildRouteLegItem(int idx, Map<String, String> leg) {
    String start = controller.getImportantAddress(leg['start_address']!);
    String end = controller.getImportantAddress(leg['end_address']!);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimelineIndicator(idx),
        const SizedBox(width: 20),
        Expanded(child: _buildRouteLegCard(start, end, leg)),
      ],
    );
  }

  Widget _buildTimelineIndicator(int idx) {
    // This widget is already dark-mode compatible (blue gradient + white text)
    // No changes needed.
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4A90E2).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${idx + 1}',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
        if (idx != controller.routeLegs.length - 1)
          Container(
            width: 3,
            height: 100,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4A90E2).withOpacity(0.6),
                  const Color(0xFF4A90E2).withOpacity(0.2),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }

  Widget _buildRouteLegCard(
      String start, String end, Map<String, String> leg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        // DARK MODE CHANGE: Dark grey card color
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        // DARK MODE CHANGE: Remove shadow, use border
        border: Border.all(color: Colors.grey[800]!, width: 1),
        boxShadow: [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLocationRow(start, true),
            _buildArrowIndicator(),
            _buildLocationRow(end, false),
            _buildDivider(),
            _buildDistanceAndDuration(leg),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(String address, bool isStart) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: isStart ? const Color(0xFF4CAF50) : const Color(0xFFFF5722),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isStart ? const Color(0xFF4CAF50) : const Color(0xFFFF5722))
                    .withOpacity(0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            address,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              // DARK MODE CHANGE: Light text
              color: Colors.white,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildArrowIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const SizedBox(width: 22),
          Container(
            width: 3,
            height: 24,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              // DARK MODE CHANGE: Stronger opacity
              color: const Color(0xFF4A90E2).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.south, size: 16, color: Color(0xFF4A90E2)),
                const SizedBox(width: 4),
                Text(
                  'to',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF4A90E2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      height: 1,
      decoration: BoxDecoration(
        // DARK MODE CHANGE: Dark grey gradient
        gradient: LinearGradient(
          colors: [
            Colors.grey[800]!,
            Colors.grey[700]!,
            Colors.grey[800]!,
          ],
        ),
      ),
    );
  }

  Widget _buildDistanceAndDuration(Map<String, String> leg) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            'Distance',
            leg['distance']!,
            Icons.route,
            const Color(0xFF4A90E2), // Blue accent
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            'Duration',
            leg['duration']!,
            Icons.schedule,
            const Color(0xFFFF9800), // Orange accent
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        // DARK MODE CHANGE: Nested dark grey
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(16),
        // DARK MODE CHANGE: Stronger accent border
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    // DARK MODE CHANGE: Lighter grey
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: color, // Accent color
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
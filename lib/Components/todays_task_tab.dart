import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Components/todaysTasks.dart';
import '../Components/taskSummary.dart';

class TodaysTasksTab extends StatelessWidget {
  const TodaysTasksTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
        child: Column(
          children: [
            const TodaysTasks(),
            // const TaskSummary(),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}

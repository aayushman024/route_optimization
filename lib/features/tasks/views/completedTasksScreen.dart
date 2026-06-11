import 'package:flutter/material.dart';
import 'package:route_optimization/features/tasks/views/widgets/completedTasks.dart';
import 'package:route_optimization/features/tasks/views/widgets/todaysTasks.dart';
import 'package:route_optimization/core/theme/fontStyle.dart';

class CompletedTasks extends StatefulWidget {
  const CompletedTasks({super.key});

  @override
  State<CompletedTasks> createState() => _CompletedTasksState();
}

class _CompletedTasksState extends State<CompletedTasks> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        title: Text(
          'Completed Tasks',
          style: AppText.bold(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF121212),
      ),
      body: const CompletedTasksContainer(),
    );
  }
}

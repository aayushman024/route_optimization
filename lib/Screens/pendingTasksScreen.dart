import 'package:flutter/material.dart';
import 'package:route_optimization/Components/pendingTasks.dart';
import 'package:route_optimization/Components/todaysTasks.dart';
import 'package:route_optimization/Globals/fontStyle.dart';

class PendingTasksScreen extends StatefulWidget {
  const PendingTasksScreen({super.key});

  @override
  State<PendingTasksScreen> createState() => _PendingTasksScreenState();
}

class _PendingTasksScreenState extends State<PendingTasksScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF0F8FF),
      appBar: AppBar(
        title: Text('Pending Tasks',
          style: AppText.bold(
              color: Colors.white,
              fontSize: 18
          ),),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xff2E2F2E),
      ),
      body: SingleChildScrollView(
        child: PendingTasks(),
      ),
    );
  }
}

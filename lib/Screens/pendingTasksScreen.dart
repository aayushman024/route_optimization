import 'package:flutter/material.dart';
import 'package:route_optimization/Components/todaysTasks.dart';
import 'package:route_optimization/Globals/fontStyle.dart';

class PendingTasks extends StatefulWidget {
  const PendingTasks({super.key});

  @override
  State<PendingTasks> createState() => _PendingTasksState();
}

class _PendingTasksState extends State<PendingTasks> {
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
        child: TodaysTasks(),
      ),
    );
  }
}

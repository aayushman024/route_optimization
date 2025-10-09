import 'package:flutter/material.dart';
import 'package:route_optimization/Components/completedTasks.dart';
import 'package:route_optimization/Components/todaysTasks.dart';
import 'package:route_optimization/Globals/fontStyle.dart';

class CompletedTasks extends StatefulWidget {
  const CompletedTasks({super.key});

  @override
  State<CompletedTasks> createState() => _CompletedTasksState();
}

class _CompletedTasksState extends State<CompletedTasks> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5fff6),
      appBar: AppBar(
        title: Text('Completed Tasks',
        style: AppText.bold(
          color: Colors.white,
          fontSize: 18
        ),),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xff2E2F2E),
      ),
      body: SingleChildScrollView(
        child: CompletedTasksContainer(),
      ),
    );
  }
}

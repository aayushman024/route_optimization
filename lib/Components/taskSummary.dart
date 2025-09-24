import 'package:flutter/material.dart';

import '../Globals/fontStyle.dart';

class TaskSummary extends StatefulWidget {
  const TaskSummary({super.key});

  @override
  State<TaskSummary> createState() => _TaskSummaryState();
}

class _TaskSummaryState extends State<TaskSummary> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 18, horizontal: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xff003BB1), width: 0.75),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Task Summary', style: AppText.bold(fontSize: 18)),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Icon(Icons.pending_actions, color: Colors.orange, size: 30),
                  const SizedBox(height: 5),
                  Text('Pending', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              Text('5', style: AppText.bold(fontSize: 20)),

              const SizedBox(width: 8),

              Container(height: 35, width: 1, color: Colors.black38,),

              const SizedBox(width: 8),

              Column(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 30),
                  const SizedBox(height: 5),
                  Text('Completed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              Text('3', style: AppText.bold(fontSize: 20)),
            ],
          ),
        ],
      ),
    );
  }
}

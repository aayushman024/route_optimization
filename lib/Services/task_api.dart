import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:route_optimization/Services/auth_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/task_model.dart';
import 'apiGlobal.dart';

class TaskApi {
  static const String baseUrl = "$apiBaseURL/api/route-plan/get-tasks";
  static bool isTaskEmpty = false;

  static Future<List<TaskModel>> fetchTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      List<TaskModel> tasks =
      data.map((json) => TaskModel.fromJson(json)).toList();

      // Sort by order field
      tasks.sort((a, b) => a.order.compareTo(b.order));

      return tasks;
    } else if (response.statusCode == 404) {
      isTaskEmpty = true;
      return [];
    } else {
      throw Exception("Failed to load tasks");
    }
  }

//to fetch client names for drowdown
  static Future<List<String>> fetchClientDropdownList() async {
    final tasks = await fetchTasks();

    return tasks
        .map((task) => "Task - ${task.order}, ${task.clientName}, (ID: ${task.clientId})")
        .toList();
  }
}


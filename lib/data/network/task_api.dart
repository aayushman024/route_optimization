import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:route_optimization/data/network/auth_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:route_optimization/data/models/task_model.dart';
import 'package:route_optimization/core/constants/api_constants.dart';

class TaskApi {
  static const String baseUrl = "$apiBaseURL/api/route-plan/get-tasks";
  static bool isTaskEmpty = false;

  static String? _getFeIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1];
      var normalized = base64Url.normalize(payload);
      var resp = utf8.decode(base64Url.decode(normalized));
      final payloadMap = json.decode(resp);
      return payloadMap['id']?.toString() ??
          payloadMap['_id']?.toString() ??
          payloadMap['feId']?.toString();
    } catch (e) {
      return null;
    }
  }

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

      if (tasks.isNotEmpty) {
        final feId = tasks.first.feId;
        if (feId.isNotEmpty) {
          await prefs.setString('feId', feId);
        }
      }

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

  static Future<List<TaskModel>> fetchCompletedTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final storedFeId = prefs.getString('feId');
    final loggedInFeName = prefs.getString('feName');

    String? targetFeId = storedFeId;
    if (targetFeId == null && token != null) {
      targetFeId = _getFeIdFromToken(token);
      if (targetFeId != null) {
        await prefs.setString('feId', targetFeId);
      }
    }

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final url = "$apiBaseURL/api/route-plan/tasks/completed?to=$todayStr";

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List<dynamic> tasksJson = body['tasks'] ?? [];
      List<TaskModel> completedTasks =
          tasksJson.map((json) => TaskModel.fromJson(json)).toList();

      // Filter locally for tasks belonging to the logged-in FE
      if (targetFeId != null && targetFeId.isNotEmpty) {
        completedTasks = completedTasks
            .where((task) => task.feId == targetFeId)
            .toList();
      } else if (loggedInFeName != null && loggedInFeName.isNotEmpty) {
        completedTasks = completedTasks
            .where((task) => task.feName.toLowerCase() == loggedInFeName.toLowerCase())
            .toList();
      }

      // Sort by latest completion time (descending)
      completedTasks.sort((a, b) {
        if (a.completedAtTime == null && b.completedAtTime == null) return 0;
        if (a.completedAtTime == null) return 1;
        if (b.completedAtTime == null) return -1;
        return b.completedAtTime!.compareTo(a.completedAtTime!);
      });

      return completedTasks;
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception("Failed to load completed tasks");
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


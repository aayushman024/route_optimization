import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:route_optimization/Services/apiGlobal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '/Models/client_model.dart';

class ClientService {
  final String apiUrl = "$apiBaseURL/api/route-plan/get-all-coordinates";

  Future<List<Client>> fetchClients() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final response = await http.get(Uri.parse(apiUrl),
    headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<Client> clients = (data['data'] as List)
          .map((client) => Client.fromJson(client))
          .toList();
      return clients;
    } else {
      throw Exception('Failed to fetch clients');
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:route_optimization/Globals/customTheme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Screens/loginScreen.dart';
import 'Screens/homeScreen.dart';

Future<void> main() async {
  // 1. Ensure bindings are initialized for async calls
  WidgetsFlutterBinding.ensureInitialized();

  FlutterForegroundTask.initCommunicationPort();

  // 2. Check token BEFORE running the app
  // This keeps the native splash screen visible until the decision is made,
  // preventing the "loading spinner" screen.
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  final Widget initialScreen = token != null ? const HomeScreen() : const LoginScreen();

  // 3. Pass the decided screen to the app
  runApp(RouteOptimizer(initialScreen: initialScreen));
}

class RouteOptimizer extends StatelessWidget {
  final Widget initialScreen;

  // Constructor now accepts the determined screen
  const RouteOptimizer({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: customTheme,
      debugShowCheckedModeBanner: false,
      // 4. Render the screen directly, removing FutureBuilder and loader
      home: initialScreen,
    );
  }
}
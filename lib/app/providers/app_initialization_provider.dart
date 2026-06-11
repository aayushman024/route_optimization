import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:route_optimization/data/services/notificationService.dart';
import 'package:route_optimization/data/services/alarm_service.dart';

enum AppInitState { loading, loggedIn, loggedOut, error }

class AppInitNotifier extends Notifier<AppInitState> {
  @override
  AppInitState build() {
    _initialize();
    return AppInitState.loading;
  }

  Future<void> _initialize() async {
    try {
      // 1. Initialize Firebase and FCM
      try {
        await Firebase.initializeApp();
        await NotificationService().initialize();
      } catch (e) {
        print('[FCM] Firebase initialization error: $e');
      }

      // 2. Initialize Alarm Service
      await AlarmService.initialize();

      // 3. Initialize Foreground Task Port
      FlutterForegroundTask.initCommunicationPort();

      // 4. Check Authentication Status
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      // Add a slight delay to ensure the splash screen is visible for at least 1 second (optional, for smoother UX)
      await Future.delayed(const Duration(milliseconds: 500));

      if (token != null) {
        state = AppInitState.loggedIn;
      } else {
        state = AppInitState.loggedOut;
      }
    } catch (e) {
      print('[INIT ERROR] Failed to initialize app: $e');
      state = AppInitState.error;
    }
  }
}

final appInitProvider = NotifierProvider<AppInitNotifier, AppInitState>(() {
  return AppInitNotifier();
});

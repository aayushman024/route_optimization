import 'dart:isolate';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:route_optimization/Services/locationTracking.dart';

class AlarmService {
  static const int START_SERVICE_ALARM_ID = 1001;
  static const int STOP_SERVICE_ALARM_ID = 1002;

  static Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
    await scheduleAlarms();
  }

  static Future<void> scheduleAlarms() async {
    final now = DateTime.now();

    // Calculate next 08:30 AM
    DateTime nextStart = DateTime(now.year, now.month, now.day, 8, 30);
    if (now.isAfter(nextStart)) {
      nextStart = nextStart.add(const Duration(days: 1));
    }

    // Calculate next 07:00 PM (19:00)
    DateTime nextStop = DateTime(now.year, now.month, now.day, 19, 0);
    if (now.isAfter(nextStop)) {
      nextStop = nextStop.add(const Duration(days: 1));
    }

    print("[DEBUG] Scheduling start alarm at $nextStart");
    await AndroidAlarmManager.periodic(
      const Duration(days: 1),
      START_SERVICE_ALARM_ID,
      startLocationServiceCallback,
      startAt: nextStart,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );

    print("[DEBUG] Scheduling stop alarm at $nextStop");
    await AndroidAlarmManager.periodic(
      const Duration(days: 1),
      STOP_SERVICE_ALARM_ID,
      stopLocationServiceCallback,
      startAt: nextStop,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  }
}

@pragma('vm:entry-point')
void startLocationServiceCallback() async {
  print("[DEBUG] Alarm triggered: startLocationServiceCallback");
  final now = DateTime.now();
  if (now.weekday != DateTime.sunday) {
    await LocationService.initializeAndStartService();
  }
}

@pragma('vm:entry-point')
void stopLocationServiceCallback() async {
  print("[DEBUG] Alarm triggered: stopLocationServiceCallback");
  await LocationService.stopService();
}

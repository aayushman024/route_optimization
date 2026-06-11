import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:route_optimization/core/theme/customTheme.dart';
import 'package:route_optimization/app/views/splash_view.dart';

Future<void> main() async {
  // 1. Ensure bindings are initialized for async calls
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Wrap the app in ProviderScope for Riverpod
  runApp(
    const ProviderScope(
      child: RouteOptimizer(),
    ),
  );
}

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class RouteOptimizer extends StatelessWidget {
  const RouteOptimizer({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Route Optimizer',
      theme: customTheme,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      // 3. Boot directly to SplashView which handles async initialization safely
      home: const SplashView(),
    );
  }
}
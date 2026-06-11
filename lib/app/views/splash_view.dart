import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:route_optimization/app/providers/app_initialization_provider.dart';
import 'package:route_optimization/features/auth/views/loginScreen.dart';
import 'package:route_optimization/features/tasks/views/homeScreen.dart';
import 'package:route_optimization/core/utils/dimensions.dart';

class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView> {
  
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Initialize SizeUtil here safely since we are now in the widget tree
    SizeUtil.init(context);
    
    final initState = ref.watch(appInitProvider);

    // React to state changes
    ref.listen<AppInitState>(appInitProvider, (previous, next) {
      if (next == AppInitState.loggedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else if (next == AppInitState.loggedOut) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else if (next == AppInitState.error) {
        // Show error or fallback to login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error initializing app.')),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.black, // Adjust to your theme's splash color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Replace with your actual app logo if available
            Icon(
              Icons.location_on,
              size: 80.sdp,
              color: Colors.white,
            ),
            SizedBox(height: 20.sdp),
            Text(
              'Route Optimizer',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 24.ssp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 40.sdp),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

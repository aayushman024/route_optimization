import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:route_optimization/Screens/loginScreen.dart';
import 'package:route_optimization/Screens/routeDetails.dart';
import 'Screens/homeScreen.dart';

void main(){
  runApp(const RouteOptimizer());
}

class RouteOptimizer extends StatelessWidget {
  const RouteOptimizer({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
      //HomeScreen(),
      //RouteDetails(),
    );
  }
}

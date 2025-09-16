import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final List<Color> gradientColors; 
  final double width;         
  final double height;
  final Color textColor;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.textColor,
    this.gradientColors = const [     
      Color(0xff4FC3F7),
      Color(0xff29B6F6),
      Color(0xff0288D1),
    ],
    this.width = 0.75,               
    this.height = 55,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        // boxShadow: [
        //   BoxShadow(
        //     color: gradientColors.last.withOpacity(0.3),
        //     spreadRadius: 2,
        //     blurRadius: 8,
        //     offset: const Offset(0, 4),
        //   ),
        //],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

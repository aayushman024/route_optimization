import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:route_optimization/core/utils/dimensions.dart';

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
    SizeUtil.init(context);
    return Container(
      width: MediaQuery.of(context).size.width * width,
      height: height.sdp,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30.sdp),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.sdp),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 18.ssp,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

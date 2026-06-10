import 'package:flutter/material.dart';
import 'package:route_optimization/Globals/dimensions.dart';

class CustomElevatedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;
  final double borderRadius;
  final double height;
  final double width;
  final Color borderColor;

  const CustomElevatedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.borderColor = Colors.transparent,
    this.backgroundColor = Colors.blue,
    this.textColor = Colors.white,
    this.fontSize = 16,
    this.borderRadius = 8,
    this.height = 50,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    SizeUtil.init(context);
    return SizedBox(
      width: width == double.infinity ? double.infinity : width.sdp,
      height: height.sdp,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: borderColor),
            borderRadius: BorderRadius.circular(borderRadius.sdp),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize.ssp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

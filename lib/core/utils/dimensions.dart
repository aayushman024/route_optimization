import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:route_optimization/core/utils/dimensions.dart';

class SizeUtil {
  static const double _baseWidth = 425.0;
  static const double _baseHeight = 890.0;

  static double _screenWidth = 0;
  static double _screenHeight = 0;
  static bool _isPortrait = true;

  static void init(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    _screenWidth = size.width;
    _screenHeight = size.height;

    // Grab orientation to handle landscape swapping
    _isPortrait = MediaQuery.orientationOf(context) == Orientation.portrait;
  }

  // In landscape, the physical width is now the longer side,
  // so we scale against the base height instead of base width.
  static double get scaleWidth => _isPortrait
      ? _screenWidth / _baseWidth
      : _screenWidth / _baseHeight;

  // In landscape, physical height is the shorter side,
  // so we scale against the base width.
  static double get scaleHeight => _isPortrait
      ? _screenHeight / _baseHeight
      : _screenHeight / _baseWidth;

  static double get scaleText => min(scaleWidth, scaleHeight);
}

// Extending num lets us call .sdp and .ssp directly on any int or double
extension ResponsiveNum on num {
  double get sdp => this * SizeUtil.scaleWidth;

  double get ssp => this * SizeUtil.scaleText;
}

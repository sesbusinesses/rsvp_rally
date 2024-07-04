import 'package:flutter/material.dart';

class AppColors {
  static const Color light = Color(0xFFfefdfd); // Light color
  static const Color dark = Color(0xFF010101); // Dark color
  static const Color main = Color(0xFF5f42b2); // Main color (purple)
  static const Color accentLight = Color(0xFFdddddd); // Light accent color
  static const Color accentDark = Color(0xFFaaaaaa); // Light accent color
  static const Color shadow = Color(0xFFd3d3d3); // Shadow color
  static const Color link = Colors.blue; // Link color
  static const double borderWidth = 2.5;
}

Color getInterpolatedColor(double value) {
  const List<Color> colors = [Colors.red, Colors.yellow, Colors.green];
  const List<double> stops = [0.0, 0.5, 1.0];

  if (value <= stops.first) return colors.first;
  if (value >= stops.last) return colors.last;

  for (int i = 0; i < stops.length - 1; i++) {
    if (value >= stops[i] && value <= stops[i + 1]) {
      final t = (value - stops[i]) / (stops[i + 1] - stops[i]);
      return Color.lerp(colors[i], colors[i + 1], t)!;
    }
  }
  return colors.last;
}

Color getInterpolatedShadow(double value) {
  Color interpolatedColor = getInterpolatedColor(value);
  int alpha =
      (interpolatedColor.alpha * 0.3).toInt(); // Adjust the factor as needed
  return interpolatedColor.withAlpha(alpha);
}

Color getInterpolatedDark(double value) {
  Color baseColor = getInterpolatedColor(value);
  return darken(baseColor);
}

Color getInterpolatedLight(double value) {
  Color baseColor = getInterpolatedColor(value);
  return lighten(baseColor);
}

Color getInterpolatedAccent(double value) {
  Color baseColor = getInterpolatedColor(value);
  return getComplementaryColor(baseColor);
}

Color darken(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);
  final hsl = HSLColor.fromColor(color);
  final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
  return hslDark.toColor();
}

Color lighten(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);
  final hsl = HSLColor.fromColor(color);
  final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
  return hslLight.toColor();
}

Color getComplementaryColor(Color color) {
  final hsl = HSLColor.fromColor(color);
  final hslComplementary = hsl.withHue((hsl.hue + 180.0) % 360.0);
  return hslComplementary.toColor();
}

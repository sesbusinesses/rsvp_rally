import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color light = Color(0xFFfefdfd); // Light color
  static const Color dark = Color(0xFF010101); // Dark color
  static const Color accentLight = Color(0xFFdddddd); // Light accent color
  static const Color accentDark =
      Color.fromARGB(255, 109, 109, 109); // Light accent color
  static const Color shadow = Color(0xFFd3d3d3); // Shadow color
  static const Color link = Colors.blue; // Link color
  static const double borderWidth = 2.5;
  static TextStyle titleStyle = GoogleFonts.arsenal(
    textStyle: const TextStyle(
      fontSize: 25,
      fontWeight: FontWeight.w400,
      color: dark,
    ),
  );
  static TextStyle topStyle = GoogleFonts.bonaNova(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: dark,
  );
  static TextStyle subtitleStyle = GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: accentDark,
  );
  static TextStyle lightDateStyle = GoogleFonts.roboto(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: accentDark,
  );
  static TextStyle darkDateStyle = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w300,
    color: dark,
  );
  static TextStyle eventTimeDisplayStyle = GoogleFonts.playfair(
    fontWeight: FontWeight.w900,
    color: dark,
  );
  static TextStyle bodyStyle = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w300,
    color: dark,
  );
  static TextStyle usernameStyle = GoogleFonts.poppins(
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w200,
      color: accentDark,
    ),
  );
  static TextStyle buttonStyle = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: light,
  );
  static TextStyle linkStyle = GoogleFonts.poppins(
      textStyle: const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    color: link,
  ));
}

Color getTextOnRatingColor(double rating) {
  if ((rating - 0.5).abs() < 0.15) {
    return AppColors.dark;
  } else {
    return AppColors.light;
  }
}

String getEmoji(double rating) {
      if (rating <= 1 / 7) return 'assets/images/octopus.png'; // Worm (Red)
      if (rating <= 2 / 7) return 'assets/images/squid.png'; // Shrimp (Orange)
      if (rating <= 3 / 7) return 'assets/images/bumblebee.png'; // Bumblebee (Yellow)
      if (rating <= 4 / 7) return 'assets/images/turtle.png'; // Turtle (Green)
      if (rating <= 5 / 7) return 'assets/images/whale.png'; // Whale (Blue)
      if (rating <= 6 / 7) return 'assets/images/dinosaur.png'; // Jellyfish (Indigo)
      return 'assets/images/unicorn.png'; // Unicorn (Violet/Purple)
    }
Color getInterpolatedColor(double value) {
  const List<Color> colors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
  ];
  const List<double> stops = [
    0.0,
    1 / 6,
    2 / 6,
    3 / 6,
    4 / 6,
    5 / 6,
    1.0,
  ];

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

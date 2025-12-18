// lib/constants.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Deine bestehenden Primary-Farben (Teal-Basis)
  static const Color primary = Color(0xFF0B8C85); // Hauptfarbe (Teal)
  static const Color primaryDark =
      Color(0xFF085C58); // Dunkler für AppBar, Schatten etc.
  static const Color primaryLight =
      Color(0xFF3BB8B0); // Heller für Hover, Akzente

  // Hintergrund & Surfaces
  static const Color background = Color(0xFFF8FFFE); // Sehr helles Mint/Weiß
  static const Color surface = Colors.white; // Karten, Dialoge
  static const Color onBackground = Color(0xFF2D3436); // Text auf Background
  static const Color onSurface = Color(0xFF2D3436); // Text auf Surfaces

  // Text-Farben
  static const Color text = Color(0xFF2D3436); // Primärer Text
  static const Color textLight = Color(0xFF636E72); // Sekundärer Text, Hints

  // Semantic / Feedback Colors (wichtig für UX!)
  static const Color success = Color(0xFF4CAF50); // Grün – Erfolg, Bestätigung
  static const Color successLight = Color(0xFF81C784);

  static const Color warning =
      Color(0xFFFFB300); // Gelb/Amber – Warnung, Achtung
  static const Color warningLight = Color(0xFFFFD54F);

  static const Color error = Color(0xFFE53935); // Rot – Fehler, Gefahr, Löschen
  static const Color danger = error; // Alias für "Gefahr" (wie gewünscht)
  static const Color errorLight = Color(0xFFEF9A9A);

  static const Color info = Color(0xFF2196F3); // Blau – Info-Meldungen

  // Accent-Farben (gut passend zu Teal)
  static const Color accentCoral =
      Color(0xFFFF6F60); // Warmes Coral – für Highlights
  static const Color accentGold = Color(0xFFFFD700); // Gold – Eleganz, Premium
  static const Color accentPurple =
      Color(0xFF9C27B0); // Lila – kreative Akzente

  // Neutrale Farben
  static const Color divider = Color(0xFFBDBDBD); // Trenner, Linien
  static const Color disabled =
      Color(0xFF9E9E9E); // Deaktivierte Buttons/Felder
  static const Color placeholder = Color(0xFFB0BEC5); // Platzhalter-Text
}

class AppText {
  static TextStyle heading = GoogleFonts.roboto(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  static TextStyle title = GoogleFonts.roboto(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );

  static TextStyle body = GoogleFonts.roboto(
    fontSize: 16,
    color: AppColors.text,
  );

  static TextStyle label = GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textLight,
  );

  static TextStyle hint = GoogleFonts.roboto(
    fontSize: 15,
    color: AppColors.textLight,
  );

  static TextStyle button = GoogleFonts.roboto(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // Optional: Zusätzliche Styles für Feedback
  static TextStyle success = GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.success,
  );

  static TextStyle error = GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.error,
  );

  static TextStyle warning = GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.warning,
  );
}

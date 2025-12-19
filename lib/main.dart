// main.dart
import 'dart:async';

import 'package:senatLager/api_service.dart';
import 'package:senatLager/constants.dart'; // ← NEU: Dein Design-System
import 'package:senatLager/login_page.dart';
import 'package:senatLager/scanner_controller.dart';
import 'package:senatLager/scanner_page.dart';
import 'package:senatLager/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart'; // Wird für Theme benötigt
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Controller dauerhaft verfügbar machen
  Get.put(ScannerController(), permanent: true);

  // Nur Portrait erlauben
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // API initialisieren
  await ApiService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Ermittelt die Start-Route basierend auf gespeicherten Einstellungen
  Future<String> startRoute() async {
    final hasServer = ApiService.prefs.getString('server')?.isNotEmpty ?? false;
    if (!hasServer) return '/settings';

    final loggedIn =
        ApiService.getUser() != null && ApiService.getDoc() != null;
    return loggedIn ? '/scanner' : '/login';
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return FutureBuilder<String>(
          future: startRoute(),
          builder: (context, snapshot) {
            // Während wir auf die Route warten → schöner Ladebildschirm
            if (!snapshot.hasData) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                home: Scaffold(
                  backgroundColor: AppColors.background,
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 4,
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          'Lade App...',
                          style: AppText.body.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // App mit Theme und Routing
            return GetMaterialApp(
              title: 'Barcode Scanner',
              debugShowCheckedModeBanner: false,
              initialRoute: snapshot.data,

              // Globales Theme mit deinen Farben und TextStyles
              theme: ThemeData(
                useMaterial3: true, // Moderner Look

                // Primärfarben
                primaryColor: AppColors.primary,
                colorScheme: ColorScheme.light(
                  primary: AppColors.primary,
                  primaryContainer: AppColors.primaryDark,
                  secondary: AppColors.accentCoral, // z. B. für Akzente
                  surface: AppColors.surface,
                  background: AppColors.background,
                  error: AppColors.error,
                  onPrimary: Colors.white,
                  onSecondary: Colors.white,
                  onSurface: AppColors.onSurface,
                  onBackground: AppColors.onBackground,
                  onError: Colors.white,
                ),

                // Hintergrund & Scaffold
                scaffoldBackgroundColor: AppColors.background,

                // AppBar Theme
                appBarTheme: AppBarTheme(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  titleTextStyle: AppText.heading.copyWith(color: Colors.white),
                  systemOverlayStyle: const SystemUiOverlayStyle(
                    statusBarBrightness: Brightness.dark,
                    statusBarIconBrightness: Brightness.light,
                  ),
                ),

                // Text-Theme mit Google Fonts und deinen Styles
                textTheme: GoogleFonts.robotoTextTheme().copyWith(
                  displayLarge: AppText.heading,
                  titleLarge: AppText.title,
                  bodyLarge: AppText.body,
                  bodyMedium: AppText.label,
                  labelMedium: AppText.hint,
                ),

                // Button-Themes
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    textStyle: AppText.button,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                  ),
                ),

                // Divider, Card etc.
                dividerColor: AppColors.divider,
                cardColor: AppColors.surface,
              ),

              getPages: [
                GetPage(name: '/settings', page: () => SettingsPage()),
                GetPage(name: '/login', page: () => LoginPage()),
                GetPage(name: '/scanner', page: () => ScannerPage()),
              ],
            );
          },
        );
      },
    );
  }
}

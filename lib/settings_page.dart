import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'api_service.dart';
import 'constants.dart'; // Für AppColors und AppText

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController(
        text: ApiService.getServer() ?? '192.168.90.50:8086');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        title: Text(
          'Server einrichten',
          style: AppText.title.copyWith(
            color: AppColors.text,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 20.h),

              // Header Icon
              Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.settings_ethernet_rounded,
                  size: 64.sp,
                  color: AppColors.primary,
                ),
              ),

              SizedBox(height: 40.h),

              // Server Eingabe Card
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.dns_rounded,
                        color: AppColors.primary,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Server Adresse',
                            style: AppText.label.copyWith(
                              fontSize: 11.sp,
                              color: AppColors.textLight,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          TextField(
                            controller: ctrl,
                            keyboardType: TextInputType.url,
                            style: AppText.body.copyWith(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'z. B. 192.168.1.100:8080',
                              hintStyle: AppText.hint.copyWith(fontSize: 15.sp),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40.h),

              // Speichern Button mit Prüfung
              StatefulBuilder(
                builder: (context, setState) {
                  bool isSaving = false;

                  return _buildGradientButton(
                    label: 'Speichern',
                    icon: Icons.save_rounded,
                    isLoading: isSaving,
                    onPressed: isSaving
                        ? null
                        : () async {
                            setState(() => isSaving = true);

                            final address = ctrl.text.trim();
                            if (address.isEmpty) {
                              Get.snackbar(
                                  'Fehler', 'Bitte Server-Adresse eingeben',
                                  backgroundColor: Colors.red.withOpacity(0.9),
                                  colorText: Colors.white);
                              setState(() => isSaving = false);
                              return;
                            }

                            // Verbindung prüfen
                            bool reachable =
                                await ApiService.checkConnectivity(address);

                            if (!reachable) {
                              Get.snackbar(
                                'Verbindung fehlgeschlagen',
                                'Der Server ist nicht erreichbar. Bitte IP/Port prüfen.',
                                backgroundColor: Colors.red.withOpacity(0.9),
                                colorText: Colors.white,
                                snackPosition: SnackPosition.BOTTOM,
                                margin: EdgeInsets.all(16.w),
                                icon: const Icon(Icons.warning,
                                    color: Colors.white),
                                duration: const Duration(seconds: 5),
                              );
                              setState(() => isSaving = false);
                              return;
                            }

                            // Erfolgreich → speichern
                            await ApiService.setServer(address);

                            Get.offAllNamed('/login');
                            Get.snackbar(
                              'Erfolg',
                              'Server erfolgreich konfiguriert und erreichbar',
                              backgroundColor:
                                  AppColors.success.withOpacity(0.9),
                              colorText: Colors.white,
                              snackPosition: SnackPosition.BOTTOM,
                              margin: EdgeInsets.all(16.w),
                              icon: const Icon(Icons.check_circle,
                                  color: Colors.white),
                            );

                            setState(() => isSaving = false);
                          },
                  );
                },
              ),

              SizedBox(height: 16.h),

              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  'Abbrechen',
                  style: AppText.body.copyWith(
                    fontSize: 14.sp,
                    color: AppColors.textLight,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // _buildGradientButton bleibt unverändert
  Widget _buildGradientButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    final bool enabled = onPressed != null && !isLoading;

    return Container(
      height: 56.h,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: enabled
            ? LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
              )
            : null,
        color: enabled ? null : AppColors.disabled.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(14.r),
          child: Center(
            child: isLoading
                ? SizedBox(
                    height: 28.h,
                    width: 28.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.white, size: 24.sp),
                      SizedBox(width: 12.w),
                      Text(
                        label,
                        style: AppText.button.copyWith(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

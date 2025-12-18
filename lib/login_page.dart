import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'api_service.dart';
import 'constants.dart'; // Für AppColors und AppText

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final perCtrl = TextEditingController();
  final dokCtrl = TextEditingController();
  String? error;
  bool isLoading = false;

  void login() async {
    setState(() {
      error = null;
      isLoading = true;
    });

    final per = int.tryParse(perCtrl.text.trim());
    final dok = int.tryParse(dokCtrl.text.trim());

    if (per == null || dok == null) {
      setState(() {
        error = 'Beide Nummern eingeben';
        isLoading = false;
      });
      return;
    }

    final pOk = await ApiService.loginPersonal(per);
    if (!pOk) {
      setState(() {
        error = 'Personalnummer ungültig';
        isLoading = false;
      });
      return;
    }

    final dOk = await ApiService.loginDocument(dok);
    if (!dOk) {
      setState(() {
        error = 'Dokumentnummer ungültig';
        isLoading = false;
      });
      return;
    }

    Get.offAllNamed('/scanner');
  }

  @override
  void dispose() {
    perCtrl.dispose();
    dokCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        title: Text(
          'Anmeldung',
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

              // Logo / Header-Bereich (optional – falls gewünscht)
              Container(
                padding: EdgeInsets.all(20.w),
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
                  Icons.qr_code_scanner_rounded,
                  size: 64.sp,
                  color: AppColors.primary,
                ),
              ),

              SizedBox(height: 32.h),

              // Personalnummer
              _buildInputCard(
                controller: perCtrl,
                label: 'Personalnummer',
                hint: 'z. B. 12345',
                icon: Icons.person_outline,
                keyboardType: TextInputType.number,
              ),

              SizedBox(height: 16.h),

              // Dokumentnummer
              _buildInputCard(
                controller: dokCtrl,
                label: 'Dokumentnummer',
                hint: 'z. B. 67890',
                icon: Icons.description_outlined,
                keyboardType: TextInputType.number,
              ),

              // Fehlermeldung
              if (error != null) ...[
                SizedBox(height: 16.h),
                Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.error.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: AppColors.error, size: 20.sp),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          error!,
                          style: AppText.body.copyWith(
                            color: AppColors.error,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 32.h),

              // Anmelden Button
              _buildGradientButton(
                label: 'Anmelden',
                icon: Icons.login_rounded,
                onPressed: isLoading ? null : login,
                isLoading: isLoading,
              ),

              SizedBox(height: 16.h),

              // Server ändern
              TextButton(
                onPressed: () => Get.toNamed('/settings'),
                child: Text(
                  'Server ändern',
                  style: AppText.body.copyWith(
                    fontSize: 14.sp,
                    color: AppColors.primary,
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

  Widget _buildInputCard({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
  }) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border:
            Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
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
            child: Icon(icon, color: AppColors.primary, size: 24.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.label.copyWith(
                    fontSize: 11.sp,
                    color: AppColors.textLight,
                  ),
                ),
                SizedBox(height: 4.h),
                Container(
                  height: 50,
                  child: TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    style: AppText.body.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: AppText.hint.copyWith(fontSize: 15.sp),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
                    child: CircularProgressIndicator(
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

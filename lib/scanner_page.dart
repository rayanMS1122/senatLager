import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'api_service.dart';
import 'constants.dart';
import 'scanner_controller.dart';

class ScannerPage extends GetView<ScannerController> {
  const ScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final qtyCtrl = TextEditingController(text: '1');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        title: Text(
          'Lager Scanner',
          style: AppText.title.copyWith(
            color: AppColors.primary,
            fontSize: 18.sp,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, size: 20.sp),
            tooltip: 'Abmelden',
            color: AppColors.primary,
            onPressed: () {
              ApiService.logout();
              Get.offAllNamed('/login');
            },
          ),
          IconButton(
            icon: Icon(Icons.settings, size: 20.sp),
            tooltip: 'Einstellungen',
            color: AppColors.primary,
            onPressed: () => Get.toNamed('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Kamera-Bereich - kompakter
          Container(
            height: 155.h,
            decoration: BoxDecoration(
              color: Colors.black,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                MobileScanner(
                  controller: controller.cam,
                  onDetect: (capture) async {
                    if (!controller.isScanning.value) return;

                    final barcode = capture.barcodes.firstOrNull?.rawValue;
                    if (barcode != null && barcode.isNotEmpty) {
                      await controller.loadProduct(barcode);
                    }
                  },
                ),

                // Overlay bei Pause - animiert
                Obx(() => AnimatedOpacity(
                      opacity: controller.isScanning.value ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: controller.isScanning.value
                          ? const SizedBox.shrink()
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.85),
                                    Colors.black.withOpacity(0.95),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.pause_circle_outline,
                                      color: AppColors.primaryLight,
                                      size: 48.sp,
                                    ),
                                    SizedBox(height: 10.h),
                                    Text(
                                      'Kamera pausiert',
                                      style: AppText.title.copyWith(
                                        color: Colors.white,
                                        fontSize: 16.sp,
                                      ),
                                    ),
                                    SizedBox(height: 6.h),
                                    Text(
                                      'Tippe auf "NEUEN ARTIKEL SCANNEN"',
                                      textAlign: TextAlign.center,
                                      style: AppText.body.copyWith(
                                        color: Colors.white60,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    )),

                // Scan-Rahmen mit Animation
                Obx(() => controller.isScanning.value
                    ? Center(
                        child: Container(
                          width: 240.w,
                          height: 90.h,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.primaryLight,
                              width: 3.w,
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryLight.withOpacity(0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink()),

                // Taschenlampe Button - repositioniert
                Positioned(
                  right: 12.w,
                  bottom: 12.h,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark.withOpacity(0.8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.flashlight_on,
                          color: Colors.white, size: 20.sp),
                      onPressed: () => controller.cam.toggleTorch(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Hauptbereich - kompakter und eleganter
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Obx(
                () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User & Dokument Card - kompakter
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.08),
                            AppColors.primaryLight.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoChip(
                            Icons.person_outline,
                            ApiService.getUser()?['name'] ?? '-',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.08),
                            AppColors.primaryLight.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoChip(
                            Icons.description_outlined,
                            ApiService.getDoc()?['name'] ?? '-',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                    // Barcode Card - moderne Glasmorphism
                    GestureDetector(
                      onTap: () => _showManualInput(context),
                      child: Container(
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
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Icon(
                                Icons.qr_code_scanner_rounded,
                                color: AppColors.primary,
                                size: 24.sp,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Barcode',
                                    style: AppText.label.copyWith(
                                      fontSize: 11.sp,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    controller.barcode.value ??
                                        'Tippen für manuelle Eingabe',
                                    style: AppText.body.copyWith(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: controller.barcode.value != null
                                          ? AppColors.text
                                          : AppColors.textLight,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.edit_outlined,
                              size: 18.sp,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Produktname - eleganter
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: controller.loading.value
                          ? Center(
                              child: SizedBox(
                                height: 24.h,
                                width: 24.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Artikel',
                                  style: AppText.label.copyWith(
                                    fontSize: 11.sp,
                                    color: AppColors.textLight,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  controller.productName.value.isEmpty
                                      ? 'Nicht gefunden'
                                      : controller.productName.value,
                                  style: AppText.heading.copyWith(
                                    fontSize: 16.sp,
                                    color: controller.productName.value.isEmpty
                                        ? AppColors.error
                                        : AppColors.text,
                                  ),
                                ),
                              ],
                            ),
                    ),

                    // Lagerbestand - kompakter
                    if (controller.stockInfo.value.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.success.withOpacity(0.12),
                              AppColors.successLight.withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: AppColors.success.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              color: AppColors.success,
                              size: 18.sp,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                controller.stockInfo.value,
                                style: AppText.body.copyWith(
                                  fontSize: 13.sp,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    SizedBox(height: 20.h),

                    // Mengen-Eingabe - moderne Stepper
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          _buildStepperButton(
                            icon: Icons.remove_rounded,
                            color: AppColors.error,
                            onPressed: () {
                              final q = int.tryParse(qtyCtrl.text) ?? 1;
                              if (q > 1) qtyCtrl.text = '${q - 1}';
                            },
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'Menge',
                                  style: AppText.label.copyWith(
                                    fontSize: 11.sp,
                                    color: AppColors.textLight,
                                  ),
                                ),
                                TextField(
                                  controller: qtyCtrl,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: AppText.heading.copyWith(
                                    fontSize: 24.sp,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildStepperButton(
                            icon: Icons.add_rounded,
                            color: AppColors.success,
                            onPressed: () {
                              qtyCtrl.text =
                                  '${(int.tryParse(qtyCtrl.text) ?? 1) + 1}';
                            },
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // Action Buttons - moderne Gradient Buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            label: 'HINZUFÜGEN',
                            icon: Icons.add_rounded,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.success,
                                AppColors.successLight,
                              ],
                            ),
                            enabled: controller.barcode.value != null,
                            onPressed: () async {
                              final qty = int.tryParse(qtyCtrl.text) ?? 1;
                              await controller.book(true, qty);
                              qtyCtrl.text = '1';
                            },
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildActionButton(
                            label: 'ENTNEHMEN',
                            icon: Icons.remove_rounded,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.error,
                                AppColors.errorLight,
                              ],
                            ),
                            enabled: controller.barcode.value != null,
                            onPressed: () async {
                              final qty = int.tryParse(qtyCtrl.text) ?? 1;
                              await controller.book(false, qty);
                              qtyCtrl.text = '1';
                            },
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16.h),

                    // Neuer Scan Button - primär
                    _buildActionButton(
                      label: 'NEUEN ARTIKEL SCANNEN',
                      icon: Icons.qr_code_scanner_rounded,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primaryLight,
                        ],
                      ),
                      fullWidth: true,
                      enabled: true,
                      onPressed: controller.newScan,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.sp, color: AppColors.primary),
        SizedBox(width: 6.w),
        Text(
          text,
          style: AppText.label.copyWith(
            fontSize: 12.sp,
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 24.sp),
        padding: EdgeInsets.all(8.w),
        constraints: BoxConstraints(
          minWidth: 44.w,
          minHeight: 44.h,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Gradient gradient,
    required bool enabled,
    required VoidCallback onPressed,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      height: 48.h,
      decoration: BoxDecoration(
        gradient: enabled ? gradient : null,
        color: enabled ? null : AppColors.disabled.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: gradient.colors.first.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(12.r),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  label,
                  style: AppText.button.copyWith(fontSize: 14.sp),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showManualInput(BuildContext context) {
    final ctrl = TextEditingController();

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      color: AppColors.primary,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Barcode eingeben',
                      style: AppText.title.copyWith(fontSize: 17.sp),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                style: AppText.body.copyWith(fontSize: 15.sp),
                decoration: InputDecoration(
                  labelText: 'Barcode',
                  hintText: 'z. B. 123456789',
                  labelStyle: AppText.label.copyWith(fontSize: 13.sp),
                  hintStyle: AppText.hint.copyWith(fontSize: 14.sp),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: AppColors.divider.withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      child: Text(
                        'Abbrechen',
                        style: AppText.body.copyWith(
                          fontSize: 14.sp,
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            final barcode = ctrl.text.trim();
                            if (barcode.isNotEmpty) {
                              controller.loadProduct(barcode);
                              Get.back();
                            }
                          },
                          borderRadius: BorderRadius.circular(10.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            alignment: Alignment.center,
                            child: Text(
                              'Laden',
                              style: AppText.button.copyWith(fontSize: 14.sp),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

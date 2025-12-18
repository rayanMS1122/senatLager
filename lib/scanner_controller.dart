import 'dart:async';
import 'dart:convert';
import 'package:barcode_scaner/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ScannerController extends GetxController {
  final MobileScannerController cam = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  var barcode = Rxn<String>();
  var productName = 'Scanne etwas...'.obs;
  var stockInfo = ''.obs;
  var loading = false.obs;
  var isScanning = true.obs; // Neu: steuert, ob Kamera aktiv scannt

  Future<void> loadProduct(String code) async {
    String cleanedCode = code.replaceFirst(RegExp(r'^0+'), '');
    if (cleanedCode.isEmpty) cleanedCode = code;

    barcode.value = cleanedCode;
    productName.value = 'Lade...';
    stockInfo.value = '';
    loading.value = true;

    final data = await ApiService.getProduct(cleanedCode);

    if (data != null) {
      String name = 'Unbekannt';
      if (data['such']?.toString().trim().isNotEmpty == true)
        name = data['such'].toString().trim();
      else if (data['bezeichnung']?.toString().trim().isNotEmpty == true)
        name = data['bezeichnung'].toString().trim();
      else if (data['nr'] != null) name = 'Artikel ${data['nr']}';

      productName.value = name;
      stockInfo.value = data['bestand'] != null
          ? 'Bestand: ${data['bestand']}'
          : 'Bestand: unbekannt';
    } else {
      productName.value = 'Nicht gefunden';
      stockInfo.value = '';
    }

    loading.value = false;
    HapticFeedback.mediumImpact();

    // WICHTIG: Nach erfolgreichem Laden → Kamera pausieren
    isScanning.value = false;
    await cam.stop();
  }

  void newScan() {
    barcode.value = null;
    productName.value = 'Scanne etwas...';
    stockInfo.value = '';

    // Kamera wieder starten
    isScanning.value = true;
    cam.start();

    Get.snackbar('Bereit', 'Scanne einen neuen Artikel',
        backgroundColor: Colors.blue, duration: Duration(seconds: 2));
  }

  Future<void> book(bool add, int qty) async {
    if (barcode.value == null || qty <= 0) {
      print('Buchung abgebrochen: Kein Barcode oder Menge ≤ 0');
      return;
    }

    loading.value = true;
    print('Starte Buchung: +$qty (${add ? 'hinzufügen' : 'entnehmen'})');

    final result = await ApiService.book(barcode.value!, qty, add);

    if (result != null && result['bestand'] != null) {
      stockInfo.value = 'Bestand: ${result['bestand']}';
      Get.snackbar('Erfolg!', add ? '+$qty hinzugefügt' : '-$qty entnommen',
          backgroundColor: Colors.green, duration: Duration(seconds: 3));
    }

    loading.value = false;
  }

  @override
  void onClose() {
    cam.dispose();
    super.onClose();
  }
}

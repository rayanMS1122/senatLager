import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/stock_item.dart';
import '../services/api_service.dart';

class ScannerController extends GetxController {
  final MobileScannerController scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    autoStart: true,
    torchEnabled: false,
    formats: [BarcodeFormat.all],
  );

  // Observables
  var items = <StockItem>[].obs;
  var lastScannedBarcode = Rxn<String>();
  var lastUsedQuantity = '1'.obs;

  var currentProductName = ''.obs;
  var currentStockInfo = ''.obs;
  var isLoadingProduct = false.obs;

  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  Future<void> fetchProductInfo(String barcode) async {
    isLoadingProduct.value = true;
    currentProductName.value = '';
    currentStockInfo.value = '';

    final data = await ApiService.fetchProductInfo(barcode);

    if (data != null) {
      final name =
          data['name'] ??
          data['productName'] ??
          data['description'] ??
          'Unbekanntes Produkt';

      final int? stock =
          data['stock'] ?? data['currentStock'] ?? data['quantity'];

      currentProductName.value = name;
      currentStockInfo.value = stock != null
          ? 'Lagerbestand: $stock'
          : 'Kein Bestand verfügbar';
    } else {
      currentProductName.value = 'Produkt nicht gefunden';
      currentStockInfo.value = 'Fehler beim Laden';
    }

    isLoadingProduct.value = false;
  }

  void handleBarcode(String barcode, BarcodeFormat? format) {
    if (barcode == lastScannedBarcode.value) return;

    HapticFeedback.vibrate();
    lastScannedBarcode.value = barcode;
    lastUsedQuantity.value = lastUsedQuantity.value;

    fetchProductInfo(barcode);

    Get.snackbar(
      'Gescannt',
      'Barcode: $barcode (${format?.name ?? 'Unbekannt'})',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void clearAll() {
    items.clear();
  }

  String generateListText() {
    return items
        .map((item) {
          final name = item.name != null ? ' (${item.name})' : '';
          return '${item.barcode} ${item.quantity}$name';
        })
        .join('\n');
  }

  @override
  void onClose() {
    scannerController.dispose();
    super.onClose();
  }
}

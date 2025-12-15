import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../controllers/scanner_controller.dart';
import '../widgets/quantity_input_row.dart';

class ScannerPage extends GetView<ScannerController> {
  const ScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController quantityController = TextEditingController(
      text: '1',
    );
    final TextEditingController manualBarcodeController =
        TextEditingController();

    // Synchronisiere mit lastUsedQuantity
    ever(controller.lastUsedQuantity, (_) {
      quantityController.text = controller.lastUsedQuantity.value;
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode Scanner'),
        actions: [
          IconButton(
            onPressed: () {
              final text = controller.generateListText();
              if (text.isNotEmpty) {
                Clipboard.setData(ClipboardData(text: text));
                Get.snackbar('Kopiert', 'Liste in Zwischenablage');
              }
            },
            icon: const Icon(Icons.copy),
          ),
          IconButton(
            onPressed: () {
              final text = controller.generateListText();
              if (text.isNotEmpty) Share.share(text);
            },
            icon: const Icon(Icons.share),
          ),
          IconButton(
            onPressed: controller.clearAll,
            icon: const Icon(Icons.clear_all),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(
                  controller: controller.scannerController,
                  onDetect: (capture) {
                    final barcode = capture.barcodes.firstOrNull;
                    if (barcode?.rawValue != null) {
                      controller.handleBarcode(
                        barcode!.rawValue!,
                        barcode.format,
                      );
                    }
                  },
                ),
                Center(
                  child: Container(
                    width: 250,
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: Stack(
                    children: [
                      Container(color: Colors.black54),
                      Center(
                        child: Container(
                          width: 260,
                          height: 130,
                          color: Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Obx(() {
              return Column(
                children: [
                  Text(
                    controller.totalQuantity > 0
                        ? 'Gesamtmenge: ${controller.totalQuantity} Artikel'
                        : 'Noch keine Artikel',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    controller.lastScannedBarcode.value != null
                        ? 'Gescannt: ${controller.lastScannedBarcode.value}'
                        : 'Scanne einen Barcode...',
                    style: const TextStyle(fontSize: 18),
                  ),
                  if (controller.isLoadingProduct.value) ...[
                    const SizedBox(height: 10),
                    const CircularProgressIndicator(),
                  ],
                  if (controller.currentProductName.value.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      controller.currentProductName.value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (controller.currentStockInfo.value.isNotEmpty)
                      Text(
                        controller.currentStockInfo.value,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                  const SizedBox(height: 20),
                  QuantityInputRow(controller: quantityController),
                  const SizedBox(height: 22),
                  TextField(
                    controller: manualBarcodeController,
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        controller.handleBarcode(value.trim(), null);
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Manuell Barcode eingeben',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                      ),
                      onPressed: () {
                        final barcode = manualBarcodeController.text.trim();
                        if (barcode.isNotEmpty) {
                          controller.handleBarcode(barcode, null);
                        }
                      },
                      child: const Text(
                        'Suchen',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 88),
                ],
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.scannerController.toggleTorch(),
        child: const Icon(Icons.flash_on),
      ),
    );
  }
}

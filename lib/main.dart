// Aktualisierte main.dart mit Integration der GET-Funktion
// Die App holt nun bei jedem Scan (oder manueller Eingabe) die Produktinformationen vom Server
// und zeigt Name + aktuellen Lagerbestand an.
// Bei Hinzufügen wird weiterhin nur Barcode + Menge gespeichert (wie bisher),
// aber in der Liste werden nun zusätzlich Name und Bestand angezeigt (falls verfügbar).

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

// Globale oder statische Base-URL – einfach anpassen, falls nötig
const String baseUrl = 'http://192.168.90.50:8086/api/v1/stock/by-ean/';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barcode Scanner App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ScannerPage(),
    );
  }
}

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );
  final TextEditingController _barCodeManuelEingebenController =
      TextEditingController(text: '');

  // Erweiterte Item-Struktur: barcode, quantity, name (optional), stock (optional)
  final List<Map<String, dynamic>> _items = [];

  String? _lastScannedBarcode;
  String _lastUsedQuantity = '1';

  // Zustand für das aktuell gescannte Produkt
  String _currentProductName = '';
  String _currentStockInfo = '';
  bool _isLoadingProduct = false;

  int get _totalQuantity =>
      _items.fold(0, (sum, item) => sum + (item['quantity'] as int));

  // Neue Funktion: Produktinformationen vom Server holen
  Future<void> _fetchProductInfo(String barcode) async {
    setState(() {
      _isLoadingProduct = true;
      _currentProductName = '';
      _currentStockInfo = '';
    });

    try {
      final uri = Uri.parse('$baseUrl$barcode');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Anpassbar je nach tatsächlichem JSON-Format deines Servers
        // Mögliche Varianten:
        final String name =
            data['name'] ??
            data['productName'] ??
            data['description'] ??
            'Unbekanntes Produkt';

        final int? stock =
            data['stock'] ?? data['currentStock'] ?? data['quantity'];

        setState(() {
          _currentProductName = name;
          _currentStockInfo = stock != null
              ? 'Lagerbestand: $stock'
              : 'Kein Bestand verfügbar';
        });
      } else {
        setState(() {
          _currentProductName = 'Fehler ${response.statusCode}';
          _currentStockInfo = 'Produkt nicht gefunden';
        });
      }
    } catch (e) {
      setState(() {
        _currentProductName = 'Verbindungsfehler';
        _currentStockInfo = e.toString();
      });
    } finally {
      setState(() {
        _isLoadingProduct = false;
      });
    }
  }

  void _handleBarcode(String barcode, BarcodeFormat? format) {
    if (barcode == _lastScannedBarcode) return;

    HapticFeedback.vibrate();

    setState(() {
      _lastScannedBarcode = barcode;
      _quantityController.text = _lastUsedQuantity;
    });

    // Produktinfo sofort laden
    _fetchProductInfo(barcode);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gescannt: $barcode (${format?.name ?? 'Unbekannt'})'),
      ),
    );
  }

  void _addOrUpdateItem() {
    final String barcode = _lastScannedBarcode ?? '';
    if (barcode.isEmpty) return;

    final int? qty = int.tryParse(_quantityController.text.trim());
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte eine gültige Menge eingeben')),
      );
      return;
    }

    setState(() {
      final existingIndex = _items.indexWhere(
        (item) => item['barcode'] == barcode,
      );
      if (existingIndex != -1) {
        _items[existingIndex]['quantity'] += qty;
      } else {
        _items.add({
          'barcode': barcode,
          'quantity': qty,
          'name': _currentProductName.isNotEmpty ? _currentProductName : null,
          'stockInfo': _currentStockInfo.isNotEmpty ? _currentStockInfo : null,
        });
      }
      _lastUsedQuantity = qty.toString();
      _quantityController.clear();
      _quantityController.text = _lastUsedQuantity;
      _lastScannedBarcode = null;
      _currentProductName = '';
      _currentStockInfo = '';
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Hinzugefügt: $barcode × $qty')));
  }

  void _clearAll() {
    setState(() {
      _items.clear();
    });
  }

  String _generateListText() {
    return _items
        .map((item) {
          final name = item['name'] != null ? ' (${item['name']})' : '';
          return '${item['barcode']} ${item['quantity']}$name';
        })
        .join('\n');
  }

  void _copyToClipboard() {
    final text = _generateListText();
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Liste in Zwischenablage kopiert')),
    );
  }

  void _shareList() {
    final text = _generateListText();
    if (text.isEmpty) return;
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode Scanner'),
        actions: [
          IconButton(onPressed: _copyToClipboard, icon: const Icon(Icons.copy)),
          IconButton(onPressed: _shareList, icon: const Icon(Icons.share)),
          IconButton(onPressed: _clearAll, icon: const Icon(Icons.clear_all)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: (BarcodeCapture capture) {
                    final barcode = capture.barcodes.firstOrNull;
                    if (barcode?.rawValue != null) {
                      _handleBarcode(barcode!.rawValue!, barcode.format);
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
            child: Column(
              children: [
                Text(
                  _totalQuantity > 0
                      ? 'Gesamtmenge: $_totalQuantity Artikel'
                      : 'Noch keine Artikel',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _lastScannedBarcode != null
                      ? 'Gescannt: $_lastScannedBarcode'
                      : 'Scanne einen Barcode...',
                  style: const TextStyle(fontSize: 18),
                ),
                if (_isLoadingProduct) ...[
                  const SizedBox(height: 10),
                  const CircularProgressIndicator(),
                ],
                if (_currentProductName.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    _currentProductName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_currentStockInfo.isNotEmpty)
                    Text(
                      _currentStockInfo,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        final current =
                            int.tryParse(_quantityController.text) ?? 0;
                        if (current >= 10)
                          _quantityController.text = '${current - 10}';
                      },
                      icon: const Icon(Icons.remove_circle, size: 36),
                    ),
                    IconButton(
                      onPressed: () {
                        final current =
                            int.tryParse(_quantityController.text) ?? 0;
                        if (current >= 1)
                          _quantityController.text = '${current - 1}';
                      },
                      icon: const Icon(Icons.remove_circle_outline, size: 30),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24),
                        decoration: const InputDecoration(
                          labelText: 'Menge',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        final current =
                            int.tryParse(_quantityController.text) ?? 0;
                        _quantityController.text = '${current + 1}';
                      },
                      icon: const Icon(Icons.add_circle_outline, size: 30),
                    ),
                    IconButton(
                      onPressed: () {
                        final current =
                            int.tryParse(_quantityController.text) ?? 0;
                        _quantityController.text = '${current + 10}';
                      },
                      icon: const Icon(Icons.add_circle, size: 36),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _barCodeManuelEingebenController,
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            _handleBarcode(value.trim(), null);
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Manuell Barcode eingeben',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        color: Colors.black,
                        child: MaterialButton(
                          onPressed: () {
                            _handleBarcode(
                              _barCodeManuelEingebenController.text.trim(),
                              null,
                            );
                          },
                          child: Text(
                            "Suchen",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 111),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.toggleTorch(),
        child: const Icon(Icons.flash_on),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    _quantityController.dispose();
    super.dispose();
  }
}

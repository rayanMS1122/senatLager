import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/stock_item.dart';

const String baseUrl = 'http://192.168.90.50:8086/api/v1/stock/by-ean/';
const String bookUrl = 'http://192.168.90.50:8086/api/v1/stock/book';

class ApiService {
  static Future<Map<String, dynamic>?> fetchProductInfo(String barcode) async {
    try {
      final uri = Uri.parse('$baseUrl$barcode');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      // Fehler werden im Controller behandelt
    }
    return null;
  }

  /// Addiert die Menge zum Lagerbestand (Zugang, mode: 2)
  /// 
  /// [barcode] - Der Barcode/EAN des Produkts
  /// [quantity] - Die Menge die addiert werden soll
  /// 
  /// Gibt true zurück wenn erfolgreich, false bei Fehler
  static Future<bool> addQuantity(String barcode, int quantity) async {
    return _bookStock(barcode, quantity, 2);
  }

  /// Subtrahiert die Menge vom Lagerbestand (Abgang, mode: 1)
  /// 
  /// [barcode] - Der Barcode/EAN des Produkts
  /// [quantity] - Die Menge die subtrahiert werden soll
  /// 
  /// Gibt true zurück wenn erfolgreich, false bei Fehler
  static Future<bool> subtractQuantity(String barcode, int quantity) async {
    return _bookStock(barcode, quantity, 1);
  }

  /// Führt eine Lagerbuchung durch
  /// 
  /// [barcode] - Der Barcode/EAN des Produkts
  /// [quantity] - Die Menge für die Buchung
  /// [mode] - Buchungsmodus: 1=Abgang, 2=Zugang, 3=Inventur
  /// 
  /// Gibt true zurück wenn erfolgreich (Status 201), false bei Fehler
  static Future<bool> _bookStock(String barcode, int quantity, int mode) async {
    try {
      final uri = Uri.parse(bookUrl);
      final body = jsonEncode({
        'code': barcode,
        'menge': quantity,
        'mode': mode,
      });

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

      // Status 201 = Erfolgreich erstellt
      return response.statusCode == 201;
    } catch (e) {
      // Fehler werden im Controller behandelt
      return false;
    }
  }

  /// Addiert die Menge für ein StockItem (Zugang, mode: 2)
  /// 
  /// [item] - Das StockItem für das die Buchung durchgeführt werden soll
  /// 
  /// Gibt true zurück wenn erfolgreich, false bei Fehler
  static Future<bool> addQuantityForItem(StockItem item) async {
    return addQuantity(item.barcode, item.quantity);
  }

  /// Subtrahiert die Menge für ein StockItem (Abgang, mode: 1)
  /// 
  /// [item] - Das StockItem für das die Buchung durchgeführt werden soll
  /// 
  /// Gibt true zurück wenn erfolgreich, false bei Fehler
  static Future<bool> subtractQuantityForItem(StockItem item) async {
    return subtractQuantity(item.barcode, item.quantity);
  }
}

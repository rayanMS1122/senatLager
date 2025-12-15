import 'dart:convert';
import 'package:http/http.dart' as http;

const String baseUrl = 'http://192.168.90.50:8086/api/v1/stock/by-ean/';

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
}

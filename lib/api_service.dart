import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ApiService {
  static late SharedPreferences prefs;
  static String baseUrl = 'http://192.168.90.50:8086';

  static String get moveUrl => '$baseUrl/api/v1/stock/move';
  static String get sessionUrl => '$baseUrl/api/v1/session/personal';
  static String get documentUrl => '$baseUrl/api/v1/session/dokument';

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('server');

    if (saved != null && saved.trim().isNotEmpty) {
      String input = saved.trim();
      input = input.replaceAll(RegExp(r'^https?://'), '');
      input = input.replaceAll(RegExp(r'/$'), '');

      if (input.contains(':')) {
        baseUrl = 'http://$input';
      } else {
        baseUrl = 'http://$input:8086';
      }
    }
    print('Base URL: $baseUrl');
  }

  static Future<void> setServer(String addr) async {
    await prefs.setString('server', addr.trim());
    await init();
  }

  static String? getServer() {
    return prefs.getString('server');
  }

  static Future<bool> loginPersonal(int nr) async {
    try {
      final res = await http
          .post(Uri.parse(sessionUrl),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'personalNr': nr}))
          .timeout(Duration(seconds: 8));

      print('Login Personal → Status: ${res.statusCode} | Body: ${res.body}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await prefs.setInt('perId', data['perId']);
        await prefs.setString('name', data['name'] ?? '');
        return true;
      }
    } catch (e) {
      print('Login Personal Fehler: $e');
    }
    return false;
  }

  static Future<bool> loginDocument(int nr) async {
    try {
      final res = await http
          .post(Uri.parse(documentUrl),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'dokumentNr': nr}))
          .timeout(Duration(seconds: 8));

      print('Login Dokument → Status: ${res.statusCode} | Body: ${res.body}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final id = data['dokId'] as int?;
        if (id != null) {
          await prefs.setInt('dokId', id);
          await prefs.setString('dokName', data['name'] ?? 'Dok $id');
          return true;
        }
      }
    } catch (e) {
      print('Login Dokument Fehler: $e');
    }
    return false;
  }

  static Map<String, dynamic>? getUser() {
    final id = prefs.getInt('perId');
    if (id == null) return null;
    return {'name': prefs.getString('name') ?? 'User'};
  }

  static Map<String, dynamic>? getDoc() {
    final id = prefs.getInt('dokId');
    if (id == null) return null;
    return {'name': prefs.getString('dokName') ?? 'Dok'};
  }

  static Future<void> logout() async => await prefs.clear();

  static Future<Map<String, dynamic>?> getProduct(String barcode) async {
    try {
      final url = '$baseUrl/api/v1/stock/search?code=$barcode';
      print('Suche Produkt: $url');
      final res = await http.get(Uri.parse(url)).timeout(Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print('Produkt gefunden: $data');
        return data;
      } else {
        print(
            'Produkt nicht gefunden → Status: ${res.statusCode} | ${res.body}');
      }
    } catch (e) {
      print('Fehler bei Produktabfrage: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> book(
      String code, int menge, bool add) async {
    final perId = prefs.getInt('perId');
    final dokId = prefs.getInt('dokId');
    if (perId == null || dokId == null) {
      print('Buchung fehlgeschlagen: Kein Login (perId/dokId fehlt)');
      return null;
    }

    final mode = add ? 2 : 1;
    print(
        'Buchung senden → Code: $code | Menge: $menge | Mode: $mode | perId: $perId | dokId: $dokId');

    try {
      final res = await http
          .post(Uri.parse(moveUrl),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'code': code,
                'menge': menge,
                'mode': mode,
                'perid': perId,
                'dokid': dokId,
              }))
          .timeout(Duration(seconds: 8));

      print('Buchung Antwort → Status: ${res.statusCode} | Body: ${res.body}');

      if ((res.statusCode == 200 || res.statusCode == 201)) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'OK') {
          print('Buchung ERFOLGREICH → Neuer Bestand: ${data['bestand']}');
          return data;
        } else {
          print('Buchung FEHLER (status != OK): ${res.body}');
          Get.snackbar('Buchung fehlgeschlagen', data['message'] ?? res.body,
              backgroundColor: Colors.red);
        }
      } else {
        print('Buchung HTTP Fehler → Status: ${res.statusCode}');
        Get.snackbar('Serverfehler', 'Status: ${res.statusCode}',
            backgroundColor: Colors.red);
      }
    } catch (e) {
      print('Buchung Netzwerkfehler: $e');
      Get.snackbar('Verbindung fehlgeschlagen', '$e',
          backgroundColor: Colors.red);
    }
    return null;
  }
}

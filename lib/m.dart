import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';

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
    } else {
      baseUrl = 'http://192.168.90.50:8086';
    }

    print('Base URL gesetzt auf: $baseUrl');
  }

  static Future<void> setServer(String addr) async {
    await prefs.setString('server', addr.trim());
    await init();
  }

  static Future<bool> loginPersonal(int nr) async {
    try {
      final res = await http
          .post(Uri.parse(sessionUrl),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'personalNr': nr}))
          .timeout(Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await prefs.setInt('perId', data['perId']);
        await prefs.setString('name', data['name'] ?? '');
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<bool> loginDocument(int nr) async {
    try {
      final res = await http
          .post(Uri.parse(documentUrl),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'dokumentNr': nr}))
          .timeout(Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final id = data['dokId'] as int?;
        if (id != null) {
          await prefs.setInt('dokId', id);
          await prefs.setString('dokName', data['name'] ?? 'Dok $id');
          return true;
        }
      }
    } catch (_) {}
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

  // NEUE FUNKTION: Korrekter Endpunkt /search?code=
  static Future<Map<String, dynamic>?> getProduct(String barcode) async {
    try {
      final url = '$baseUrl/api/v1/stock/search?code=$barcode';
      print('Lade Produkt von: $url');

      final res = await http.get(Uri.parse(url)).timeout(Duration(seconds: 8));

      print('HTTP Status: ${res.statusCode}');
      print('Raw Response Body: ${res.body}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print('JSON dekodiert: $data');
        return data;
      }
    } on TimeoutException {
      print('Timeout beim Laden von $barcode');
    } catch (e) {
      print('Fehler beim Laden von Produkt $barcode: $e');
    }
    return null;
  }

  static Future<bool> book(String code, int menge, bool add) async {
    final perId = prefs.getInt('perId');
    final dokId = prefs.getInt('dokId');
    if (perId == null || dokId == null) return false;

    try {
      final res = await http
          .post(Uri.parse(moveUrl),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'code': code,
                'menge': menge,
                'mode': add ? 2 : 1,
                'perid': perId,
                'dokid': dokId,
              }))
          .timeout(Duration(seconds: 8));

      final success = res.statusCode >= 200 && res.statusCode < 300;
      print(
          'Buchung $code | Menge: $menge | Mode: ${add ? 2 : 1} → ${success ? "ERFOLG" : "FEHLER"} (Status: ${res.statusCode})');
      return success;
    } catch (e) {
      print('Buchung fehlgeschlagen: $e');
      return false;
    }
  }
}

class ScannerController extends GetxController {
  final MobileScannerController cam = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  var barcode = Rxn<String>();
  var productName = 'Scanne etwas...'.obs;
  var stockInfo = ''.obs;
  var loading = false.obs;

  Future<void> loadProduct(String code) async {
    if (barcode.value == code) return;

    // Führende Nullen entfernen
    String cleanedCode = code.replaceFirst(RegExp(r'^0+'), '');
    if (cleanedCode.isEmpty) cleanedCode = code;

    print('Original Barcode: $code → Bereinigt: $cleanedCode');

    loading.value = true;
    barcode.value = cleanedCode;
    productName.value = 'Lade...';
    stockInfo.value = '';

    final data = await ApiService.getProduct(cleanedCode);

    if (data != null) {
      print('Produkt gefunden! Daten: $data');

      // Produktname: such → bezeichnung → nr
      String name = 'Unbekannt';
      if (data['such'] != null && data['such'].toString().trim().isNotEmpty) {
        name = data['such'].toString().trim();
      } else if (data['bezeichnung'] != null &&
          data['bezeichnung'].toString().trim().isNotEmpty) {
        name = data['bezeichnung'].toString().trim();
      } else if (data['nr'] != null) {
        name = 'Artikel ${data['nr']}';
      }

      productName.value = name;
      print('Produktname: $name');

      // Bestand direkt aus "bestand"
      if (data['bestand'] != null) {
        final bestand = data['bestand'];
        stockInfo.value = 'Bestand: $bestand';
        print('Bestand: $bestand');
      } else {
        stockInfo.value = 'Kein Bestand verfügbar';
        print('Kein "bestand"-Feld im Response');
      }
    } else {
      productName.value = 'Produkt nicht gefunden';
      stockInfo.value = '';
      print('Produkt NICHT gefunden für $cleanedCode');
    }

    loading.value = false;
    HapticFeedback.vibrate();
  }

  Future<void> book(bool add, int qty) async {
    if (barcode.value == null) return;
    final success = await ApiService.book(barcode.value!, qty, add);
    Get.snackbar(
      success ? 'Erfolg' : 'Fehler',
      success
          ? (add ? 'Hinzugefügt (+$qty)' : 'Entnommen (-$qty)')
          : 'Buchung fehlgeschlagen',
      backgroundColor: success ? Colors.green : Colors.red,
      colorText: Colors.white,
    );
  }

  @override
  void onClose() {
    cam.dispose();
    super.onClose();
  }
}

// main(), SettingsPage, LoginPage, ScannerPage bleiben EXAKT gleich wie in deinem Code
// (Ich kopiere sie hier nicht nochmal, um Platz zu sparen – du kannst sie 1:1 übernehmen)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init();
  Get.lazyPut(() => ScannerController());
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  Future<String> startRoute() async {
    final hasServer = ApiService.prefs.getString('server')?.isNotEmpty ?? false;
    if (!hasServer) return '/settings';
    final loggedIn =
        ApiService.getUser() != null && ApiService.getDoc() != null;
    return loggedIn ? '/scanner' : '/login';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: startRoute(),
      builder: (context, snap) {
        if (!snap.hasData)
          return MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())));
        return GetMaterialApp(
          initialRoute: snap.data,
          getPages: [
            GetPage(name: '/settings', page: () => SettingsPage()),
            GetPage(name: '/login', page: () => LoginPage()),
            GetPage(name: '/scanner', page: () => ScannerPage()),
          ],
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

// SettingsPage, LoginPage und ScannerPage genau wie bei dir – unverändert
// (Einfach deinen alten Code dafür kopieren – nur ApiService + ScannerController sind neu)

class SettingsPage extends StatelessWidget {
  final ctrl = TextEditingController(text: '192.168.90.50:8086');
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Server')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(children: [
          TextField(
              controller: ctrl,
              decoration: InputDecoration(labelText: 'Server IP:Port')),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              ApiService.setServer(ctrl.text);
              Get.offAllNamed('/login');
              Get.snackbar('OK', 'Server gespeichert',
                  backgroundColor: Colors.green);
            },
            child: Text('Speichern'),
          ),
        ]),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final perCtrl = TextEditingController();
  final dokCtrl = TextEditingController();
  String? error;

  void login() async {
    final per = int.tryParse(perCtrl.text);
    final dok = int.tryParse(dokCtrl.text);
    if (per == null || dok == null) {
      setState(() => error = 'Nummern eingeben');
      return;
    }
    final pOk = await ApiService.loginPersonal(per);
    if (!pOk) {
      setState(() => error = 'Personal falsch');
      return;
    }
    final dOk = await ApiService.loginDocument(dok);
    if (!dOk) {
      setState(() => error = 'Dokument falsch');
      return;
    }
    Get.offAllNamed('/scanner');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
          padding: EdgeInsets.all(20),
          child: Column(children: [
            TextField(
                controller: perCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Personalnummer')),
            SizedBox(height: 20),
            TextField(
                controller: dokCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Dokumentnummer')),
            if (error != null)
              Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(error!, style: TextStyle(color: Colors.red))),
            SizedBox(height: 30),
            ElevatedButton(onPressed: login, child: Text('Anmelden')),
            TextButton(
                onPressed: () => Get.toNamed('/settings'),
                child: Text('Server ändern')),
          ])),
    );
  }
}

class ScannerPage extends GetView<ScannerController> {
  @override
  Widget build(BuildContext context) {
    final qtyCtrl = TextEditingController(text: '1');

    return Scaffold(
      appBar: AppBar(
          title: Text('Scanner'),
          backgroundColor: Colors.grey[800],
          actions: [
            IconButton(
                icon: Icon(Icons.logout),
                onPressed: () {
                  ApiService.logout();
                  Get.offAllNamed('/login');
                }),
            IconButton(
                icon: Icon(Icons.settings),
                onPressed: () => Get.toNamed('/settings')),
          ]),
      body: Column(children: [
        Expanded(
            flex: 3,
            child: MobileScanner(
              controller: controller.cam,
              onDetect: (cap) {
                final b = cap.barcodes.firstOrNull?.rawValue;
                if (b != null) controller.loadProduct(b);
              },
            )),
        Container(
            color: Colors.black87,
            child: Center(
                child: Container(
                    width: 300,
                    height: 100,
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.red, width: 4))))),
        Expanded(
            flex: 2,
            child: Container(
                color: Colors.grey[300],
                padding: EdgeInsets.all(16),
                child: Obx(() => Column(children: [
                      Text('User: ${ApiService.getUser()?['name'] ?? ''}',
                          style: TextStyle(fontSize: 16)),
                      Text('Dok: ${ApiService.getDoc()?['name'] ?? ''}',
                          style: TextStyle(fontSize: 16)),
                      SizedBox(height: 20),
                      Text(controller.barcode.value ?? 'Kein Scan',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      if (controller.loading.value) CircularProgressIndicator(),
                      Text(controller.productName.value,
                          style: TextStyle(fontSize: 20)),
                      if (controller.stockInfo.value.isNotEmpty)
                        Text(controller.stockInfo.value,
                            style: TextStyle(color: Colors.blue)),
                      SizedBox(height: 20),
                      Row(children: [
                        IconButton(
                            onPressed: () => qtyCtrl.text =
                                '${(int.tryParse(qtyCtrl.text) ?? 1) + 1}',
                            icon: Icon(Icons.add, size: 40)),
                        Expanded(
                            child: TextField(
                                controller: qtyCtrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Menge'))),
                        IconButton(
                            onPressed: () {
                              final q = int.tryParse(qtyCtrl.text) ?? 1;
                              if (q > 1) qtyCtrl.text = '${q - 1}';
                            },
                            icon: Icon(Icons.remove, size: 40)),
                      ]),
                      SizedBox(height: 20),
                      Row(children: [
                        Expanded(
                            child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[800]),
                          onPressed: controller.barcode.value == null
                              ? null
                              : () {
                                  final qty = int.tryParse(qtyCtrl.text) ?? 1;
                                  controller.book(true, qty);
                                  qtyCtrl.text = '1';
                                },
                          child: Text('HINZUFÜGEN',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18)),
                        )),
                        SizedBox(width: 10),
                        Expanded(
                            child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[800]),
                          onPressed: controller.barcode.value == null
                              ? null
                              : () {
                                  final qty = int.tryParse(qtyCtrl.text) ?? 1;
                                  controller.book(false, qty);
                                  qtyCtrl.text = '1';
                                },
                          child: Text('ENTNEHMEN',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18)),
                        )),
                      ]),
                    ])))),
      ]),
      floatingActionButton: FloatingActionButton(
          onPressed: () => controller.cam.toggleTorch(),
          child: Icon(Icons.flash_on)),
    );
  }
}

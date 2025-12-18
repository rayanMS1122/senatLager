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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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
    return ScreenUtilInit(
      designSize: Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return FutureBuilder<String>(
          future: startRoute(),
          builder: (context, snap) {
            if (!snap.hasData)
              return MaterialApp(
                  home: Scaffold(
                      body: Center(child: CircularProgressIndicator())));
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
      },
    );
  }
}

class SettingsPage extends StatelessWidget {
  final ctrl = TextEditingController(text: '192.168.90.50:8086');
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Server einrichten', style: TextStyle(fontSize: 18.sp)),
      ),
      body: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(children: [
            SizedBox(height: 20.h),
            TextField(
                controller: ctrl,
                style: TextStyle(fontSize: 16.sp),
                decoration: InputDecoration(
                  labelText: 'Server IP:Port',
                  labelStyle: TextStyle(fontSize: 14.sp),
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                )),
            SizedBox(height: 30.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  onPressed: () {
                    ApiService.setServer(ctrl.text);
                    Get.offAllNamed('/login');
                    Get.snackbar('Gespeichert', 'Server konfiguriert',
                        backgroundColor: Colors.green);
                  },
                  child: Text('Speichern',
                      style: TextStyle(fontSize: 16.sp, color: Colors.white))),
            ),
          ])),
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
      setState(() => error = 'Beide Nummern eingeben');
      return;
    }
    final pOk = await ApiService.loginPersonal(per);
    if (!pOk) {
      setState(() => error = 'Personalnummer ungültig');
      return;
    }
    final dOk = await ApiService.loginDocument(dok);
    if (!dOk) {
      setState(() => error = 'Dokumentnummer ungültig');
      return;
    }
    Get.offAllNamed('/scanner');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Anmeldung', style: TextStyle(fontSize: 18.sp)),
      ),
      body: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(children: [
            SizedBox(height: 20.h),
            TextField(
                controller: perCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 16.sp),
                decoration: InputDecoration(
                  labelText: 'Personalnummer',
                  labelStyle: TextStyle(fontSize: 14.sp),
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                )),
            SizedBox(height: 20.h),
            TextField(
                controller: dokCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 16.sp),
                decoration: InputDecoration(
                  labelText: 'Dokumentnummer',
                  labelStyle: TextStyle(fontSize: 14.sp),
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                )),
            if (error != null)
              Padding(
                  padding: EdgeInsets.only(top: 12.h),
                  child: Text(error!,
                      style: TextStyle(color: Colors.red, fontSize: 14.sp))),
            SizedBox(height: 30.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  onPressed: login,
                  child: Text('Anmelden',
                      style: TextStyle(fontSize: 16.sp, color: Colors.white))),
            ),
            SizedBox(height: 12.h),
            TextButton(
                onPressed: () => Get.toNamed('/settings'),
                child:
                    Text('Server ändern', style: TextStyle(fontSize: 14.sp))),
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
          title: Text('Lager Scanner', style: TextStyle(fontSize: 18.sp)),
          actions: [
            IconButton(
                icon: Icon(Icons.logout, size: 24.sp),
                onPressed: () {
                  ApiService.logout();
                  Get.offAllNamed('/login');
                }),
            IconButton(
                icon: Icon(Icons.settings, size: 24.sp),
                onPressed: () => Get.toNamed('/settings')),
          ]),
      body: Column(children: [
        // Kamera Bereich
        Container(
          height: 280.h,
          child: Stack(
            children: [
              MobileScanner(
                controller: controller.cam,
                onDetect: (capture) async {
                  // Nur scannen, wenn aktiv
                  if (!controller.isScanning.value) return;

                  final b = capture.barcodes.firstOrNull?.rawValue;
                  if (b != null && b.isNotEmpty) {
                    await controller.loadProduct(b);
                  }
                },
              ),

              // Overlay wenn pausiert
              Obx(() => controller.isScanning.value
                  ? SizedBox.shrink()
                  : Container(
                      color: Colors.black.withOpacity(0.7),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.pause_circle_filled,
                                color: Colors.white, size: 60.sp),
                            SizedBox(height: 16.h),
                            Text(
                              'Kamera pausiert',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 20.sp),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Tippe unten auf\n"NEUEN ARTIKEL SCANNEN"',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 16.sp),
                            ),
                          ],
                        ),
                      ),
                    )),

              // Scan-Rahmen (immer sichtbar)
              Center(
                child: Container(
                  width: 280.w,
                  height: 100.h,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red, width: 3.w),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Info Bereich
        Expanded(
          child: Container(
              color: Colors.grey[100],
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: SingleChildScrollView(
                  child: Obx(
                () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('User: ${ApiService.getUser()?['name'] ?? '-'}',
                              style: TextStyle(
                                  fontSize: 14.sp, color: Colors.grey[700])),
                          Text('Dok: ${ApiService.getDoc()?['name'] ?? '-'}',
                              style: TextStyle(
                                  fontSize: 14.sp, color: Colors.grey[700])),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      GestureDetector(
                        onTap: () => _showManualInput(context),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 10.h),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            border: Border.all(color: Colors.blue[300]!),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.qr_code,
                                  color: Colors.blue[700], size: 20.sp),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  controller.barcode.value ??
                                      'Kein Artikel (Tippen für Eingabe)',
                                  style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      controller.loading.value
                          ? Center(child: CircularProgressIndicator())
                          : Text(controller.productName.value,
                              style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800])),
                      SizedBox(height: 10.h),
                      if (controller.stockInfo.value.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(controller.stockInfo.value,
                              style: TextStyle(
                                  color: Colors.green[800],
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold)),
                        ),
                      SizedBox(height: 24.h),
                      Row(children: [
                        IconButton(
                            onPressed: () {
                              final q = int.tryParse(qtyCtrl.text) ?? 1;
                              if (q > 1) qtyCtrl.text = '${q - 1}';
                            },
                            icon: Icon(Icons.remove_circle,
                                size: 36.sp, color: Colors.red[600])),
                        Expanded(
                            child: TextField(
                                controller: qtyCtrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Menge',
                                    labelStyle: TextStyle(fontSize: 14.sp),
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 12.h)))),
                        IconButton(
                            onPressed: () => qtyCtrl.text =
                                '${(int.tryParse(qtyCtrl.text) ?? 1) + 1}',
                            icon: Icon(Icons.add_circle,
                                size: 36.sp, color: Colors.green[600])),
                      ]),
                      SizedBox(height: 20.h),
                      Row(children: [
                        Expanded(
                            child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              )),
                          onPressed: controller.barcode.value == null
                              ? null
                              : () async {
                                  final qty = int.tryParse(qtyCtrl.text) ?? 1;
                                  await controller.book(true, qty);
                                  qtyCtrl.text = '1';
                                },
                          child: Text('HINZUFÜGEN',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 15.sp)),
                        )),
                        SizedBox(width: 12.w),
                        Expanded(
                            child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[700],
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              )),
                          onPressed: controller.barcode.value == null
                              ? null
                              : () async {
                                  final qty = int.tryParse(qtyCtrl.text) ?? 1;
                                  await controller.book(false, qty);
                                  qtyCtrl.text = '1';
                                },
                          child: Text('ENTNEHMEN',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 15.sp)),
                        )),
                      ]),
                      SizedBox(height: 16.h),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[700],
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              )),
                          icon: Icon(Icons.qr_code_scanner, size: 24.sp),
                          label: Text('NEUEN ARTIKEL SCANNEN',
                              style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold)),
                          onPressed: controller.newScan,
                        ),
                      ),
                    ]),
              ))),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.amber[700],
          onPressed: () => controller.cam.toggleTorch(),
          child: Icon(Icons.flash_on, size: 28.sp)),
    );
  }

  void _showManualInput(BuildContext context) {
    final ctrl = TextEditingController();
    final scanCtrl = Get.find<ScannerController>();

    Get.dialog(
      AlertDialog(
        title:
            Text('Barcode manuell eingeben', style: TextStyle(fontSize: 18.sp)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Barcode',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                scanCtrl.loadProduct(ctrl.text.trim());
                Get.back();
              }
            },
            child: Text('Laden'),
          ),
        ],
      ),
    );
  }
}

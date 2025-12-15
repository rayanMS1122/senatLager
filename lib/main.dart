import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/routes.dart';
import 'app/bindings/scanner_binding.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Barcode Scanner App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: Routes.scanner,
      initialBinding: ScannerBinding(),
      getPages: AppRoutes.pages,
    );
  }
}

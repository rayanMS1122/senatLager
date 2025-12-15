import 'package:get/get.dart';
import '../views/scanner_page.dart';
import '../app/bindings/scanner_binding.dart';

class Routes {
  static const scanner = '/scanner';
}

class AppRoutes {
  static final pages = [
    GetPage(
      name: Routes.scanner,
      page: () => const ScannerPage(),
      binding: ScannerBinding(),
    ),
  ];
}

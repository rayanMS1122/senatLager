import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/scanner_controller.dart';

class QuantityInputRow extends StatelessWidget {
  final TextEditingController controller;
  ScannerController ctrl = Get.find();
  QuantityInputRow({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            final current = int.tryParse(controller.text) ?? 0;
            if (current >= 10) controller.text = '${current - 10}';
          },
          icon: const Icon(Icons.remove_circle, size: 36),
        ),
        IconButton(
          onPressed: () {
            final current = int.tryParse(controller.text) ?? 0;
            if (current >= 1) controller.text = '${current - 1}';
          },
          icon: const Icon(Icons.remove_circle_outline, size: 30),
        ),
        Expanded(
          child: TextField(
            controller: controller,
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
            final current = int.tryParse(controller.text) ?? 0;
            controller.text = '${current + 1}';
          },
          icon: const Icon(Icons.add_circle_outline, size: 30),
        ),
        IconButton(
          onPressed: () {
            final current = int.tryParse(controller.text) ?? 0;
            controller.text = '${current + 10}';
          },
          icon: const Icon(Icons.add_circle, size: 36),
        ),
      ],
    );
  }
}

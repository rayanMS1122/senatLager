class StockItem {
  final String barcode;
  int quantity;
  final String? name;
  final String? stockInfo;

  StockItem({
    required this.barcode,
    required this.quantity,
    this.name,
    this.stockInfo,
  });

  StockItem copyWith({int? quantity}) {
    return StockItem(
      barcode: barcode,
      quantity: quantity ?? this.quantity,
      name: name,
      stockInfo: stockInfo,
    );
  }
}

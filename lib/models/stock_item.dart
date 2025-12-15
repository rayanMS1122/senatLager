class StockItem {
  final String barcode;
  final int quantity;
  final String? name;
  final String? stockInfo;

  StockItem({
    required this.barcode,
    required this.quantity,
    this.name,
    this.stockInfo,
  }) : assert(quantity > 0, 'Quantity must be greater than 0'),
       assert(barcode.isNotEmpty, 'Barcode cannot be empty');

  StockItem copyWith({
    String? barcode,
    int? quantity,
    String? name,
    String? stockInfo,
  }) {
    return StockItem(
      barcode: barcode ?? this.barcode,
      quantity: quantity ?? this.quantity,
      name: name ?? this.name,
      stockInfo: stockInfo ?? this.stockInfo,
    );
  }

  // Equals und HashCode für korrekten Vergleich
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StockItem &&
        other.barcode == barcode &&
        other.quantity == quantity &&
        other.name == name &&
        other.stockInfo == stockInfo;
  }

  @override
  int get hashCode {
    return Object.hash(barcode, quantity, name, stockInfo);
  }

  @override
  String toString() {
    return 'StockItem(barcode: $barcode, quantity: $quantity, name: $name, stockInfo: $stockInfo)';
  }

  // JSON Serialisierung (optional, falls benötigt)
  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'quantity': quantity,
      'name': name,
      'stockInfo': stockInfo,
    };
  }

  factory StockItem.fromJson(Map<String, dynamic> json) {
    return StockItem(
      barcode: json['barcode'] as String,
      quantity: json['quantity'] as int,
      name: json['name'] as String?,
      stockInfo: json['stockInfo'] as String?,
    );
  }
}

class InventoryItem {
  String id;
  String name;
  String category; // e.g., "Feed", "Equipment", "Supplies"
  int quantity;
  String unit; // e.g., "kg", "pcs", "liters"

  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    this.quantity = 0,
    this.unit = 'pcs',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'quantity': quantity,
        'unit': unit,
      };

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        id: json['id'],
        name: json['name'],
        category: json['category'],
        quantity: json['quantity'],
        unit: json['unit'],
      );
}

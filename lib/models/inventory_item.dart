import 'package:flutter/material.dart';

class InventoryItem {
  final String id;
  final String name;
  final String category;
  final int quantity;
  final String rfidTag;
  final DateTime lastUpdated;
  final int minStockLevel;
  final int maxStockLevel;

  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.rfidTag,
    required this.lastUpdated,
    required this.minStockLevel,
    required this.maxStockLevel,
  });

  bool get isLowStock => quantity <= minStockLevel;
  bool get isOutOfStock => quantity == 0;
  double get stockPercentage => quantity / maxStockLevel;

  factory InventoryItem.fromJson(Map<String, dynamic> json, String id) {
    return InventoryItem(
      id: id,
      name: json['name'] ?? 'Unknown Item',
      category: json['category'] ?? 'Uncategorized',
      quantity: json['quantity']?.toInt() ?? 0,
      rfidTag: json['rfidTag'] ?? '',
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
        (json['lastUpdated'] ?? 0) * 1000,
      ),
      minStockLevel: json['minStockLevel']?.toInt() ?? 0,
      maxStockLevel: json['maxStockLevel']?.toInt() ?? 100,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'quantity': quantity,
      'rfidTag': rfidTag,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch ~/ 1000,
      'minStockLevel': minStockLevel,
      'maxStockLevel': maxStockLevel,
    };
  }
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  // ✅ Start with default data (Dell XPS)
  final List<InventoryItem> _items = [
    InventoryItem(
      id: "1",
      name: "Laptop Dell XPS",
      category: "Electronics",
      quantity: 15,
      rfidTag: "RFID_001",
      lastUpdated: DateTime.now(),
      minStockLevel: 5,
      maxStockLevel: 50,
    ),
  ];

  void _addItem() {
    final newItem = InventoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: "Sample Item",
      category: "Accessories",
      quantity: 8,
      rfidTag: "RFID_002",
      lastUpdated: DateTime.now(),
      minStockLevel: 3,
      maxStockLevel: 20,
    );

    setState(() {
      _items.add(newItem); // ✅ Add to the same list used in UI
      print("Items count: ${_items.length}");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventory Management"),
      ),
      body: _items.isEmpty
          ? const Center(child: Text("No items yet"))
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: const Icon(Icons.devices_other),
                    title: Text(item.name),
                    subtitle: Text(
                      "Category: ${item.category} | RFID: ${item.rfidTag}\n"
                      "Stock: ${item.quantity}/${item.maxStockLevel}",
                    ),
                    trailing: item.isOutOfStock
                        ? const Icon(Icons.warning, color: Colors.red)
                        : item.isLowStock
                            ? const Icon(Icons.error, color: Colors.orange)
                            : const Icon(Icons.check_circle,
                                color: Colors.green),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItem,
        label: const Text("Add Item"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: InventoryScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

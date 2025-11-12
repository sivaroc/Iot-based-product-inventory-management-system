import 'package:flutter/material.dart';
import '../models/inventory_item.dart';

class InventoryChart extends StatelessWidget {
  final List<InventoryItem> inventoryItems;

  const InventoryChart({super.key, required this.inventoryItems});

  @override
  Widget build(BuildContext context) {
    final categoryData = _getCategoryData();

    // Handle empty data case
    if (categoryData.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Inventory by Category',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: SizedBox(
                height: 100,
                child: ListView.builder(
                  itemCount: categoryData.length,
                  itemBuilder: (context, index) {
                    final item = categoryData[index];
                    return _buildCategoryRow(item['category'] as String, item['count'] as int);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow(String category, int count) {
    final totalItems = inventoryItems.length;
    final percentage = totalItems > 0 ? (count / totalItems) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              Text(
                '$count (${(percentage * 100).toStringAsFixed(0)}%)',
                style: const TextStyle(fontSize: 8),
              ),
            ],
          ),
          const SizedBox(height: 2),
          LinearProgressIndicator(
            value: percentage.toDouble(),
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(_getCategoryColor(category)),
            minHeight: 3,
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red];
    final index = category.hashCode % colors.length;
    return colors[index];
  }

  List<Map<String, dynamic>> _getCategoryData() {
    final Map<String, int> categoryCount = {};

    for (var item in inventoryItems) {
      categoryCount[item.category] = (categoryCount[item.category] ?? 0) + 1;
    }

    return categoryCount.entries
        .map((entry) => {'category': entry.key, 'count': entry.value})
        .toList();
  }
}

class StockLevelChart extends StatelessWidget {
  final List<InventoryItem> inventoryItems;

  const StockLevelChart({super.key, required this.inventoryItems});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Stock Levels',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 250, // Reduced height to prevent overflow
              child: ListView.builder(
                itemCount: inventoryItems.length,
                itemBuilder: (context, index) {
                  final item = inventoryItems[index];
                  return _buildStockItem(item);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockItem(InventoryItem item) {
    final maxValue = item.maxStockLevel.toDouble();
    final currentPercentage = item.quantity / maxValue;
    final minPercentage = item.minStockLevel / maxValue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Stack(
            children: [
              // Background track
              Container(
                height: 20,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // Current stock level
              LayoutBuilder(
                builder: (context, constraints) {
                  final barWidth = constraints.maxWidth * currentPercentage;
                  return Container(
                    height: 20,
                    width: barWidth,
                    decoration: BoxDecoration(
                      color: item.isLowStock ? Colors.red : Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
              // Minimum stock indicator
              LayoutBuilder(
                builder: (context, constraints) {
                  final indicatorPosition = constraints.maxWidth * minPercentage;
                  return Positioned(
                    left: indicatorPosition - 2,
                    child: Container(
                      width: 4,
                      height: 24,
                      color: Colors.orange,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Min: ${item.minStockLevel}', style: const TextStyle(fontSize: 10)),
              Text('Max: ${item.maxStockLevel}', style: const TextStyle(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

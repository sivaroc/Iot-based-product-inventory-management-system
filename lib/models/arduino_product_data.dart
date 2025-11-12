import 'package:flutter/material.dart';

class ArduinoProductData {
  final String productId; // This will be the node key (e.g., "341B3402")
  final String rfidTag; // The rfid_tag field from Firebase
  final int productCount; // product_count from Firebase
  final double weight; // weight from Firebase
  final DateTime timestamp; // timestamp from Firebase

  ArduinoProductData({
    required this.productId,
    required this.rfidTag,
    required this.productCount,
    required this.weight,
    required this.timestamp,
  });

  // Parse from Firebase structure: { product_count, rfid_tag, timestamp, weight }
  factory ArduinoProductData.fromJson(Map<String, dynamic> json, String id) {
    return ArduinoProductData(
      productId: id, // Use the node key as product ID
      rfidTag: json['rfid_tag']?.toString() ?? '',
      productCount: (json['product_count'] is int) 
          ? json['product_count'] 
          : int.tryParse(json['product_count']?.toString() ?? '0') ?? 0,
      weight: (json['weight'] is num) 
          ? json['weight'].toDouble() 
          : double.tryParse(json['weight']?.toString() ?? '0') ?? 0.0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        ((json['timestamp'] is int) 
            ? json['timestamp'] 
            : int.tryParse(json['timestamp']?.toString() ?? '0') ?? 0) * 1000,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rfid_tag': rfidTag,
      'product_count': productCount,
      'weight': weight,
      'timestamp': timestamp.millisecondsSinceEpoch ~/ 1000,
    };
  }

  // Stock status based on product_count
  bool get isLowStock => productCount <= 2;
  bool get isOutOfStock => productCount == 0;
  bool get hasWeight => weight > 0;

  // Display helpers
  String get weightDisplay => '${weight.toStringAsFixed(2)}g';
  String get stockDisplay => '$productCount units';
  String get productName => 'RFID: $rfidTag'; // Display name based on RFID tag

  Color get stockStatusColor {
    if (isOutOfStock) return Colors.red;
    if (isLowStock) return Colors.orange;
    return Colors.green;
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}

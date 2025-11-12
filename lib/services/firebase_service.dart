// File: lib/services/firebase_service.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:firebase_database/firebase_database.dart';
import '../models/arduino_product_data.dart';
import '../models/inventory_item.dart';

class FirebaseService {
  static FirebaseOptions get config {
    return const FirebaseOptions(
      apiKey: "AIzaSyCfA5mCy9F8rrsOdxvKROGRNBoM-5x3YAQ",
      appId: "1:597109012761:web:ecdf9eb92b660d14536d88",
      messagingSenderId: "597109012761",
      projectId: "arduino-148de",
      authDomain: "arduino-148de.firebaseapp.com",
      databaseURL: "https://arduino-148de-default-rtdb.asia-southeast1.firebasedatabase.app",
      storageBucket: "arduino-148de.firebasestorage.app",
    );
  }

  static DatabaseReference get _database {
    return FirebaseDatabase.instance.ref();
  }

  // Get reference to root database (RFID tags are at root level)
  static DatabaseReference get _productsRef {
    return _database; // Read from root where RFID tags like "341B3402" are stored
  }

  // Stream of Arduino product data (reads from root level)
  static Stream<List<ArduinoProductData>> getArduinoProductStream() {
    return _productsRef.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) return [];

      List<ArduinoProductData> products = [];

      data.forEach((key, value) {
        // Skip non-RFID nodes (like 'inventory', 'inventory_history', etc.)
        if (value != null && value is Map<dynamic, dynamic>) {
          // Check if this node has the expected RFID structure
          if (value.containsKey('rfid_tag') && 
              value.containsKey('product_count') && 
              value.containsKey('timestamp') && 
              value.containsKey('weight')) {
            try {
              final product = ArduinoProductData.fromJson(
                Map<String, dynamic>.from(value),
                key.toString(),
              );
              products.add(product);
            } catch (e) {
              print('Error parsing product data for key $key: $e');
            }
          }
        }
      });

      // Sort by timestamp (most recent first)
      products.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return products;
    });
  }

  // Get single product data
  static Future<ArduinoProductData?> getProductData(String productId) async {
    try {
      final snapshot = await _productsRef.child(productId).get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return ArduinoProductData.fromJson(data, productId);
      }

      return null;
    } catch (e) {
      print('Error getting product data: $e');
      return null;
    }
  }

  // Update product data
  static Future<bool> updateProductData(String productId, ArduinoProductData product) async {
    try {
      await _productsRef.child(productId).set(product.toJson());
      return true;
    } catch (e) {
      print('Error updating product data: $e');
      return false;
    }
  }

  // Delete product data
  static Future<bool> deleteProductData(String productId) async {
    try {
      await _productsRef.child(productId).remove();
      return true;
    } catch (e) {
      print('Error deleting product data: $e');
      return false;
    }
  }

  // Get all product IDs
  static Future<List<String>> getProductIds() async {
    try {
      final snapshot = await _productsRef.get();

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return data.keys.map((key) => key.toString()).toList();
      }

      return [];
    } catch (e) {
      print('Error getting product IDs: $e');
      return [];
    }
  }

  // Get reference to inventory node
  static DatabaseReference get _inventoryRef {
    return _database.child('inventory');
  }

  // Stream of inventory items
  static Stream<List<InventoryItem>> getInventoryStream() {
    return _inventoryRef.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) return [];

      List<InventoryItem> inventory = [];

      data.forEach((key, value) {
        if (value != null && value is Map<dynamic, dynamic>) {
          try {
            final item = InventoryItem.fromJson(
              Map<String, dynamic>.from(value),
              key.toString(),
            );
            inventory.add(item);
          } catch (e) {
            print('Error parsing inventory data: $e');
          }
        }
      });

      // Sort by last updated (most recent first)
      inventory.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

      return inventory;
    });
  }

  // Get single inventory item
  static Future<InventoryItem?> getInventoryItem(String itemId) async {
    try {
      final snapshot = await _inventoryRef.child(itemId).get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return InventoryItem.fromJson(data, itemId);
      }

      return null;
    } catch (e) {
      print('Error getting inventory item: $e');
      return null;
    }
  }

  // Add new inventory item
  static Future<bool> addInventoryItem(InventoryItem item) async {
    try {
      await _inventoryRef.child(item.id).set(item.toJson());
      return true;
    } catch (e) {
      print('Error adding inventory item: $e');
      return false;
    }
  }

  // Update inventory item
  static Future<bool> updateInventoryItem(InventoryItem item) async {
    try {
      await _inventoryRef.child(item.id).update(item.toJson());
      return true;
    } catch (e) {
      print('Error updating inventory item: $e');
      return false;
    }
  }

  // Delete inventory item
  static Future<bool> deleteInventoryItem(String itemId) async {
    try {
      await _inventoryRef.child(itemId).remove();
      return true;
    } catch (e) {
      print('Error deleting inventory item: $e');
      return false;
    }
  }

  // Update item quantity (useful for Arduino integration)
  static Future<bool> updateItemQuantity(String itemId, int newQuantity) async {
    try {
      await _inventoryRef.child(itemId).update({
        'quantity': newQuantity,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      });
      return true;
    } catch (e) {
      print('Error updating item quantity: $e');
      return false;
    }
  }

  // Stream of inventory dashboard data (aggregated from all inventory items)
  static Stream<Map<String, dynamic>?> getInventoryDashboardStream() {
    return _inventoryRef.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null || data.isEmpty) {
        return {
          'product_count': 0,
          'rfid_tag': 'None',
          'timestamp': 'No data',
          'weight': 0.0
        };
      }

      // Aggregate data from all inventory items
      int totalCount = 0;
      double totalWeight = 0.0;
      String latestRfid = 'None';
      dynamic latestTimestamp = 'No data';
      int maxTimestamp = 0;

      data.forEach((key, value) {
        if (value != null && value is Map) {
          // Sum up product counts
          final count = value['product_count'] ?? value['quantity'] ?? 0;
          totalCount += (count is int ? count : int.tryParse(count.toString()) ?? 0);
          
          // Sum up weights
          final weight = value['weight'] ?? 0.0;
          totalWeight += (weight is double ? weight : double.tryParse(weight.toString()) ?? 0.0);
          
          // Track the most recent item
          final timestamp = value['timestamp'] ?? 0;
          final timestampInt = timestamp is int ? timestamp : int.tryParse(timestamp.toString()) ?? 0;
          if (timestampInt > maxTimestamp) {
            maxTimestamp = timestampInt;
            latestRfid = value['rfid_tag'] ?? value['rfid'] ?? key.toString();
            latestTimestamp = timestamp;
          }
        }
      });

      // Return the aggregated data
      return {
        'product_count': totalCount,
        'rfid_tag': latestRfid,
        'timestamp': latestTimestamp,
        'weight': totalWeight
      };
    });
  }

  // Get current inventory dashboard data (aggregated)
  static Future<Map<String, dynamic>?> getCurrentInventoryData() async {
    try {
      final snapshot = await _inventoryRef.get();

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        
        // Aggregate data from all inventory items
        int totalCount = 0;
        double totalWeight = 0.0;
        String latestRfid = 'None';
        dynamic latestTimestamp = 'No data';
        int maxTimestamp = 0;

        data.forEach((key, value) {
          if (value != null && value is Map) {
            final count = value['product_count'] ?? value['quantity'] ?? 0;
            totalCount += (count is int ? count : int.tryParse(count.toString()) ?? 0);
            
            final weight = value['weight'] ?? 0.0;
            totalWeight += (weight is double ? weight : double.tryParse(weight.toString()) ?? 0.0);
            
            final timestamp = value['timestamp'] ?? 0;
            final timestampInt = timestamp is int ? timestamp : int.tryParse(timestamp.toString()) ?? 0;
            if (timestampInt > maxTimestamp) {
              maxTimestamp = timestampInt;
              latestRfid = value['rfid_tag'] ?? value['rfid'] ?? key.toString();
              latestTimestamp = timestamp;
            }
          }
        });
        
        return {
          'product_count': totalCount,
          'rfid_tag': latestRfid,
          'timestamp': latestTimestamp,
          'weight': totalWeight
        };
      }

      return {
        'product_count': 0,
        'rfid_tag': 'None',
        'timestamp': 'No data',
        'weight': 0.0
      };
    } catch (e) {
      print('Error getting inventory data: $e');
      return null;
    }
  }

  // Set sample inventory dashboard data (for testing)
  static Future<bool> setSampleInventoryData() async {
    try {
      await _inventoryRef.set({
        'product_count': 0,
        'rfid_tag': 'None',
        'timestamp': 164140,
        'weight': -53048.23
      });
      return true;
    } catch (e) {
      print('Error setting sample inventory data: $e');
      return false;
    }
  }

  // Update inventory dashboard data
  static Future<bool> updateInventoryDashboardData({
    int? productCount,
    String? rfidTag,
    int? timestamp,
    double? weight,
  }) async {
    try {
      Map<String, dynamic> updates = {};
      if (productCount != null) updates['product_count'] = productCount;
      if (rfidTag != null) updates['rfid_tag'] = rfidTag;
      if (timestamp != null) updates['timestamp'] = timestamp;
      if (weight != null) updates['weight'] = weight;

      if (updates.isNotEmpty) {
        await _inventoryRef.update(updates);
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating inventory dashboard data: $e');
      return false;
    }
  }

  // Get reference to inventory history node
  static DatabaseReference get _inventoryHistoryRef {
    return _database.child('inventory_history');
  }

  // Add inventory history record
  static Future<bool> addInventoryHistoryRecord({
    required int productCount,
    required String rfidTag,
    required double weight,
    required int timestamp,
    String? action, // 'added' or 'removed'
  }) async {
    try {
      final historyRef = _inventoryHistoryRef.push();
      await historyRef.set({
        'product_count': productCount,
        'rfid_tag': rfidTag,
        'weight': weight,
        'timestamp': timestamp,
        'recorded_at': DateTime.now().millisecondsSinceEpoch,
        'action': action ?? 'updated',
      });
      return true;
    } catch (e) {
      print('Error adding inventory history record: $e');
      return false;
    }
  }

  // Stream of inventory history (last 50 records)
  static Stream<List<Map<String, dynamic>>> getInventoryHistoryStream() {
    return _inventoryHistoryRef
        .orderByChild('recorded_at')
        .limitToLast(50)
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) return [];

      List<Map<String, dynamic>> history = [];

      data.forEach((key, value) {
        if (value != null && value is Map<dynamic, dynamic>) {
          try {
            final record = Map<String, dynamic>.from(value);
            record['id'] = key.toString();
            history.add(record);
          } catch (e) {
            print('Error parsing history record: $e');
          }
        }
      });

      // Sort by recorded_at (most recent first)
      history.sort((a, b) {
        final aTime = a['recorded_at'] ?? 0;
        final bTime = b['recorded_at'] ?? 0;
        return bTime.compareTo(aTime);
      });

      return history;
    });
  }

  // Get inventory history (last N records)
  static Future<List<Map<String, dynamic>>> getInventoryHistory({int limit = 50}) async {
    try {
      final snapshot = await _inventoryHistoryRef
          .orderByChild('recorded_at')
          .limitToLast(limit)
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        List<Map<String, dynamic>> history = [];

        data.forEach((key, value) {
          if (value != null && value is Map<dynamic, dynamic>) {
            final record = Map<String, dynamic>.from(value);
            record['id'] = key.toString();
            history.add(record);
          }
        });

        // Sort by recorded_at (most recent first)
        history.sort((a, b) {
          final aTime = a['recorded_at'] ?? 0;
          final bTime = b['recorded_at'] ?? 0;
          return bTime.compareTo(aTime);
        });

        return history;
      }

      return [];
    } catch (e) {
      print('Error getting inventory history: $e');
      return [];
    }
  }

  // Clear old history records (keep last N records)
  static Future<bool> clearOldHistory({int keepLast = 100}) async {
    try {
      final snapshot = await _inventoryHistoryRef
          .orderByChild('recorded_at')
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final records = data.entries.toList();

        // Sort by recorded_at
        records.sort((a, b) {
          final aTime = (a.value as Map)['recorded_at'] ?? 0;
          final bTime = (b.value as Map)['recorded_at'] ?? 0;
          return bTime.compareTo(aTime);
        });

        // Delete old records
        if (records.length > keepLast) {
          for (int i = keepLast; i < records.length; i++) {
            await _inventoryHistoryRef.child(records[i].key.toString()).remove();
          }
        }
      }

      return true;
    } catch (e) {
      print('Error clearing old history: $e');
      return false;
    }
  }

  // Initialize Firebase Database (call this in main.dart)
  static Future<void> initialize() async {
    try {
      // Firebase is already initialized in main.dart via Firebase.initializeApp()
      // Persistence is not supported on web, so we skip it
      print('✅ Firebase Database ready');
    } catch (e) {
      print('Error initializing Firebase Database: $e');
    }
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import 'firebase_service.dart';

class InventoryService extends ChangeNotifier {
  static final InventoryService _instance = InventoryService._internal();
  factory InventoryService() => _instance;
  InventoryService._internal();

  List<InventoryItem> _inventory = [];
  StreamSubscription<List<InventoryItem>>? _subscription;
  bool _isConnected = false;

  List<InventoryItem> get inventory => List.unmodifiable(_inventory);
  bool get isConnected => _isConnected;

  // Get inventory items filtered by stock status
  List<InventoryItem> get lowStockItems =>
      _inventory.where((item) => item.isLowStock).toList();

  List<InventoryItem> get outOfStockItems =>
      _inventory.where((item) => item.isOutOfStock).toList();

  List<InventoryItem> get normalStockItems =>
      _inventory.where((item) => !item.isLowStock && !item.isOutOfStock).toList();

  // Get inventory item by ID
  InventoryItem? getInventoryItemById(String itemId) {
    try {
      return _inventory.firstWhere((item) => item.id == itemId);
    } catch (e) {
      return null;
    }
  }

  // Get inventory item by RFID tag
  InventoryItem? getInventoryItemByRFID(String rfidTag) {
    try {
      return _inventory.firstWhere((item) => item.rfidTag == rfidTag);
    } catch (e) {
      return null;
    }
  }

  // Get recent inventory items (last 10)
  List<InventoryItem> get recentItems {
    final sorted = List<InventoryItem>.from(_inventory)
      ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
    return sorted.take(10).toList();
  }

  // Initialize the service and start listening to Firebase
  void initialize() {
    startListening();
  }

  // Start listening to Firebase stream
  void startListening() {
    _subscription?.cancel();
    _subscription = FirebaseService.getInventoryStream().listen(
      (inventory) {
        _inventory = inventory;
        _isConnected = true;
        notifyListeners();
      },
      onError: (error) {
        print('Error listening to inventory data: $error');
        _isConnected = false;
        notifyListeners();
      },
      onDone: () {
        _isConnected = false;
        notifyListeners();
      },
    );
  }

  // Stop listening
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _isConnected = false;
    notifyListeners();
  }

  // Refresh data manually
  Future<void> refreshData() async {
    try {
      _isConnected = true;
      notifyListeners();

      // Force a refresh by restarting the listener
      startListening();
    } catch (e) {
      print('Error refreshing inventory data: $e');
      _isConnected = false;
      notifyListeners();
    }
  }

  // Add new inventory item
  Future<bool> addInventoryItem(InventoryItem item) async {
    final success = await FirebaseService.addInventoryItem(item);
    if (success) {
      // Refresh data to get updated list
      await refreshData();
    }
    return success;
  }

  // Update inventory item
  Future<bool> updateInventoryItem(InventoryItem item) async {
    final success = await FirebaseService.updateInventoryItem(item);
    if (success) {
      // Refresh data to get updated list
      await refreshData();
    }
    return success;
  }

  // Delete inventory item
  Future<bool> deleteInventoryItem(String itemId) async {
    final success = await FirebaseService.deleteInventoryItem(itemId);
    if (success) {
      // Refresh data to get updated list
      await refreshData();
    }
    return success;
  }

  // Update item quantity (useful for Arduino integration)
  Future<bool> updateItemQuantity(String itemId, int newQuantity) async {
    final success = await FirebaseService.updateItemQuantity(itemId, newQuantity);
    if (success) {
      // Refresh data to get updated list
      await refreshData();
    }
    return success;
  }

  // Update item quantity by RFID tag (for Arduino sensor integration)
  Future<bool> updateItemQuantityByRFID(String rfidTag, int newQuantity) async {
    final item = getInventoryItemByRFID(rfidTag);
    if (item != null) {
      return await updateItemQuantity(item.id, newQuantity);
    }
    return false;
  }

  // Get connection status text
  String get connectionStatusText {
    if (_isConnected && _inventory.isNotEmpty) {
      return 'Connected (${_inventory.length} items)';
    } else if (_isConnected) {
      return 'Connecting...';
    } else {
      return 'Disconnected';
    }
  }

  // Get connection status color
  Color get connectionStatusColor {
    if (_isConnected && _inventory.isNotEmpty) {
      return Colors.green;
    } else if (_isConnected) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  // Get inventory statistics
  Map<String, int> get inventoryStats {
    return {
      'total': _inventory.length,
      'lowStock': lowStockItems.length,
      'outOfStock': outOfStockItems.length,
      'normalStock': normalStockItems.length,
    };
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}

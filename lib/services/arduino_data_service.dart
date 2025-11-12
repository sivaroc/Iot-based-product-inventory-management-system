// File: lib/services/arduino_data_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/arduino_product_data.dart';
import 'firebase_service.dart';
import 'inventory_service.dart';

class ArduinoDataService extends ChangeNotifier {
  static final ArduinoDataService _instance = ArduinoDataService._internal();
  factory ArduinoDataService() => _instance;
  ArduinoDataService._internal();

  List<ArduinoProductData> _products = [];
  StreamSubscription<List<ArduinoProductData>>? _subscription;
  bool _isConnected = false;

  List<ArduinoProductData> get products => List.unmodifiable(_products);
  bool get isConnected => _isConnected;

  // Get products filtered by stock status
  List<ArduinoProductData> get lowStockProducts =>
      _products.where((product) => product.isLowStock).toList();

  List<ArduinoProductData> get outOfStockProducts =>
      _products.where((product) => product.isOutOfStock).toList();

  List<ArduinoProductData> get normalStockProducts =>
      _products.where((product) => !product.isLowStock && !product.isOutOfStock).toList();

  // Get product by ID
  ArduinoProductData? getProductById(String productId) {
    try {
      return _products.firstWhere((product) => product.productId == productId);
    } catch (e) {
      return null;
    }
  }

  // Get recent products (last 10)
  List<ArduinoProductData> get recentProducts {
    final sorted = List<ArduinoProductData>.from(_products)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.take(10).toList();
  }

  // Initialize the service and start listening to Firebase
  void initialize() {
    startListening();
  }

  // Start listening to Firebase stream
  void startListening() {
    _subscription?.cancel();
    _subscription = FirebaseService.getArduinoProductStream().listen(
      (products) {
        _products = products;
        _isConnected = true;
        // Sync with inventory system
        _syncWithInventory();
        notifyListeners();
      },
      onError: (error) {
        print('Error listening to Arduino data: $error');
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
      print('Error refreshing Arduino data: $e');
      _isConnected = false;
      notifyListeners();
    }
  }

  // Get connection status text
  String get connectionStatusText {
    if (_isConnected && _products.isNotEmpty) {
      return 'Connected (${_products.length} products)';
    } else if (_isConnected) {
      return 'Connecting...';
    } else {
      return 'Disconnected';
    }
  }

  final InventoryService _inventoryService = InventoryService();

  // Sync Arduino data with inventory when products are received
  void _syncWithInventory() {
    for (final product in _products) {
      final inventoryItem = _inventoryService.getInventoryItemByRFID(product.productId);
      if (inventoryItem != null) {
        // Update inventory quantity based on Arduino sensor data
        _inventoryService.updateItemQuantityByRFID(
          product.productId,
          product.productCount
        );
      }
    }
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}

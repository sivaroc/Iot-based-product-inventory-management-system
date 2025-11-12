import 'dart:math';
import '../models/inventory_item.dart';
import '../models/sensor_data.dart';
import '../models/user.dart';

class MockDataService {
  static final Random _random = Random();
  
  // Generate only ONE mock inventory item
  static List<InventoryItem> getMockInventory() {
    return [
      InventoryItem(
        id: '1',
        name: 'Laptop Dell XPS',
        category: 'Electronics',
        quantity: 15,
        rfidTag: 'RFID_001',
        lastUpdated: DateTime.now().subtract(const Duration(hours: 2)),
        minStockLevel: 5,
        maxStockLevel: 50,
      ),
    ];
  }

  // Generate mock sensor data - REMOVED location parameter
  static List<SensorData> getMockSensorData() {
    return [
      SensorData(
        sensorId: 'RFID_001',
        type: 'rfid',
        value: 1.0,
        timestamp: DateTime.now().subtract(Duration(minutes: _random.nextInt(30))),
        itemId: '1',
      ),
    ];
  }

  // Generate mock user
  static User getMockUser() {
    return User(
      id: 'user_001',
      name: 'John Doe',
      email: 'john.doe@company.com',
      role: 'Inventory Manager',
      department: 'Operations',
      lastLogin: DateTime.now(),
    );
  }

  // Simulate real-time data updates
  static Stream<List<SensorData>> getSensorDataStream() {
    return Stream.periodic(const Duration(seconds: 5), (count) {
      return getMockSensorData();
    });
  }
}
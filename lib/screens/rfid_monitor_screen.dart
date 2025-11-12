import 'package:flutter/material.dart';
import '../services/arduino_data_service.dart';
import '../models/arduino_product_data.dart';

/// Simple RFID Monitor Screen - Shows real-time data from Firebase
/// This screen displays RFID tags and their data as they update in Firebase
class RFIDMonitorScreen extends StatefulWidget {
  const RFIDMonitorScreen({super.key});

  @override
  State<RFIDMonitorScreen> createState() => _RFIDMonitorScreenState();
}

class _RFIDMonitorScreenState extends State<RFIDMonitorScreen> {
  final ArduinoDataService _arduinoService = ArduinoDataService();

  @override
  void initState() {
    super.initState();
    _arduinoService.initialize();
  }

  @override
  void dispose() {
    _arduinoService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RFID Real-Time Monitor'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _arduinoService.refreshData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing data...')),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _arduinoService,
        builder: (context, child) {
          return Column(
            children: [
              // Connection Status Card
              _buildConnectionStatus(),
              
              // Products List
              Expanded(
                child: _buildProductsList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildConnectionStatus() {
    final isConnected = _arduinoService.isConnected;
    final productCount = _arduinoService.products.length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isConnected ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.check_circle : Icons.error,
            color: isConnected ? Colors.green : Colors.red,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected ? 'Connected to Firebase' : 'Disconnected',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isConnected ? Colors.green[800] : Colors.red[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$productCount RFID tag${productCount != 1 ? 's' : ''} detected',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          // Live indicator
          if (isConnected)
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    if (_arduinoService.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sensors_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No RFID Tags Detected',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Waiting for data from Firebase...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _arduinoService.products.length,
      itemBuilder: (context, index) {
        final product = _arduinoService.products[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(ArduinoProductData product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: product.stockStatusColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // RFID Tag ID
                Row(
                  children: [
                    Icon(
                      Icons.nfc,
                      color: Colors.blue,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      product.productId,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                // Status Badge
                _buildStatusChip(product),
              ],
            ),
            
            const Divider(height: 24),
            
            // Data Grid
            Row(
              children: [
                Expanded(
                  child: _buildDataItem(
                    icon: Icons.tag,
                    label: 'RFID Tag',
                    value: product.rfidTag,
                    color: Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildDataItem(
                    icon: Icons.inventory_2,
                    label: 'Count',
                    value: '${product.productCount}',
                    color: product.stockStatusColor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildDataItem(
                    icon: Icons.scale,
                    label: 'Weight',
                    value: product.weightDisplay,
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildDataItem(
                    icon: Icons.access_time,
                    label: 'Updated',
                    value: product.timeAgo,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Timestamp
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    'Timestamp: ${product.timestamp.millisecondsSinceEpoch ~/ 1000}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ArduinoProductData product) {
    String statusText;
    if (product.isOutOfStock) {
      statusText = 'Out of Stock';
    } else if (product.isLowStock) {
      statusText = 'Low Stock';
    } else {
      statusText = 'In Stock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: product.stockStatusColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: product.stockStatusColor,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: product.stockStatusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              color: product.stockStatusColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

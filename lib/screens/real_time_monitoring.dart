import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/arduino_product_data.dart';
import '../services/firebase_service.dart';

class RealTimeMonitoringScreen extends StatefulWidget {
  const RealTimeMonitoringScreen({super.key});

  @override
  _RealTimeMonitoringScreenState createState() => _RealTimeMonitoringScreenState();
}

class _RealTimeMonitoringScreenState extends State<RealTimeMonitoringScreen> with TickerProviderStateMixin {
  // Firebase Database Reference
  late final DatabaseReference databaseRef;
  
  // Animation Controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize database reference with your Firebase URL
    databaseRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://arduino-148de-default-rtdb.asia-southeast1.firebasedatabase.app/',
    ).ref();
    
    debugPrint('🔥 Firebase Database initialized for real-time monitoring');
    
    // Setup animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(_pulseController);
    
    // Log when data changes
    databaseRef.child('inventory').onValue.listen((event) {
      debugPrint('📡 Real-time update received from Firebase');
      debugPrint('📦 Data: ${event.snapshot.value}');
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IoT Inventory Monitor'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Connection Status
            _buildConnectionStatus(),
            
            // System Summary
            _buildSystemStatus(),
            
            // Divider
            const Divider(height: 1, thickness: 1),
            
            // Products List
            Expanded(
              child: _buildProductsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return StreamBuilder<bool>(
      stream: databaseRef.child('.info/connected').onValue.map((event) => event.snapshot.value == true),
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? false;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: isConnected ? Colors.green[50] : Colors.orange[50],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isConnected ? Icons.wifi : Icons.wifi_off,
                color: isConnected ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isConnected ? 'Connected to Firebase' : 'Disconnected',
                style: TextStyle(
                  color: isConnected ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSystemStatus() {
    return StreamBuilder<DatabaseEvent>(
      stream: databaseRef.child('inventory').onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }
        
        final data = snapshot.data?.snapshot.value as Map<dynamic, dynamic>? ?? {};
        List<ArduinoProductData> products = [];
        
        try {
          products = data.entries.map((e) => ArduinoProductData.fromJson(
            Map<String, dynamic>.from(e.value as Map),
            e.key as String,
          )).toList();
        } catch (e) {
          debugPrint('Error parsing products: $e');
          return Center(child: Text('Error loading data: $e'));
        }
        
        final totalProducts = products.length;
        final outOfStockProducts = products.where((p) => p.isOutOfStock).length;
        final lowStockProducts = products.where((p) => p.isLowStock && !p.isOutOfStock).length;
        
        // Overall system status
        final hasIssues = lowStockProducts > 0 || outOfStockProducts > 0;
        final status = hasIssues ? 'Attention Needed' : 'All Good';
        final statusColor = hasIssues ? Colors.orange : Colors.green;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'System Status: ',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.5)),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Stats Grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                'Total Items',
                totalProducts.toString(),
                Icons.inventory_2_outlined,
                Colors.blue,
              ),
              _buildStatCard(
                'Low Stock',
                lowStockProducts.toString(),
                Icons.warning_amber_rounded,
                Colors.orange,
              ),
              _buildStatCard(
                'Out of Stock',
                outOfStockProducts.toString(),
                Icons.error_outline,
                Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
  
  Widget _buildProductsList() {
    return StreamBuilder<DatabaseEvent>(
      stream: databaseRef.child('inventory').onValue,
      builder: (context, snapshot) {
        // Show loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading data...'),
              ],
            ),
          );
        }
        
        // Handle errors
        if (snapshot.hasError) {
          debugPrint('❌ Error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _refreshData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        // Check if data exists
        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No inventory data found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Add items to your Firebase database',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }
        
        final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        debugPrint('📡 Real-time data received: ${data.length} items');
        
        // Parse products
        List<ArduinoProductData> products = [];
        try {
          products = data.entries.map((e) {
            return ArduinoProductData.fromJson(
              Map<String, dynamic>.from(e.value as Map),
              e.key as String,
            );
          }).toList();
          
          // Sort by last updated (most recent first)
          products.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          
          debugPrint('✅ Successfully parsed ${products.length} products');
        } catch (e, stackTrace) {
          debugPrint('❌ Error parsing products: $e');
          debugPrint('📜 Stack trace: $stackTrace');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.orange, size: 48),
                const SizedBox(height: 16),
                const Text('Error parsing data', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Text('$e', style: const TextStyle(color: Colors.red, fontSize: 12)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        if (products.isEmpty) {
          return const Center(
            child: Text('No products found. Scan an RFID tag to begin.'),
          );
        }
        
        // Build list with real-time updates
        return RefreshIndicator(
          onRefresh: _refreshData,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildProductCard(product, key: ValueKey(product.rfidTag)),
              );
            },
          ),
        );
      },
    );
  }
  
  Widget _buildProductCard(ArduinoProductData product, {Key? key}) {
    final dateFormat = DateFormat('MMM d, y - hh:mm a');
    
    return Card(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: product.stockStatusColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            product.isOutOfStock 
                ? Icons.remove_shopping_cart 
                : Icons.shopping_cart_checkout,
            color: product.stockStatusColor,
          ),
        ),
        title: Text(
          'RFID: ${product.rfidTag}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                _buildInfoChip(
                  '${product.productCount} items',
                  Icons.numbers,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  product.weightDisplay,
                  Icons.scale,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Last updated: ${dateFormat.format(product.timestamp)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: product.stockStatusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            product.isOutOfStock 
                ? 'Out of Stock' 
                : product.isLowStock 
                    ? 'Low Stock' 
                    : 'In Stock',
            style: TextStyle(
              color: product.stockStatusColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _refreshData() async {
    debugPrint('🔄 Manually refreshing data...');
    try {
      final snapshot = await databaseRef.child('inventory').get();
      if (snapshot.exists) {
        debugPrint('✅ Data refreshed successfully');
        debugPrint('📦 Data count: ${(snapshot.value as Map).length} items');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data refreshed successfully'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        debugPrint('ℹ️ No data available at the database location');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No data found in database'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error refreshing data: $e');
      debugPrint('📜 Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _refreshData,
            ),
          ),
        );
      }
    }
  }
}
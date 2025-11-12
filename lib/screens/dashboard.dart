import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animations/animations.dart';
import '../services/firebase_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  late StreamSubscription<Map<String, dynamic>?> _inventorySubscription;
  Map<String, dynamic>? inventoryData;
  Timer? _timer;

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    // Initialize screens with current data
    _updateScreens();
    // Listen to inventory changes using Firebase Database SDK
    _setupInventoryListener();
  }

  void _updateScreens() {
    _screens.clear();
    _screens.addAll([
      _DashboardOverview(data: inventoryData),
      _InventoryScreen(data: inventoryData),
      _MonitoringScreen(data: inventoryData),
      const _ReportsScreen(),
    ]);
  }

  void _setupInventoryListener() {
    try {
      _inventorySubscription = FirebaseService.getInventoryDashboardStream().listen((data) {
        setState(() {
          inventoryData = data;
          _updateScreens(); // Update screens with new data
        });
      });
    } catch (e) {
      debugPrint('Error setting up inventory listener: $e');
    }
  }

  Future<void> _setSampleData() async {
    try {
      final success = await FirebaseService.setSampleInventoryData();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sample data added to RTDB successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add sample data')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  void dispose() {
    _inventorySubscription.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(_getAppBarTitle(),
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: const Color(0xFF2E5BFF),
        elevation: 3,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
        actions: [
          _buildAppBarAction(Icons.notifications_outlined, _showNotifications),
          _buildAppBarAction(Icons.account_circle_outlined, _showProfile),
          _buildAppBarAction(Icons.add, _setSampleData),
          _buildAppBarAction(Icons.logout_rounded, _logout),
        ],
      ),
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
          return FadeThroughTransition(
            animation: primaryAnimation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildAppBarAction(IconData icon, VoidCallback onPressed) =>
      IconButton(icon: Icon(icon), onPressed: onPressed, color: Colors.white);

  BottomNavigationBar _buildBottomNavigationBar() => BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF2E5BFF),
        unselectedItemColor: const Color(0xFF8C94A0),
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined), label: 'Inventory'),
          BottomNavigationBarItem(
              icon: Icon(Icons.sensors_outlined), label: 'Monitoring'),
          BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined), label: 'Reports'),
        ],
      );

  String _getAppBarTitle() =>
      ['Dashboard Overview', 'Inventory Management', 'Real-time Monitoring', 'Analytics & Reports']
          [_currentIndex];

  void _showNotifications() => showModal(
        context: context,
        configuration: const FadeScaleTransitionConfiguration(),
        builder: (context) => AlertDialog(
          title: const Text('Notifications'),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                  leading: Icon(Icons.warning, color: Colors.orange),
                  title: Text('Low Stock Alert'),
                  subtitle: Text('5 items are running low')),
              Divider(),
              ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('System Status'),
                  subtitle: Text('All systems operational')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
          ],
        ),
      );

  void _showProfile() {
    final user = FirebaseAuth.instance.currentUser;
    showModal(
      context: context,
      configuration: const FadeScaleTransitionConfiguration(),
      builder: (context) => AlertDialog(
        title: const Text('Profile'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${user?.email ?? 'Not available'}'),
            const Text('Role: Inventory Manager'),
            const Text('Department: Operations'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// -------------------- DASHBOARD OVERVIEW --------------------
class _DashboardOverview extends StatefulWidget {
  final Map<String, dynamic>? data;

  const _DashboardOverview({this.data});

  @override
  State<_DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<_DashboardOverview> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.data != null ? widget.data!['product_count'] ?? 0 : 0;
    final timestamp = widget.data != null ? widget.data!['timestamp'] ?? 'No data' : 'Loading...';
    final rfid = widget.data != null ? widget.data!['rfid_tag'] ?? 'None' : 'Loading...';
    final weight = widget.data != null ? widget.data!['weight'] ?? 0.0 : 0.0;

    String formattedTimestamp = 'No data';
    if (timestamp != 'No data' && timestamp != 'Loading...') {
      try {
        if (timestamp is num) {
          final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt() * 1000);
          formattedTimestamp = '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
        } else {
          formattedTimestamp = timestamp.toString();
        }
      } catch (e) {
        formattedTimestamp = timestamp.toString();
      }
    }

    String formattedWeight = '${weight.toStringAsFixed(2)}g';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(),
          const SizedBox(height: 20),
          _buildStatsGrid(count, formattedWeight, rfid, formattedTimestamp),
          const SizedBox(height: 20),
          _buildRecentActivity(rfid, formattedWeight),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E5BFF), Color(0xFF5A7CFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E5BFF).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.dashboard_rounded, size: 32, color: Colors.white),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard Overview',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Real-time inventory monitoring',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(int count, String weight, String rfid, String timestamp) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard('Total Products', count.toString(), Icons.inventory_2_rounded, const Color(0xFF2E5BFF), Colors.blue.shade50),
        _buildStatCard('Total Weight', weight, Icons.scale_rounded, Colors.green, Colors.green.shade50),
        _buildStatCard('RFID Tag', rfid.length > 8 ? '${rfid.substring(0, 8)}...' : rfid, Icons.nfc_rounded, Colors.purple, Colors.purple.shade50),
        _buildStatCard('Last Update', timestamp == 'No data' ? 'N/A' : timestamp.split(' ').last, Icons.access_time_rounded, Colors.orange, Colors.orange.shade50),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, Color bgColor) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.2), width: 1.5),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentActivity(String rfid, String weight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              _buildActivityItem('Product scanned', 'RFID: $rfid', Icons.qr_code, Colors.blue),
              const Divider(height: 1),
              _buildActivityItem('Weight updated', weight, Icons.scale, Colors.green),
              const Divider(height: 1),
              _buildActivityItem('Inventory synced', 'Just now', Icons.sync, Colors.purple),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String subtitle, IconData icon, Color color) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
    );
  }
}

/// -------------------- INVENTORY SCREEN --------------------
class _InventoryScreen extends StatefulWidget {
  final Map<String, dynamic>? data;

  const _InventoryScreen({this.data});

  @override
  State<_InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<_InventoryScreen> {
  List<Map<String, dynamic>> _historyData = [];
  bool _isLoading = true;
  int _previousCount = 0;
  StreamSubscription<Map<String, dynamic>?>? _inventorySubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _historySubscription;

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
    _trackInventoryChanges();
  }

  @override
  void dispose() {
    _inventorySubscription?.cancel();
    _historySubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadHistoryData() async {
    setState(() => _isLoading = true);
    
    try {
      // Listen to Firebase history stream
      _historySubscription = FirebaseService.getInventoryHistoryStream().listen((history) {
        if (mounted) {
          setState(() {
            _historyData = history;
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading history: $e');
    }
  }

  void _trackInventoryChanges() {
    // Listen to inventory changes and save to Firebase
    _inventorySubscription = FirebaseService.getInventoryDashboardStream().listen((data) async {
      if (data != null && mounted) {
        final currentCount = data['product_count'] ?? 0;
        final rfidTag = data['rfid_tag'] ?? 'None';
        final weight = (data['weight'] ?? 0.0) is int 
            ? (data['weight'] as int).toDouble() 
            : data['weight'] as double;
        final timestamp = data['timestamp'] ?? 0;

        // Determine action based on count change
        String? action;
        if (_previousCount > 0 && currentCount != _previousCount) {
          if (currentCount > _previousCount) {
            action = 'added';
          } else if (currentCount < _previousCount) {
            action = 'removed';
          }
        }

        // Save to Firebase if there's a change or it's the first record
        if (_previousCount != currentCount || _historyData.isEmpty) {
          await FirebaseService.addInventoryHistoryRecord(
            productCount: currentCount,
            rfidTag: rfidTag,
            weight: weight,
            timestamp: timestamp is int ? timestamp : 0,
            action: action,
          );
        }

        _previousCount = currentCount;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentCount = widget.data != null ? widget.data!['product_count'] ?? 0 : 0;
    final currentWeight = widget.data != null ? widget.data!['weight'] ?? 0.0 : 0.0;

    return Column(
      children: [
        // Current Status Summary
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E5BFF), Color(0xFF5A7CFF)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E5BFF).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.history, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inventory History',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'All recorded inventory data',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildCurrentStat('Count', '$currentCount', Icons.inventory_2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCurrentStat('Weight', '${currentWeight.toStringAsFixed(1)}g', Icons.scale),
                  ),
                ],
              ),
            ],
          ),
        ),

        // History List Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'History Records (${_historyData.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              if (_historyData.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() => _historyData.clear());
                  },
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // History List
        Expanded(
          child: _isLoading && _historyData.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _historyData.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No history records yet',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Data will appear as inventory updates',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _historyData.length,
                      itemBuilder: (context, index) {
                        return _buildHistoryCard(_historyData[index], index);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildCurrentStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> data, int index) {
    final count = data['product_count'] ?? 0;
    final rfid = data['rfid_tag'] ?? 'None';
    final weight = data['weight'] ?? 0.0;
    final timestamp = data['recorded_at'] ?? data['timestamp'] ?? 0;
    final action = data['action'] ?? 'updated';
    
    String formattedTime = 'Unknown';
    try {
      if (timestamp is num && timestamp > 0) {
        final dateTime = DateTime.fromMillisecondsSinceEpoch(
          timestamp > 9999999999 ? timestamp.toInt() : timestamp.toInt() * 1000
        );
        formattedTime = '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      formattedTime = 'Invalid time';
    }

    // Determine action color and icon
    Color actionColor = const Color(0xFF2E5BFF);
    IconData actionIcon = Icons.update;
    String actionText = 'Updated';
    
    if (action == 'added') {
      actionColor = Colors.green;
      actionIcon = Icons.add_circle;
      actionText = 'Added';
    } else if (action == 'removed') {
      actionColor = Colors.red;
      actionIcon = Icons.remove_circle;
      actionText = 'Removed';
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOut,
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header with timestamp and action
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: actionColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          actionIcon,
                          size: 16,
                          color: actionColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: actionColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          actionText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: actionColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          formattedTime,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#${index + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Data rows
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      _buildDataRow('Product Count', '$count', Icons.inventory_2_rounded, Colors.blue),
                      const Divider(height: 16),
                      _buildDataRow('RFID Tag', rfid, Icons.nfc_rounded, Colors.purple),
                      const Divider(height: 16),
                      _buildDataRow('Weight', '${weight.toStringAsFixed(2)}g', Icons.scale_rounded, Colors.green),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// -------------------- MONITORING SCREEN --------------------
class _MonitoringScreen extends StatefulWidget {
  final Map<String, dynamic>? data;

  const _MonitoringScreen({this.data});

  @override
  State<_MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<_MonitoringScreen> with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.data != null ? widget.data!['product_count'] ?? 0 : 0;
    final rfid = widget.data != null ? widget.data!['rfid_tag'] ?? 'None' : 'Loading...';
    final weight = widget.data != null ? widget.data!['weight'] ?? 0.0 : 0.0;
    final timestamp = widget.data != null ? widget.data!['timestamp'] ?? 'No data' : 'Loading...';

    String formattedWeight = '${weight.toStringAsFixed(2)}g';
    String formattedTimestamp = 'No data';
    if (timestamp != 'No data' && timestamp != 'Loading...') {
      try {
        if (timestamp is num) {
          final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt() * 1000);
          formattedTimestamp = '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
        } else {
          formattedTimestamp = timestamp.toString();
        }
      } catch (e) {
        formattedTimestamp = timestamp.toString();
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Colors.green, Color(0xFF4CAF50)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _blinkController,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2 + (_blinkController.value * 0.3)),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.sensors_rounded, size: 32, color: Colors.white),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Real-time Monitoring', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          AnimatedBuilder(
                            animation: _blinkController,
                            builder: (context, child) {
                              return Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.5 + (_blinkController.value * 0.5)),
                                  shape: BoxShape.circle,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          const Text('Live', style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildMonitorCard('Product Count', count.toString(), Icons.inventory_2_rounded, Colors.blue),
          const SizedBox(height: 16),
          _buildMonitorCard('RFID Tag', rfid, Icons.nfc_rounded, Colors.purple),
          const SizedBox(height: 16),
          _buildMonitorCard('Weight', formattedWeight, Icons.scale_rounded, Colors.green),
          const SizedBox(height: 16),
          _buildMonitorCard('Last Update', formattedTimestamp, Icons.access_time_rounded, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildMonitorCard(String title, String value, IconData icon, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2), width: 1.5),
              boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// -------------------- REPORTS SCREEN --------------------
class _ReportsScreen extends StatefulWidget {
  const _ReportsScreen();

  @override
  State<_ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<_ReportsScreen> {
  final List<Map<String, dynamic>> _productHistory = [];
  int _totalAdded = 0;
  int _totalRemoved = 0;
  int _previousCount = 0;

  @override
  void initState() {
    super.initState();
    _trackProductChanges();
  }

  void _trackProductChanges() {
    FirebaseService.getInventoryDashboardStream().listen((data) {
      if (data != null && mounted) {
        final currentCount = (data['product_count'] ?? 0) as int;
        final timestamp = DateTime.now();

        setState(() {
          // Track additions and removals
          if (_previousCount > 0) {
            final change = currentCount - _previousCount;
            if (change > 0) {
              _totalAdded += change.toInt();
            } else if (change < 0) {
              _totalRemoved += change.abs().toInt();
            }

            // Add to history for graph
            _productHistory.add({
              'timestamp': timestamp,
              'count': currentCount,
              'change': change,
            });

            // Keep last 20 data points for graph
            if (_productHistory.length > 20) {
              _productHistory.removeAt(0);
            }
          }

          _previousCount = currentCount;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B46C1), Color(0xFF9333EA)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B46C1).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analytics & Reports',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Product movement tracking',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Products Added',
                  _totalAdded.toString(),
                  Icons.add_circle_outline,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Products Removed',
                  _totalRemoved.toString(),
                  Icons.remove_circle_outline,
                  Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Product Count Graph
          _buildGraphCard(),

          const SizedBox(height: 20),

          // Movement Timeline
          _buildMovementTimeline(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGraphCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E5BFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.show_chart,
                  color: Color(0xFF2E5BFF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Product Count Over Time',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _productHistory.isEmpty
              ? Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timeline, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'No data yet',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Graph will appear as products change',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : SizedBox(
                  height: 200,
                  child: _buildLineChart(),
                ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    return CustomPaint(
      painter: _LineChartPainter(_productHistory),
      child: Container(),
    );
  }

  Widget _buildMovementTimeline() {
    if (_productHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.history, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'No movement history',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.history, color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Recent Movements',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...(_productHistory.reversed.take(5).map((entry) {
            final change = entry['change'] as int;
            final timestamp = entry['timestamp'] as DateTime;
            final count = entry['count'] as int;
            
            return _buildMovementItem(
              change > 0 ? 'Added ${change.abs()} product(s)' : 'Removed ${change.abs()} product(s)',
              'Total: $count',
              timestamp,
              change > 0 ? Colors.green : Colors.red,
              change > 0 ? Icons.add_circle : Icons.remove_circle,
            );
          }).toList()),
        ],
      ),
    );
  }

  Widget _buildMovementItem(String title, String subtitle, DateTime time, Color color, IconData icon) {
    final timeStr = '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            timeStr,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for line chart
class _LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;

  _LineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFF2E5BFF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = const Color(0xFF2E5BFF).withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    // Draw grid lines
    for (int i = 0; i <= 4; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Find min and max values
    final counts = data.map((e) => e['count'] as int).toList();
    final maxCount = counts.reduce((a, b) => a > b ? a : b);
    final minCount = counts.reduce((a, b) => a < b ? a : b);
    final range = maxCount - minCount;

    if (range == 0) return;

    // Create path for line
    final path = Path();
    final fillPath = Path();
    
    for (int i = 0; i < data.length; i++) {
      final count = data[i]['count'] as int;
      final x = (size.width / (data.length - 1)) * i;
      final y = size.height - ((count - minCount) / range * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      // Draw data points
      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()..color = const Color(0xFF2E5BFF),
      );
      canvas.drawCircle(
        Offset(x, y),
        6,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Complete fill path
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Draw fill and line
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

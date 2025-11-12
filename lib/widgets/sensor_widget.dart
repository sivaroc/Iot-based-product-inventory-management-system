import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import 'animated_widgets.dart';

class SensorWidget extends StatefulWidget {
  final SensorData sensorData;

  const SensorWidget({super.key, required this.sensorData});

  @override
  State<SensorWidget> createState() => _SensorWidgetState();
}

class _SensorWidgetState extends State<SensorWidget> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Pulse animation for active sensors
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _animationController.forward();

    // Start pulse animation if sensor is active
    if (widget.sensorData.isActive) {
      _pulseController.forward();
    }
  }

  @override
  void didUpdateWidget(SensorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update pulse animation based on sensor status
    if (widget.sensorData.isActive && !oldWidget.sensorData.isActive) {
      _pulseController.forward();
    } else if (!widget.sensorData.isActive && oldWidget.sensorData.isActive) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: AnimatedContainerWidget(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.sensorData.statusColor.withValues(alpha: 0.1),
                      widget.sensorData.statusColor.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.sensorData.statusColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header with icon and status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSensorIcon(),
                            Flexible(child: _buildStatusIndicator()),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Sensor name
                        Text(
                          _getSensorName(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),

                        const SizedBox(height: 6),

                        // Value display with pulse effect for active sensors
                        if (widget.sensorData.isActive)
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: _buildValueDisplay(),
                              );
                            },
                          )
                        else
                          _buildValueDisplay(),

                        const SizedBox(height: 6),

                        // Activity indicator for real-time data
                        _buildActivityIndicator(),

                        const SizedBox(height: 3),

                        // Last updated
                        _buildLastUpdated(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSensorIcon() {
    IconData icon;
    Color color;

    switch (widget.sensorData.type) {
      case 'rfid':
        icon = Icons.nfc;
        color = Colors.blue;
        break;
      case 'temperature':
        icon = Icons.thermostat;
        color = Colors.red;
        break;
      case 'humidity':
        icon = Icons.water_drop;
        color = Colors.cyan;
        break;
      case 'motion':
        icon = Icons.directions_run;
        color = Colors.green;
        break;
      default:
        icon = Icons.sensors;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.1),
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildStatusIndicator() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.sensorData.statusColor.withValues(alpha: 0.2),
            widget.sensorData.statusColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.sensorData.statusColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.sensorData.statusColor.withValues(alpha: 0.2),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: widget.sensorData.isActive ? widget.sensorData.statusColor : Colors.grey,
              shape: BoxShape.circle,
              boxShadow: widget.sensorData.isActive
                  ? [
                      BoxShadow(
                        color: widget.sensorData.statusColor.withValues(alpha: 0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            widget.sensorData.status,
            style: TextStyle(
              color: widget.sensorData.statusColor,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getSensorName() {
    switch (widget.sensorData.type) {
      case 'rfid': return 'RFID Reader';
      case 'temperature': return 'Temperature Sensor';
      case 'humidity': return 'Humidity Sensor';
      case 'motion': return 'Motion Detector';
      default: return 'Sensor';
    }
  }

  Widget _buildValueDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.sensorData.statusColor.withValues(alpha: 0.15),
            widget.sensorData.statusColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.sensorData.statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getFormattedValue(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: widget.sensorData.statusColor,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          Text(
            _getValueUnit(),
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityIndicator() {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.sensorData.statusColor.withValues(alpha: 0.3),
                widget.sensorData.statusColor.withValues(alpha: 0.1),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.sensors,
            size: 10,
            color: widget.sensorData.statusColor,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Real-time monitoring',
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[600],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (widget.sensorData.isActive)
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: widget.sensorData.statusColor,
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildLastUpdated() {
    final now = DateTime.now();
    final difference = now.difference(widget.sensorData.timestamp);
    final minutes = difference.inMinutes;

    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 10,
          color: Colors.grey[500],
        ),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            minutes < 1 ? 'Just now' : '$minutes min ago',
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[500],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getFormattedValue() {
    switch (widget.sensorData.type) {
      case 'rfid': return 'Scan Active';
      case 'temperature': return '${widget.sensorData.value.toStringAsFixed(1)}°C';
      case 'humidity': return '${widget.sensorData.value.toStringAsFixed(1)}%';
      case 'motion': return widget.sensorData.value > 0 ? 'Motion Detected' : 'No Motion';
      default: return 'Active';
    }
  }

  String _getValueUnit() {
    switch (widget.sensorData.type) {
      case 'temperature': return 'Temperature';
      case 'humidity': return 'Humidity Level';
      case 'motion': return 'Motion Status';
      default: return 'Status';
    }
  }
}
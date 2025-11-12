import 'package:flutter/material.dart';

class SensorData {
  final String sensorId;
  final String type;
  final double value;
  final DateTime timestamp;
  final String itemId;
  final bool isActive;

  SensorData({
    required this.sensorId,
    required this.type,
    required this.value,
    required this.timestamp,
    required this.itemId,
    this.isActive = true,
  });

  String get status {
    return 'Active';
  }

  Color get statusColor {
    return isActive ? Colors.green : Colors.grey;
  }
}
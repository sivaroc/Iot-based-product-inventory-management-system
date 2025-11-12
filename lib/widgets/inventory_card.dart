import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../models/inventory_item.dart';
import 'animated_widgets.dart';

class InventoryCard extends StatefulWidget {
  final InventoryItem item;
  final bool isAlert;

  const InventoryCard({super.key, required this.item, this.isAlert = false});

  @override
  State<InventoryCard> createState() => _InventoryCardState();
}

class _InventoryCardState extends State<InventoryCard> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

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

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
              duration: const Duration(milliseconds: 300),
              onTap: () => _showItemDetails(context),
              child: Card(
                elevation: 0,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: widget.isAlert ? Colors.orange[50] : Colors.white,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (widget.isAlert ? Colors.orange[100]! : Colors.white).withValues(alpha: 0.9),
                        (widget.isAlert ? Colors.orange[50]! : Colors.grey[50]!).withValues(alpha: 0.5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.isAlert ? Colors.orange[200]! : Colors.grey[200]!,
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _buildItemIcon(),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.item.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: widget.isAlert ? Colors.orange[800] : Colors.grey[800],
                                      ),
                                    ),
                                  ),
                                  if (widget.isAlert)
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.warning, color: Colors.white, size: 16),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Category: ${widget.item.category} • RFID: ${widget.item.rfidTag}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildStockIndicator(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        _buildQuantityBadge(),
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

  Widget _buildItemIcon() {
    IconData icon;
    Color color;
    
    switch (widget.item.category.toLowerCase()) {
      case 'electronics':
        icon = Icons.computer;
        color = Colors.blue;
        break;
      case 'furniture':
        icon = Icons.chair;
        color = Colors.brown;
        break;
      case 'networking':
        icon = Icons.router;
        color = Colors.purple;
        break;
      default:
        icon = Icons.inventory_2;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.1),
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildStockIndicator() {
    final percentage = widget.item.stockPercentage;
    Color color;
    String status;
    
    if (widget.item.quantity == 0) {
      color = Colors.red;
      status = 'Out of Stock';
    } else if (widget.item.isLowStock) {
      color = Colors.orange;
      status = 'Low Stock';
    } else {
      color = Colors.green;
      status = 'In Stock';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color, width: 0.5),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${widget.item.quantity}/${widget.item.maxStockLevel}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearPercentIndicator(
            width: MediaQuery.of(context).size.width > 600 ? 200 : MediaQuery.of(context).size.width * 0.4,
            lineHeight: 8,
            percent: percentage > 1.0 ? 1.0 : percentage,
            progressColor: color,
            backgroundColor: Colors.grey[200]!,
            barRadius: const Radius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityBadge() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: const [
                Color(0xFF2E5BFF),
                Color(0xFF5A7CFF),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E5BFF).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            '${widget.item.quantity}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Min: ${widget.item.minStockLevel}',
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    );
  }

  void _showItemDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.item.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Category', widget.item.category),
              _buildDetailRow('Quantity', widget.item.quantity.toString()),
              _buildDetailRow('RFID Tag', widget.item.rfidTag),
              _buildDetailRow('Min Stock', widget.item.minStockLevel.toString()),
              _buildDetailRow('Max Stock', widget.item.maxStockLevel.toString()),
              _buildDetailRow('Last Updated', _formatDate(widget.item.lastUpdated)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
import 'package:flutter/material.dart';

class OrderStatusBadge extends StatelessWidget {
  final String status;
  const OrderStatusBadge({super.key, required this.status});

  Color _colorFor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFE6391A);
      case 'cooking':
        return const Color(0xFFE6391A);
      case 'ready':
        return const Color(0xFFE6391A);
      case 'done':
        return const Color(0xFF007A4D);
      default:
        return Colors.grey;
    }
  }

  String _labelFor(String status) {
    switch (status) {
      case 'pending':
        return 'รอดำเนินการ';
      case 'cooking':
        return 'กำลังทำ';
      case 'ready':
        return 'อาหารพร้อมเสิร์ฟ';
      case 'done':
        return 'เสร็จแล้ว';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status == 'done' ? const Color(0xFFB9F4D9) : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _labelFor(status),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../widgets/order_status_badge.dart';

class OrderTrackingPage extends StatelessWidget {
  final OrderModel order;
  const OrderTrackingPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('รับออเดอร์แล้ว', 'ร้านค้าขอยืนยันออเดอร์แล้ว', Icons.check_circle),
      (
        'กำลังเตรียมอาหาร 🔥',
        'ร้านกำลังปรุงเมนูของคุณอย่างพิถีพิถัน',
        Icons.local_fire_department,
      ),
      (
        'อาหารพร้อมเสิร์ฟ',
        'อาหารเสร็จเรียบร้อยและกำลังส่งมอบให้คุณ',
        Icons.notifications,
      ),
      ('จัดส่งสำเร็จ', 'ออเดอร์ของคุณเสร็จสมบูรณ์', Icons.card_giftcard),
    ];
    final active = switch (order.status) {
      'cooking' => 1,
      'ready' => 2,
      'done' => 3,
      _ => 0,
    };
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('สถานะออเดอร์')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF0321C),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.local_shipping_outlined,
                    color: Color(0xFFF0321C),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('เวลาส่งโดยประมาณ'),
                    const Text(
                      '20 - 30 นาที',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text('หมายเลขออเดอร์: #${_shortId(order.id)}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                for (var i = 0; i < steps.length; i++)
                  _StepRow(
                    title: steps[i].$1,
                    subtitle: steps[i].$2,
                    icon: steps[i].$3,
                    active: i <= active,
                    last: i == steps.length - 1,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Center(child: OrderStatusBadge(status: order.status)),
        ],
      ),
    );
  }

  String _shortId(String id) =>
      id.length > 6 ? id.substring(0, 6).toUpperCase() : id.toUpperCase();
}

class _StepRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool active;
  final bool last;

  const _StepRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.active,
    required this.last,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF10B981) : const Color(0xFF8B7B76);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: active ? color : const Color(0xFFEDE7E4),
              child: Icon(icon, size: 15, color: active ? Colors.white : color),
            ),
            if (!last)
              Container(
                width: 2,
                height: 38,
                color: active ? color : const Color(0xFFEDE7E4),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF8B7B76),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

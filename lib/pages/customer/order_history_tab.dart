import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../providers/auth_provider.dart';
import '../group_info_page.dart';
import 'cart_tab.dart';
import 'order_tracking_page.dart';

class OrderHistoryTab extends StatelessWidget {
  const OrderHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userId = auth.user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('คำสั่งซื้อของฉัน'),
        actions: [
          IconButton(
            tooltip: 'ข้อมูลผู้พัฒนา',
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GroupInfoPage()),
            ),
          ),
          IconButton(
            tooltip: 'ตะกร้า',
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartTab()),
            ),
          ),
        ],
      ),
      body: userId == null
          ? const Center(
              child: Text(
                'กรุณาเข้าสู่ระบบเพื่อดูประวัติคำสั่งซื้อ (ไปที่แท็บโปรไฟล์)',
              ),
            )
          : StreamBuilder<List<OrderModel>>(
              // stream นี้จะอัปเดตทันทีเมื่อฝั่งร้านค้ากดเปลี่ยนสถานะ ไม่ต้องกด refresh เอง
              stream: OrderService().streamMyOrders(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('โหลดประวัติไม่สำเร็จ: ${snapshot.error}'),
                  );
                }
                final orders = snapshot.data ?? [];
                if (orders.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 68,
                          color: Color(0xFFC62828),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'ยังไม่มีประวัติคำสั่งซื้อ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text('รายการสั่งซื้อของคุณจะแสดงที่นี่'),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderTrackingPage(order: order),
                          ),
                        ),
                        child: _OrderCard(order: order),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final created = order.createdAt;
    final date = created == null
        ? 'รอสักครู่'
        : '${created.day}/${created.month}/${created.year}, ${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')} น.';
    final status = order.status == 'done' ? 'สำเร็จ' : 'กำลังทำ';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF0321C),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'ออเดอร์ #${order.id.length > 6 ? order.id.substring(0, 6).toUpperCase() : order.id.toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Chip(
                label: Text(status),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: order.status == 'done'
                      ? Colors.green
                      : const Color(0xFFF0321C),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Text(date, style: const TextStyle(fontSize: 12)),
          const Divider(color: Colors.white70),
          Text(
            order.items
                .map((item) => item['name']?.toString() ?? '')
                .join(', '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ยอดสุทธิ'),
              Text(
                order.totalPrice.toStringAsFixed(0),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

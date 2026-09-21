import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
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
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.person_outline),
            tooltip: 'เกี่ยวกับเรา',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GroupInfoPage()),
              );
            },
          ),
          const SizedBox(width: 12),
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
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Consumer<CartProvider>(
        builder: (context, cart, child) {
          return Badge(
            isLabelVisible: cart.itemCount > 0,
            label: Text(
              '${cart.itemCount}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: const Color(0xFFE8391A),
            offset: const Offset(1, -2),
            child: FloatingActionButton(
              heroTag: 'home-cart-button',
              tooltip: 'ตะกร้า',
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF222222),
              elevation: 5,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartTab()),
                );
              },
              child: const Icon(Icons.shopping_bag_outlined, size: 25),
            ),
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

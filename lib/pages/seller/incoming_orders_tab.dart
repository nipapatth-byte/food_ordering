import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../widgets/order_status_badge.dart';

class IncomingOrdersTab extends StatefulWidget {
  const IncomingOrdersTab({super.key});

  @override
  State<IncomingOrdersTab> createState() => _IncomingOrdersTabState();
}

class _IncomingOrdersTabState extends State<IncomingOrdersTab> {
  final _searchController = TextEditingController();
  final _orderService = OrderService();
  String _search = '';
  String? _expandedOrderId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text('รายการออเดอร์'),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _search = value.trim()),
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: 'ค้นหาเลขออเดอร์, ชื่อลูกค้า...',
                hintStyle: const TextStyle(color: Color(0xFF8B7B76)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF8B7B76)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<OrderModel>>(
              stream: _orderService.streamAllOrders(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('โหลดออเดอร์ไม่สำเร็จ: ${snapshot.error}'),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final orders = (snapshot.data ?? [])
                    .where(_matchesSearch)
                    .toList();
                if (orders.isEmpty) {
                  return const Center(child: Text('ไม่พบรายการออเดอร์'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: orders.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _OrderCard(
                      order: order,
                      expanded: _expandedOrderId == order.id,
                      onUpdate: () => setState(() {
                        _expandedOrderId = _expandedOrderId == order.id
                            ? null
                            : order.id;
                      }),
                      onStatusSelected: (status) =>
                          _orderService.updateStatus(order.id, status),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _matchesSearch(OrderModel order) {
    if (_search.isEmpty) return true;
    final text = [
      order.id,
      order.customerName,
      ...order.items.map((item) => item['name']?.toString() ?? ''),
    ].join(' ').toLowerCase();
    return text.contains(_search.toLowerCase());
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final bool expanded;
  final VoidCallback onUpdate;
  final Future<void> Function(String status) onStatusSelected;

  const _OrderCard({
    required this.order,
    required this.expanded,
    required this.onUpdate,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    final orderNumber = order.id.length > 3
        ? order.id.substring(order.id.length - 3).toUpperCase()
        : order.id.toUpperCase();
    final customer = order.customerName.isEmpty
        ? 'คุณลูกค้า'
        : order.customerName;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0321C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#$orderNumber',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              OrderStatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            customer,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            order.items
                .map((item) => '${item['name']} x${item['qty']}')
                .join(', '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 11),
            child: Divider(color: Colors.white, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ยอดรวมสุทธิ', style: TextStyle(fontSize: 12)),
                  Text(
                    order.totalPrice.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: onUpdate,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: const Text(
                  'อัปเดตสถานะ',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          if (expanded) ...[
            const SizedBox(height: 14),
            _StatusActions(status: order.status, onSelected: onStatusSelected),
          ],
        ],
      ),
    );
  }
}

class _StatusActions extends StatelessWidget {
  final String status;
  final Future<void> Function(String status) onSelected;

  const _StatusActions({required this.status, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final actions = status == 'pending'
        ? const [('กำลังเตรียมอาหาร', 'cooking')]
        : status == 'cooking'
        ? const [('อาหารพร้อมเสิร์ฟ', 'ready')]
        : status == 'ready'
        ? const [('จัดส่งสำเร็จ', 'done')]
        : const <(String, String)>[];

    if (actions.isEmpty) return const SizedBox.shrink();
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 12,
      childAspectRatio: 3.8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: actions
          .map(
            (action) => TextButton(
              onPressed: () => onSelected(action.$2),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF201D1B),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  action.$1,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

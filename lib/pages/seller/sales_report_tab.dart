import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../models/menu_item_model.dart';
import '../../services/order_service.dart';
import '../../services/menu_service.dart';

class SalesReportTab extends StatefulWidget {
  const SalesReportTab({super.key});

  @override
  State<SalesReportTab> createState() => _SalesReportTabState();
}

class _SalesReportTabState extends State<SalesReportTab> {
  int _section = 0;
  int _range = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'รายงานยอดขาย',
            style: TextStyle(
              fontFamily: 'FCMinimal',
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: OrderService().streamAllOrders(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('โหลดรายงานไม่สำเร็จ: ${snapshot.error}'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snapshot.data ?? [];
          return StreamBuilder<List<MenuItemModel>>(
            stream: MenuService().streamAllMenu(),
            builder: (context, menuSnapshot) {
              final menuById = {
                for (final item in menuSnapshot.data ?? <MenuItemModel>[])
                  item.id: item,
              };
              return Column(
                children: [
                  _SegmentedControl(
                    labels: const ['รายงานยอดขาย', 'ประวัติการขาย'],
                    selected: _section,
                    onChanged: (value) => setState(() => _section = value),
                  ),
                  Expanded(
                    child: _section == 0
                        ? _SalesSummary(
                            orders: orders,
                            menuById: menuById,
                            range: _range,
                            onRangeChanged: (value) =>
                                setState(() => _range = value),
                          )
                        : _SalesHistory(orders: orders),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _SalesSummary extends StatelessWidget {
  final List<OrderModel> orders;
  final Map<String, MenuItemModel> menuById;
  final int range;
  final ValueChanged<int> onRangeChanged;

  const _SalesSummary({
    required this.orders,
    required this.menuById,
    required this.range,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = orders.where((order) => _inRange(order, range)).toList();
    final salesOrders = filtered
        .where((order) => order.status == 'done')
        .toList();
    final revenue = salesOrders.fold<double>(
      0,
      (sum, order) => sum + order.totalPrice,
    );
    final topItems = _topItems(salesOrders, menuById);
    final chartDays = _chartDays();
    final chartValues = _chartValues(salesOrders, chartDays);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: [
        _RangeSelector(selected: range, onChanged: onRangeChanged),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _MetricCard(label: 'ยอดขาย', value: _money(revenue)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'ออเดอร์',
                value: '${salesOrders.length}',
                darkValue: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const Text(
          'สถิติยอดขาย',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        _SalesChart(
          values: chartValues,
          labels: chartDays.map(_shortThaiWeekday).toList(),
        ),
        const SizedBox(height: 22),
        const Text(
          'เมนูขายดี Top 3 ⭐',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        if (topItems.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: Text('ยังไม่มีข้อมูลยอดขาย')),
          )
        else
          ...topItems.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TopMenuCard(rank: entry.key + 1, item: entry.value),
            ),
          ),
      ],
    );
  }
}

class _SalesHistory extends StatelessWidget {
  final List<OrderModel> orders;

  const _SalesHistory({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(child: Text('ยังไม่มีประวัติการขาย'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) => _HistoryCard(order: orders[index]),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final OrderModel order;

  const _HistoryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final number = order.id.length > 3
        ? order.id.substring(order.id.length - 3).toUpperCase()
        : order.id.toUpperCase();
    final customer = order.customerName.isEmpty
        ? 'คุณลูกค้า'
        : order.customerName;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0321C), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '#$number',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            customer,
            style: const TextStyle(
              color: Color(0xFF201D1B),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            order.items
                .map((item) => '${item['name']} x${item['qty']}')
                .join(', '),
            style: const TextStyle(color: Color(0xFF201D1B), fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFF0321C), height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ยอดรวมสุทธิ',
                style: TextStyle(color: Color(0xFF201D1B), fontSize: 12),
              ),
              Text(
                _money(order.totalPrice),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  const _SegmentedControl({
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      height: 45,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: labels.asMap().entries.map((entry) {
          final active = selected == entry.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(entry.key),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFF0321C) : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    color: active ? Colors.white : const Color(0xFF8B7B76),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _RangeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Row(
        children: ['วันนี้', 'สัปดาห์', 'เดือน'].asMap().entries.map((entry) {
          final active = selected == entry.key;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: entry.key == 2 ? 0 : 8),
              child: GestureDetector(
                onTap: () => onChanged(entry.key),
                child: Container(
                  height: 29,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFFF0321C) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      color: active ? Colors.white : const Color(0xFF8B7B76),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final bool darkValue;

  const _MetricCard({
    required this.label,
    required this.value,
    this.darkValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8B7B76),
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Center(
            child: Text(
              value,
              style: TextStyle(
                color: darkValue
                    ? const Color(0xFF201D1B)
                    : const Color(0xFFF0321C),
                fontSize: 31,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;

  const _SalesChart({required this.values, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 158,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: CustomPaint(
        painter: _ChartPainter(values, labels),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;

  _ChartPainter(this.values, this.labels);

  @override
  void paint(Canvas canvas, Size size) {
    final chartHeight = size.height - 22;
    final maxValue = math.max(values.reduce(math.max), 1);
    final step = size.width / (values.length - 1);
    final points = values
        .asMap()
        .entries
        .map(
          (entry) => Offset(
            entry.key * step,
            chartHeight - (entry.value / maxValue * (chartHeight - 18)),
          ),
        )
        .toList();
    final gridPaint = Paint()
      ..color = const Color(0xFFE9DDD7)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = i * chartHeight / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final fillPath = Path()..moveTo(points.first.dx, chartHeight);
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final midpoint = (points[i - 1].dx + points[i].dx) / 2;
      linePath.cubicTo(
        midpoint,
        points[i - 1].dy,
        midpoint,
        points[i].dy,
        points[i].dx,
        points[i].dy,
      );
      fillPath.lineTo(points[i].dx, points[i].dy);
    }
    fillPath
      ..lineTo(points.last.dx, chartHeight)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x66F0321C), Color(0x05F0321C)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight)),
    );
    canvas.drawPath(
      linePath,
      Paint()
        ..color = const Color(0xFFF0321C)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    for (final point in points) {
      canvas.drawCircle(point, 4, Paint()..color = const Color(0xFFF0321C));
      canvas.drawCircle(point, 2, Paint()..color = Colors.white);
    }
    for (var i = 0; i < labels.length; i++) {
      final text = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(color: Color(0xFF4D4340), fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, Offset(i * step - text.width / 2, chartHeight + 5));
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) =>
      oldDelegate.values != values;
}

class _TopMenuCard extends StatelessWidget {
  final int rank;
  final _MenuSales item;

  const _TopMenuCard({required this.rank, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: const Color(0xFFFFF4E8),
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Color(0xFFF0321C),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _SmallImage(url: item.imageUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF201D1B),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'ขายแล้ว ${item.quantity}',
                  style: const TextStyle(
                    color: Color(0xFF8B7B76),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _money(item.revenue),
            style: const TextStyle(
              color: Color(0xFFF0321C),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallImage extends StatelessWidget {
  final String url;

  const _SmallImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: url.isEmpty
          ? Container(
              width: 48,
              height: 48,
              color: const Color(0xFFEDE7E4),
              child: const Icon(Icons.fastfood, color: Color(0xFF9F8F89)),
            )
          : Image.network(
              url,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFFEDE7E4),
                width: 48,
                height: 48,
                child: const Icon(Icons.fastfood, color: Color(0xFF9F8F89)),
              ),
            ),
    );
  }
}

class _MenuSales {
  final String name;
  final String imageUrl;
  int quantity;
  double revenue;

  _MenuSales({
    required this.name,
    required this.imageUrl,
    required this.quantity,
    required this.revenue,
  });
}

bool _inRange(OrderModel order, int range) {
  final date = order.createdAt;
  if (date == null) return false;
  final now = DateTime.now();
  final start = range == 0
      ? DateTime(now.year, now.month, now.day)
      : range == 1
      ? now.subtract(const Duration(days: 6))
      : DateTime(now.year, now.month, 1);
  return !date.isBefore(start);
}

List<_MenuSales> _topItems(
  List<OrderModel> orders,
  Map<String, MenuItemModel> menuById,
) {
  final values = <String, _MenuSales>{};
  for (final order in orders) {
    for (final rawItem in order.items) {
      final name = rawItem['name']?.toString() ?? 'เมนูไม่ระบุชื่อ';
      final qty =
          (rawItem['qty'] as num?)?.toInt() ??
          int.tryParse('${rawItem['qty']}') ??
          0;
      final menu = menuById[rawItem['menuId']?.toString()];
      final price =
          (rawItem['priceAtOrder'] as num?)?.toDouble() ?? menu?.price ?? 0;
      final imageUrl = rawItem['imageUrl']?.toString().isNotEmpty == true
          ? rawItem['imageUrl'].toString()
          : menu?.imageUrl ?? '';
      final current = values[name];
      if (current == null) {
        values[name] = _MenuSales(
          name: name,
          imageUrl: imageUrl,
          quantity: qty,
          revenue: qty * price,
        );
      } else {
        current.quantity += qty;
        current.revenue += qty * price;
      }
    }
  }
  final result = values.values.toList()
    ..sort((a, b) => b.quantity.compareTo(a.quantity));
  return result.take(3).toList();
}

List<DateTime> _chartDays() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return List.generate(7, (index) {
    return today.subtract(Duration(days: 6 - index));
  });
}

List<double> _chartValues(List<OrderModel> orders, List<DateTime> days) {
  return days.map((day) {
    return orders
        .where((order) {
          final date = order.createdAt;
          return date != null &&
              date.year == day.year &&
              date.month == day.month &&
              date.day == day.day;
        })
        .fold<double>(0, (sum, order) => sum + order.totalPrice);
  }).toList();
}

String _shortThaiWeekday(DateTime date) {
  const labels = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];
  return labels[date.weekday - 1];
}

String _money(num value) => value.toStringAsFixed(0);

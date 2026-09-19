import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/menu_item_model.dart';
import '../../providers/cart_provider.dart';
import 'cart_tab.dart';

class FoodDetailPage extends StatefulWidget {
  final MenuItemModel item;

  const FoodDetailPage({super.key, required this.item});

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('รายละเอียดอาหาร'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartTab()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 1.35,
              child: item.imageUrl.isEmpty
                  ? const ColoredBox(
                      color: Color(0xFF3B2922),
                      child: Icon(
                        Icons.restaurant,
                        color: Colors.white,
                        size: 60,
                      ),
                    )
                  : Image.network(item.imageUrl, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${item.price.toStringAsFixed(0)} บาท',
                style: const TextStyle(
                  color: Color(0xFFF0321C),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            item.description.isEmpty
                ? 'เมนูอร่อยจากร้านกินไรดี'
                : item.description,
            style: const TextStyle(color: Colors.white70, height: 1.5),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 28),
          const Text(
            'จำนวนอาหาร',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _QuantityButton(
                icon: Icons.remove,
                onPressed: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('$_quantity', style: const TextStyle(fontSize: 18)),
              ),
              _QuantityButton(
                icon: Icons.add,
                onPressed: () => setState(() => _quantity++),
                filled: true,
              ),
            ],
          ),
          const SizedBox(height: 34),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: item.price <= 0
                  ? null
                  : () {
                      final cart = context.read<CartProvider>();
                      for (var i = 0; i < _quantity; i++) {
                        cart.addItem(item);
                      }
                      Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF0321C),
                foregroundColor: Colors.white,
              ),
              child: Text(
                'เพิ่มลงตะกร้า  •  ${(item.price * _quantity).toStringAsFixed(0)} บาท',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool filled;

  const _QuantityButton({
    required this.icon,
    required this.onPressed,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: filled ? const Color(0xFFF0321C) : Colors.white,
        foregroundColor: filled ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon),
    );
  }
}

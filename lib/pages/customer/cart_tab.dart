import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import 'checkout_page.dart';

class CartTab extends StatelessWidget {
  const CartTab({super.key});

  static const _accent = Color(0xFFFF7A00);

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text(
          'ตะกร้าของฉัน',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'FCMinimal',
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: cart.isEmpty
          ? const _EmptyCart()
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 190),
              children: [
                ...cart.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CartItemCard(
                      item: item,
                      onDecrease: () => context
                          .read<CartProvider>()
                          .decrementItem(item.menuItem.id),
                      onIncrease: () => context
                          .read<CartProvider>()
                          .incrementItem(item.menuItem.id),
                      onRemove: () => context.read<CartProvider>().removeItem(
                        item.menuItem.id,
                      ),
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : _CartSummary(
              cart: cart,
              onCheckout: () {
                if (!auth.isLoggedIn) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'กรุณาเข้าสู่ระบบก่อนสั่งซื้อ (ไปที่แท็บโปรไฟล์)',
                      ),
                    ),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CheckoutPage()),
                );
              },
            ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final dynamic item;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final menuItem = item.menuItem;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF333333)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: menuItem.imageUrl.isEmpty
                ? const SizedBox(
                    width: 82,
                    height: 82,
                    child: ColoredBox(
                      color: Color(0xFF30251F),
                      child: Icon(
                        Icons.restaurant,
                        color: Colors.white54,
                        size: 35,
                      ),
                    ),
                  )
                : Image.network(
                    menuItem.imageUrl,
                    width: 82,
                    height: 82,
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stackTrace) => const SizedBox(
                      width: 82,
                      height: 82,
                      child: ColoredBox(
                        color: Color(0xFF30251F),
                        child: Icon(
                          Icons.restaurant,
                          color: Colors.white54,
                          size: 35,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  menuItem.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${menuItem.price.toStringAsFixed(0)} บาท',
                  style: const TextStyle(
                    color: CartTab._accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    _QuantityButton(icon: Icons.remove, onPressed: onDecrease),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _QuantityButton(icon: Icons.add, onPressed: onIncrease),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'ลบรายการ',
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _QuantityButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: 29,
        height: 29,
        decoration: BoxDecoration(
          color: const Color(0xFF2B2B2B),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: Colors.white70, size: 17),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final CartProvider cart;
  final VoidCallback onCheckout;

  const _CartSummary({required this.cart, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(top: BorderSide(color: Color(0xFF333333))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SummaryRow(label: 'ราคาอาหารรวม', value: cart.totalPrice),
            const SizedBox(height: 7),
            _SummaryRow(label: 'ค่าส่งอาหาร', value: CartProvider.deliveryFee),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: Color(0xFF333333), height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ยอดสุทธิ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${cart.grandTotal.toStringAsFixed(0)} บาท',
                  style: const TextStyle(
                    color: CartTab._accent,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF0321C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'ดำเนินการสั่งซื้อ',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '${value.toStringAsFixed(0)} บาท',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_basket_outlined,
            size: 76,
            color: Color(0xFFFF7A00),
          ),
          SizedBox(height: 16),
          Text(
            'ตะกร้าของคุณยังว่างอยู่',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'เลือกเมนูอร่อย ๆ แล้วกลับมาได้ที่นี่',
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../group_info_page.dart';
import 'checkout_page.dart';

class CartTab extends StatelessWidget {
  const CartTab({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context
        .watch<
          CartProvider
        >(); // ฟัง CartProvider ตัวเดียวกับที่ home_tab แก้ไข
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ตะกร้าของฉัน'),
        actions: [const GroupInfoAction()],
      ),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.shopping_basket_outlined,
                    size: 72,
                    color: Color(0xFFC62828),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'ตะกร้าของคุณยังว่างอยู่',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 6),
                  Text('เลือกเมนูอร่อย ๆ แล้วกลับมาได้ที่นี่'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                final item = cart.items[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    leading: item.menuItem.imageUrl.isNotEmpty
                        ? Image.network(
                            item.menuItem.imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.fastfood, size: 40),
                    title: Text(item.menuItem.name),
                    subtitle: Text(
                      '${item.menuItem.price.toStringAsFixed(0)} บาท x ${item.quantity}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => context
                              .read<CartProvider>()
                              .decrementItem(item.menuItem.id),
                        ),
                        Text('${item.quantity}'),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => context
                              .read<CartProvider>()
                              .incrementItem(item.menuItem.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'รวม: ${cart.totalPrice.toStringAsFixed(0)} บาท',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
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
                          MaterialPageRoute(
                            builder: (_) => const CheckoutPage(),
                          ),
                        );
                      },
                      child: const Text('ยืนยันสั่งซื้อ'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import 'payment_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _payment = 'cash';
  bool _submitting = false;

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final cart = context.read<CartProvider>();
    if (!auth.isLoggedIn) return;
    if (_payment == 'promptpay') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PaymentPage(amount: cart.totalPrice)),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await cart.checkout(auth.user!.uid);
      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
    } catch (error) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('สั่งซื้อไม่สำเร็จ: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();
    final address = auth.profile['address']?.toString().trim();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('ยืนยันคำสั่งซื้อ')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 120),
        children: [
          _Section(
            title: 'สถานที่จัดส่ง',
            child: Text(
              address == null || address.isEmpty
                  ? 'ยังไม่ได้ระบุที่อยู่จัดส่ง กรุณาเพิ่มข้อมูลในโปรไฟล์'
                  : address,
              style: const TextStyle(height: 1.4),
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'รายการอาหาร',
            child: Column(
              children: cart.items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.menuItem.name} x${item.quantity}',
                            ),
                          ),
                          Text('${item.subtotal.toStringAsFixed(0)} บาท'),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'เลือกวิธีการชำระเงิน',
            child: Column(
              children: [
                _PaymentChoice(
                  title: 'PromptPay (พร้อมเพย์)',
                  icon: Icons.qr_code_2,
                  value: 'promptpay',
                  groupValue: _payment,
                  onChanged: (value) => setState(() => _payment = value),
                ),
                _PaymentChoice(
                  title: 'เงินสด (Cash)',
                  icon: Icons.payments_outlined,
                  value: 'cash',
                  groupValue: _payment,
                  onChanged: (value) => setState(() => _payment = value),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF0321C),
              foregroundColor: Colors.white,
            ),
            child: Text(
              'ยืนยันการสั่งซื้อ  •  ${cart.totalPrice.toStringAsFixed(0)} บาท',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF0321C),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

class _PaymentChoice extends StatelessWidget {
  final String title;
  final IconData icon;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  const _PaymentChoice({
    required this.title,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => onChanged(value),
    child: Row(
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(width: 12),
        Expanded(child: Text(title)),
        Radio<String>(
          value: value,
          groupValue: groupValue,
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
          activeColor: Colors.white,
        ),
      ],
    ),
  );
}

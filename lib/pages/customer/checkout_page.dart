import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import 'payment_page.dart';
import 'order_success_splash_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _payment = 'cash';
  bool _submitting = false;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final cart = context.read<CartProvider>();

    if (!auth.isLoggedIn) return;

    final address = auth.profile['address']?.toString().trim() ?? '';

    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเพิ่มที่อยู่จัดส่งในหน้าโปรไฟล์ก่อนสั่งซื้อ'),
        ),
      );
      return;
    }

    if (_payment == 'promptpay') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentPage(
            amount: cart.grandTotal,
            notes: _notesController.text.trim(),
          ),
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      await cart.checkout(
        auth.user!.uid,
        deliveryAddress: address,
        paymentMethod: _payment,
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OrderSuccessSplashPage()),
        );
      }
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
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text(
          'ยืนยันคำสั่งซื้อ',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 120),
        children: [
          _Section(
            title: 'สถานที่จัดส่ง',
            icon: Icons.location_on_outlined,
            child: Text(
              address == null || address.isEmpty
                  ? 'ยังไม่ได้ระบุที่อยู่จัดส่ง กรุณาเพิ่มข้อมูลในโปรไฟล์'
                  : address,
              style: const TextStyle(
                color: Color(0xFF292321),
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _Section(
            title: 'หมายเหตุถึงร้าน',
            icon: Icons.note_alt_outlined,
            child: TextField(
              controller: _notesController,
              maxLines: 2,
              style: const TextStyle(color: Color(0xFF292321)),
              decoration: const InputDecoration(
                hintText: 'เช่น ไม่ใส่ผัก, โทรก่อนจัดส่ง',
                filled: false,
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _Section(
            title: 'รายการอาหาร',
            icon: Icons.receipt_long_outlined,
            child: Column(
              children: cart.items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.menuItem.name} x${item.quantity}',
                              style: const TextStyle(
                                color: Color(0xFF292321),
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            item.subtotal.toStringAsFixed(0),
                            style: const TextStyle(
                              color: Color(0xFF171313),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 18),
          _TotalSection(cart: cart),
          const SizedBox(height: 18),
          _Section(
            title: 'เลือกวิธีการชำระเงิน',
            icon: Icons.payments_outlined,
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
        minimum: const EdgeInsets.fromLTRB(26, 10, 26, 18),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF0321C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'ยืนยันการสั่งซื้อ  •  ${cart.grandTotal.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }
}

class _TotalSection extends StatelessWidget {
  final CartProvider cart;

  const _TotalSection({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _PriceRow(label: 'ราคาอาหารรวม', value: cart.totalPrice),
          const SizedBox(height: 8),
          _PriceRow(label: 'ค่าส่งอาหาร', value: CartProvider.deliveryFee),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Color(0xFFE0E0E0)),
          ),
          _PriceRow(
            label: 'ยอดสุทธิรวมค่าส่ง',
            value: cart.grandTotal,
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double value;
  final bool emphasized;

  const _PriceRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: emphasized ? const Color(0xFF171313) : const Color(0xFF292321),
      fontSize: emphasized ? 14 : 13,
      fontWeight: emphasized ? FontWeight.w900 : FontWeight.w600,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value.toStringAsFixed(0), style: style),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF292321), size: 18),
            const SizedBox(width: 7),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF171313),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
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
        Icon(icon, color: const Color(0xFF292321), size: 19),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF292321),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Radio<String>(
          value: value,
          groupValue: groupValue,
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
          activeColor: Colors.black,
        ),
      ],
    ),
  );
}

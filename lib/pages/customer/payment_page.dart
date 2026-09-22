import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import 'order_success_splash_page.dart';

class PaymentPage extends StatefulWidget {
  final double amount;
  final String notes;

  const PaymentPage({super.key, required this.amount, this.notes = ''});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _submitting = false;

  Future<void> _confirm() async {
    final auth = context.read<AuthProvider>();
    final cart = context.read<CartProvider>();
    setState(() => _submitting = true);
    try {
      final address = auth.profile['address']?.toString().trim() ?? '';
      if (address.isEmpty) {
        throw StateError('ไม่พบที่อยู่จัดส่ง');
      }
      await cart.checkout(
        auth.user!.uid,
        deliveryAddress: address,
        paymentMethod: 'promptpay',
        notes: widget.notes,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OrderSuccessSplashPage()),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ยืนยันการชำระเงินไม่สำเร็จ: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrUrl =
        'https://api.qrserver.com/v1/create-qr-code/?size=500x500&data=PromptPay-${widget.amount.toStringAsFixed(0)}';
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('ชำระเงินด้วย QR พร้อมเพย์')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 110),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Image.network(qrUrl, height: 280, fit: BoxFit.contain),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              'ยอดชำระทั้งหมด: ${widget.amount.toStringAsFixed(0)} บาท',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'สแกน QR เพื่อชำระเงิน แล้วกดยืนยันการชำระเงิน',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _submitting ? null : _confirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF0321C),
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'ยืนยันการชำระเงิน',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }
}

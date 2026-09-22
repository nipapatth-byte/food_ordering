import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'customer/customer_shell.dart';
import 'customer/splash_page.dart';
import 'seller/seller_shell.dart';
import '../widgets/notification_overlay.dart';

// ตัวตัดสินใจว่าจะโชว์ splash / แอปฝั่งลูกค้า / ฝั่งร้านค้า
// ทำงานอัตโนมัติ: พอ role เปลี่ยน (login/logout/register) จะสลับ shell ทั้งแอปทันที
class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // ยังรอ Firebase เช็ค session เดิม (persistent login) อยู่ -> โชว์ splash ไว้ก่อน
    // กันไม่ให้กระพริบไปหน้า customer แป๊บนึงก่อนสลับเป็น seller ตอนเปิดแอปใหม่
    if (!auth.initialized) {
      return const SplashPage();
    }

    // ยังไม่ login หรือ login แล้วเป็นลูกค้า -> เห็น shell ลูกค้า (guest ก็ดูเมนู/โต๊ะได้)
    if (auth.role == 'seller') {
      return NotificationOverlay(
        userId: auth.user?.uid,
        child: const SellerShell(),
      );
    }
    return NotificationOverlay(
      userId: auth.user?.uid,
      child: const CustomerShell(),
    );
  }
}

import 'package:flutter/material.dart';
import 'home_tab.dart';
import 'order_history_tab.dart';
import 'profile_tab.dart';
import '../reservation/reservation_shell_entry.dart';
import '../../widgets/app_bottom_nav.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _index = 0;

  late final List<Widget> _pages = [
    HomeTab(onProfileTap: () => setState(() => _index = 3)),
    const OrderHistoryTab(),
    const ReservationShellEntry(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack กันไม่ให้แต่ละหน้า rebuild ใหม่ทุกครั้งที่สลับ tab
      // ทำให้ state ของตะกร้า/scroll position ไม่หายตอนสลับไปมา
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          AppBottomNavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: 'หน้าแรก',
          ),
          AppBottomNavItem(
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long,
            label: 'คำสั่งซื้อ',
          ),
          AppBottomNavItem(
            icon: Icons.table_restaurant_outlined,
            selectedIcon: Icons.table_restaurant,
            label: 'จองโต๊ะ',
          ),
          AppBottomNavItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'โปรไฟล์',
          ),
        ],
      ),
    );
  }
}

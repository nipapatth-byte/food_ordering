import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'home_tab.dart';
import 'order_history_tab.dart';
import 'profile_tab.dart';
import '../reservation/reservation_shell_entry.dart';

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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Colors.black,
          padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
          child: GNav(
            backgroundColor: Colors.black,
            color: Colors.white70,
            activeColor: Colors.white,
            tabBackgroundColor: const Color(0xFFE6391A),
            gap: 6,
            padding: const EdgeInsets.all(12),
            selectedIndex: _index,
            onTabChange: (index) => setState(() => _index = index),
            tabs: const [
              GButton(icon: Icons.home_outlined, text: 'หน้าแรก'),
              GButton(icon: Icons.receipt_long_outlined, text: 'คำสั่งซื้อ'),
              GButton(icon: Icons.table_restaurant_outlined, text: 'จองโต๊ะ'),
              GButton(icon: Icons.person_outline, text: 'โปรไฟล์'),
            ],
          ),
        ),
      ),
    );
  }
}

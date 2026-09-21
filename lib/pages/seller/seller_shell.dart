import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'incoming_orders_tab.dart';
import 'manage_menu_tab.dart';
import 'manage_tables_tab.dart';
import 'sales_report_tab.dart';
import '../customer/profile_tab.dart'; // ใช้ตัวเดิมได้เลย เพราะมันเช็ค role/logout ในตัวอยู่แล้ว

class SellerShell extends StatefulWidget {
  const SellerShell({super.key});

  @override
  State<SellerShell> createState() => _SellerShellState();
}

class _SellerShellState extends State<SellerShell> {
  int _index = 0;

  final _pages = const [
    IncomingOrdersTab(),
    ManageMenuTab(),
    ManageTablesTab(),
    SalesReportTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Colors.black,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: GNav(
            backgroundColor: Colors.black,
            color: Colors.white70,
            activeColor: Colors.white,
            tabBackgroundColor: const Color(0xFFE6391A),
            gap: 4,
            padding: const EdgeInsets.all(11),
            selectedIndex: _index,
            onTabChange: (index) => setState(() => _index = index),
            tabs: const [
              GButton(icon: Icons.receipt_outlined, text: 'Order'),
              GButton(icon: Icons.restaurant_menu_outlined, text: 'Menu'),
              GButton(icon: Icons.table_bar_outlined, text: 'Tables'),
              GButton(icon: Icons.bar_chart_outlined, text: 'Report'),
              GButton(icon: Icons.person_outline, text: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

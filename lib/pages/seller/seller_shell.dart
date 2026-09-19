import 'package:flutter/material.dart';
import 'incoming_orders_tab.dart';
import 'manage_menu_tab.dart';
import 'manage_tables_tab.dart';
import 'sales_report_tab.dart';
import '../customer/profile_tab.dart'; // ใช้ตัวเดิมได้เลย เพราะมันเช็ค role/logout ในตัวอยู่แล้ว
import '../../widgets/app_bottom_nav.dart';

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
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          AppBottomNavItem(
            icon: Icons.receipt_outlined,
            selectedIcon: Icons.receipt,
            label: 'Order',
          ),
          AppBottomNavItem(
            icon: Icons.restaurant_menu_outlined,
            selectedIcon: Icons.restaurant_menu,
            label: 'Menu',
          ),
          AppBottomNavItem(
            icon: Icons.table_bar_outlined,
            selectedIcon: Icons.table_bar,
            label: 'Tables',
          ),
          AppBottomNavItem(
            icon: Icons.bar_chart_outlined,
            selectedIcon: Icons.bar_chart,
            label: 'Report',
          ),
          AppBottomNavItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

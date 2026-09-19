import 'package:flutter/material.dart';
import '../customer/cart_tab.dart';
import '../group_info_page.dart';
import 'my_reservations_page.dart';
import 'table_layout_page.dart';

class ReservationShellEntry extends StatefulWidget {
  const ReservationShellEntry({super.key});

  @override
  State<ReservationShellEntry> createState() => _ReservationShellEntryState();
}

class _ReservationShellEntryState extends State<ReservationShellEntry> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'จองโต๊ะ',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          _HeaderIcon(
            icon: Icons.person_outline,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GroupInfoPage()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _HeaderIcon(
              icon: Icons.shopping_cart_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartTab()),
              ),
              badge: '3',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
            child: _SegmentedTabs(
              selectedIndex: _tabIndex,
              onChanged: (index) => setState(() => _tabIndex = index),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: IndexedStack(
              index: _tabIndex,
              children: const [TableLayoutPage(), MyReservationsPage()],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;

  const _HeaderIcon({required this.icon, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onTap,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.all(10),
          ),
          icon: Icon(icon, size: 25),
        ),
        if (badge != null)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFFE8391A),
                shape: BoxShape.circle,
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _SegmentedTabs({required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'ผังโต๊ะ',
            selected: selectedIndex == 0,
            onTap: () => onChanged(0),
          ),
          _TabButton(
            label: 'การจองของฉัน',
            selected: selectedIndex == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFF5429) : Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF8B7D77),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

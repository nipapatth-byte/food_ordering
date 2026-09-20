import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppBottomNavItem> items;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: items.asMap().entries.map((entry) {
              final item = entry.value;
              final selected = entry.key == currentIndex;
              return Expanded(
                child: Semantics(
                  button: true,
                  selected: selected,
                  label: item.label,
                  child: InkWell(
                    onTap: () => onTap(entry.key),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        padding: EdgeInsets.symmetric(
                          horizontal: selected ? 18 : 10,
                          vertical: selected ? 10 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF2A211F)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                selected ? item.selectedIcon : item.icon,
                                color: selected
                                    ? const Color(0xFFFF4D26)
                                    : const Color(0xFFB8AAA5),
                                size: selected ? 26 : 22,
                              ),
                              if (selected) ...[
                                const SizedBox(width: 7),
                                Text(
                                  item.label,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class AppBottomNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const AppBottomNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

import 'package:flutter/material.dart';
import '../../models/menu_item_model.dart';
import '../../services/menu_service.dart';
import 'menu_form_page.dart';

class ManageMenuTab extends StatelessWidget {
  const ManageMenuTab({super.key});

  @override
  Widget build(BuildContext context) {
    final menuService = MenuService();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text('จัดการเมนู'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openMenuForm(context, null),
        backgroundColor: const Color(0xFFF0321C),
        foregroundColor: Colors.white,
        elevation: 8,
        icon: const Icon(Icons.add),
        label: const Text(
          'เพิ่มเมนูใหม่',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<List<MenuItemModel>>(
        stream: menuService.streamAllMenu(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('โหลดเมนูไม่สำเร็จ: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
                child: Text(
                  'รายการอาหารทั้งหมด (${items.length} รายการ)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('ยังไม่มีเมนู'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                        itemCount: items.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 13),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _MenuCard(
                            item: item,
                            onEdit: () => _openMenuForm(context, item),
                            onDelete: () =>
                                _confirmDelete(context, menuService, item),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    MenuService service,
    MenuItemModel item,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ลบเมนู'),
        content: Text('ต้องการลบเมนู "${item.name}" หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (shouldDelete == true) {
      await service.deleteMenuItem(item.id);
    }
  }

  Future<void> _openMenuForm(
    BuildContext context,
    MenuItemModel? existing,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MenuFormPage(existing: existing)),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final MenuItemModel item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MenuCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 79,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _MenuImage(url: item.imageUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF201D1B),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      item.price.toStringAsFixed(0),
                      style: const TextStyle(
                        color: Color(0xFFF0321C),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0E6),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          item.category.isEmpty
                              ? 'อาหารจานหลัก'
                              : item.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFF0321C),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _ActionCircle(
            icon: Icons.edit_outlined,
            backgroundColor: const Color(0xFFFFF4E8),
            color: const Color(0xFFF0321C),
            onPressed: onEdit,
          ),
          const SizedBox(width: 8),
          _ActionCircle(
            icon: Icons.delete_outline,
            backgroundColor: const Color(0xFFFFE2E2),
            color: const Color(0xFFFF4D55),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _MenuImage extends StatelessWidget {
  final String url;

  const _MenuImage({required this.url});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 56,
      height: 56,
      color: const Color(0xFFEDE7E4),
      child: const Icon(Icons.fastfood, color: Color(0xFF9F8F89)),
    );

    if (url.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: placeholder,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
    );
  }
}

class _ActionCircle extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color color;
  final VoidCallback onPressed;

  const _ActionCircle({
    required this.icon,
    required this.backgroundColor,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}

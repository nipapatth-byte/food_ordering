import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../models/menu_item_model.dart';
import '../../services/menu_service.dart';
import 'menu_form_page.dart';

class ManageMenuTab extends StatefulWidget {
  const ManageMenuTab({super.key});

  @override
  State<ManageMenuTab> createState() => _ManageMenuTabState();
}

class _ManageMenuTabState extends State<ManageMenuTab> {
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
                          return _SwipeMenuRow(
                            key: ValueKey(item.id),
                            onStartReached: () async {
                              await _openMenuForm(context, item);
                            },
                            onEndReached: () async {
                              await _confirmDelete(context, menuService, item);
                            },
                            child: _MenuCard(item: item),
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

  Future<bool> _confirmDelete(
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
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (shouldDelete == true) {
      try {
        await service.deleteMenuItem(item.id);
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('ลบเมนูไม่สำเร็จ: $error')));
        }
        return false;
      }
    }
    return shouldDelete == true;
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

class _SwipeMenuRow extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onStartReached;
  final Future<void> Function() onEndReached;

  const _SwipeMenuRow({
    super.key,
    required this.child,
    required this.onStartReached,
    required this.onEndReached,
  });

  @override
  State<_SwipeMenuRow> createState() => _SwipeMenuRowState();
}

class _SwipeMenuRowState extends State<_SwipeMenuRow>
    with SingleTickerProviderStateMixin {
  late final SlidableController _controller;
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    _controller = SlidableController(this);
    _controller.animation.addStatusListener(_handleAnimationStatus);
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _triggered) return;
    final actionPane = _controller.actionPaneType.value;
    if (actionPane == ActionPaneType.none) return;

    _triggered = true;
    final action = actionPane == ActionPaneType.start
        ? widget.onStartReached
        : widget.onEndReached;
    action().whenComplete(() async {
      await _controller.close();
      if (mounted) _triggered = false;
    });
  }

  @override
  void dispose() {
    _controller.animation.removeStatusListener(_handleAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Slidable(
      controller: _controller,
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.52,
        children: [
          SlidableAction(
            onPressed: (_) {},
            backgroundColor: const Color(0xFF00D86B),
            foregroundColor: Colors.white,
            icon: Icons.edit_outlined,
            label: 'แก้ไข',
            borderRadius: BorderRadius.circular(16),
            spacing: 8,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.52,
        children: [
          SlidableAction(
            onPressed: (_) {},
            backgroundColor: const Color(0xFFFF1744),
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: 'ลบ',
            borderRadius: BorderRadius.circular(16),
            spacing: 8,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
        ],
      ),
      child: widget.child,
    );
  }
}

class _MenuCard extends StatelessWidget {
  final MenuItemModel item;

  const _MenuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDailySpecial = item.source == 'external';

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
                Row(
                  children: [
                    if (isDailySpecial) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB300),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'วันนี้',
                          style: TextStyle(
                            color: Color(0xFF24170E),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],

                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF201D1B),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    Text(
                      '${item.price.toStringAsFixed(0)} บาท',
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

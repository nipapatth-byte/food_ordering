import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/menu_item_model.dart';
import '../../providers/cart_provider.dart';
import '../../services/menu_service.dart';
import '../group_info_page.dart';
import 'cart_tab.dart';
import 'food_detail_page.dart';

class HomeTab extends StatefulWidget {
  final VoidCallback? onProfileTap;

  const HomeTab({super.key, this.onProfileTap});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final MenuService _menuService = MenuService();

  MenuItemModel? _todaysSpecial;
  bool _loadingSpecial = true;

  String _selectedCategory = 'ทั้งหมด';

  static const Color primaryRed = Color(0xFFE8391A);
  static const Color darkBg = Color(0xFF000000);

  static const List<String> _categories = [
    'ทั้งหมด',
    'อาหารจานหลัก',
    'ของทานเล่น',
    'ชุดหมูกะทะ',
    'กุ้งเผา',
    'ก๋วยเตี๋ยว',
    'ของหวาน',
    'เครื่องดื่ม',
    'เครื่องดื่มแอลกอฮอล',
  ];

  @override
  void initState() {
    super.initState();
    _loadTodaysSpecial();
  }

  Future<void> _loadTodaysSpecial() async {
    if (mounted) {
      setState(() {
        _loadingSpecial = true;
      });
    }

    try {
      final special = await _menuService.fetchDailySpecial();

      if (!mounted) return;

      setState(() {
        _todaysSpecial = special;
        _loadingSpecial = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _todaysSpecial = null;
        _loadingSpecial = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: primaryRed,
        backgroundColor: Colors.white,
        onRefresh: _loadTodaysSpecial,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              sliver: SliverToBoxAdapter(child: _buildTodaysSpecial()),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 18),
                child: _buildCategoryChips(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Menu Grid
            _buildMenuGrid(),

            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Consumer<CartProvider>(
        builder: (context, cart, child) {
          return Badge(
            isLabelVisible: cart.itemCount > 0,
            label: Text(
              '${cart.itemCount}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: primaryRed,
            offset: const Offset(1, -2),
            child: FloatingActionButton(
              heroTag: 'home-cart-button',
              tooltip: 'ตะกร้า',
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF222222),
              elevation: 5,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartTab()),
                );
              },
              child: const Icon(Icons.shopping_bag_outlined, size: 25),
            ),
          );
        },
      ),
    );
  }

  // =========================================================
  // APP BAR
  // =========================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 20,
      toolbarHeight: 70,

      title: Row(
        children: [
          Image.asset(
            'lib/assests/images/chef.jpg',
            width: 38,
            height: 38,
            errorBuilder: (_, __, ___) {
              return const Icon(Icons.restaurant, color: primaryRed, size: 36);
            },
          ),

          const SizedBox(width: 10),

          const Text(
            'กินไรดี (Kin Rai Dee)',
            style: TextStyle(
              color: primaryRed,
              fontFamily: 'FCMinimal',
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),

      actions: [
        // Profile
        _topButton(
          icon: Icons.person_outline,
          tooltip: 'เกี่ยวกับเรา',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GroupInfoPage()),
            );
          },
        ),

        const SizedBox(width: 12),
      ],
    );
  }

  Widget _topButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: const Color(0xFF222222), size: 24),
      ),
    );
  }

  // =========================================================
  // TODAY'S SPECIAL
  // =========================================================

  Widget _buildTodaysSpecial() {
    if (_loadingSpecial) {
      return Container(
        height: 218,
        decoration: BoxDecoration(
          color: const Color(0xFF1B1817),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: primaryRed),
        ),
      );
    }

    if (_todaysSpecial == null) {
      return Container(
        height: 218,
        decoration: BoxDecoration(
          color: primaryRed,
          borderRadius: BorderRadius.circular(22),
        ),
        alignment: Alignment.center,
        child: const Text(
          'อร่อยง่าย ได้ทุกวัน 🍜',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    final item = _todaysSpecial!;

    final subtitle = item.description.trim().isEmpty
        ? 'หอมเครื่องแกง · รสชาติที่คิดถึง'
        : item.description.trim();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FoodDetailPage(item: item)),
        );
      },
      child: Container(
        height: 218,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF15120F),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            item.imageUrl.isEmpty
                ? const ColoredBox(
                    color: Color(0xFF3B2922),
                    child: Center(
                      child: Icon(
                        Icons.restaurant,
                        color: Colors.white70,
                        size: 55,
                      ),
                    ),
                  )
                : Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: Color(0xFF3B2922),
                      child: Center(
                        child: Icon(
                          Icons.restaurant,
                          color: Colors.white70,
                          size: 55,
                        ),
                      ),
                    ),
                  ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xD915120F), Color(0x3015120F)],
                ),
              ),
            ),
            Positioned(
              left: 22,
              top: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB300),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'เมนูแนะนำวันนี้',
                  style: TextStyle(
                    color: Color(0xFF24170E),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 22,
              right: 16,
              bottom: 22,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFF9EDE5),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: primaryRed,
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Text(
                      '${item.price.toStringAsFixed(0)} บาท',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // CATEGORY
  // =========================================================

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (_, __) {
          return const SizedBox(width: 8);
        },
        itemBuilder: (context, index) {
          final category = _categories[index];
          final bool selected = category == _selectedCategory;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(
                horizontal: selected ? 16 : 14,
                vertical: 9,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? primaryRed : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected ? primaryRed : const Color(0xFF333333),
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: primaryRed.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected) ...[
                    const Icon(Icons.check, color: Colors.white, size: 15),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    category,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // =========================================================
  // MENU GRID
  // =========================================================

  Widget _buildMenuGrid() {
    return StreamBuilder<List<MenuItemModel>>(
      stream: _menuService.streamAllMenu(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(50),
              child: Center(
                child: CircularProgressIndicator(color: primaryRed),
              ),
            ),
          );
        }

        final items = (snapshot.data ?? [])
            .where((item) => item.source != 'external')
            .where(
              (item) =>
                  _selectedCategory == 'ทั้งหมด' ||
                  item.category == _selectedCategory,
            )
            .toList();

        if (items.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'ยังไม่มีเมนูในหมวดนี้',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
          sliver: SliverGrid.builder(
            itemCount: items.length,

            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 14,
              childAspectRatio: 0.78,
            ),

            itemBuilder: (context, index) {
              return _MenuTile(item: items[index]);
            },
          ),
        );
      },
    );
  }
}

// ===========================================================
// MENU TILE
// ===========================================================

class _MenuTile extends StatelessWidget {
  final MenuItemModel item;

  const _MenuTile({required this.item});

  static const Color primaryRed = Color(0xFFE8391A);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food image
          Expanded(
            child: item.imageUrl.isEmpty
                ? Container(
                    width: double.infinity,
                    color: const Color(0xFFE8E1DD),
                    child: const Center(
                      child: Icon(
                        Icons.restaurant,
                        color: Color(0xFF777777),
                        size: 42,
                      ),
                    ),
                  )
                : Image.network(
                    item.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        color: const Color(0xFFE8E1DD),
                        child: const Center(
                          child: Icon(
                            Icons.restaurant,
                            color: Color(0xFF777777),
                            size: 42,
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Food information
          Container(
            height: 72,
            padding: const EdgeInsets.fromLTRB(12, 8, 7, 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
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
                          color: primaryRed,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        '${item.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: primaryRed,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),

                // Add button
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FoodDetailPage(item: item),
                      ),
                    );
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: primaryRed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

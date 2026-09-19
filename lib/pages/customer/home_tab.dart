import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/menu_item_model.dart';
import '../../providers/cart_provider.dart';
import '../../services/menu_service.dart';
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
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1A1A);

  static const List<String> _categories = [
    'ทั้งหมด',
    'อาหารจานหลัก',
    'ของหวาน',
    'เครื่องดื่ม',
    'ทานเล่น',
  ];

  @override
  void initState() {
    super.initState();
    _loadTodaysSpecial();
  }

  Future<void> _loadTodaysSpecial() async {
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
            // Today's Special
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              sliver: SliverToBoxAdapter(child: _buildTodaysSpecial()),
            ),

            // Category
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 22),
                child: _buildCategoryChips(),
              ),
            ),

            // Popular title
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(18, 20, 18, 10),
                child: Text(
                  'เมนูยอดฮิต 🔥',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),

            // Menu Grid
            _buildMenuGrid(),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
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
            'lib/assests/images/logo.png',
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
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),

      actions: [
        // Profile
        _topButton(
          icon: Icons.person_outline,
          tooltip: 'โปรไฟล์',
          onPressed: widget.onProfileTap,
        ),

        const SizedBox(width: 8),

        // Cart
        Consumer<CartProvider>(
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
              offset: const Offset(2, -3),
              child: _topButton(
                icon: Icons.shopping_cart_outlined,
                tooltip: 'ตะกร้า',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartTab()),
                  );
                },
              ),
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

    return Container(
      height: 218,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Image
          Expanded(
            child: item.imageUrl.isEmpty
                ? Container(
                    width: double.infinity,
                    color: const Color(0xFF3B2922),
                    child: const Icon(
                      Icons.restaurant,
                      color: Colors.white,
                      size: 55,
                    ),
                  )
                : Image.network(
                    item.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        color: const Color(0xFF3B2922),
                        child: const Center(
                          child: Icon(
                            Icons.restaurant,
                            color: Colors.white,
                            size: 55,
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom information
          Container(
            height: 58,
            padding: const EdgeInsets.fromLTRB(16, 8, 14, 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: primaryRed,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),

                Text(
                  '${item.price.toStringAsFixed(0)} บาท',
                  style: const TextStyle(
                    color: primaryRed,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
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
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: primaryRed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CATEGORY
  // =========================================================

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
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
              padding: const EdgeInsets.symmetric(horizontal: 17),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? primaryRed : const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF555555),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
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

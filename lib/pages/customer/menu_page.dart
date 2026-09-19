import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/menu_item_model.dart';
import '../../services/menu_service.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/menu_card.dart';
import '../../widgets/responsive_layout.dart';
import '../group_info_page.dart';
import 'cart_tab.dart';
import 'food_detail_page.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final menuService = MenuService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('เมนูอาหารทั้งหมด'),
        actions: [const GroupInfoAction()],
      ),
      floatingActionButton: Consumer<CartProvider>(
        builder: (context, cart, child) {
          return Badge(
            label: Text('${cart.itemCount}'),
            isLabelVisible: cart.itemCount > 0,
            offset: const Offset(-2, 2),
            child: FloatingActionButton(
              tooltip: 'เปิดตะกร้าอาหาร',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartTab()),
              ),
              child: const Icon(Icons.shopping_basket_outlined),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: StreamBuilder<List<MenuItemModel>>(
        stream: menuService.streamAllMenu(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('ยังไม่มีเมนูในร้าน'));
          }
          final isTablet = ResponsiveLayout.isTablet(context);
          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 18, 16, 2),
                  child: Text(
                    'เลือกเมนูที่คุณชอบ',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid.builder(
                  itemCount: items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isTablet ? 4 : 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return MenuCard(
                      item: item,
                      onAddToCart: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FoodDetailPage(item: item),
                          ),
                        );
                      },
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
}

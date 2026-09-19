import 'menu_item_model.dart';

class CartItemModel {
  final MenuItemModel menuItem;
  int quantity;

  CartItemModel({required this.menuItem, this.quantity = 1});

  double get subtotal => menuItem.price * quantity;

  Map<String, dynamic> toOrderItemMap() {
    return {
      'menuId': menuItem.id,
      'name': menuItem.name,
      'qty': quantity,
      'priceAtOrder': menuItem.price,
      'imageUrl': menuItem.imageUrl,
    };
  }
}

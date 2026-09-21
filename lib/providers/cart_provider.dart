import 'package:flutter/material.dart';
import '../models/menu_item_model.dart';
import '../models/cart_item_model.dart';
import '../services/order_service.dart';

// นี่คือ single source of truth ของตะกร้า
// ทุกหน้าที่ watch<CartProvider>() จะเห็นข้อมูลตรงกันเสมอ ไม่มีทางไม่ sync กัน
class CartProvider extends ChangeNotifier {
  static const double deliveryFee = 15;
  final List<CartItemModel> _items = [];
  final OrderService _orderService = OrderService();

  List<CartItemModel> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalPrice => _items.fold(0, (sum, item) => sum + item.subtotal);
  double get grandTotal => isEmpty ? 0 : totalPrice + deliveryFee;
  bool get isEmpty => _items.isEmpty;

  void addItem(MenuItemModel menuItem) {
    final index = _items.indexWhere((i) => i.menuItem.id == menuItem.id);
    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(CartItemModel(menuItem: menuItem));
    }
    notifyListeners();
  }

  void incrementItem(String menuId) {
    final index = _items.indexWhere((i) => i.menuItem.id == menuId);
    if (index >= 0) {
      _items[index].quantity++;
      notifyListeners();
    }
  }

  void decrementItem(String menuId) {
    final index = _items.indexWhere((i) => i.menuItem.id == menuId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removeItem(String menuId) {
    _items.removeWhere((i) => i.menuItem.id == menuId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // เรียกตอนกดยืนยันสั่งซื้อ -> คืน orderId กลับไป
  Future<String> checkout(
    String userId, {
    required String deliveryAddress,
  }) async {
    final orderId = await _orderService.createOrder(
      userId: userId,
      cartItems: _items,
      deliveryAddress: deliveryAddress,
      deliveryFee: deliveryFee,
    );
    clearCart();
    return orderId;
  }
}

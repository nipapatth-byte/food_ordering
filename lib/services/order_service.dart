import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';

class OrderService {
  final _db = FirebaseFirestore.instance;

  // สร้างออเดอร์ใหม่จากตะกร้า
  Future<String> createOrder({
    required String userId,
    required List<CartItemModel> cartItems,
    required String deliveryAddress,
    required double deliveryFee,
  }) async {
    final userSnapshot = await _db.collection('users').doc(userId).get();
    final userData = userSnapshot.data() ?? <String, dynamic>{};
    final customerName = userData['displayName']?.toString().trim() ?? '';
    final subtotal = cartItems.fold<double>(
      0,
      (total, item) => total + item.subtotal,
    );
    final total = subtotal + deliveryFee;

    final docRef = await _db.collection('orders').add({
      'userId': userId,
      'customerName': customerName,
      'deliveryAddress': deliveryAddress,
      'items': cartItems.map((c) => c.toOrderItemMap()).toList(),
      'status': 'pending',
      'totalPrice': total,
      'deliveryFee': deliveryFee,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  // ฝั่ง seller: ฟังออเดอร์ทั้งหมดที่ยังไม่เสร็จ แบบ real-time
  Stream<List<OrderModel>> streamActiveOrders() {
    return _db
        .collection('orders')
        .where('status', isNotEqualTo: 'done')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => OrderModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<OrderModel>> streamAllOrders() {
    return _db.collection('orders').snapshots().map((snap) {
      final orders = snap.docs
          .map((doc) => OrderModel.fromMap(doc.id, doc.data()))
          .toList();
      orders.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return orders;
    });
  }

  // ฝั่ง user: ดูประวัติออเดอร์ของตัวเอง แบบ real-time
  Stream<List<OrderModel>> streamMyOrders(String userId) {
    return _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final orders = snap.docs
              .map((doc) => OrderModel.fromMap(doc.id, doc.data()))
              .toList();
          orders.sort((a, b) {
            final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });
          return orders;
        });
  }

  // seller กดปุ่มอัปเดตสถานะ -> จะไป trigger stream ของฝั่ง user ทันทีแบบ real-time
  Future<void> updateStatus(String orderId, String newStatus) async {
    await _db.collection('orders').doc(orderId).update({'status': newStatus});
  }
}

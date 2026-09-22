import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';
import 'notification_service.dart';

class OrderService {
  final _db = FirebaseFirestore.instance;
  final _notifications = NotificationService();

  // สร้างออเดอร์ใหม่จากตะกร้า
  Future<String> createOrder({
    required String userId,
    required List<CartItemModel> cartItems,
    required String deliveryAddress,
    required double deliveryFee,
    String paymentMethod = 'cash',
    String notes = '',
  }) async {
    final userSnapshot = await _db.collection('users').doc(userId).get();
    final userData = userSnapshot.data() ?? <String, dynamic>{};
    final customerName = userData['displayName']?.toString().trim() ?? '';
    final customerPhone = userData['phone']?.toString().trim() ?? '';
    final subtotal = cartItems.fold<double>(
      0,
      (total, item) => total + item.subtotal,
    );
    final total = subtotal + deliveryFee;

    final docRef = await _db.collection('orders').add({
      'userId': userId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'notes': notes,
      'deliveryAddress': deliveryAddress,
      'items': cartItems.map((c) => c.toOrderItemMap()).toList(),
      'status': 'pending',
      'totalPrice': total,
      'deliveryFee': deliveryFee,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentMethod == 'promptpay' ? 'pending' : 'unpaid',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _notifications.notifyAdmins(
      title: 'มีออเดอร์ใหม่',
      message:
          '${customerName.isEmpty ? 'ลูกค้า' : customerName} สั่งอาหาร ${total.toStringAsFixed(0)} บาท',
      type: 'new_order',
    );
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
    const allowed = {'pending', 'cooking', 'ready', 'done', 'cancelled'};
    if (!allowed.contains(newStatus)) {
      throw ArgumentError('สถานะออเดอร์ไม่ถูกต้อง');
    }
    final ref = _db.collection('orders').doc(orderId);
    final snapshot = await ref.get();
    final userId = snapshot.data()?['userId']?.toString();
    await ref.update({'status': newStatus});
    if (userId != null && userId.isNotEmpty) {
      await _notifications.notifyUser(
        userId: userId,
        title: 'สถานะออเดอร์เปลี่ยนแปลง',
        message: 'ออเดอร์ของคุณเปลี่ยนเป็นสถานะ $newStatus',
        type: 'order_status',
      );
    }
  }

  Future<void> updatePaymentStatus(String orderId, String newStatus) async {
    const allowed = {'unpaid', 'pending', 'paid', 'rejected'};
    if (!allowed.contains(newStatus)) {
      throw ArgumentError('สถานะการชำระเงินไม่ถูกต้อง');
    }
    final ref = _db.collection('orders').doc(orderId);
    final snapshot = await ref.get();
    final userId = snapshot.data()?['userId']?.toString();
    await ref.update({'paymentStatus': newStatus});
    if (userId != null && userId.isNotEmpty) {
      await _notifications.notifyUser(
        userId: userId,
        title: 'สถานะการชำระเงินเปลี่ยนแปลง',
        message:
            'การชำระเงินของออเดอร์ถูกอัปเดตเป็น ${_paymentLabel(newStatus)}',
        type: 'payment_status',
      );
    }
  }

  String _paymentLabel(String status) {
    switch (status) {
      case 'paid':
        return 'ชำระแล้ว';
      case 'rejected':
        return 'ไม่ผ่าน';
      case 'pending':
        return 'รอตรวจสอบ';
      default:
        return 'ยังไม่ชำระ';
    }
  }
}

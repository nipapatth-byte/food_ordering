import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> streamForUser(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> notifyUser({
    required String userId,
    required String title,
    required String message,
    String? type,
  }) async {
    await _db.collection('notifications').add({
      'userId': userId,
      'title': title,
      'message': message,
      'type': type ?? 'general',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> notifyAdmins({
    required String title,
    required String message,
    String? type,
  }) async {
    final admins = await _db
        .collection('users')
        .where('role', isEqualTo: 'seller')
        .get();
    for (final admin in admins.docs) {
      await notifyUser(
        userId: admin.id,
        title: title,
        message: message,
        type: type,
      );
    }
  }
}

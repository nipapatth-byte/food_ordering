import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/table_model.dart';
import '../models/reservation_model.dart';

class ReservationService {
  final _db = FirebaseFirestore.instance;

  // Stream โต๊ะทั้งหมด แบบ real-time เรียงตามหมายเลขโต๊ะ
  Stream<List<TableModel>> streamTables() {
    return _db
        .collection('tables')
        .orderBy('tableNumber')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => TableModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> updateTableStatus(String tableId, String status) async {
    const allowedStatuses = {'available', 'occupied'};
    if (!allowedStatuses.contains(status)) {
      throw ArgumentError('สถานะโต๊ะไม่ถูกต้อง');
    }
    final tableRef = _db.collection('tables').doc(tableId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(tableRef);
      final currentStatus = snapshot.data()?['status']?.toString();
      if (currentStatus == 'reserved') {
        throw Exception('โต๊ะนี้มีการจองออนไลน์อยู่ จัดการจากหน้าการจองแทน');
      }
      transaction.update(tableRef, {'status': status});
    });
  }

  // จองโต๊ะแบบปลอดภัยจาก race condition ด้วย transaction
  // ถ้า 2 คนกดพร้อมกัน คนแรกจะผ่าน คนที่สองจะได้ error กลับไปทันที
  Future<String?> reserveTable({
    required String tableId,
    required String userId,
    required int partySize,
    required DateTime reservationDate,
    required String reservationTime,
  }) async {
    final tableRef = _db.collection('tables').doc(tableId);

    try {
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(tableRef);

        if (!snapshot.exists) {
          throw Exception('ไม่พบโต๊ะนี้');
        }

        final currentStatus = snapshot.get('status');
        if (currentStatus != 'available') {
          throw Exception('โต๊ะนี้ถูกจองไปแล้ว กรุณาเลือกโต๊ะอื่น');
        }

        // อัปเดตสถานะโต๊ะ
        transaction.update(tableRef, {'status': 'reserved'});

        // สร้างเอกสารการจอง
        final reservationRef = _db.collection('reservations').doc();
        transaction.set(reservationRef, {
          'userId': userId,
          'tableId': tableId,
          'tableNumber': snapshot.get('tableNumber'),
          'partySize': partySize,
          'status': 'pending',
          'reservedAt': FieldValue.serverTimestamp(),
          'reservationDate': Timestamp.fromDate(
            DateTime(
              reservationDate.year,
              reservationDate.month,
              reservationDate.day,
            ),
          ),
          'reservationTime': reservationTime,
        });
      });
      return null; // สำเร็จ ไม่มี error
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  // ฝั่ง user: ดูการจองของตัวเอง แบบ real-time
  Stream<List<ReservationModel>> streamMyReservations(String userId) {
    return _db
        .collection('reservations')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final reservations = snap.docs
              .map((doc) => ReservationModel.fromMap(doc.id, doc.data()))
              .toList();
          _sortReservations(reservations);
          return reservations;
        });
  }

  Stream<List<ReservationModel>> streamAllReservations() {
    return _db.collection('reservations').snapshots().map((snap) {
      final reservations = snap.docs
          .map((doc) => ReservationModel.fromMap(doc.id, doc.data()))
          .toList();
      _sortReservations(reservations);
      return reservations;
    });
  }

  void _sortReservations(List<ReservationModel> reservations) {
    reservations.sort((a, b) {
      final aDate = a.reservedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.reservedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
  }

  Future<void> updateReservationStatus(
    String reservationId,
    String tableId,
    String status,
  ) async {
    final reservationRef = _db.collection('reservations').doc(reservationId);
    final tableRef = _db.collection('tables').doc(tableId);

    await _db.runTransaction((transaction) async {
      final reservationSnapshot = await transaction.get(reservationRef);
      final currentStatus = reservationSnapshot.data()?['status']?.toString();
      if (currentStatus == 'completed' || currentStatus == 'cancelled') {
        throw Exception('การจองนี้จบแล้ว ไม่สามารถเปลี่ยนสถานะต่อได้');
      }
      final allowed = currentStatus == 'pending'
          ? {'confirmed', 'cancelled'}
          : currentStatus == 'confirmed'
          ? {'completed', 'cancelled'}
          : <String>{};
      if (!allowed.contains(status)) {
        throw Exception(
          'ไม่สามารถเปลี่ยนสถานะจาก $currentStatus เป็น $status ได้',
        );
      }
      transaction.update(reservationRef, {'status': status});
      if (status == 'cancelled' || status == 'completed') {
        transaction.update(tableRef, {'status': 'available'});
      } else if (status == 'confirmed' || status == 'pending') {
        transaction.update(tableRef, {'status': 'reserved'});
      }
    });
  }

  Future<void> cancelReservation(String reservationId, String tableId) async {
    await updateReservationStatus(reservationId, tableId, 'cancelled');
  }
}

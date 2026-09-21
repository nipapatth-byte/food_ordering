import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/table_model.dart';
import '../models/reservation_model.dart';

class ReservationService {
  final _db = FirebaseFirestore.instance;
  static const int openingMinutes = 9 * 60;
  static const int closingMinutes = 21 * 60;
  static const int reservationDurationMinutes = 2 * 60;

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

  Stream<List<ReservationModel>> streamReservations() {
    return _db
        .collection('reservations')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => ReservationModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  bool reservationOverlaps({
    required ReservationModel reservation,
    required DateTime date,
    required String timeRange,
  }) {
    if (reservation.reservationDate == null ||
        reservation.reservationTime == null ||
        reservation.status == 'cancelled' ||
        reservation.status == 'completed') {
      return false;
    }
    final reservationDate = reservation.reservationDate!;
    if (reservationDate.year != date.year ||
        reservationDate.month != date.month ||
        reservationDate.day != date.day) {
      return false;
    }
    final requested = _parseTimeRange(timeRange);
    final existing = _parseTimeRange(reservation.reservationTime!);
    if (requested == null || existing == null) return false;
    return requested.$1 < existing.$2 && existing.$1 < requested.$2;
  }

  (int, int)? _parseTimeRange(String value) {
    final parts = value.split('-');
    if (parts.length != 2) return null;
    int? parse(String input) {
      final time = input.trim().replaceAll(':', '.').split('.');
      if (time.length != 2) return null;
      final hour = int.tryParse(time[0]);
      final minute = int.tryParse(time[1]);
      if (hour == null || minute == null || hour < 0 || hour > 23) {
        return null;
      }
      if (minute < 0 || minute > 59) return null;
      return hour * 60 + minute;
    }

    final start = parse(parts[0]);
    final end = parse(parts[1]);
    if (start == null || end == null || end <= start) return null;
    return (start, end);
  }

  List<int>? _slotHours(String value) {
    final range = _parseTimeRange(value);
    if (range == null) return null;
    if (range.$1 < openingMinutes ||
        range.$2 > closingMinutes ||
        range.$2 - range.$1 != reservationDurationMinutes) {
      return null;
    }
    final firstHour = range.$1 ~/ 60;
    final lastHour = (range.$2 - 1) ~/ 60;
    return [for (var hour = firstHour; hour <= lastHour; hour++) hour];
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';
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
      final legacyReservations = await _db
          .collection('reservations')
          .where('tableId', isEqualTo: tableId)
          .get();
      final legacyConflict = legacyReservations.docs.any((doc) {
        return reservationOverlaps(
          reservation: ReservationModel.fromMap(doc.id, doc.data()),
          date: reservationDate,
          timeRange: reservationTime,
        );
      });
      if (legacyConflict) {
        return 'โต๊ะนี้ถูกจองในช่วงเวลานี้แล้ว กรุณาเลือกเวลาอื่น';
      }

      final requestedRange = _parseTimeRange(reservationTime);
      if (requestedRange == null ||
          requestedRange.$1 < openingMinutes ||
          requestedRange.$2 > closingMinutes ||
          requestedRange.$2 - requestedRange.$1 != reservationDurationMinutes) {
        return 'ร้านเปิดให้จองเวลา 09.00-21.00 น. รอบละ 2 ชั่วโมง';
      }

      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(tableRef);

        if (!snapshot.exists) {
          throw Exception('ไม่พบโต๊ะนี้');
        }

        final currentStatus = snapshot.get('status');
        if (currentStatus == 'occupied') {
          throw Exception('โต๊ะนี้กำลังใช้งานหน้าร้าน');
        }

        final hours = _slotHours(reservationTime);
        if (hours == null) {
          throw Exception('รูปแบบเวลาไม่ถูกต้อง');
        }
        final slotRefs = hours
            .map(
              (hour) => _db
                  .collection('reservation_slots')
                  .doc('${tableId}_${_dateKey(reservationDate)}_$hour'),
            )
            .toList();
        final slotSnapshots = <DocumentSnapshot<Map<String, dynamic>>>[];
        for (final slotRef in slotRefs) {
          slotSnapshots.add(await transaction.get(slotRef));
        }
        if (slotSnapshots.any((slot) => slot.exists)) {
          throw Exception('โต๊ะนี้ถูกจองในช่วงเวลานี้แล้ว กรุณาเลือกเวลาอื่น');
        }

        // Keep the table available; reservations are time-slot based.
        if (currentStatus == 'reserved') {
          transaction.update(tableRef, {'status': 'available'});
        }

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
        for (final slotRef in slotRefs) {
          transaction.set(slotRef, {
            'reservationId': reservationRef.id,
            'tableId': tableId,
            'reservationDate': Timestamp.fromDate(
              DateTime(
                reservationDate.year,
                reservationDate.month,
                reservationDate.day,
              ),
            ),
            'reservationTime': reservationTime,
          });
        }
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
      if (status == 'cancelled' || status == 'completed') {
        final reservationData = reservationSnapshot.data()!;
        final date = reservationData['reservationDate']?.toDate();
        final time = reservationData['reservationTime']?.toString();
        if (date is DateTime && time != null) {
          final hours = _slotHours(time);
          if (hours != null) {
            for (final hour in hours) {
              final slotRef = _db
                  .collection('reservation_slots')
                  .doc('${tableId}_${_dateKey(date)}_$hour');
              transaction.delete(slotRef);
            }
          }
        }
        final tableSnapshot = await transaction.get(tableRef);
        if (tableSnapshot.data()?['status'] == 'reserved') {
          transaction.update(tableRef, {'status': 'available'});
        }
      }
      transaction.update(reservationRef, {'status': status});
    });
  }

  Future<void> cancelReservation(String reservationId, String tableId) async {
    await updateReservationStatus(reservationId, tableId, 'cancelled');
  }
}

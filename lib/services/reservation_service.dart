import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/table_model.dart';
import '../models/reservation_model.dart';
import 'notification_service.dart';

class ReservationService {
  final _db = FirebaseFirestore.instance;
  final _notifications = NotificationService();
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

  // Stream เฉพาะ slot ของวันที่เลือก สำหรับตรวจสอบโต๊ะว่าง
  Stream<Set<String>> streamReservedSlotIds(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);

    return _db
        .collection('reservation_slots')
        .where('reservationDate', isEqualTo: Timestamp.fromDate(dateOnly))
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.id).toSet());
  }

  // ตรวจว่าโต๊ะมีการจองชนกับช่วงเวลาที่เลือกหรือไม่
  bool slotConflict({
    required String tableId,
    required DateTime date,
    required String timeRange,
    required Set<String> reservedSlotIds,
  }) {
    final hours = _slotHours(timeRange);
    if (hours == null) return false;

    final dateKey = _dateKey(date);

    return hours.any(
      (hour) => reservedSlotIds.contains('${tableId}_${dateKey}_$hour'),
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

  // ตรวจสอบว่าสถานะ "กำลังใช้งาน" ของโต๊ะขัดกับช่วงเวลาที่ลูกค้าต้องการจองหรือไม่
  // "กำลังใช้งาน" คือสถานะของโต๊ะ ณ ปัจจุบัน ไม่ใช่ Reservation แต่ลูกค้าหน้าร้านย่อมใช้เวลา
  // อยู่ที่โต๊ะประมาณหนึ่ง (ปกติเทียบเท่ารอบจอง = reservationDurationMinutes) ไม่ใช่แค่ "เสี้ยววินาทีนี้"
  // และไม่ใช่การล็อกโต๊ะทั้งวันเช่นกัน จึงต้องเทียบกับ "ช่วงเวลาที่คาดว่าจะใช้งาน"
  // (occupiedAt ถึง occupiedUntil ที่บันทึกไว้ตอน Admin กดเปลี่ยนสถานะ) ว่าทับซ้อนกับ
  // ช่วงเวลาที่ลูกค้าเลือกหรือไม่ ส่วน Reservation อื่น ๆ ให้ตรวจสอบด้วย reservationOverlaps ตามปกติ
  bool occupiedConflict({
    required String tableStatus,
    DateTime? occupiedAt,
    DateTime? occupiedUntil,
    required DateTime date,
    required String timeRange,
  }) {
    if (tableStatus != 'occupied') return false;
    final range = _parseTimeRange(timeRange);
    if (range == null) return false;
    final requestedStart = DateTime(
      date.year,
      date.month,
      date.day,
    ).add(Duration(minutes: range.$1));
    final requestedEnd = DateTime(
      date.year,
      date.month,
      date.day,
    ).add(Duration(minutes: range.$2));

    final now = DateTime.now();
    if (occupiedUntil == null) {
      // ไม่มีข้อมูลช่วงเวลาที่คาดว่าจะใช้งาน (เช่นข้อมูลเก่า) ให้ถือว่า
      // กำลังใช้งานเฉพาะ ณ ขณะนี้เท่านั้น เป็นทางเลือกสำรองที่ปลอดภัยที่สุด
      return !requestedStart.isAfter(now) && requestedEnd.isAfter(now);
    }
    if (!now.isBefore(occupiedUntil)) {
      // ครบช่วงเวลาที่คาดว่าจะใช้งานแล้ว ถือว่าไม่ใช่ช่วงที่กำลังใช้งานอยู่อีกต่อไป
      // (แม้ Admin จะยังไม่ได้กดเปลี่ยนสถานะกลับเป็นว่างก็ตาม)
      return false;
    }
    final blockStart = occupiedAt ?? now;
    return requestedStart.isBefore(occupiedUntil) &&
        blockStart.isBefore(requestedEnd);
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
      if (status == 'occupied') {
        // บันทึกช่วงเวลาที่คาดว่าลูกค้าหน้าร้านจะใช้โต๊ะนี้ (ค่าเริ่มต้นเท่ากับ 1 รอบจอง)
        // เพื่อให้ระบบรู้ว่าจะทับซ้อนกับการจองล่วงหน้าช่วงไหนบ้าง โดยไม่ล็อกโต๊ะทั้งวัน
        final now = DateTime.now();
        transaction.update(tableRef, {
          'status': status,
          'occupiedAt': Timestamp.fromDate(now),
          'occupiedUntil': Timestamp.fromDate(
            now.add(const Duration(minutes: reservationDurationMinutes)),
          ),
        });
      } else {
        transaction.update(tableRef, {
          'status': status,
          'occupiedAt': FieldValue.delete(),
          'occupiedUntil': FieldValue.delete(),
        });
      }
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
      final today = DateTime.now();
      final selectedDay = DateTime(
        reservationDate.year,
        reservationDate.month,
        reservationDate.day,
      );
      final currentDay = DateTime(today.year, today.month, today.day);
      if (selectedDay.isBefore(currentDay)) {
        return 'ไม่สามารถจองวันที่ผ่านมาแล้วได้';
      }
      final requestedRange = _parseTimeRange(reservationTime);
      if (requestedRange == null ||
          requestedRange.$1 < openingMinutes ||
          requestedRange.$2 > closingMinutes ||
          requestedRange.$2 - requestedRange.$1 != reservationDurationMinutes) {
        return 'ร้านเปิดให้จองเวลา 09.00-21.00 น. รอบละ 2 ชั่วโมง';
      }
      if (selectedDay == currentDay &&
          requestedRange.$1 <= (today.hour * 60 + today.minute)) {
        return 'ไม่สามารถจองเวลาที่ผ่านไปแล้วได้';
      }
      final userSnapshot = await _db.collection('users').doc(userId).get();
      final userData = userSnapshot.data() ?? <String, dynamic>{};
      final customerName = userData['displayName']?.toString().trim() ?? '';
      final customerPhone = userData['phone']?.toString().trim() ?? '';

      var tableLabel = tableId;
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(tableRef);

        if (!snapshot.exists) {
          throw Exception('ไม่พบโต๊ะนี้');
        }

        final tableData = snapshot.data() ?? <String, dynamic>{};
        tableLabel = snapshot.data()?['tableNumber']?.toString() ?? tableId;
        final currentStatus = (tableData['status'] as String?) ?? 'available';
        final seatCount = (tableData['seatCount'] as num?)?.toInt() ?? 0;
        if (partySize <= 0 || partySize > seatCount) {
          throw Exception('จำนวนผู้จองเกินจำนวนที่นั่งของโต๊ะนี้');
        }
        // "กำลังใช้งาน" เป็นสถานะปัจจุบันของโต๊ะ ไม่ใช่การล็อกโต๊ะทั้งวัน
        // จึงบล็อกเฉพาะช่วงเวลาที่คาดว่าลูกค้าหน้าร้านจะยังนั่งอยู่ (occupiedAt-occupiedUntil)
        if (occupiedConflict(
          tableStatus: currentStatus,
          occupiedAt: (tableData['occupiedAt'] as Timestamp?)?.toDate(),
          occupiedUntil: (tableData['occupiedUntil'] as Timestamp?)?.toDate(),
          date: reservationDate,
          timeRange: reservationTime,
        )) {
          throw Exception(
            'โต๊ะนี้กำลังใช้งานหน้าร้านอยู่ในขณะนี้ กรุณาเลือกเวลาอื่น',
          );
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

        // สร้างเอกสารการจอง
        final reservationRef = _db.collection('reservations').doc();
        transaction.set(reservationRef, {
          'userId': userId,
          'tableId': tableId,
          'tableNumber': snapshot.get('tableNumber'),
          'partySize': partySize,
          'customerName': customerName,
          'customerPhone': customerPhone,
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
      await _notifications.notifyAdmins(
        title: 'มีการจองโต๊ะใหม่',
        message:
            '${customerName.isEmpty ? 'ลูกค้า' : customerName} จองโต๊ะ $tableLabel เวลา $reservationTime',
        type: 'new_reservation',
      );
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
      final tableSnapshot = await transaction.get(tableRef);
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
        if (tableSnapshot.data()?['status'] == 'reserved') {
          transaction.update(tableRef, {'status': 'available'});
        }
      }
      transaction.update(reservationRef, {'status': status});
    });
    final reservation = await reservationRef.get();
    final userId = reservation.data()?['userId']?.toString();
    if (userId != null && userId.isNotEmpty) {
      await _notifications.notifyUser(
        userId: userId,
        title: 'สถานะการจองเปลี่ยนแปลง',
        message: 'การจองโต๊ะของคุณเปลี่ยนเป็นสถานะ $status',
        type: 'reservation_status',
      );
    }
  }

  Future<void> cancelReservation(String reservationId, String tableId) async {
    await updateReservationStatus(reservationId, tableId, 'cancelled');
  }
}

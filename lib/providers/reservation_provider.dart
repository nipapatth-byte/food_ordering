import 'package:flutter/material.dart';
import '../services/reservation_service.dart';

// เก็บ state เล็กๆ ของ flow การจอง (เช่น กำลังจองอยู่ไหม, error ล่าสุด)
// ข้อมูลโต๊ะ/การจองจริงมาจาก stream ของ ReservationService โดยตรงใน UI (ไม่ต้อง cacheซ้ำที่นี่)
class ReservationProvider extends ChangeNotifier {
  final ReservationService _service = ReservationService();

  bool _isReserving = false;
  String? _lastError;

  bool get isReserving => _isReserving;
  String? get lastError => _lastError;

  Future<bool> reserveTable({
    required String tableId,
    required String userId,
    required int partySize,
    required DateTime reservationDate,
    required String reservationTime,
  }) async {
    _isReserving = true;
    _lastError = null;
    notifyListeners();

    final error = await _service.reserveTable(
      tableId: tableId,
      userId: userId,
      partySize: partySize,
      reservationDate: reservationDate,
      reservationTime: reservationTime,
    );

    _isReserving = false;
    _lastError = error;
    notifyListeners();

    return error == null; // true = สำเร็จ
  }

  Future<void> cancelReservation(String reservationId, String tableId) async {
    await _service.cancelReservation(reservationId, tableId);
  }
}

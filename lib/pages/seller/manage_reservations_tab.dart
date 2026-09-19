import 'package:flutter/material.dart';
import '../../models/reservation_model.dart';
import '../../services/reservation_service.dart';
import '../group_info_page.dart';

class ManageReservationsTab extends StatelessWidget {
  const ManageReservationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final service = ReservationService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการการจอง'),
        actions: [const GroupInfoAction()],
      ),
      body: StreamBuilder<List<ReservationModel>>(
        stream: service.streamAllReservations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('โหลดการจองไม่สำเร็จ: ${snapshot.error}'),
            );
          }
          final reservations = snapshot.data ?? [];
          if (reservations.isEmpty) {
            return const Center(child: Text('ยังไม่มีรายการจองโต๊ะ'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final reservation = reservations[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.table_bar),
                  title: Text(
                    'จองโต๊ะ ${reservation.tableNumber ?? reservation.tableId} '
                    'จำนวน ${reservation.partySize} คน',
                  ),
                  subtitle: Text(
                    'ลูกค้า: ${reservation.userId}\n'
                    '${_reservationSchedule(reservation)}\n'
                    'สถานะ: ${reservation.status}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    tooltip: 'เปลี่ยนสถานะ',
                    enabled:
                        reservation.status != 'completed' &&
                        reservation.status != 'cancelled',
                    icon: const Icon(Icons.edit_note),
                    onSelected: (status) async {
                      try {
                        await service.updateReservationStatus(
                          reservation.id,
                          reservation.tableId,
                          status,
                        );
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('อัปเดตสถานะไม่สำเร็จ: $error'),
                            ),
                          );
                        }
                      }
                    },
                    itemBuilder: (_) => [
                      if (reservation.status == 'pending')
                        const PopupMenuItem(
                          value: 'confirmed',
                          child: Text('ยืนยันการจอง'),
                        ),
                      if (reservation.status == 'confirmed')
                        const PopupMenuItem(
                          value: 'completed',
                          child: Text('ใช้งานเสร็จแล้ว'),
                        ),
                      const PopupMenuItem(
                        value: 'cancelled',
                        child: Text('ยกเลิกการจอง'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _reservationSchedule(ReservationModel reservation) {
    final date = reservation.reservationDate;
    final dateText = date == null
        ? ''
        : '${date.day.toString().padLeft(2, '0')}/'
              '${date.month.toString().padLeft(2, '0')}/${date.year}';
    final timeText = reservation.reservationTime ?? '';
    if (dateText.isEmpty && timeText.isEmpty) {
      return 'วันเวลา: ยังไม่มีข้อมูล';
    }
    return 'วันเวลา: $dateText${timeText.isEmpty ? '' : ' • $timeText'}';
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/reservation_model.dart';
import '../../services/reservation_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reservation_provider.dart';

class MyReservationsPage extends StatelessWidget {
  const MyReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().user?.uid;
    if (userId == null) {
      return const Center(
        child: Text(
          'กรุณาเข้าสู่ระบบเพื่อดูการจองของคุณ',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return StreamBuilder<List<ReservationModel>>(
      stream: ReservationService().streamMyReservations(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'โหลดประวัติไม่สำเร็จ: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }
        final reservations = snapshot.data ?? [];
        if (reservations.isEmpty) {
          return const Center(
            child: Text(
              'ยังไม่มีการจองโต๊ะ',
              style: TextStyle(color: Colors.white),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          itemCount: reservations.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) =>
              _ReservationHistoryCard(reservation: reservations[index]),
        );
      },
    );
  }
}

class _ReservationHistoryCard extends StatelessWidget {
  final ReservationModel reservation;

  const _ReservationHistoryCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final completed = reservation.status == 'completed';
    final terminal = completed || reservation.status == 'cancelled';
    final statusLabel = switch (reservation.status) {
      'pending' => 'รอดำเนินการ',
      'confirmed' => 'ยืนยันแล้ว',
      'completed' => 'สำเร็จ',
      'cancelled' => 'ยกเลิกแล้ว',
      _ => reservation.status,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEF351B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'โต๊ะ ${reservation.tableNumber ?? reservation.tableId}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: completed ? const Color(0xFFD6F5E6) : Colors.white,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: completed
                        ? const Color(0xFF0D9A61)
                        : const Color(0xFFEF351B),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'จำนวน ${reservation.partySize} คน',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          if (reservation.reservationDate != null ||
              reservation.reservationTime != null)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                '${reservation.reservationDate == null ? '' : _formatDate(reservation.reservationDate!)}'
                '${reservation.reservationTime == null ? '' : ' • ${reservation.reservationTime}'}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Colors.white, height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'สถานะ: ${reservation.status}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              if (!terminal)
                TextButton(
                  onPressed: () => _cancel(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text(
                    'ยกเลิกการจอง',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _cancel(BuildContext context) async {
    try {
      await context.read<ReservationProvider>().cancelReservation(
        reservation.id,
        reservation.tableId,
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ยกเลิกการจองไม่สำเร็จ: $error')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

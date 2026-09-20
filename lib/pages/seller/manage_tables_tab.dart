import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/reservation_model.dart';
import '../../models/table_model.dart';
import '../../services/reservation_service.dart';

class ManageTablesTab extends StatefulWidget {
  const ManageTablesTab({super.key});

  @override
  State<ManageTablesTab> createState() => _ManageTablesTabState();
}

class _ManageTablesTabState extends State<ManageTablesTab> {
  int _section = 0;
  final _service = ReservationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text('จัดการโต๊ะ'),
        ),
      ),
      floatingActionButton: _section == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showAddTableDialog(context),
              backgroundColor: const Color(0xFFF0321C),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text(
                'เพิ่มโต๊ะ',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            )
          : null,
      body: Column(
        children: [
          _SectionToggle(
            selected: _section,
            onChanged: (value) => setState(() => _section = value),
          ),
          Expanded(
            child: _section == 0
                ? _TablesView(
                    service: _service,
                    onEdit: _showEditTableDialog,
                    onDelete: _confirmDeleteTable,
                    onStatus: _showTableStatusDialog,
                  )
                : _ReservationsView(service: _service),
          ),
        ],
      ),
    );
  }

  void _showAddTableDialog(BuildContext context) {
    final numberCtrl = TextEditingController();
    final seatCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('เพิ่มโต๊ะใหม่'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: numberCtrl,
              decoration: const InputDecoration(labelText: 'หมายเลขโต๊ะ'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: seatCtrl,
              decoration: const InputDecoration(labelText: 'จำนวนที่นั่ง'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              final number = int.tryParse(numberCtrl.text.trim());
              final seats = int.tryParse(seatCtrl.text.trim());
              if (number == null ||
                  seats == null ||
                  number <= 0 ||
                  seats <= 0) {
                return;
              }
              await FirebaseFirestore.instance.collection('tables').add({
                'tableNumber': number,
                'seatCount': seats,
                'status': 'available',
              });
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditTableDialog(
    BuildContext context,
    TableModel table,
  ) async {
    final numberCtrl = TextEditingController(text: '${table.tableNumber}');
    final seatCtrl = TextEditingController(text: '${table.seatCount}');
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('แก้ไขโต๊ะ ${table.tableNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: numberCtrl,
              decoration: const InputDecoration(labelText: 'หมายเลขโต๊ะ'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: seatCtrl,
              decoration: const InputDecoration(labelText: 'จำนวนที่นั่ง'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              final number = int.tryParse(numberCtrl.text.trim());
              final seats = int.tryParse(seatCtrl.text.trim());
              if (number == null ||
                  seats == null ||
                  number <= 0 ||
                  seats <= 0) {
                return;
              }
              await FirebaseFirestore.instance
                  .collection('tables')
                  .doc(table.id)
                  .update({'tableNumber': number, 'seatCount': seats});
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
    numberCtrl.dispose();
    seatCtrl.dispose();
  }

  Future<void> _confirmDeleteTable(
    BuildContext context,
    TableModel table,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ลบโต๊ะ'),
        content: Text(
          'ต้องการลบโต๊ะ ${table.tableNumber} หรือไม่?\n'
          'การดำเนินการนี้ไม่สามารถย้อนกลับได้',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF0321C),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ลบโต๊ะ'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('tables')
          .doc(table.id)
          .delete();
    }
  }

  Future<void> _showTableStatusDialog(
    BuildContext context,
    TableModel table,
  ) async {
    final status = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'สถานะโต๊ะ ${table.tableNumber}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFD6F5E6),
                  child: Icon(Icons.check_circle, color: Color(0xFF13A66A)),
                ),
                title: const Text(
                  'เปิดโต๊ะ / ว่าง',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: const Text('ให้ลูกค้าออนไลน์เลือกจองได้'),
                onTap: () => Navigator.pop(sheetContext, 'available'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFE0E0),
                  child: Icon(Icons.groups, color: Color(0xFFF0321C)),
                ),
                title: const Text(
                  'กำลังใช้งานหน้าร้าน',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: const Text('ป้องกันลูกค้าออนไลน์จองโต๊ะนี้'),
                onTap: () => Navigator.pop(sheetContext, 'occupied'),
              ),
            ],
          ),
        ),
      ),
    );
    if (status == null || !context.mounted) return;
    try {
      await _service.updateTableStatus(table.id, status);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('อัปเดตสถานะโต๊ะไม่สำเร็จ: $error')),
        );
      }
    }
  }
}

class _SectionToggle extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _SectionToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      height: 45,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _ToggleItem(
            label: 'จัดการโต๊ะ',
            selected: selected == 0,
            onTap: () => onChanged(0),
          ),
          _ToggleItem(
            label: 'การจอง',
            selected: selected == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF0321C) : Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF8B7B76),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _TablesView extends StatelessWidget {
  final ReservationService service;
  final Future<void> Function(BuildContext context, TableModel table) onEdit;
  final Future<void> Function(BuildContext context, TableModel table) onDelete;
  final Future<void> Function(BuildContext context, TableModel table) onStatus;

  const _TablesView({
    required this.service,
    required this.onEdit,
    required this.onDelete,
    required this.onStatus,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TableModel>>(
      stream: service.streamTables(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('โหลดโต๊ะไม่สำเร็จ: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final tables = snapshot.data ?? [];
        if (tables.isEmpty) {
          return const Center(child: Text('ยังไม่มีโต๊ะ กดปุ่มเพิ่มโต๊ะ'));
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 700 ? 24.0 : 16.0;
            return GridView.builder(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                0,
                horizontalPadding,
                100,
              ),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 240,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.25,
              ),
              itemCount: tables.length,
              itemBuilder: (context, index) => _TableCard(
                table: tables[index],
                onEdit: () => onEdit(context, tables[index]),
                onDelete: () => onDelete(context, tables[index]),
                onStatus: () => onStatus(context, tables[index]),
              ),
            );
          },
        );
      },
    );
  }
}

class _TableCard extends StatelessWidget {
  final TableModel table;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onStatus;

  const _TableCard({
    required this.table,
    required this.onEdit,
    required this.onDelete,
    required this.onStatus,
  });

  @override
  Widget build(BuildContext context) {
    final occupied = table.status == 'occupied';
    final reserved = table.status == 'reserved';
    final unavailable = occupied || reserved;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
      decoration: BoxDecoration(
        color: unavailable ? const Color(0xFFF0321C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'โต๊ะ ${table.tableNumber}',
                style: TextStyle(
                  color: unavailable ? Colors.white : const Color(0xFF201D1B),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              GestureDetector(
                onTap: onStatus,
                child: _StatusChip(
                  label: occupied
                      ? 'หน้าร้าน'
                      : reserved
                      ? 'จองแล้ว'
                      : 'ว่าง',
                  reserved: unavailable,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${table.seatCount} ที่นั่ง',
            style: TextStyle(
              color: unavailable ? Colors.white : const Color(0xFF8B7B76),
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Divider(color: unavailable ? Colors.white : const Color(0xFFE9DDD7)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _RoundAction(
                icon: Icons.edit_outlined,
                color: const Color(0xFFF0321C),
                background: unavailable
                    ? Colors.white
                    : const Color(0xFFFFF4E8),
                onTap: onEdit,
              ),
              _RoundAction(
                icon: Icons.delete_outline,
                color: const Color(0xFFFF4D55),
                background: unavailable
                    ? Colors.white
                    : const Color(0xFFFFE2E2),
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool reserved;

  const _StatusChip({required this.label, required this.reserved});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: reserved ? Colors.white : const Color(0xFFB9F4D9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: reserved ? const Color(0xFFF0321C) : const Color(0xFF13A66A),
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ReservationsView extends StatelessWidget {
  final ReservationService service;

  const _ReservationsView({required this.service});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReservationModel>>(
      stream: service.streamAllReservations(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('โหลดการจองไม่สำเร็จ: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final reservations = snapshot.data ?? [];
        if (reservations.isEmpty) {
          return const Center(child: Text('ยังไม่มีรายการจองโต๊ะ'));
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          itemCount: reservations.length,
          separatorBuilder: (context, index) => const SizedBox(height: 14),
          itemBuilder: (context, index) => _ReservationCard(
            reservation: reservations[index],
            service: service,
          ),
        );
      },
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  final ReservationService service;

  const _ReservationCard({required this.reservation, required this.service});

  @override
  Widget build(BuildContext context) {
    final statusText = switch (reservation.status) {
      'pending' => 'รอดำเนินการ',
      'confirmed' => 'จองแล้ว',
      'completed' => 'สำเร็จ',
      'cancelled' => 'ยกเลิกแล้ว',
      _ => reservation.status,
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0321C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'โต๊ะ ${reservation.tableNumber ?? reservation.tableId}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              _ReservationStatus(label: statusText, status: reservation.status),
            ],
          ),
          const SizedBox(height: 4),
          Text('จำนวน ${reservation.partySize} คน'),
          if (reservation.reservationDate != null ||
              reservation.reservationTime != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _reservationSchedule(reservation),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Colors.white, height: 1),
          ),
          Text('สถานะ: ${reservation.status}'),
          if (reservation.status != 'completed' &&
              reservation.status != 'cancelled') ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                if (reservation.status == 'pending')
                  _StatusAction(
                    label: 'ยืนยัน',
                    onPressed: () => _changeStatus(context, 'confirmed'),
                  ),
                if (reservation.status == 'confirmed')
                  _StatusAction(
                    label: 'สำเร็จ',
                    onPressed: () => _changeStatus(context, 'completed'),
                  ),
                _StatusAction(
                  label: 'ยกเลิก',
                  onPressed: () => _changeStatus(context, 'cancelled'),
                ),
              ],
            ),
          ],
        ],
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
    if (dateText.isEmpty) return 'เวลา: $timeText';
    if (timeText.isEmpty) return 'วันที่: $dateText';
    return 'วันที่: $dateText • เวลา: $timeText';
  }

  Future<void> _changeStatus(BuildContext context, String status) async {
    try {
      await service.updateReservationStatus(
        reservation.id,
        reservation.tableId,
        status,
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('อัปเดตสถานะไม่สำเร็จ: $error')));
      }
    }
  }
}

class _StatusAction extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _StatusAction({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF201D1B),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }
}

class _ReservationStatus extends StatelessWidget {
  final String label;
  final String status;

  const _ReservationStatus({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    final success = status == 'completed';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: success ? const Color(0xFFB9F4D9) : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: success ? const Color(0xFF13A66A) : const Color(0xFFF0321C),
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _RoundAction({
    required this.icon,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(icon, color: color, size: 17),
        ),
      ),
    );
  }
}

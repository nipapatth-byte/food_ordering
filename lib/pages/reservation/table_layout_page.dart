import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/table_model.dart';
import '../../services/reservation_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reservation_provider.dart';

class TableLayoutPage extends StatefulWidget {
  const TableLayoutPage({super.key});

  @override
  State<TableLayoutPage> createState() => _TableLayoutPageState();
}

class _TableLayoutPageState extends State<TableLayoutPage> {
  TableModel? _selectedTable;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedStartTime = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _selectedEndTime = const TimeOfDay(hour: 19, minute: 0);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return StreamBuilder<List<TableModel>>(
      stream: ReservationService().streamTables(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'โหลดโต๊ะไม่สำเร็จ: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }
        final tables = snapshot.data ?? [];
        if (tables.isEmpty) {
          return const Center(
            child: Text(
              'ยังไม่มีข้อมูลโต๊ะ',
              style: TextStyle(color: Colors.white),
            ),
          );
        }
        if (_selectedTable != null &&
            !tables.any((table) => table.id == _selectedTable!.id)) {
          _selectedTable = null;
        }

        return Column(
          children: [
            _buildFilters(),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                itemCount: tables.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 26,
                  mainAxisSpacing: 14,
                  childAspectRatio: .88,
                ),
                itemBuilder: (context, index) {
                  final table = tables[index];
                  final available = table.status == 'available';
                  final selected = _selectedTable?.id == table.id;
                  return _TableCard(
                    table: table,
                    available: available,
                    selected: selected,
                    onTap: available
                        ? () => setState(() => _selectedTable = table)
                        : null,
                  );
                },
              ),
            ),
            _buildFooter(auth.user?.uid),
          ],
        );
      },
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: _FilterBox(
              icon: '📅',
              label: _formatDate(_selectedDate),
              onTap: _pickDate,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _FilterBox(
              icon: '⏰',
              label:
                  '${_formatTime(_selectedStartTime)}-${_formatTime(_selectedEndTime)}',
              onTap: _pickTime,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}.'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(today) ? today : _selectedDate,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(today.year + 1, 12, 31),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFFF5429),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFFF5429),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    final endMinutes = picked.hour * 60 + picked.minute + 60;
    if (endMinutes >= 24 * 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกเวลาเริ่มก่อน 23.00 น.')),
      );
      return;
    }
    setState(() {
      _selectedStartTime = picked;
      _selectedEndTime = TimeOfDay(
        hour: endMinutes ~/ 60,
        minute: endMinutes % 60,
      );
    });
  }

  Widget _buildFooter(String? userId) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legend(color: Colors.black, border: Colors.white, label: 'ว่าง'),
              SizedBox(width: 18),
              _Legend(color: Color(0xFFF0E7DD), label: 'กำลังเลือก'),
              SizedBox(width: 18),
              _Legend(color: Color(0xFFEF351B), label: 'ไม่ว่าง'),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _selectedTable == null
                  ? null
                  : () => _showReserveDialog(context, _selectedTable!, userId),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5429),
                disabledBackgroundColor: const Color(0xFF4B4B4B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              child: Text(
                _selectedTable == null
                    ? 'ยืนยันการจอง'
                    : 'ยืนยันการจอง • โต๊ะ ${_selectedTable!.tableNumber}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReserveDialog(
    BuildContext context,
    TableModel table,
    String? userId,
  ) {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนจองโต๊ะ')),
      );
      return;
    }
    var partySize = 1;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('จองโต๊ะ ${table.tableNumber}'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => setDialogState(
                  () => partySize = partySize > 1 ? partySize - 1 : 1,
                ),
              ),
              Text('$partySize คน', style: const TextStyle(fontSize: 18)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setDialogState(
                  () => partySize = partySize < table.seatCount
                      ? partySize + 1
                      : partySize,
                ),
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
                final provider = context.read<ReservationProvider>();
                final success = await provider.reserveTable(
                  tableId: table.id,
                  userId: userId,
                  partySize: partySize,
                  reservationDate: _selectedDate,
                  reservationTime:
                      '${_formatTime(_selectedStartTime)}-${_formatTime(_selectedEndTime)}',
                );
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                if (success && mounted) setState(() => _selectedTable = null);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'จองโต๊ะ ${table.tableNumber} สำเร็จ'
                          : provider.lastError ?? 'จองไม่สำเร็จ',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              },
              child: const Text('ยืนยันจอง'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBox extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _FilterBox({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 39,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF857770),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  final TableModel table;
  final bool available;
  final bool selected;
  final VoidCallback? onTap;

  const _TableCard({
    required this.table,
    required this.available,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = selected
        ? const Color(0xFFF0E7DD)
        : available
        ? Colors.black
        : const Color(0xFFEF351B);
    final foreground = selected ? Colors.black : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 7),
        decoration: BoxDecoration(
          color: background,
          border: Border.all(
            color: available && !selected ? Colors.white : background,
          ),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              table.tableNumber.toString().padLeft(2, '0'),
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
            const Spacer(),
            Center(
              child: Icon(Icons.person_outline, color: foreground, size: 25),
            ),
            Center(
              child: Text(
                '${available && !selected ? 0 : (selected ? 0 : table.seatCount)}/${table.seatCount}',
                style: TextStyle(color: foreground, fontSize: 12),
              ),
            ),
            const Spacer(),
            
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final Color? border;
  final String label;

  const _Legend({required this.color, this.border, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 25,
          height: 25,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: border ?? color),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}

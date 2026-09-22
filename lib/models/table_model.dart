class TableModel {
  final String id;
  final int tableNumber;
  final int seatCount;
  final String status; // available | reserved | occupied

  // ช่วงเวลาโดยประมาณที่โต๊ะถูกใช้งานหน้าร้าน (มีค่าเฉพาะตอนสถานะเป็น occupied)
  // ใช้คำนวณว่าการจองล่วงหน้าช่วงไหนจะชนกับการใช้งานจริงบ้าง
  final DateTime? occupiedAt;
  final DateTime? occupiedUntil;

  TableModel({
    required this.id,
    required this.tableNumber,
    required this.seatCount,
    required this.status,
    this.occupiedAt,
    this.occupiedUntil,
  });

  factory TableModel.fromMap(String id, Map<String, dynamic> map) {
    return TableModel(
      id: id,
      tableNumber: map['tableNumber'] ?? 0,
      seatCount: map['seatCount'] ?? 0,
      status: map['status'] ?? 'available',
      occupiedAt: map['occupiedAt']?.toDate(),
      occupiedUntil: map['occupiedUntil']?.toDate(),
    );
  }
}

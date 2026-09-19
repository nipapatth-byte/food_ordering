class TableModel {
  final String id;
  final int tableNumber;
  final int seatCount;
  final String status; // available | reserved | occupied

  TableModel({
    required this.id,
    required this.tableNumber,
    required this.seatCount,
    required this.status,
  });

  factory TableModel.fromMap(String id, Map<String, dynamic> map) {
    return TableModel(
      id: id,
      tableNumber: map['tableNumber'] ?? 0,
      seatCount: map['seatCount'] ?? 0,
      status: map['status'] ?? 'available',
    );
  }
}

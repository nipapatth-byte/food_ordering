class ReservationModel {
  final String id;
  final String userId;
  final String tableId;
  final int partySize;
  final int? tableNumber;
  final String status; // pending | confirmed | completed | cancelled
  final DateTime? reservedAt;
  final DateTime? reservationDate;
  final String? reservationTime;
  final String customerName;
  final String customerPhone;

  ReservationModel({
    required this.id,
    required this.userId,
    required this.tableId,
    required this.partySize,
    required this.status,
    this.tableNumber,
    this.reservedAt,
    this.reservationDate,
    this.reservationTime,
    this.customerName = '',
    this.customerPhone = '',
  });

  factory ReservationModel.fromMap(String id, Map<String, dynamic> map) {
    return ReservationModel(
      id: id,
      userId: map['userId'] ?? '',
      tableId: map['tableId'] ?? '',
      tableNumber: (map['tableNumber'] as num?)?.toInt(),
      partySize: map['partySize'] ?? 1,
      status: map['status'] ?? 'pending',
      reservedAt: map['reservedAt']?.toDate(),
      reservationDate: map['reservationDate']?.toDate(),
      reservationTime: map['reservationTime']?.toString(),
      customerName: map['customerName']?.toString() ?? '',
      customerPhone: map['customerPhone']?.toString() ?? '',
    );
  }
}

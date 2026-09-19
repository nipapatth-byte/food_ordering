class OrderModel {
  final String id;
  final String userId;
  final List<Map<String, dynamic>> items; // [{menuId, name, qty, priceAtOrder}]
  final String status; // pending | cooking | ready | done
  final double totalPrice;
  final String customerName;
  final DateTime? createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.status,
    required this.totalPrice,
    this.customerName = '',
    this.createdAt,
  });

  factory OrderModel.fromMap(String id, Map<String, dynamic> map) {
    return OrderModel(
      id: id,
      userId: map['userId'] ?? '',
      items: List<Map<String, dynamic>>.from(map['items'] ?? []),
      status: map['status'] ?? 'pending',
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      customerName: map['customerName']?.toString() ?? '',
      createdAt: map['createdAt']?.toDate(),
    );
  }
}

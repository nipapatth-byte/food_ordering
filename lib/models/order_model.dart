class OrderModel {
  final String id;
  final String userId;
  final List<Map<String, dynamic>> items; // [{menuId, name, qty, priceAtOrder}]
  final String status; // pending | cooking | ready | done
  final double totalPrice;
  final double deliveryFee;
  final String customerName;
  final String deliveryAddress;
  final DateTime? createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.status,
    required this.totalPrice,
    this.customerName = '',
    this.deliveryFee = 0,
    this.deliveryAddress = '',
    this.createdAt,
  });

  factory OrderModel.fromMap(String id, Map<String, dynamic> map) {
    return OrderModel(
      id: id,
      userId: map['userId'] ?? '',
      items: List<Map<String, dynamic>>.from(map['items'] ?? []),
      status: map['status'] ?? 'pending',
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      deliveryFee: (map['deliveryFee'] ?? 0).toDouble(),
      customerName: map['customerName']?.toString() ?? '',
      deliveryAddress: map['deliveryAddress']?.toString() ?? '',
      createdAt: map['createdAt']?.toDate(),
    );
  }
}

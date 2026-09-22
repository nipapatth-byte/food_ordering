class OrderModel {
  final String id;
  final String userId;
  final List<Map<String, dynamic>> items; // [{menuId, name, qty, priceAtOrder}]
  final String status; // pending | cooking | ready | done | cancelled
  final String paymentStatus; // unpaid | pending | paid | rejected
  final String paymentMethod; // cash | promptpay | unknown
  final double totalPrice;
  final double deliveryFee;
  final String customerName;
  final String deliveryAddress;
  final String customerPhone;
  final String notes;
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
    this.customerPhone = '',
    this.notes = '',
    this.paymentStatus = 'unpaid',
    this.paymentMethod = 'cash',
    this.createdAt,
  });

  factory OrderModel.fromMap(String id, Map<String, dynamic> map) {
    return OrderModel(
      id: id,
      userId: map['userId'] ?? '',
      items: List<Map<String, dynamic>>.from(map['items'] ?? []),
      status: map['status'] ?? 'pending',
      paymentStatus: map['paymentStatus']?.toString() ?? 'unpaid',
      paymentMethod: map['paymentMethod']?.toString() ?? 'unknown',
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      deliveryFee: (map['deliveryFee'] ?? 0).toDouble(),
      customerName: map['customerName']?.toString() ?? '',
      deliveryAddress: map['deliveryAddress']?.toString() ?? '',
      customerPhone: map['customerPhone']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      createdAt: map['createdAt']?.toDate(),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class OrderEntity {
  String id;
  final String userId;
  final List<OrderItem> items;
  final bool status; 
  DateTime date;



  OrderEntity({
    required this.userId,
    this.id = '',
    required this.items,
    required this.status,
    required this.date
  });

  factory OrderEntity.fromJson(Map<String, dynamic> data) {
    return OrderEntity(
      userId: data['userId'],
      id: data['id'] = '',
      status: data['status'],
      items: (data['items'] as List<dynamic>)
          .map((item) => OrderItem.fromMap(item))
          .toList(),
      date: DateTime.parse(data['date']),
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'id': id,
    'status': status,
    'items': items.map((item) => item.toMap()).toList(),
    "date": date.toIso8601String(),
  };
}


//
// OrderItem
class OrderItem {
  final String name;
  final double quantity;

  OrderItem({required this.name, required this.quantity});

  factory OrderItem.fromMap(Map<String, dynamic> data) => OrderItem(
    name: data['name'],
    quantity: data['quantity'],
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'quantity': quantity,
  };
}

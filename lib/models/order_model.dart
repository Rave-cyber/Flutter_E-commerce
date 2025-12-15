import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentMethod {
  gcash,
  bankCard,
  grabPay,
}

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled,
}

class OrderItem {
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final int quantity;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'price': price,
      'quantity': quantity,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImage: map['productImage'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 1,
    );
  }

  double get total => price * quantity;
}

class OrderModel {
  final String id;
  final String userId;
  final String customerId;
  final List<OrderItem> items;
  final double subtotal;
  final double shipping;
  final double total;
  final PaymentMethod paymentMethod;
  final OrderStatus status;
  final String? shippingAddress;
  final String? contactNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;
<<<<<<< HEAD
  final String? deliveryProofImage;
  final String? deliveryNotes;
  final String? deliveryStaffId;
  final DateTime? deliveredAt;
=======
>>>>>>> 3add35312551b90752a2c004e342857fcb126663

  OrderModel({
    required this.id,
    required this.userId,
    required this.customerId,
    required this.items,
    required this.subtotal,
    required this.shipping,
    required this.total,
    required this.paymentMethod,
    this.status = OrderStatus.pending,
    this.shippingAddress,
    this.contactNumber,
    this.createdAt,
    this.updatedAt,
<<<<<<< HEAD
    this.deliveryProofImage,
    this.deliveryNotes,
    this.deliveryStaffId,
    this.deliveredAt,
=======
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
  });

  // Convert OrderModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'customerId': customerId,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'shipping': shipping,
      'total': total,
      'paymentMethod': paymentMethod.name,
      'status': status.name,
      'shippingAddress': shippingAddress,
      'contactNumber': contactNumber,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
<<<<<<< HEAD
      'deliveryProofImage': deliveryProofImage,
      'deliveryNotes': deliveryNotes,
      'deliveryStaffId': deliveryStaffId,
      'deliveredAt':
          deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
=======
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
    };
  }

  // Create OrderModel from Firestore Map
  factory OrderModel.fromMap(Map<String, dynamic> map, String docId) {
    return OrderModel(
      id: docId,
      userId: map['userId'] ?? '',
      customerId: map['customerId'] ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (map['subtotal'] ?? 0.0).toDouble(),
      shipping: (map['shipping'] ?? 0.0).toDouble(),
      total: (map['total'] ?? 0.0).toDouble(),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == map['paymentMethod'],
        orElse: () => PaymentMethod.gcash,
      ),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      shippingAddress: map['shippingAddress'],
      contactNumber: map['contactNumber'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
<<<<<<< HEAD
      deliveryProofImage: map['deliveryProofImage'],
      deliveryNotes: map['deliveryNotes'],
      deliveryStaffId: map['deliveryStaffId'],
      deliveredAt: (map['deliveredAt'] as Timestamp?)?.toDate(),
    );
  }
}
=======
    );
  }
}

>>>>>>> 3add35312551b90752a2c004e342857fcb126663

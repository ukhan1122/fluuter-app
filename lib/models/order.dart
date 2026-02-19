class Order {
  final int? id;
  final String orderNumber;
  final String customerName;
  final String phone;
  final String email;
  final String shippingAddress;
  final String city;
  final double subtotal;
  final double deliveryCharge;
  final double total;
  final String paymentMethod;
  final String deliveryOption;
  final String status;
  final DateTime createdAt;
  final List<OrderItem> items;

  Order({
    this.id,
    required this.orderNumber,
    required this.customerName,
    required this.phone,
    required this.email,
    required this.shippingAddress,
    required this.city,
    required this.subtotal,
    required this.deliveryCharge,
    required this.total,
    required this.paymentMethod,
    required this.deliveryOption,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      orderNumber: json['order_number'] ?? '',
      customerName: json['customer_name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      shippingAddress: json['shipping_address'] ?? json['address'] ?? '',
      city: json['city'] ?? '',
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      deliveryCharge: (json['delivery_charge'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      paymentMethod: json['payment_method'] ?? '',
      deliveryOption: json['delivery_option'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      items: (json['items'] as List? ?? [])
          .map((item) => OrderItem.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_number': orderNumber,
      'customer_name': customerName,
      'phone': phone,
      'email': email,
      'shipping_address': shippingAddress,
      'city': city,
      'subtotal': subtotal,
      'delivery_charge': deliveryCharge,
      'total': total,
      'payment_method': paymentMethod,
      'delivery_option': deliveryOption,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class OrderItem {
  final int productId;
  final String productTitle;
  final String productImage;
  final double price;
  final int quantity;
  final double total;

  OrderItem({
    required this.productId,
    required this.productTitle,
    required this.productImage,
    required this.price,
    required this.quantity,
    required this.total,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id'] ?? 0,
      productTitle: json['product_title'] ?? '',
      productImage: json['product_image'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
      total: (json['total'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_title': productTitle,
      'product_image': productImage,
      'price': price,
      'quantity': quantity,
      'total': total,
    };
  }
}
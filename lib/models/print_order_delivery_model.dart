import 'package:pms/models/print_order_model.dart';
import 'package:pms/models/user_model.dart';

class PrintOrderDeliveryModel {
  final int id;
  final String deliveryNumber;
  final int printOrderId;
  final String challanNumber;
  final String? deliveryDate;
  final int? receivedByUserId;
  final String? remarks;
  final String status; // partially_received, completed
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final PrintOrderModel? printOrder;
  final UserModel? receivedByUser;
  final List<PrintOrderDeliveryItemModel> items;

  PrintOrderDeliveryModel({
    required this.id,
    required this.deliveryNumber,
    required this.printOrderId,
    required this.challanNumber,
    this.deliveryDate,
    this.receivedByUserId,
    this.remarks,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.printOrder,
    this.receivedByUser,
    this.items = const [],
  });

  factory PrintOrderDeliveryModel.fromJson(Map<String, dynamic> json) {
    return PrintOrderDeliveryModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      deliveryNumber: json['delivery_number']?.toString() ?? '',
      printOrderId: json['print_order_id'] is int
          ? json['print_order_id']
          : int.tryParse('${json['print_order_id']}') ?? 0,
      challanNumber: json['challan_number']?.toString() ?? '',
      deliveryDate: json['delivery_date']?.toString(),
      receivedByUserId: json['received_by_user_id'] != null
          ? int.tryParse('${json['received_by_user_id']}')
          : null,
      remarks: json['remarks']?.toString(),
      status: json['status']?.toString() ?? 'partially_received',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      printOrder:
          json['print_order'] != null &&
              json['print_order'] is Map<String, dynamic>
          ? PrintOrderModel.fromJson(json['print_order'])
          : null,
      receivedByUser:
          json['received_by_user'] != null &&
              json['received_by_user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['received_by_user'])
          : null,
      items: json['items'] != null && json['items'] is List
          ? (json['items'] as List)
                .map(
                  (i) => PrintOrderDeliveryItemModel.fromJson(
                    i as Map<String, dynamic>,
                  ),
                )
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'delivery_number': deliveryNumber,
      'print_order_id': printOrderId,
      'challan_number': challanNumber,
      'delivery_date': deliveryDate,
      'received_by_user_id': receivedByUserId,
      'remarks': remarks,
      'status': status,
    };
  }
}

class PrintOrderDeliveryItemModel {
  final int id;
  final int printOrderDeliveryId;
  final int printOrderItemId;
  final String productName;
  final int orderedQuantity;
  final int receivedQuantity;
  final int totalReceivedToDate;
  final String? size;
  final String? attachmentPath;

  PrintOrderDeliveryItemModel({
    required this.id,
    required this.printOrderDeliveryId,
    required this.printOrderItemId,
    required this.productName,
    required this.orderedQuantity,
    required this.receivedQuantity,
    required this.totalReceivedToDate,
    this.size,
    this.attachmentPath,
  });

  factory PrintOrderDeliveryItemModel.fromJson(Map<String, dynamic> json) {
    return PrintOrderDeliveryItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      printOrderDeliveryId: json['print_order_delivery_id'] is int
          ? json['print_order_delivery_id']
          : int.tryParse('${json['print_order_delivery_id']}') ?? 0,
      printOrderItemId: json['print_order_item_id'] is int
          ? json['print_order_item_id']
          : int.tryParse('${json['print_order_item_id']}') ?? 0,
      productName: json['product_name']?.toString() ?? 'Item',
      orderedQuantity: json['ordered_quantity'] is int
          ? json['ordered_quantity']
          : int.tryParse('${json['ordered_quantity']}') ?? 1,
      receivedQuantity: json['received_quantity'] is int
          ? json['received_quantity']
          : int.tryParse('${json['received_quantity']}') ?? 0,
      totalReceivedToDate: json['total_received_to_date'] is int
          ? json['total_received_to_date']
          : int.tryParse('${json['total_received_to_date']}') ?? 0,
      size: json['size']?.toString(),
      attachmentPath: json['attachment_path']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'print_order_delivery_id': printOrderDeliveryId,
      'print_order_item_id': printOrderItemId,
      'product_name': productName,
      'ordered_quantity': orderedQuantity,
      'received_quantity': receivedQuantity,
      'total_received_to_date': totalReceivedToDate,
      'size': size,
      'attachment_path': attachmentPath,
    };
  }
}

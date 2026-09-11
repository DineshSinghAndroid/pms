import 'package:pms/models/purchase_request_model.dart';
import 'package:pms/models/vendor_model.dart';
import 'package:pms/models/wing_model.dart';

class PrintOrderModel {
  final int id;
  final String poNumber;
  final int? purchaseRequestId;
  final int vendorId;
  final int? wingId;
  final int? createdByUserId;
  final String? expectedDeliveryDate;
  final String? expectedDeliveryTime;
  final String? requesterRemarks;
  final String? printOrderRemarks;
  final String status;
  final DateTime? acceptedAt;
  final DateTime? dispatchedAt;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final VendorModel? vendor;
  final WingModel? wing;
  final PurchaseRequestModel? purchaseRequest;
  final List<PrintOrderItemModel> items;
  final List<PrintOrderActivityModel> activities;

  PrintOrderModel({
    required this.id,
    required this.poNumber,
    this.purchaseRequestId,
    required this.vendorId,
    this.wingId,
    this.createdByUserId,
    this.expectedDeliveryDate,
    this.expectedDeliveryTime,
    this.requesterRemarks,
    this.printOrderRemarks,
    required this.status,
    this.acceptedAt,
    this.dispatchedAt,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
    this.vendor,
    this.wing,
    this.purchaseRequest,
    this.items = const [],
    this.activities = const [],
  });

  factory PrintOrderModel.fromJson(Map<String, dynamic> json) {
    return PrintOrderModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      poNumber: json['po_number']?.toString() ?? '',
      purchaseRequestId: json['purchase_request_id'] != null
          ? int.tryParse('${json['purchase_request_id']}')
          : null,
      vendorId: json['vendor_id'] is int
          ? json['vendor_id']
          : int.tryParse('${json['vendor_id']}') ?? 0,
      wingId: json['wing_id'] != null
          ? int.tryParse('${json['wing_id']}')
          : null,
      createdByUserId: json['created_by_user_id'] != null
          ? int.tryParse('${json['created_by_user_id']}')
          : null,
      expectedDeliveryDate: json['expected_delivery_date']?.toString(),
      expectedDeliveryTime: json['expected_delivery_time']?.toString(),
      requesterRemarks: json['requester_remarks']?.toString(),
      printOrderRemarks: json['print_order_remarks']?.toString(),
      status: json['status']?.toString() ?? 'in_production',
      acceptedAt: json['accepted_at'] != null
          ? DateTime.tryParse(json['accepted_at'].toString())
          : null,
      dispatchedAt: json['dispatched_at'] != null
          ? DateTime.tryParse(json['dispatched_at'].toString())
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      vendor: json['vendor'] != null && json['vendor'] is Map<String, dynamic>
          ? VendorModel.fromJson(json['vendor'])
          : null,
      wing: json['wing'] != null && json['wing'] is Map<String, dynamic>
          ? WingModel.fromJson(json['wing'])
          : null,
      purchaseRequest:
          json['purchase_request'] != null &&
              json['purchase_request'] is Map<String, dynamic>
          ? PurchaseRequestModel.fromJson(json['purchase_request'])
          : null,
      items: json['items'] != null && json['items'] is List
          ? (json['items'] as List)
                .map(
                  (i) =>
                      PrintOrderItemModel.fromJson(i as Map<String, dynamic>),
                )
                .toList()
          : [],
      activities: json['activities'] != null && json['activities'] is List
          ? (json['activities'] as List)
                .map(
                  (a) => PrintOrderActivityModel.fromJson(
                    a as Map<String, dynamic>,
                  ),
                )
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'po_number': poNumber,
      'purchase_request_id': purchaseRequestId,
      'vendor_id': vendorId,
      'wing_id': wingId,
      'created_by_user_id': createdByUserId,
      'expected_delivery_date': expectedDeliveryDate,
      'expected_delivery_time': expectedDeliveryTime,
      'requester_remarks': requesterRemarks,
      'print_order_remarks': printOrderRemarks,
      'status': status,
      'accepted_at': acceptedAt?.toIso8601String(),
      'dispatched_at': dispatchedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get isFullyReceived {
    if (isCompleted) return true;
    if (items.isNotEmpty &&
        items.every((it) => it.receivedQuantity >= it.quantity)) {
      return true;
    }
    return false;
  }
}

class PrintOrderItemModel {
  final int id;
  final int printOrderId;
  final int? productTypeId;
  final String productName;
  final int quantity;
  final int receivedQuantity;
  final String? size;
  final String? attachmentPath;
  final String? attachmentName;

  PrintOrderItemModel({
    required this.id,
    required this.printOrderId,
    this.productTypeId,
    required this.productName,
    required this.quantity,
    this.receivedQuantity = 0,
    this.size,
    this.attachmentPath,
    this.attachmentName,
  });

  factory PrintOrderItemModel.fromJson(Map<String, dynamic> json) {
    return PrintOrderItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      printOrderId: json['print_order_id'] is int
          ? json['print_order_id']
          : int.tryParse('${json['print_order_id']}') ?? 0,
      productTypeId: json['product_type_id'] != null
          ? int.tryParse('${json['product_type_id']}')
          : null,
      productName: json['product_name']?.toString() ?? 'Printing Item',
      quantity: json['quantity'] is int
          ? json['quantity']
          : int.tryParse('${json['quantity']}') ?? 1,
      receivedQuantity: json['received_quantity'] is int
          ? json['received_quantity']
          : int.tryParse('${json['received_quantity']}') ?? 0,
      size: json['size']?.toString(),
      attachmentPath: json['attachment_path']?.toString(),
      attachmentName: json['attachment_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'print_order_id': printOrderId,
      'product_type_id': productTypeId,
      'product_name': productName,
      'quantity': quantity,
      'received_quantity': receivedQuantity,
      'size': size,
      'attachment_path': attachmentPath,
      'attachment_name': attachmentName,
    };
  }
}

class PrintOrderActivityModel {
  final int id;
  final int printOrderId;
  final int? userId;
  final String action;
  final String? remarks;
  final String? attachmentPath;
  final String? attachmentName;
  final DateTime? createdAt;

  PrintOrderActivityModel({
    required this.id,
    required this.printOrderId,
    this.userId,
    required this.action,
    this.remarks,
    this.attachmentPath,
    this.attachmentName,
    this.createdAt,
  });

  factory PrintOrderActivityModel.fromJson(Map<String, dynamic> json) {
    return PrintOrderActivityModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      printOrderId: json['print_order_id'] is int
          ? json['print_order_id']
          : int.tryParse('${json['print_order_id']}') ?? 0,
      userId: json['user_id'] != null
          ? int.tryParse('${json['user_id']}')
          : null,
      action: json['action']?.toString() ?? '',
      remarks: json['remarks']?.toString(),
      attachmentPath: json['attachment_path']?.toString(),
      attachmentName: json['attachment_name']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

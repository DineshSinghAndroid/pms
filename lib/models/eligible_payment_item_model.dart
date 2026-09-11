class ReceivingHistoryEntry {
  final String? deliveryNumber;
  final String challanNumber;
  final String deliveryDate;
  final int receivedQuantity;
  final int totalReceivedToDate;
  final String receiverName;
  final String? remarks;
  final String formattedEntry;

  ReceivingHistoryEntry({
    this.deliveryNumber,
    required this.challanNumber,
    required this.deliveryDate,
    required this.receivedQuantity,
    required this.totalReceivedToDate,
    required this.receiverName,
    this.remarks,
    required this.formattedEntry,
  });

  factory ReceivingHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ReceivingHistoryEntry(
      deliveryNumber: json['delivery_number']?.toString(),
      challanNumber: json['challan_number']?.toString() ?? 'N/A',
      deliveryDate: json['delivery_date']?.toString() ?? '',
      receivedQuantity: json['received_quantity'] is int
          ? json['received_quantity']
          : int.tryParse('${json['received_quantity']}') ?? 0,
      totalReceivedToDate: json['total_received_to_date'] is int
          ? json['total_received_to_date']
          : int.tryParse('${json['total_received_to_date']}') ?? 0,
      receiverName: json['receiver_name']?.toString() ?? 'Administrator',
      remarks: json['remarks']?.toString(),
      formattedEntry: json['formatted_entry']?.toString() ?? '',
    );
  }
}

class EligibleOrderItemProduct {
  final int id;
  final String productName;
  final String productCode;
  final int quantity;
  final int receivedQuantity;
  final int pendingQuantity;
  final bool isFullyReceived;
  final String? size;
  final String? attachmentPath;
  final String? attachmentName;

  EligibleOrderItemProduct({
    required this.id,
    required this.productName,
    required this.productCode,
    required this.quantity,
    required this.receivedQuantity,
    required this.pendingQuantity,
    required this.isFullyReceived,
    this.size,
    this.attachmentPath,
    this.attachmentName,
  });

  factory EligibleOrderItemProduct.fromJson(Map<String, dynamic> json) {
    return EligibleOrderItemProduct(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      productName: json['product_name']?.toString() ?? 'Product',
      productCode: json['product_code']?.toString() ?? '',
      quantity: json['quantity'] is int
          ? json['quantity']
          : int.tryParse('${json['quantity']}') ?? 1,
      receivedQuantity: json['received_quantity'] is int
          ? json['received_quantity']
          : int.tryParse('${json['received_quantity']}') ?? 0,
      pendingQuantity: json['pending_quantity'] is int
          ? json['pending_quantity']
          : int.tryParse('${json['pending_quantity']}') ?? 0,
      isFullyReceived: json['is_fully_received'] == true,
      size: json['size']?.toString(),
      attachmentPath: json['attachment_path']?.toString(),
      attachmentName: json['attachment_name']?.toString(),
    );
  }
}

class EligiblePaymentItemModel {
  final int id;
  final int printOrderId;
  final String poNumber;
  final String poStatus;
  final int? purchaseRequestId;
  final String prNumber;
  final int? vendorId;
  final String vendorName;
  final int? wingId;
  final String wingName;
  final int? productTypeId;
  final String productCode;
  final String productName;
  final int quantity;
  final int receivedQuantity;
  final int pendingQuantity;
  final bool isFullyReceived;
  final bool isFullyCompleted;
  final String receivingStatus; // completed, partially_received, not_received
  final int itemsCount;
  final int fullyReceivedItemsCount;
  final int totalOrderedQuantity;
  final int totalReceivedQuantity;
  final int totalPendingQuantity;
  final String? size;
  final String? attachmentPath;
  final String? attachmentName;
  final String? requesterRemarks;
  final String? printOrderRemarks;
  final List<EligibleOrderItemProduct> items;
  final List<ReceivingHistoryEntry> receivingHistory;
  final String? createdAt;

  EligiblePaymentItemModel({
    required this.id,
    required this.printOrderId,
    required this.poNumber,
    required this.poStatus,
    this.purchaseRequestId,
    required this.prNumber,
    this.vendorId,
    required this.vendorName,
    this.wingId,
    required this.wingName,
    this.productTypeId,
    required this.productCode,
    required this.productName,
    required this.quantity,
    required this.receivedQuantity,
    required this.pendingQuantity,
    required this.isFullyReceived,
    required this.isFullyCompleted,
    required this.receivingStatus,
    this.itemsCount = 1,
    this.fullyReceivedItemsCount = 0,
    this.totalOrderedQuantity = 1,
    this.totalReceivedQuantity = 0,
    this.totalPendingQuantity = 0,
    this.size,
    this.attachmentPath,
    this.attachmentName,
    this.requesterRemarks,
    this.printOrderRemarks,
    this.items = const [],
    this.receivingHistory = const [],
    this.createdAt,
  });

  factory EligiblePaymentItemModel.fromJson(Map<String, dynamic> json) {
    final parsedItems = json['items'] != null && json['items'] is List
        ? (json['items'] as List)
            .map((e) => EligibleOrderItemProduct.fromJson(e as Map<String, dynamic>))
            .toList()
        : <EligibleOrderItemProduct>[];

    final parsedHistory = json['receiving_history'] != null && json['receiving_history'] is List
        ? (json['receiving_history'] as List)
            .map((e) => ReceivingHistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList()
        : (json['delivery_logs'] != null && json['delivery_logs'] is List
            ? (json['delivery_logs'] as List)
                .map((e) => ReceivingHistoryEntry.fromJson(e as Map<String, dynamic>))
                .toList()
            : <ReceivingHistoryEntry>[]);

    final isComplete = json['is_fully_completed'] == true || json['is_fully_received'] == true;
    final totalOrd = json['total_ordered_quantity'] is int
        ? json['total_ordered_quantity']
        : int.tryParse('${json['total_ordered_quantity']}') ?? (json['quantity'] is int ? json['quantity'] : int.tryParse('${json['quantity']}') ?? 1);
    final totalRec = json['total_received_quantity'] is int
        ? json['total_received_quantity']
        : int.tryParse('${json['total_received_quantity']}') ?? (json['received_quantity'] is int ? json['received_quantity'] : int.tryParse('${json['received_quantity']}') ?? 0);

    final firstItem = parsedItems.isNotEmpty ? parsedItems.first : null;

    return EligiblePaymentItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      printOrderId: json['print_order_id'] is int
          ? json['print_order_id']
          : int.tryParse('${json['print_order_id']}') ?? 0,
      poNumber: json['po_number']?.toString() ?? 'PO-N/A',
      poStatus: json['po_status']?.toString() ?? 'unknown',
      purchaseRequestId: json['purchase_request_id'] != null
          ? int.tryParse('${json['purchase_request_id']}')
          : null,
      prNumber: json['pr_number']?.toString() ?? 'PR-N/A',
      vendorId: json['vendor_id'] != null
          ? int.tryParse('${json['vendor_id']}')
          : null,
      vendorName: json['vendor_name']?.toString() ?? 'Vendor',
      wingId: json['wing_id'] != null
          ? int.tryParse('${json['wing_id']}')
          : null,
      wingName: json['wing_name']?.toString() ?? 'Wing',
      productTypeId: json['product_type_id'] != null
          ? int.tryParse('${json['product_type_id']}')
          : null,
      productCode: json['product_code']?.toString() ?? (firstItem?.productCode ?? ''),
      productName: json['product_name']?.toString() ?? (firstItem?.productName ?? 'Print Order'),
      quantity: totalOrd,
      receivedQuantity: totalRec,
      pendingQuantity: json['total_pending_quantity'] is int
          ? json['total_pending_quantity']
          : int.tryParse('${json['total_pending_quantity']}') ?? (json['pending_quantity'] is int ? json['pending_quantity'] : 0),
      isFullyReceived: isComplete,
      isFullyCompleted: isComplete,
      receivingStatus: json['receiving_status']?.toString() ?? 'not_received',
      itemsCount: json['items_count'] is int
          ? json['items_count']
          : int.tryParse('${json['items_count']}') ?? parsedItems.length,
      fullyReceivedItemsCount: json['fully_received_items_count'] is int
          ? json['fully_received_items_count']
          : int.tryParse('${json['fully_received_items_count']}') ?? 0,
      totalOrderedQuantity: totalOrd,
      totalReceivedQuantity: totalRec,
      totalPendingQuantity: max(0, totalOrd - totalRec),
      size: json['size']?.toString() ?? firstItem?.size,
      attachmentPath: json['attachment_path']?.toString() ?? firstItem?.attachmentPath,
      attachmentName: json['attachment_name']?.toString() ?? firstItem?.attachmentName,
      requesterRemarks: json['requester_remarks']?.toString(),
      printOrderRemarks: json['print_order_remarks']?.toString(),
      items: parsedItems,
      receivingHistory: parsedHistory,
      createdAt: json['created_at']?.toString(),
    );
  }
}

int max(int a, int b) => a > b ? a : b;

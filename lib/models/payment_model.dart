import 'package:pms/models/print_order_model.dart';
import 'package:pms/models/user_model.dart';
import 'package:pms/models/vendor_model.dart';
import 'package:pms/models/wing_model.dart';

class PaymentLifecycleStage {
  final String stage;
  final String title;
  final String? date;
  final String status;
  final Map<String, dynamic> details;

  PaymentLifecycleStage({
    required this.stage,
    required this.title,
    this.date,
    required this.status,
    this.details = const {},
  });

  factory PaymentLifecycleStage.fromJson(Map<String, dynamic> json) {
    return PaymentLifecycleStage(
      stage: json['stage']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      date: json['date']?.toString(),
      status: json['status']?.toString() ?? 'completed',
      details: json['details'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['details'])
          : {},
    );
  }
}

class ProductPaymentModel {
  final int id;
  final String paymentNumber;
  final int? printOrderItemId;
  final int printOrderId;
  final String poNumber;
  final int? vendorId;
  final int? wingId;
  final String invoiceNumber;
  final String? paymentDate;
  final double? amount;
  final String? paymentMethod;
  final String? transactionReference;
  final String? remarks;
  final int? paidByUserId;
  final String? paidByUserName;
  final DateTime? createdAt;
  final UserModel? paidByUser;
  final VendorModel? vendor;
  final WingModel? wing;
  final PrintOrderModel? printOrder;
  final PrintOrderItemModel? printOrderItem;
  final int itemsCount;
  final int totalOrderedQuantity;
  final int totalReceivedQuantity;
  final String productsSummary;
  final List<dynamic> items;
  final List<PaymentLifecycleStage> lifecycle;

  ProductPaymentModel({
    required this.id,
    required this.paymentNumber,
    this.printOrderItemId,
    required this.printOrderId,
    required this.poNumber,
    this.vendorId,
    this.wingId,
    required this.invoiceNumber,
    this.paymentDate,
    this.amount,
    this.paymentMethod,
    this.transactionReference,
    this.remarks,
    this.paidByUserId,
    this.paidByUserName,
    this.createdAt,
    this.paidByUser,
    this.vendor,
    this.wing,
    this.printOrder,
    this.printOrderItem,
    this.itemsCount = 1,
    this.totalOrderedQuantity = 0,
    this.totalReceivedQuantity = 0,
    this.productsSummary = '',
    this.items = const [],
    this.lifecycle = const [],
  });

  factory ProductPaymentModel.fromJson(Map<String, dynamic> json) {
    double? parseAmount(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString());
    }

    final poMap = json['print_order'] is Map<String, dynamic>
        ? json['print_order'] as Map<String, dynamic>
        : null;

    final poNum = json['po_number']?.toString() ??
        poMap?['po_number']?.toString() ??
        'PO-N/A';

    final itemsList = json['items'] is List
        ? json['items'] as List
        : (poMap?['items'] is List ? poMap!['items'] as List : []);

    final summary = json['products_summary']?.toString() ??
        itemsList.map((x) => x['product_name']?.toString() ?? '').where((s) => s.isNotEmpty).join(', ');

    return ProductPaymentModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      paymentNumber: json['payment_number']?.toString() ?? 'PAY-N/A',
      printOrderItemId: json['print_order_item_id'] != null
          ? int.tryParse('${json['print_order_item_id']}')
          : null,
      printOrderId: json['print_order_id'] is int
          ? json['print_order_id']
          : int.tryParse('${json['print_order_id']}') ?? 0,
      poNumber: poNum,
      vendorId: json['vendor_id'] != null
          ? int.tryParse('${json['vendor_id']}')
          : null,
      wingId: json['wing_id'] != null ? int.tryParse('${json['wing_id']}') : null,
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      paymentDate: json['payment_date']?.toString(),
      amount: parseAmount(json['amount']),
      paymentMethod: json['payment_method']?.toString() ?? 'Bank Transfer',
      transactionReference: json['transaction_reference']?.toString(),
      remarks: json['remarks']?.toString(),
      paidByUserId: json['paid_by_user_id'] != null
          ? int.tryParse('${json['paid_by_user_id']}')
          : null,
      paidByUserName: json['paid_by_user_name']?.toString() ??
          (json['paid_by_user'] is Map ? json['paid_by_user']['name']?.toString() : null),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      paidByUser: json['paid_by_user'] != null &&
              json['paid_by_user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['paid_by_user'])
          : null,
      vendor: json['vendor'] != null && json['vendor'] is Map<String, dynamic>
          ? VendorModel.fromJson(json['vendor'])
          : (poMap?['vendor'] is Map<String, dynamic>
              ? VendorModel.fromJson(poMap!['vendor'])
              : null),
      wing: json['wing'] != null && json['wing'] is Map<String, dynamic>
          ? WingModel.fromJson(json['wing'])
          : (poMap?['wing'] is Map<String, dynamic>
              ? WingModel.fromJson(poMap!['wing'])
              : null),
      printOrder: poMap != null ? PrintOrderModel.fromJson(poMap) : null,
      printOrderItem: json['print_order_item'] != null &&
              json['print_order_item'] is Map<String, dynamic>
          ? PrintOrderItemModel.fromJson(json['print_order_item'])
          : null,
      itemsCount: json['items_count'] is int
          ? json['items_count']
          : int.tryParse('${json['items_count']}') ?? itemsList.length,
      totalOrderedQuantity: json['total_ordered_quantity'] is int
          ? json['total_ordered_quantity']
          : int.tryParse('${json['total_ordered_quantity']}') ?? 0,
      totalReceivedQuantity: json['total_received_quantity'] is int
          ? json['total_received_quantity']
          : int.tryParse('${json['total_received_quantity']}') ?? 0,
      productsSummary: summary,
      items: itemsList,
      lifecycle: json['lifecycle'] != null && json['lifecycle'] is List
          ? (json['lifecycle'] as List)
              .map((l) => PaymentLifecycleStage.fromJson(l as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}

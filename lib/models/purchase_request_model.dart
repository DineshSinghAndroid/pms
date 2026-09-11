import 'package:equatable/equatable.dart';

import 'print_order_model.dart';
import 'product_type_model.dart';
import 'user_model.dart';
import 'wing_model.dart';

class PurchaseRequestActivityModel extends Equatable {
  final int id;
  final int purchaseRequestId;
  final int? userId;
  final String action;
  final String? remarks;
  final String? attachmentPath;
  final String? attachmentName;
  final UserModel? user;
  final DateTime? createdAt;

  const PurchaseRequestActivityModel({
    required this.id,
    required this.purchaseRequestId,
    this.userId,
    required this.action,
    this.remarks,
    this.attachmentPath,
    this.attachmentName,
    this.user,
    this.createdAt,
  });

  factory PurchaseRequestActivityModel.fromJson(Map<String, dynamic> json) {
    return PurchaseRequestActivityModel(
      id: json['id'] as int? ?? 0,
      purchaseRequestId: json['purchase_request_id'] as int? ?? 0,
      userId: json['user_id'] as int?,
      action: json['action'] as String? ?? 'activity',
      remarks: json['remarks'] as String?,
      attachmentPath: json['attachment_path'] as String?,
      attachmentName: json['attachment_name'] as String?,
      user: json['user'] != null && json['user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'purchase_request_id': purchaseRequestId,
      'user_id': userId,
      'action': action,
      'remarks': remarks,
      'attachment_path': attachmentPath,
      'attachment_name': attachmentName,
    };
  }

  @override
  List<Object?> get props => [
    id,
    purchaseRequestId,
    userId,
    action,
    remarks,
    attachmentPath,
    attachmentName,
    user,
    createdAt,
  ];
}

class PurchaseRequestItemModel extends Equatable {
  final int id;
  final int purchaseRequestId;
  final int? productTypeId;
  final String productName;
  final int quantity;
  final String? size;
  final String? attachmentPath;
  final String? attachmentName;
  final ProductTypeModel? productType;
  final DateTime? createdAt;

  const PurchaseRequestItemModel({
    required this.id,
    required this.purchaseRequestId,
    this.productTypeId,
    required this.productName,
    required this.quantity,
    this.size,
    this.attachmentPath,
    this.attachmentName,
    this.productType,
    this.createdAt,
  });

  factory PurchaseRequestItemModel.fromJson(Map<String, dynamic> json) {
    return PurchaseRequestItemModel(
      id: json['id'] as int? ?? 0,
      purchaseRequestId: json['purchase_request_id'] as int? ?? 0,
      productTypeId: json['product_type_id'] as int?,
      productName: json['product_name'] as String? ?? 'Product',
      quantity: json['quantity'] as int? ?? 1,
      size: json['size'] as String?,
      attachmentPath: json['attachment_path'] as String?,
      attachmentName: json['attachment_name'] as String?,
      productType:
          json['product_type'] != null &&
              json['product_type'] is Map<String, dynamic>
          ? ProductTypeModel.fromJson(
              json['product_type'] as Map<String, dynamic>,
            )
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'purchase_request_id': purchaseRequestId,
      'product_type_id': productTypeId,
      'product_name': productName,
      'quantity': quantity,
      'size': size,
      'attachment_path': attachmentPath,
      'attachment_name': attachmentName,
    };
  }

  @override
  List<Object?> get props => [
    id,
    purchaseRequestId,
    productTypeId,
    productName,
    quantity,
    size,
    attachmentPath,
    attachmentName,
    productType,
    createdAt,
  ];
}

class PurchaseRequestModel extends Equatable {
  final int id;
  final String prNumber;
  final int? wingId;
  final int? assignedDesignerId;
  final int? createdByUserId;
  final String? expectedDeliveryDate;
  final String? expectedDeliveryTime;
  final String status;
  final DateTime? workStartedAt;
  final int? workStartedByUserId;
  final DateTime? submittedAt;
  final String? artworkFilePath;
  final String? artworkFileName;
  final String? designerSubmissionRemarks;
  final DateTime? approvedAt;
  final int? approvedByUserId;
  final String? adminReviewRemarks;
  final int revisionCount;
  final bool isPosted;
  final DateTime? postedAt;
  final int? postedByUserId;
  final String? postRemarks;
  final UserModel? postedByUser;
  final PrintOrderModel? activePrintOrder;
  final List<PrintOrderModel> printOrders;
  final String? remarks;
  final WingModel? wing;
  final UserModel? assignedDesigner;
  final UserModel? createdByUser;
  final UserModel? workStartedByUser;
  final UserModel? approvedByUser;
  final List<PurchaseRequestItemModel> items;
  final List<PurchaseRequestActivityModel> activities;
  final DateTime? createdAt;

  const PurchaseRequestModel({
    required this.id,
    required this.prNumber,
    this.wingId,
    this.assignedDesignerId,
    this.createdByUserId,
    this.expectedDeliveryDate,
    this.expectedDeliveryTime,
    required this.status,
    this.workStartedAt,
    this.workStartedByUserId,
    this.submittedAt,
    this.artworkFilePath,
    this.artworkFileName,
    this.designerSubmissionRemarks,
    this.approvedAt,
    this.approvedByUserId,
    this.adminReviewRemarks,
    this.revisionCount = 0,
    this.isPosted = false,
    this.postedAt,
    this.postedByUserId,
    this.postRemarks,
    this.postedByUser,
    this.activePrintOrder,
    this.printOrders = const [],
    this.remarks,
    this.wing,
    this.assignedDesigner,
    this.createdByUser,
    this.workStartedByUser,
    this.approvedByUser,
    this.items = const [],
    this.activities = const [],
    this.createdAt,
  });

  factory PurchaseRequestModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'];
    List<PurchaseRequestItemModel> itemsList = [];
    if (rawItems is List) {
      itemsList = rawItems
          .map(
            (it) =>
                PurchaseRequestItemModel.fromJson(it as Map<String, dynamic>),
          )
          .toList();
    }

    var rawActivities = json['activities'];
    List<PurchaseRequestActivityModel> activitiesList = [];
    if (rawActivities is List) {
      activitiesList = rawActivities
          .map(
            (act) => PurchaseRequestActivityModel.fromJson(
              act as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    var rawPrintOrders = json['print_orders'];
    List<PrintOrderModel> printOrdersList = [];
    if (rawPrintOrders is List) {
      printOrdersList = rawPrintOrders
          .map((po) => PrintOrderModel.fromJson(po as Map<String, dynamic>))
          .toList();
    }

    PrintOrderModel? activePO;
    if (json['active_print_order'] != null &&
        json['active_print_order'] is Map<String, dynamic>) {
      activePO = PrintOrderModel.fromJson(
        json['active_print_order'] as Map<String, dynamic>,
      );
    } else if (printOrdersList.isNotEmpty) {
      activePO = printOrdersList
          .where((po) => po.status != 'cancelled')
          .firstOrNull;
    }

    return PurchaseRequestModel(
      id: json['id'] as int? ?? 0,
      prNumber: json['pr_number'] as String? ?? 'PR-0000',
      wingId: json['wing_id'] as int?,
      assignedDesignerId: json['assigned_designer_id'] as int?,
      createdByUserId: json['created_by_user_id'] as int?,
      expectedDeliveryDate: json['expected_delivery_date'] as String?,
      expectedDeliveryTime: json['expected_delivery_time'] as String?,
      status: json['status'] as String? ?? 'pending_assignment',
      workStartedAt: json['work_started_at'] != null
          ? DateTime.tryParse(json['work_started_at'].toString())
          : null,
      workStartedByUserId: json['work_started_by_user_id'] as int?,
      submittedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'].toString())
          : null,
      artworkFilePath: json['artwork_file_path'] as String?,
      artworkFileName: json['artwork_file_name'] as String?,
      designerSubmissionRemarks: json['designer_submission_remarks'] as String?,
      approvedAt: json['approved_at'] != null
          ? DateTime.tryParse(json['approved_at'].toString())
          : null,
      approvedByUserId: json['approved_by_user_id'] as int?,
      adminReviewRemarks: json['admin_review_remarks'] as String?,
      revisionCount: json['revision_count'] as int? ?? 0,
      isPosted: json['is_posted'] == true || json['is_posted'] == 1,
      postedAt: json['posted_at'] != null
          ? DateTime.tryParse(json['posted_at'].toString())
          : null,
      postedByUserId: json['posted_by_user_id'] as int?,
      postRemarks: json['post_remarks'] as String?,
      postedByUser:
          json['posted_by_user'] != null &&
              json['posted_by_user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['posted_by_user'] as Map<String, dynamic>)
          : null,
      activePrintOrder: activePO,
      printOrders: printOrdersList,
      remarks: json['remarks'] as String?,
      wing: json['wing'] != null && json['wing'] is Map<String, dynamic>
          ? WingModel.fromJson(json['wing'] as Map<String, dynamic>)
          : null,
      assignedDesigner:
          json['assigned_designer'] != null &&
              json['assigned_designer'] is Map<String, dynamic>
          ? UserModel.fromJson(
              json['assigned_designer'] as Map<String, dynamic>,
            )
          : null,
      createdByUser:
          json['created_by_user'] != null &&
              json['created_by_user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['created_by_user'] as Map<String, dynamic>)
          : null,
      workStartedByUser:
          json['work_started_by_user'] != null &&
              json['work_started_by_user'] is Map<String, dynamic>
          ? UserModel.fromJson(
              json['work_started_by_user'] as Map<String, dynamic>,
            )
          : null,
      approvedByUser:
          json['approved_by_user'] != null &&
              json['approved_by_user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['approved_by_user'] as Map<String, dynamic>)
          : null,
      items: itemsList,
      activities: activitiesList,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pr_number': prNumber,
      'wing_id': wingId,
      'assigned_designer_id': assignedDesignerId,
      'created_by_user_id': createdByUserId,
      'expected_delivery_date': expectedDeliveryDate,
      'expected_delivery_time': expectedDeliveryTime,
      'status': status,
      'work_started_at': workStartedAt?.toIso8601String(),
      'work_started_by_user_id': workStartedByUserId,
      'submitted_at': submittedAt?.toIso8601String(),
      'artwork_file_path': artworkFilePath,
      'artwork_file_name': artworkFileName,
      'designer_submission_remarks': designerSubmissionRemarks,
      'approved_at': approvedAt?.toIso8601String(),
      'approved_by_user_id': approvedByUserId,
      'admin_review_remarks': adminReviewRemarks,
      'revision_count': revisionCount,
      'is_posted': isPosted,
      'posted_at': postedAt?.toIso8601String(),
      'posted_by_user_id': postedByUserId,
      'post_remarks': postRemarks,
      'remarks': remarks,
      'items': items.map((it) => it.toJson()).toList(),
      'activities': activities.map((act) => act.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    prNumber,
    wingId,
    assignedDesignerId,
    createdByUserId,
    expectedDeliveryDate,
    expectedDeliveryTime,
    status,
    workStartedAt,
    workStartedByUserId,
    submittedAt,
    artworkFilePath,
    artworkFileName,
    designerSubmissionRemarks,
    approvedAt,
    approvedByUserId,
    adminReviewRemarks,
    revisionCount,
    isPosted,
    postedAt,
    postedByUserId,
    postRemarks,
    postedByUser,
    activePrintOrder,
    printOrders,
    remarks,
    wing,
    assignedDesigner,
    createdByUser,
    workStartedByUser,
    approvedByUser,
    items,
    activities,
    createdAt,
  ];
}

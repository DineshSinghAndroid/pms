import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:pms/models/print_order_delivery_model.dart';
import 'package:pms/models/print_order_model.dart';
import 'package:pms/services/api_service.dart';

class CreatePrintOrderItemParam {
  final int? productTypeId;
  final String productName;
  final int quantity;
  final String? size;
  final String? attachmentPath;
  final String? attachmentName;
  final List<int>? fileBytes;

  CreatePrintOrderItemParam({
    this.productTypeId,
    required this.productName,
    required this.quantity,
    this.size,
    this.attachmentPath,
    this.attachmentName,
    this.fileBytes,
  });
}

class PrintOrderRepository {
  final ApiService _apiService;

  PrintOrderRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  Future<List<PrintOrderModel>> getPrintOrders({
    String? phone,
    int? vendorId,
    int? wingId,
    String? status,
    String? search,
    int? purchaseRequestId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (phone != null && phone.isNotEmpty) queryParams['phone'] = phone;
      if (vendorId != null) queryParams['vendor_id'] = vendorId;
      if (wingId != null) queryParams['wing_id'] = wingId;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (purchaseRequestId != null) {
        queryParams['purchase_request_id'] = purchaseRequestId;
      }

      final response = await _apiService.client.get(
        '/api/print-orders',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final List<dynamic> list = body['data'] as List<dynamic>? ?? [];
        return list
            .map(
              (item) => PrintOrderModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }
      throw Exception('Failed to load print orders: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error loading print orders',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<PrintOrderModel> getPrintOrderDetails(int id) async {
    try {
      final response = await _apiService.client.get('/api/print-orders/$id');

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return PrintOrderModel.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw Exception(
        'Failed to load print order details: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error loading print order details',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<PrintOrderModel> createPrintOrder({
    required int vendorId,
    int? purchaseRequestId,
    int? wingId,
    String? expectedDeliveryDate,
    String? expectedDeliveryTime,
    String? requesterRemarks,
    String? printOrderRemarks,
    String? phone,
    required List<CreatePrintOrderItemParam> items,
  }) async {
    try {
      final formData = FormData();
      formData.fields.add(MapEntry('vendor_id', vendorId.toString()));
      if (purchaseRequestId != null) {
        formData.fields.add(
          MapEntry('purchase_request_id', purchaseRequestId.toString()),
        );
      }
      if (wingId != null) {
        formData.fields.add(MapEntry('wing_id', wingId.toString()));
      }
      if (expectedDeliveryDate != null) {
        formData.fields.add(
          MapEntry('expected_delivery_date', expectedDeliveryDate),
        );
      }
      if (expectedDeliveryTime != null) {
        formData.fields.add(
          MapEntry('expected_delivery_time', expectedDeliveryTime),
        );
      }
      if (requesterRemarks != null) {
        formData.fields.add(MapEntry('requester_remarks', requesterRemarks));
      }
      if (printOrderRemarks != null) {
        formData.fields.add(MapEntry('print_order_remarks', printOrderRemarks));
      }
      if (phone != null) {
        formData.fields.add(MapEntry('phone', phone));
      }

      for (int i = 0; i < items.length; i++) {
        final it = items[i];
        if (it.productTypeId != null) {
          formData.fields.add(
            MapEntry('items[$i][product_type_id]', it.productTypeId.toString()),
          );
        }
        formData.fields.add(
          MapEntry('items[$i][product_name]', it.productName),
        );
        formData.fields.add(
          MapEntry('items[$i][quantity]', it.quantity.toString()),
        );
        if (it.size != null && it.size!.isNotEmpty) {
          formData.fields.add(MapEntry('items[$i][size]', it.size!));
        }
        if (it.attachmentPath != null && it.attachmentPath!.isNotEmpty) {
          formData.fields.add(
            MapEntry('items[$i][attachment_path]', it.attachmentPath!),
          );
        }
        if (it.attachmentName != null && it.attachmentName!.isNotEmpty) {
          formData.fields.add(
            MapEntry('items[$i][attachment_name]', it.attachmentName!),
          );
        }

        if (it.fileBytes != null && it.fileBytes!.isNotEmpty) {
          final fName = it.attachmentName ?? 'item_$i.png';
          formData.files.add(
            MapEntry(
              'item_file_$i',
              MultipartFile.fromBytes(it.fileBytes!, filename: fName),
            ),
          );
          // Dual-channel base64 fallback
          formData.fields.add(
            MapEntry(
              'items[$i][attachment_base64]',
              base64Encode(it.fileBytes!),
            ),
          );
        }
      }

      final response = await _apiService.client.post(
        '/api/print-orders',
        data: formData,
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return PrintOrderModel.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to create print order: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error creating print order',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<PrintOrderModel> updatePrintOrderStatus(
    int poId, {
    required String status,
    String? remarks,
    String? phone,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    try {
      dynamic postData;
      if (fileBytes != null && fileBytes.isNotEmpty) {
        final fName =
            fileName ?? 'proof_${DateTime.now().millisecondsSinceEpoch}.png';
        final formData = FormData();
        formData.fields.add(MapEntry('status', status));
        if (remarks != null) formData.fields.add(MapEntry('remarks', remarks));
        if (phone != null) formData.fields.add(MapEntry('phone', phone));
        formData.files.add(
          MapEntry(
            'attachment',
            MultipartFile.fromBytes(fileBytes, filename: fName),
          ),
        );
        formData.fields.add(
          MapEntry('attachment_base64', base64Encode(fileBytes)),
        );
        formData.fields.add(MapEntry('attachment_name', fName));
        postData = formData;
      } else {
        postData = <String, dynamic>{
          'status': status,
          'remarks': ?remarks,
          'phone': ?phone,
        };
      }

      final response = await _apiService.client.post(
        '/api/print-orders/$poId/update-status',
        data: postData,
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return PrintOrderModel.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to update PO status: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error updating PO status',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<List<PrintOrderDeliveryModel>> getDeliveryLogs({
    String? status,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiService.client.get(
        '/api/delivery-logs',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final List<dynamic> list = body['data'] as List<dynamic>? ?? [];
        return list
            .map(
              (item) => PrintOrderDeliveryModel.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();
      }
      throw Exception('Failed to load delivery logs: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error loading delivery logs',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<Map<String, dynamic>> recordDelivery({
    required int printOrderId,
    required String challanNumber,
    String? deliveryDate,
    String? remarks,
    String? phone,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await _apiService.client.post(
        '/api/print-orders/$printOrderId/record-delivery',
        data: {
          'challan_number': challanNumber,
          'delivery_date': deliveryDate,
          'remarks': remarks,
          'phone': phone,
          'items': items,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final delivery = body['delivery'] != null
            ? PrintOrderDeliveryModel.fromJson(
                body['delivery'] as Map<String, dynamic>,
              )
            : null;
        final printOrder = body['print_order'] != null
            ? PrintOrderModel.fromJson(
                body['print_order'] as Map<String, dynamic>,
              )
            : null;

        return {
          'success': true,
          'message': body['message'] ?? 'Delivery recorded successfully!',
          'delivery': delivery,
          'print_order': printOrder,
          'is_completed': body['is_completed'] ?? false,
        };
      }
      throw Exception('Failed to record delivery: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error recording delivery',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<PrintOrderModel> submitQuotation(
    int poId, {
    required List<Map<String, dynamic>> items,
    double? gstRate,
    String? quoteRemarks,
    String? phone,
  }) async {
    try {
      final response = await _apiService.client.post(
        '/api/print-orders/$poId/submit-quotation',
        data: {
          'items': items,
          'gst_rate': gstRate,
          'quote_remarks': quoteRemarks,
          'phone': phone,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return PrintOrderModel.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to submit quotation: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error submitting quotation',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<PrintOrderModel> approveQuotation(
    int poId, {
    String? phone,
  }) async {
    try {
      final response = await _apiService.client.post(
        '/api/print-orders/$poId/approve-quotation',
        data: {
          'phone': phone,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return PrintOrderModel.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to approve quotation: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error approving quotation',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<PrintOrderModel> requestQuotationRevision(
    int poId, {
    required String remarks,
    String? phone,
  }) async {
    try {
      final response = await _apiService.client.post(
        '/api/print-orders/$poId/request-quotation-revision',
        data: {
          'remarks': remarks,
          'phone': phone,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return PrintOrderModel.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to request revision: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error requesting quotation revision',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<PrintOrderModel> reassignVendor(
    int poId, {
    required int vendorId,
    String? remarks,
    String? phone,
  }) async {
    try {
      final response = await _apiService.client.post(
        '/api/print-orders/$poId/reassign-vendor',
        data: {
          'vendor_id': vendorId,
          'remarks': remarks,
          'phone': phone,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return PrintOrderModel.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to reassign vendor: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error reassigning vendor',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}

import 'package:dio/dio.dart';
import 'package:pms/models/eligible_payment_item_model.dart';
import 'package:pms/models/payment_model.dart';
import 'package:pms/services/api_service.dart';

class PaymentRepository {
  final ApiService _apiService;

  PaymentRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Fetch all recorded payments
  Future<List<ProductPaymentModel>> getPayments({
    String? search,
    int? vendorId,
    int? wingId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (vendorId != null) queryParams['vendor_id'] = vendorId;
      if (wingId != null) queryParams['wing_id'] = wingId;

      final response = await _apiService.client.get(
        '/api/payments',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : {};
        final List<dynamic> list = body['data'] as List<dynamic>? ?? [];
        return list
            .map((e) => ProductPaymentModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to load payments',
      );
    } catch (e) {
      throw Exception('Failed to load payments: $e');
    }
  }

  /// Fetch candidate items gone for printing/order with receiving status
  Future<List<EligiblePaymentItemModel>> getEligibleItems({
    String? search,
    int? vendorId,
    int? wingId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (vendorId != null) queryParams['vendor_id'] = vendorId;
      if (wingId != null) queryParams['wing_id'] = wingId;

      final response = await _apiService.client.get(
        '/api/payments/eligible-items',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : {};
        final List<dynamic> list = body['data'] as List<dynamic>? ?? [];
        return list
            .map(
              (e) =>
                  EligiblePaymentItemModel.fromJson(e as Map<String, dynamic>),
            )
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to load eligible items',
      );
    } catch (e) {
      throw Exception('Failed to load eligible items: $e');
    }
  }

  /// Get single payment details with full Day 1 lifecycle history
  Future<ProductPaymentModel> getPaymentDetails(int id) async {
    try {
      final response = await _apiService.client.get('/api/payments/$id');
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : {};
        final Map<String, dynamic> data = body['data'] is Map<String, dynamic>
            ? body['data'] as Map<String, dynamic>
            : {};
        final paymentJson = data['payment'] as Map<String, dynamic>? ?? {};
        paymentJson['lifecycle'] = data['lifecycle'] ?? [];
        if (data['items'] != null && paymentJson['items'] == null) {
          paymentJson['items'] = data['items'];
        }
        return ProductPaymentModel.fromJson(paymentJson);
      }
      throw Exception('Payment not found');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to fetch payment details',
      );
    } catch (e) {
      throw Exception('Failed to fetch payment details: $e');
    }
  }

  /// Record a payment against a fully completed print order
  Future<ProductPaymentModel> recordPayment({
    required int printOrderId,
    int? printOrderItemId,
    required String invoiceNumber,
    required String paymentDate,
    double? amount,
    String? paymentMethod,
    String? transactionReference,
    String? remarks,
    String? phone,
  }) async {
    try {
      final payload = <String, dynamic>{
        'print_order_id': printOrderId,
        'print_order_item_id': ?printOrderItemId,
        'invoice_number': invoiceNumber.trim(),
        'payment_date': paymentDate,
        'amount': ?amount,
        if (paymentMethod != null && paymentMethod.isNotEmpty)
          'payment_method': paymentMethod,
        if (transactionReference != null && transactionReference.trim().isNotEmpty)
          'transaction_reference': transactionReference.trim(),
        if (remarks != null && remarks.trim().isNotEmpty)
          'remarks': remarks.trim(),
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      };

      final response = await _apiService.client.post(
        '/api/payments',
        data: payload,
      );

      if (response.statusCode == 201 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : {};
        final data = body['data'] as Map<String, dynamic>? ?? {};
        return ProductPaymentModel.fromJson(data);
      }
      throw Exception('Failed to record payment');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Error recording payment';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Error recording payment: $e');
    }
  }
}

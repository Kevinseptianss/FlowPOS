import 'dart:convert';
import 'package:http/http.dart' as http;

class MidtransService {
  final String serverKey;
  final bool isProduction;

  MidtransService({required this.serverKey, this.isProduction = false});

  String get _baseUrl => isProduction
      ? 'https://api.midtrans.com/v2'
      : 'https://api.sandbox.midtrans.com/v2';

  Future<Map<String, dynamic>> generateQris({
    required String orderId,
    required int amount,
  }) async {
    final String auth = 'Basic ${base64Encode(utf8.encode('$serverKey:'))}';

    final response = await http.post(
      Uri.parse('$_baseUrl/charge'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': auth,
      },
      body: jsonEncode({
        'payment_type': 'qris',
        'transaction_details': {'order_id': orderId, 'gross_amount': amount},
        'qris': {
          'acquirer': 'gopay',
        },
      }),
    );

    final data = jsonDecode(response.body);

    // DEBUG LOG
    print('Midtrans Response [${response.statusCode}]: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Midtrans returns QR string in actions[0].url for gopay
      final actions = data['actions'] as List<dynamic>?;
      if (actions != null && actions.isNotEmpty) {
        final qrisAction = actions.firstWhere(
          (action) => action['name'] == 'generate-qr-code',
          orElse: () => null,
        );
        if (qrisAction != null) {
          return {
            'success': true,
            'qr_string': qrisAction['url'],
            'transaction_id': data['transaction_id'],
          };
        }
      }
      return {'success': false, 'message': 'QR code not found in response'};
    } else {
      return {
        'success': false,
        'status_code': response.statusCode.toString(),
        'midtrans_status_code': data['status_code'],
        'message': data['status_message'] ?? 'Failed to generate QRIS',
      };
    }
  }

  Future<Map<String, dynamic>> generateSnapUrl({
    required String orderId,
    required int amount,
  }) async {
    final String snapUrl = isProduction
        ? 'https://app.midtrans.com/snap/v1/transactions'
        : 'https://app.sandbox.midtrans.com/snap/v1/transactions';

    final String auth = 'Basic ${base64Encode(utf8.encode('$serverKey:'))}';

    final response = await http.post(
      Uri.parse(snapUrl),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': auth,
      },
      body: jsonEncode({
        'transaction_details': {'order_id': orderId, 'gross_amount': amount},
        'enabled_payments': ['qris'], // Only QRIS
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'redirect_url': data['redirect_url'],
        'token': data['token'],
      };
    } else {
      final data = jsonDecode(response.body);
      return {
        'success': false,
        'message': data['error_messages'] != null
            ? (data['error_messages'] as List).join(', ')
            : 'Failed to generate Snap URL',
      };
    }
  }

  Future<Map<String, dynamic>> checkTransactionStatus(String orderId) async {
    final String auth = 'Basic ${base64Encode(utf8.encode('$serverKey:'))}';

    final response = await http.get(
      Uri.parse('$_baseUrl/$orderId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': auth,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'status': data['transaction_status'], // 'settlement' means paid
        'payment_type': data['payment_type'],
      };
    } else {
      return {'success': false, 'message': 'Failed to check status'};
    }
  }
}

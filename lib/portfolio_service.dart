import 'dart:convert';

import 'package:http/http.dart' as http;

class PortfolioService {
  // ============================================================
  // BACKEND URL
  // ============================================================
  //
  // IMPORTANT:
  // This must be your BACKEND URL.
  //
  // NOT:
  // https://thevah.vercel.app
  //
  // unless your backend API is actually hosted there.
  //
  static const String baseUrl = 'https://YOUR-BACKEND-URL.com';

  // ============================================================
  // GET ALL PORTFOLIO
  // ============================================================

  Future<List<Map<String, dynamic>>> getPortfolio() async {
    final uri = Uri.parse('$baseUrl/api/portfolio');

    try {
      print('==========================================');
      print('PORTFOLIO REQUEST');
      print('URL: $uri');
      print('==========================================');

      final response = await http.get(
        uri,
        headers: const {
          'Accept': 'application/json',
        },
      );

      print('STATUS: ${response.statusCode}');
      print('CONTENT TYPE: ${response.headers['content-type']}');
      print('RESPONSE: ${response.body}');

      // ----------------------------------------------------------
      // HTTP ERROR
      // ----------------------------------------------------------

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          'Portfolio API failed.\n'
              'Status: ${response.statusCode}\n'
              'Response: ${response.body}',
        );
      }

      // ----------------------------------------------------------
      // CHECK CONTENT TYPE
      // ----------------------------------------------------------

      final contentType =
          response.headers['content-type'] ?? '';

      if (!contentType.contains('application/json')) {
        throw Exception(
          'Portfolio API did not return JSON.\n\n'
              'URL: $uri\n\n'
              'Content-Type: $contentType\n\n'
              'Response:\n${response.body}',
        );
      }

      // ----------------------------------------------------------
      // DECODE JSON
      // ----------------------------------------------------------

      dynamic decoded;

      try {
        decoded = jsonDecode(response.body);
      } catch (e) {
        throw Exception(
          'Invalid JSON returned by portfolio API.\n'
              'Error: $e\n\n'
              'Response:\n${response.body}',
        );
      }

      // ----------------------------------------------------------
      // RESPONSE IS DIRECT ARRAY
      // ----------------------------------------------------------

      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map<Map<String, dynamic>>(
              (item) => Map<String, dynamic>.from(item),
        )
            .toList();
      }

      // ----------------------------------------------------------
      // RESPONSE IS OBJECT
      // ----------------------------------------------------------

      if (decoded is Map) {
        final map =
        Map<String, dynamic>.from(decoded);

        // Example:
        //
        // {
        //   "data": [...]
        // }

        final data = map['data'];

        if (data is List) {
          return data
              .whereType<Map>()
              .map<Map<String, dynamic>>(
                (item) =>
            Map<String, dynamic>.from(item),
          )
              .toList();
        }

        // Example:
        //
        // {
        //   "portfolio": [...]
        // }

        final portfolio = map['portfolio'];

        if (portfolio is List) {
          return portfolio
              .whereType<Map>()
              .map<Map<String, dynamic>>(
                (item) =>
            Map<String, dynamic>.from(item),
          )
              .toList();
        }
      }

      throw Exception(
        'Invalid portfolio response structure.\n'
            'Expected a JSON array or an object containing '
            '"data" or "portfolio".',
      );
    } catch (e) {
      print('==========================================');
      print('PORTFOLIO ERROR');
      print(e);
      print('==========================================');

      rethrow;
    }
  }

  // ============================================================
  // FILTER BY CATEGORY
  // ============================================================

  Future<List<Map<String, dynamic>>> getPortfolioByCategory(
      String category,
      ) async {
    final items = await getPortfolio();

    if (category.toUpperCase() == 'ALL') {
      return items;
    }

    return items.where((item) {
      final itemCategory =
      item['category']
          ?.toString()
          .toUpperCase();

      return itemCategory ==
          category.toUpperCase();
    }).toList();
  }
}
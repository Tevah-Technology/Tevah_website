import 'dart:convert';
import 'package:http/http.dart' as http;

import 'environmental.dart';

class PortfolioAvailabilityService {
  // Change this to your actual portfolio API.
  static  String apiUrl =
      '$Vercel_url/api/portfolio';

  static Future<bool> isPortfolioAvailable() async {
    try {
      final response = await http
          .get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json',
        },
      )
          .timeout(const Duration(seconds: 8));

      // Only consider successful API responses as available.
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final body = jsonDecode(response.body);

          // If your API returns a list directly:
          if (body is List) {
            return true;
          }

          // If your API returns:
          // { "success": true, "data": [...] }
          if (body is Map<String, dynamic>) {
            if (body['success'] == false) {
              return false;
            }

            return true;
          }

          return true;
        } catch (_) {
          // API responded successfully but response wasn't JSON.
          // You can change this to false if your API must return JSON.
          return true;
        }
      }

      // 401, 403, 404, 500, etc.
      return false;
    } catch (_) {
      // Network error, timeout, server unavailable, etc.
      return false;
    }
  }
}
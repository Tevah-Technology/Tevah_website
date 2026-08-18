import 'dart:convert';
import 'package:http/http.dart' as http;

import 'environmental.dart';

class PortfolioAvailabilityService {
  static String apiUrl =
      'http://localhost:3000/api/portfolio';

  static Future<bool> isPortfolioAvailable() async {
    print('');
    print('========================================');
    print('CHECKING PORTFOLIO AVAILABILITY');
    print('========================================');

    print('Ngrok_url:');
    print(Ngrok_url);

    print('');
    print('Final Portfolio API URL:');
    print(apiUrl);

    try {
      final uri = Uri.parse(apiUrl);

      print('');
      print('Parsed URI:');
      print(uri);

      print('');
      print('Sending GET request...');

      final response = await http
          .get(
        uri,
        headers: {
          'Accept': 'application/json',
        },
      )
          .timeout(
        const Duration(seconds: 15),
      );

      print('');
      print('========================================');
      print('PORTFOLIO API RESPONSE');
      print('========================================');

      print('Status Code: ${response.statusCode}');
      print('Headers: ${response.headers}');
      print('Body:');
      print(response.body);

      print('========================================');

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        try {
          final body = jsonDecode(response.body);

          print('');
          print('Decoded JSON:');
          print(body);

          if (body is Map<String, dynamic>) {
            final success = body['success'];

            print('');
            print('API success value: $success');

            if (success == true) {
              print('Portfolio API is AVAILABLE');
              return true;
            }

            print('Portfolio API returned success=false');
            return false;
          }

          print('Unexpected response format');
          return false;
        } catch (e) {
          print('JSON decode error: $e');
          return false;
        }
      }

      print(
        'Portfolio API returned HTTP ${response.statusCode}',
      );

      return false;
    } catch (error, stackTrace) {
      print('');
      print('========================================');
      print('PORTFOLIO API ERROR');
      print('========================================');

      print('Error: $error');

      print('');
      print('StackTrace:');
      print(stackTrace);

      print('========================================');

      return false;
    }
  }
}
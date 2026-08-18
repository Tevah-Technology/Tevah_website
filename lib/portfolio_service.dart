import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:tevahweb/environmental.dart';

class PortfolioService {
  // ============================================================
  // BACKEND
  // ============================================================

  static String baseUrl = '$Vercel_url';

  // ============================================================
  // GET PORTFOLIO
  // ============================================================

  Future<List<Map<String, dynamic>>> getPortfolio() async {
    final uri = Uri.parse('$baseUrl/api/portfolio');

    debugPrint('');
    debugPrint('==============================================');
    debugPrint('THEVA PORTFOLIO API');
    debugPrint('==============================================');
    debugPrint('GET: $uri');
    debugPrint('==============================================');

    try {
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      debugPrint('');
      debugPrint('--------------- API RESPONSE ----------------');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Headers: ${response.headers}');
      debugPrint('----------------------------------------------');
      debugPrint('RAW RESPONSE:');
      debugPrint(response.body);
      debugPrint('----------------------------------------------');

      if (response.statusCode != 200) {
        throw Exception('Portfolio API failed: ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);

      debugPrint('');
      debugPrint('--------------- DECODED DATA ----------------');

      const encoder = JsonEncoder.withIndent('  ');

      debugPrint(encoder.convert(decoded));

      debugPrint('----------------------------------------------');

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid portfolio response.');
      }

      if (decoded['success'] != true) {
        throw Exception(
          decoded['message']?.toString() ?? 'Failed to load portfolio.',
        );
      }

      final data = decoded['data'];

      debugPrint('');
      debugPrint('--------------- PORTFOLIO DATA ---------------');
      debugPrint('Data type: ${data.runtimeType}');

      if (data is! List) {
        debugPrint('Data is not a List.');

        return [];
      }

      debugPrint('Number of projects: ${data.length}');

      debugPrint('----------------------------------------------');

      final List<Map<String, dynamic>> projects = [];

      for (int i = 0; i < data.length; i++) {
        final raw = data[i];

        if (raw is! Map) {
          debugPrint('Skipping invalid item at index $i');
          continue;
        }

        final item = Map<String, dynamic>.from(raw);

        debugPrint('');
        debugPrint('PROJECT ${i + 1}');
        debugPrint(encoder.convert(item));

        final normalized = _normalizePortfolioItem(item, i);

        projects.add(normalized);
      }

      debugPrint('');
      debugPrint('==============================================');
      debugPrint('PORTFOLIO LOADED');
      debugPrint('Total Projects: ${projects.length}');
      debugPrint('==============================================');
      debugPrint('');

      return projects;
    } catch (error) {
      debugPrint('');
      debugPrint('==============================================');
      debugPrint('PORTFOLIO ERROR');
      debugPrint('==============================================');
      debugPrint(error.toString());
      debugPrint('==============================================');

      throw Exception('Unable to load portfolio: $error');
    }
  }

  // ============================================================
  // NORMALIZE
  // ============================================================

  Map<String, dynamic> _normalizePortfolioItem(
    Map<String, dynamic> item,
    int index,
  ) {
    final title =
        item['title']?.toString() ?? item['name']?.toString() ?? 'Project';

    final category = _normalizeCategory(item['category']?.toString() ?? '');

    final thumbnail =
        item['thumbnail']?.toString() ??
        item['thumbnailUrl']?.toString() ??
        item['imageUrl']?.toString() ??
        '';

    final videoUrl =
        item['videoUrl']?.toString() ?? item['fileUrl']?.toString() ?? '';

    final files = item['files'] is List
        ? List<dynamic>.from(item['files'])
        : <dynamic>[];

    return {
      ...item,

      'num': _formatNumber(index + 1),

      'title': title,

      'category': category,

      'imageUrl': thumbnail,

      'thumbnailUrl': thumbnail,

      'videoUrl': videoUrl,

      'subtitle': _buildSubtitle(category),

      'client': item['client']?.toString() ?? 'THEVA',

      'year': item['year']?.toString() ?? DateTime.now().year.toString(),

      'description': item['description']?.toString() ?? '',

      'overview':
          item['overview']?.toString() ?? item['description']?.toString() ?? '',

      'challenge': item['challenge']?.toString() ?? '',

      'solution': item['solution']?.toString() ?? '',

      'metrics': _stringList(item['metrics']),

      'tags': _stringList(item['tags']),

      'files': files,

      'isFeatured': item['isFeatured'] == true,

      'isDataFeatured': item['isDataFeatured'] == true,
    };
  }

  // ============================================================
  // CATEGORY
  // ============================================================

  String _normalizeCategory(String category) {
    final value = category.trim().toUpperCase();

    switch (value) {
      case 'APP':
      case 'APPS':
      case 'APPLICATION':
      case 'APPLICATIONS':
        return 'APP';

      case 'WEBSITE':
      case 'WEBSITES':
      case 'WEB':
        return 'WEBSITE';

      case 'LOGO':
      case 'LOGOS':
      case 'BRANDING':
        return 'LOGO';

      case 'VIDEO':
      case 'VIDEOS':
        return 'VIDEO';

      case 'GRAPHIC':
      case 'GRAPHICS':
      case 'GRAPHIC DESIGN':
      case 'GRAPHIC DESIGNS':
      case 'GRAPHIC_DESIGNS':
        return 'GRAPHIC DESIGNS';

      default:
        return value;
    }
  }

  // ============================================================
  // SUBTITLE
  // ============================================================

  String _buildSubtitle(String category) {
    switch (category) {
      case 'APP':
        return 'Mobile Application';

      case 'WEBSITE':
        return 'Digital Website Experience';

      case 'LOGO':
        return 'Brand Identity & Logo Design';

      case 'VIDEO':
        return 'Cinematic Video Production';

      case 'GRAPHIC DESIGNS':
        return 'Creative Graphic Design';

      default:
        return 'Digital Experience';
    }
  }

  // ============================================================
  // STRING LIST
  // ============================================================

  List<String> _stringList(dynamic value) {
    if (value is! List) {
      return [];
    }

    return value
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  // ============================================================
  // NUMBER
  // ============================================================

  String _formatNumber(int number) {
    return number.toString().padLeft(2, '0');
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;

class PortfolioService {
  // ============================================================
  // BACKEND URL
  // ============================================================

  static const String baseUrl = 'http://localhost:3000';

  // ============================================================
  // GET PORTFOLIO
  // ============================================================

  Future<List<Map<String, dynamic>>> getPortfolio() async {
    final uri = Uri.parse(
      '$baseUrl/api/portfolio',
    );

    print('');
    print('==============================================');
    print('THEVA PORTFOLIO API');
    print('==============================================');
    print('GET: $uri');
    print('==============================================');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
        },
      );

      // ==========================================================
      // RESPONSE STATUS
      // ==========================================================

      print('');
      print('--------------- API RESPONSE ----------------');
      print('Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('----------------------------------------------');

      // Print complete raw response
      print('RAW RESPONSE:');
      print(response.body);

      print('----------------------------------------------');

      // ==========================================================
      // STATUS CHECK
      // ==========================================================

      if (response.statusCode != 200) {
        print(
          '❌ Portfolio API failed with status '
              '${response.statusCode}',
        );

        throw Exception(
          'Portfolio API failed: ${response.statusCode}',
        );
      }

      // ==========================================================
      // JSON DECODE
      // ==========================================================

      dynamic decoded;

      try {
        decoded = jsonDecode(response.body);
      } catch (error) {
        print('❌ JSON DECODE ERROR: $error');

        throw Exception(
          'Invalid JSON response from portfolio API.',
        );
      }

      print('');
      print('--------------- DECODED DATA ----------------');
      print(
        const JsonEncoder.withIndent('  ').convert(decoded),
      );
      print('----------------------------------------------');

      // ==========================================================
      // RESPONSE FORMAT CHECK
      // ==========================================================

      if (decoded is! Map<String, dynamic>) {
        print('❌ Invalid portfolio response format.');

        throw Exception(
          'Invalid portfolio response.',
        );
      }

      // ==========================================================
      // SUCCESS CHECK
      // ==========================================================

      if (decoded['success'] != true) {
        final message =
            decoded['message']?.toString() ??
                'Failed to load portfolio.';

        print('❌ API returned success=false');
        print('Message: $message');

        throw Exception(message);
      }

      // ==========================================================
      // GET DATA
      // ==========================================================

      final data = decoded['data'];

      print('');
      print('--------------- PORTFOLIO DATA ---------------');
      print('Data type: ${data.runtimeType}');
      print(
        'Number of projects: '
            '${data is List ? data.length : 0}',
      );
      print('----------------------------------------------');

      if (data is! List) {
        print('⚠️ API data is not a List.');
        return [];
      }

      // ==========================================================
      // NORMALIZE PROJECTS
      // ==========================================================

      final List<Map<String, dynamic>> projects = [];

      for (int i = 0; i < data.length; i++) {
        final raw = data[i];

        if (raw is! Map) {
          print(
            '⚠️ Skipping invalid project at index $i',
          );
          continue;
        }

        final item =
        Map<String, dynamic>.from(raw);

        print('');
        print('==============================================');
        print('PROJECT ${i + 1}');
        print('==============================================');

        print(
          const JsonEncoder.withIndent('  ').convert(item),
        );

        final normalized =
        _normalizePortfolioItem(
          item,
          i,
        );

        projects.add(normalized);

        print('');
        print('NORMALIZED PROJECT:');

        print(
          const JsonEncoder.withIndent('  ')
              .convert(normalized),
        );
      }

      // ==========================================================
      // FINAL RESULT
      // ==========================================================

      print('');
      print('==============================================');
      print('PORTFOLIO LOADED');
      print('Total Projects: ${projects.length}');
      print('==============================================');

      for (final project in projects) {
        print(
          '${project['num']} | '
              '${project['title']} | '
              '${project['category']}',
        );

        print(
          'Thumbnail: ${project['thumbnailUrl']}',
        );

        print(
          'Video: ${project['videoUrl']}',
        );

        print('----------------------------------------------');
      }

      return projects;
    } catch (error) {
      print('');
      print('==============================================');
      print('❌ PORTFOLIO API ERROR');
      print('==============================================');
      print(error);
      print('==============================================');

      throw Exception(
        'Unable to load portfolio: $error',
      );
    }
  }

  // ============================================================
  // NORMALIZE BACKEND DATA
  // ============================================================

  Map<String, dynamic> _normalizePortfolioItem(
      Map<String, dynamic> item,
      int index,
      ) {
    // ==========================================================
    // TITLE
    // ==========================================================

    final title =
        item['title']?.toString() ??
            item['name']?.toString() ??
            'Project';

    // ==========================================================
    // CATEGORY
    // ==========================================================

    final category = _normalizeCategory(
      item['category']?.toString() ?? '',
    );

    // ==========================================================
    // THUMBNAIL
    // ==========================================================

    final thumbnail =
        item['thumbnail']?.toString() ??
            item['thumbnailUrl']?.toString() ??
            item['imageUrl']?.toString() ??
            '';

    // ==========================================================
    // VIDEO
    // ==========================================================

    final videoUrl =
        item['videoUrl']?.toString() ?? '';

    // ==========================================================
    // FILES
    // ==========================================================

    final files =
    item['files'] is List
        ? List<dynamic>.from(
      item['files'],
    )
        : <dynamic>[];

    return {
      // Keep all backend fields
      ...item,

      // ========================================================
      // UI FIELDS
      // ========================================================

      'num': _formatNumber(
        index + 1,
      ),

      'title': title,

      'category': category,

      'imageUrl': thumbnail,

      'thumbnailUrl': thumbnail,

      'videoUrl': videoUrl,

      'subtitle': _buildSubtitle(
        category,
      ),

      'client':
      item['client']?.toString() ??
          'THEVA',

      'year':
      item['year']?.toString() ??
          DateTime.now()
              .year
              .toString(),

      'description':
      item['description']?.toString() ??
          '',

      'overview':
      item['overview']?.toString() ??
          item['description']?.toString() ??
          '',

      'challenge':
      item['challenge']?.toString() ??
          '',

      'solution':
      item['solution']?.toString() ??
          '',

      'metrics': _stringList(
        item['metrics'],
      ),

      'tags': _stringList(
        item['tags'],
      ),

      'files': files,

      'isFeatured':
      item['isFeatured'] == true,

      'isDataFeatured':
      item['isDataFeatured'] == true,
    };
  }

  // ============================================================
  // CATEGORY NORMALIZATION
  // ============================================================

  String _normalizeCategory(
      String category,
      ) {
    final value =
    category
        .trim()
        .toUpperCase();

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

  String _buildSubtitle(
      String category,
      ) {
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

  List<String> _stringList(
      dynamic value,
      ) {
    if (value is! List) {
      return [];
    }

    return value
        .map(
          (item) => item.toString(),
    )
        .where(
          (item) => item.isNotEmpty,
    )
        .toList();
  }

  // ============================================================
  // NUMBER
  // ============================================================

  String _formatNumber(
      int number,
      ) {
    return number
        .toString()
        .padLeft(2, '0');
  }
}
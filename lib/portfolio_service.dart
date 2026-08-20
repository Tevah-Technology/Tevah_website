import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:tevahweb/environmental.dart';

class PortfolioService {
  static String baseUrl = '$Vercel_url';

  Future<List<Map<String, dynamic>>> getPortfolio() async {
    final uri = Uri.parse('$baseUrl/api/portfolio');

    try {
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Portfolio API failed: ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
        throw Exception(decoded['message']?.toString() ?? 'Failed to load portfolio.');
      }

      final List<dynamic> data = decoded['data'] ?? [];

      // 1. Separate .json companion files from media files using your API's exact structure
      final Map<String, String> jsonDownloadMap = {};
      final List<Map<String, dynamic>> mediaItems = [];

      for (final raw in data) {
        if (raw is! Map) continue;
        final item = Map<String, dynamic>.from(raw);
        final String titleKey = (item['title'] ?? item['name'] ?? '').toString().trim().toLowerCase();

        final files = item['files'] as List<dynamic>?;
        bool isJsonFile = false;
        String? jsonUrl;

        if (files != null && files.isNotEmpty) {
          final firstFile = files[0];
          if (firstFile is Map) {
            final ext = firstFile['extension']?.toString().toLowerCase();
            final name = firstFile['name']?.toString().toLowerCase() ?? '';
            if (ext == 'json' || name.endsWith('.json')) {
              isJsonFile = true;
              jsonUrl = firstFile['url']?.toString();
            }
          }
        }

        if (isJsonFile && jsonUrl != null && jsonUrl.isNotEmpty) {
          jsonDownloadMap[titleKey] = jsonUrl;
        } else {
          mediaItems.add(item);
        }
      }

      // 2. Download and parse all companion JSONs concurrently
      final Map<String, Map<String, dynamic>> parsedMetaMap = {};

      await Future.wait(
        jsonDownloadMap.entries.map((entry) async {
          try {
            final res = await http.get(Uri.parse(entry.value));
            if (res.statusCode == 200) {
              final body = jsonDecode(res.body);
              if (body is Map) {
                if (body.containsKey('liveUrl') || body.containsKey('link') || body.containsKey('url')) {
                  parsedMetaMap[entry.key] = Map<String, dynamic>.from(body);
                } else {
                  // If nested with {"web1q.png": {"liveUrl": "..."}}
                  for (final val in body.values) {
                    if (val is Map) {
                      parsedMetaMap[entry.key] = Map<String, dynamic>.from(val);
                      break;
                    }
                  }
                }
              }
            }
          } catch (e) {
            debugPrint('Failed to fetch metadata for ${entry.key}: $e');
          }
        }),
      );

      // 3. Attach metadata to matching media item by title
      final List<Map<String, dynamic>> projects = [];

      for (int i = 0; i < mediaItems.length; i++) {
        final item = mediaItems[i];
        final String titleKey = (item['title'] ?? item['name'] ?? '').toString().trim().toLowerCase();

        if (parsedMetaMap.containsKey(titleKey)) {
          final meta = parsedMetaMap[titleKey]!;
          item['liveUrl'] = meta['liveUrl'] ?? meta['link'] ?? meta['url'] ?? meta['websiteUrl'] ?? '';
          if (meta['description'] != null) item['description'] = meta['description'];
        }

        projects.add(_normalizePortfolioItem(item, projects.length));
      }

      return projects;
    } catch (error) {
      debugPrint('[PortfolioService Error]: $error');
      throw Exception('Unable to load portfolio: $error');
    }
  }

  Map<String, dynamic> _normalizePortfolioItem(Map<String, dynamic> item, int index) {
    final title = item['title']?.toString() ?? 'Project';
    final category = _normalizeCategory(item['category']?.toString() ?? '');
    final thumbnail = item['thumbnail']?.toString() ?? '';
    final videoUrl = item['videoUrl']?.toString() ?? '';
    final liveUrl = (item['liveUrl'] ?? '').toString().trim();

    return {
      ...item,
      'num': (index + 1).toString().padLeft(2, '0'),
      'title': title,
      'category': category,
      'imageUrl': thumbnail,
      'thumbnailUrl': thumbnail,
      'videoUrl': videoUrl,
      'liveUrl': liveUrl,
      'subtitle': _buildSubtitle(category),
      'description': item['description']?.toString() ?? '',
      'files': item['files'] ?? [],
      'isFeatured': item['isFeatured'] == true,
    };
  }

  String _normalizeCategory(String category) {
    final value = category.trim().toUpperCase();
    switch (value) {
      case 'APP':
      case 'APPS':
        return 'APP';
      case 'WEBSITE':
      case 'WEBSITES':
        return 'WEBSITE';
      case 'LOGO':
      case 'LOGOS':
        return 'LOGO';
      case 'VIDEO':
      case 'VIDEOS':
        return 'VIDEO';
      case 'GRAPHIC':
      case 'GRAPHICS':
      case 'GRAPHIC DESIGNS':
        return 'GRAPHIC DESIGNS';
      default:
        return value;
    }
  }

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
      default:
        return 'Digital Experience';
    }
  }
}
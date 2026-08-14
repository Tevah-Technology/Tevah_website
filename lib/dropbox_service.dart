import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'environmental.dart';

class DropboxService {
  static  String clientId = Dropbox_APP_KEY;

  // MUST exactly match Dropbox App Console.
  static  String redirectUri = Vercel_url;

  static const String verifierKey =
      'dropbox_code_verifier';

  String? _codeVerifier;
  String? accessToken;

  // ============================================================
  // CONNECT
  // ============================================================

  Future<void> connectDropbox() async {
    _codeVerifier = _generateCodeVerifier();

    // Save PKCE verifier before leaving the app.
    final prefs =
    await SharedPreferences.getInstance();

    await prefs.setString(
      verifierKey,
      _codeVerifier!,
    );

    final codeChallenge =
    _generateCodeChallenge(_codeVerifier!);

    final uri = Uri.https(
      'www.dropbox.com',
      '/oauth2/authorize',
      {
        'client_id': clientId,
        'response_type': 'code',
        'redirect_uri': redirectUri,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'token_access_type': 'offline',
      },
    );

    debugPrint(
      'Opening Dropbox OAuth:',
    );

    debugPrint(uri.toString());

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      throw Exception(
        'Could not open Dropbox authorization page.',
      );
    }
  }

  // ============================================================
  // HANDLE CALLBACK
  // ============================================================

  Future<bool> handleCallback() async {
    if (!kIsWeb) {
      return false;
    }

    final uri = Uri.base;

    final error = uri.queryParameters['error'];

    if (error != null) {
      final description =
      uri.queryParameters['error_description'];

      throw Exception(
        'Dropbox authorization failed: '
            '$error ${description ?? ''}',
      );
    }

    final code = uri.queryParameters['code'];

    if (code == null || code.isEmpty) {
      return false;
    }

    debugPrint(
      'Dropbox authorization code received.',
    );

    final prefs =
    await SharedPreferences.getInstance();

    _codeVerifier =
        prefs.getString(verifierKey);

    if (_codeVerifier == null ||
        _codeVerifier!.isEmpty) {
      throw Exception(
        'Code verifier is missing. '
            'Please connect Dropbox again.',
      );
    }

    final success =
    await exchangeCode(code);

    if (success) {
      await prefs.remove(verifierKey);

      // Clean ?code= from browser URL.
      //
      // We don't reload the page here because that would
      // create unnecessary navigation.
      debugPrint(
        'Dropbox OAuth completed successfully.',
      );
    }

    return success;
  }

  // ============================================================
  // EXCHANGE CODE
  // ============================================================

  Future<bool> exchangeCode(
      String code,
      ) async {
    if (_codeVerifier == null) {
      throw Exception(
        'Code verifier is missing.',
      );
    }

    final response = await http.post(
      Uri.parse(
        'https://api.dropboxapi.com/oauth2/token',
      ),
      headers: {
        'Content-Type':
        'application/x-www-form-urlencoded',
      },
      body: {
        'code': code,
        'grant_type': 'authorization_code',
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'code_verifier': _codeVerifier!,
      },
    );

    if (response.statusCode != 200) {
      debugPrint(
        'Dropbox token error:',
      );

      debugPrint(
        response.body,
      );

      return false;
    }

    final data = jsonDecode(response.body);

    accessToken = data['access_token'];

    debugPrint(
      'Dropbox connected successfully.',
    );

    return accessToken != null;
  }

  // ============================================================
  // ACCOUNT
  // ============================================================

  Future<Map<String, dynamic>?> getAccountInfo() async {
    _checkAccessToken();

    final response = await http.post(
      Uri.parse(
        'https://api.dropboxapi.com/2/users/get_current_account',
      ),
      headers: {
        'Authorization':
        'Bearer $accessToken',
        'Content-Type':
        'application/json',
      },
    );

    if (response.statusCode != 200) {
      debugPrint(
        'Account error: ${response.body}',
      );

      return null;
    }

    return jsonDecode(response.body)
    as Map<String, dynamic>;
  }

  // ============================================================
  // LIST FILES
  // ============================================================

  Future<List<dynamic>> listFiles({
    String path = '',
  }) async {
    _checkAccessToken();

    final response = await http.post(
      Uri.parse(
        'https://api.dropboxapi.com/2/files/list_folder',
      ),
      headers: {
        'Authorization':
        'Bearer $accessToken',
        'Content-Type':
        'application/json',
      },
      body: jsonEncode({
        'path': path,
        'recursive': false,
        'include_media_info': true,
      }),
    );

    if (response.statusCode != 200) {
      debugPrint(
        'List files error:',
      );

      debugPrint(
        response.body,
      );

      return [];
    }

    final data = jsonDecode(response.body);

    return data['entries'] ?? [];
  }

  // ============================================================
  // TEMPORARY FILE LINK
  // ============================================================

  Future<String?> getTemporaryLink(
      String path,
      ) async {
    _checkAccessToken();

    final response = await http.post(
      Uri.parse(
        'https://api.dropboxapi.com/2/files/get_temporary_link',
      ),
      headers: {
        'Authorization':
        'Bearer $accessToken',
        'Content-Type':
        'application/json',
      },
      body: jsonEncode({
        'path': path,
      }),
    );

    if (response.statusCode != 200) {
      debugPrint(
        'Temporary link error:',
      );

      debugPrint(
        response.body,
      );

      return null;
    }

    final data = jsonDecode(response.body);

    return data['link'];
  }

  // ============================================================
  // DOWNLOAD FILE
  // ============================================================

  Future<List<int>?> downloadFile(
      String path,
      ) async {
    _checkAccessToken();

    final response = await http.post(
      Uri.parse(
        'https://content.dropboxapi.com/2/files/download',
      ),
      headers: {
        'Authorization':
        'Bearer $accessToken',
        'Dropbox-API-Arg':
        jsonEncode({
          'path': path,
        }),
      },
    );

    if (response.statusCode != 200) {
      debugPrint(
        'Download error:',
      );

      debugPrint(
        response.body,
      );

      return null;
    }

    return response.bodyBytes;
  }

  // ============================================================
  // VIDEO CHECK
  // ============================================================

  bool isVideo(
      String? name,
      ) {
    if (name == null) return false;

    final value =
    name.toLowerCase();

    return value.endsWith('.mp4') ||
        value.endsWith('.mov') ||
        value.endsWith('.m4v') ||
        value.endsWith('.webm');
  }

  // ============================================================
  // IMAGE CHECK
  // ============================================================

  bool isImage(
      String? name,
      ) {
    if (name == null) return false;

    final value =
    name.toLowerCase();

    return value.endsWith('.jpg') ||
        value.endsWith('.jpeg') ||
        value.endsWith('.png') ||
        value.endsWith('.webp') ||
        value.endsWith('.gif');
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    accessToken = null;
    _codeVerifier = null;

    final prefs =
    await SharedPreferences.getInstance();

    await prefs.remove(verifierKey);
  }

  // ============================================================
  // INTERNAL
  // ============================================================

  void _checkAccessToken() {
    if (accessToken == null ||
        accessToken!.isEmpty) {
      throw Exception(
        'Dropbox is not connected.',
      );
    }
  }

  String _generateCodeVerifier() {
    final random =
    Random.secure();

    final bytes =
    List<int>.generate(
      64,
          (_) => random.nextInt(256),
    );

    return base64UrlEncode(bytes)
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
  }

  String _generateCodeChallenge(
      String verifier,
      ) {
    final bytes =
    utf8.encode(verifier);

    final digest =
    sha256.convert(bytes);

    return base64UrlEncode(
      digest.bytes,
    )
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
  }
}
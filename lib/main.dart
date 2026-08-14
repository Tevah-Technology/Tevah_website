import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dropbox_service.dart';
import 'home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dropbox = DropboxService();

  final prefs = await SharedPreferences.getInstance();

  final currentUrl =
      Uri.base;

  final code =
  currentUrl.queryParameters['code'];

  if (code != null && code.isNotEmpty) {
    try {
      await dropbox.exchangeCode(
        code,
      );

      print(
        'Dropbox OAuth completed!',
      );
    } catch (e) {
      print(
        'Dropbox OAuth error: $e',
      );
    }
  }

  runApp(
    const ThevahApp(),
  );
}

class ThevahApp extends StatelessWidget {
  const ThevahApp({
    super.key,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MainAgencyScreen(),
    );
  }
}
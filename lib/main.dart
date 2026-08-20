import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';

import 'about_screen.dart';
import 'home_screen.dart';
import 'legal_screen.dart';
import 'portfolio_screen.dart';

void main() {
  usePathUrlStrategy();
  runApp(const MyApp());
}

final GoRouter _router = GoRouter(
  initialLocation: '/home',
  errorBuilder: (context, state) => const NotFoundPage(),
  routes: <RouteBase>[
    // Redirect root to /home
    GoRoute(
      path: '/',
      redirect: (_, __) => '/home',
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      pageBuilder: (context, state) => const MaterialPage(
        child: MainAgencyScreen(),
      ),
    ),
    GoRoute(
      path: '/about',
      name: 'about',
      pageBuilder: (context, state) => const MaterialPage(
        child: AboutScreen(),
      ),
    ),
    GoRoute(
      path: '/portfolio',
      name: 'portfolio',
      pageBuilder: (context, state) => const MaterialPage(
        child: PortfolioScreen(),
      ),
    ),

    // Legal: Terms & Conditions
    GoRoute(
      path: '/terms-and-conditions',
      name: 'terms',
      pageBuilder: (context, state) => const MaterialPage(
        child: LegalScreen(initialSection: LegalSection.terms),
      ),
    ),
    GoRoute(
      path: '/terms and conditions',
      redirect: (_, __) => '/terms-and-conditions',
    ),

    // Legal: Privacy Policy
    GoRoute(
      path: '/privacy-policy',
      name: 'privacy',
      pageBuilder: (context, state) => const MaterialPage(
        child: LegalScreen(initialSection: LegalSection.privacy),
      ),
    ),
    GoRoute(
      path: '/privacy policy',
      redirect: (_, __) => '/privacy-policy',
    ),

    // Legal: Refund & Cancellation
    GoRoute(
      path: '/refund-and-cancellation',
      name: 'refund',
      pageBuilder: (context, state) => const MaterialPage(
        child: LegalScreen(initialSection: LegalSection.refund),
      ),
    ),
    GoRoute(
      path: '/refund & cancellation',
      redirect: (_, __) => '/refund-and-cancellation',
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'tevah.technology',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0B),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFa02928),
        ),
      ),
      routerConfig: _router,
    );
  }
}

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0B),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '404 - Page Not Found',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFa02928),
                foregroundColor: Colors.white,
              ),
              onPressed: () => context.go('/home'),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
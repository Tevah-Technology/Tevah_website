import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tevahweb/portfolio_availability.dart';
import 'package:url_launcher/url_launcher.dart';

import 'dropbox.dart';
import 'home_screen.dart';
import 'about_screen.dart';
import 'letstalk.dart';
import 'portfolio_screen.dart';

// ============================================================================
// NAVIGATION ROUTE ENUM
// ============================================================================

enum NavRoute {
  home,
  about,
  portfolio,
  dropbox,
  solutions,
  capabilities,
  contact,
}

// ============================================================================
// CENTRAL BRAND PALETTE
// RED, BLACK & CHARCOAL GREY
// ============================================================================

abstract class AppTheme {
  static const Color brandRed = Color(0xFFa02928);

  static const Color darkBackground = Color(0xFF0A0A0B);

  static const Color darkCard = Color(0xFF141416);

  static const Color darkSurface = Color(0xFF18181D);

  static const Color greyBorder = Colors.white10;

  static const Color targetCream = Color(0xFFE0E0E0);
}

// ============================================================================
// TEVAH NAVBAR
// RESPONSIVE TOP NAVIGATION
// ============================================================================

class TevahNavbar extends StatefulWidget {
  final NavRoute currentRoute;
  final ValueChanged<bool>? onHoverItem;

  const TevahNavbar({super.key, required this.currentRoute, this.onHoverItem});

  @override
  State<TevahNavbar> createState() => _TevahNavbarState();
}

class _TevahNavbarState extends State<TevahNavbar> {
  // Portfolio starts hidden.
  //
  // It will only become true after the API successfully confirms
  // that the portfolio is available.
  bool _portfolioAvailable = false;

  bool _checkingPortfolio = true;

  @override
  void initState() {
    super.initState();

    _checkPortfolioAvailability();
  }

  // ==========================================================================
  // CHECK PORTFOLIO API
  // ==========================================================================

  Future<void> _checkPortfolioAvailability() async {
    try {
      print('Checking portfolio availability...');

      final bool available =
          await PortfolioAvailabilityService.isPortfolioAvailable();

      if (!mounted) return;

      setState(() {
        _portfolioAvailable = available;
        _checkingPortfolio = false;
      });

      print('Portfolio availability result: $_portfolioAvailable');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _portfolioAvailable = false;
        _checkingPortfolio = false;
      });

      print('Portfolio availability check failed: $e');
    }
  }

  // ==========================================================================
  // NAVIGATION
  // ==========================================================================

  void _navigate(BuildContext context, NavRoute target) {
    if (target == widget.currentRoute) {
      return;
    }

    // ------------------------------------------------------------------------
    // IMPORTANT:
    // Never allow Portfolio navigation if API says unavailable.
    // ------------------------------------------------------------------------

    if (target == NavRoute.portfolio && !_portfolioAvailable) {
      print('Portfolio navigation blocked because portfolio is unavailable.');
      return;
    }

    // ------------------------------------------------------------------------
    // DROPBOX
    // ------------------------------------------------------------------------

    if (target == NavRoute.dropbox) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const DropboxPage()));

      return;
    }

    Widget page;

    switch (target) {
      case NavRoute.home:
        page = const MainAgencyScreen();
        break;

      case NavRoute.about:
        page = const AboutScreen();
        break;

      case NavRoute.portfolio:
        page = const PortfolioScreen();
        break;

      default:
        return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  // ==========================================================================
  // MOBILE MENU
  // ==========================================================================

  void _openMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----------------------------------------------------------------
              // HEADER
              // ----------------------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'NAVIGATION',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brandRed,
                      letterSpacing: 2.0,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ----------------------------------------------------------------
              // HOME
              // ----------------------------------------------------------------
              _MobileNavItem(
                text: 'Home',
                isActive: widget.currentRoute == NavRoute.home,
                onTap: () {
                  Navigator.of(context).pop();

                  _navigate(context, NavRoute.home);
                },
              ),

              // ----------------------------------------------------------------
              // ABOUT
              // ----------------------------------------------------------------
              _MobileNavItem(
                text: 'About Us',
                isActive: widget.currentRoute == NavRoute.about,
                onTap: () {
                  Navigator.of(context).pop();

                  _navigate(context, NavRoute.about);
                },
              ),

              // ----------------------------------------------------------------
              // PORTFOLIO
              //
              // ONLY SHOW WHEN API CONFIRMS AVAILABILITY
              // ----------------------------------------------------------------
              if (_portfolioAvailable)
                _MobileNavItem(
                  text: 'Portfolio',
                  isActive: widget.currentRoute == NavRoute.portfolio,
                  onTap: () {
                    Navigator.of(context).pop();

                    _navigate(context, NavRoute.portfolio);
                  },
                ),

              const SizedBox(height: 24),

              // ----------------------------------------------------------------
              // LET'S TALK
              // ----------------------------------------------------------------
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();

                    openLetsTalkModal(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    "Let's Talk",
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================================
  // BUILD NAVBAR
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    final bool isMobile = screenWidth < 900;

    final double horizontalPadding = isMobile ? 16.0 : 48.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 20.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ==================================================================
          // LOGO
          // ==================================================================
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                _navigate(context, NavRoute.home);
              },
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 8 : 10,
                      vertical: isMobile ? 3 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.brandRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'T',
                      style: TextStyle(
                        fontFamily: 'Thunder',
                        fontWeight: FontWeight.w700,
                        fontSize: isMobile ? 22 : 26,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TEVAH',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: isMobile ? 16 : 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'TECH SOLUTIONS PRIVATE LIMITED',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: isMobile ? 7 : 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white38,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ==================================================================
          // MOBILE NAVIGATION
          // ==================================================================
          if (isMobile) ...[
            IconButton(
              icon: const Icon(
                Icons.menu_rounded,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () {
                _openMobileMenu(context);
              },
            ),
          ]
          // ==================================================================
          // DESKTOP NAVIGATION
          // ==================================================================
          else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: AppTheme.greyBorder),
              ),
              child: Row(
                children: [
                  // ------------------------------------------------------------
                  // HOME
                  // ------------------------------------------------------------
                  _NavItem(
                    text: 'Home',
                    isActive: widget.currentRoute == NavRoute.home,
                    onTap: () {
                      _navigate(context, NavRoute.home);
                    },
                    onHover: (h) {
                      widget.onHoverItem?.call(h);
                    },
                  ),

                  const SizedBox(width: 24),

                  // ------------------------------------------------------------
                  // ABOUT
                  // ------------------------------------------------------------
                  _NavItem(
                    text: 'About Us',
                    isActive: widget.currentRoute == NavRoute.about,
                    onTap: () {
                      _navigate(context, NavRoute.about);
                    },
                    onHover: (h) {
                      widget.onHoverItem?.call(h);
                    },
                  ),

                  // ------------------------------------------------------------
                  // PORTFOLIO
                  //
                  // ONLY CREATE THE NAV ITEM IF AVAILABLE
                  // ------------------------------------------------------------
                  if (_portfolioAvailable) ...[
                    const SizedBox(width: 24),

                    _NavItem(
                      text: 'Portfolio',
                      isActive: widget.currentRoute == NavRoute.portfolio,
                      onTap: () {
                        _navigate(context, NavRoute.portfolio);
                      },
                      onHover: (h) {
                        widget.onHoverItem?.call(h);
                      },
                    ),
                  ],
                ],
              ),
            ),

            // =================================================================
            // LET'S TALK
            // =================================================================
            _MagneticPillButton(
              label: "Let's Talk",
              onHover: (h) {
                widget.onHoverItem?.call(h);
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// MOBILE NAVIGATION LIST ITEM
// ============================================================================

class _MobileNavItem extends StatelessWidget {
  final String text;
  final bool isActive;
  final VoidCallback onTap;

  const _MobileNavItem({
    required this.text,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            color: isActive ? AppTheme.brandRed : Colors.white,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// DESKTOP NAVIGATION LINK ITEM
// ============================================================================

class _NavItem extends StatefulWidget {
  final String text;
  final bool isActive;
  final ValueChanged<bool> onHover;
  final VoidCallback? onTap;

  const _NavItem({
    required this.text,
    this.isActive = false,
    required this.onHover,
    this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) {
        setState(() {
          _hovered = true;
        });

        widget.onHover(true);
      },
      onExit: (_) {
        setState(() {
          _hovered = false;
        });

        widget.onHover(false);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: widget.isActive ? FontWeight.bold : FontWeight.w600,
            color: widget.isActive || _hovered
                ? AppTheme.brandRed
                : Colors.white,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// HEADER MAGNETIC CTA PILL BUTTON
// ============================================================================

class _MagneticPillButton extends StatefulWidget {
  final String label;
  final ValueChanged<bool> onHover;

  const _MagneticPillButton({required this.label, required this.onHover});

  @override
  State<_MagneticPillButton> createState() => _MagneticPillButtonState();
}

class _MagneticPillButtonState extends State<_MagneticPillButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() {
          _hovered = true;
        });

        widget.onHover(true);
      },
      onExit: (_) {
        setState(() {
          _hovered = false;
        });

        widget.onHover(false);
      },
      child: GestureDetector(
        onTap: () {
          openLetsTalkModal(context);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: _hovered ? AppTheme.brandRed : Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.plusJakartaSans(
              color: _hovered ? Colors.white : Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// HERO GRID BACKGROUND PAINTER
// ============================================================================

class HeroGridBackgroundPainter extends CustomPainter {
  final Offset cursorPos;
  final double animationProgress;

  HeroGridBackgroundPainter({
    required this.cursorPos,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1.0;

    const double step = 60.0;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (cursorPos != Offset.zero) {
      final Paint mouseGlowPaint = Paint()
        ..shader = RadialGradient(
          colors: [AppTheme.brandRed.withOpacity(0.12), Colors.transparent],
        ).createShader(Rect.fromCircle(center: cursorPos, radius: 350));

      canvas.drawCircle(cursorPos, 350, mouseGlowPaint);
    }

    final math.Random rand = math.Random(42);

    final Paint particlePaint = Paint()..color = Colors.white.withOpacity(0.18);

    for (int i = 0; i < 40; i++) {
      final double x = rand.nextDouble() * size.width;

      final double initialY = rand.nextDouble() * size.height;

      final double speed = 20 + rand.nextDouble() * 40;

      final double y =
          (initialY - animationProgress * speed * 20) % size.height;

      final double radius = 1.0 + rand.nextDouble() * 2.0;

      canvas.drawCircle(Offset(x, y), radius, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant HeroGridBackgroundPainter oldDelegate) => true;
}

// ============================================================================
// CINEMATIC AGENCY FOOTER
// ============================================================================

class AgencyFooter extends StatefulWidget {
  const AgencyFooter({super.key});

  @override
  State<AgencyFooter> createState() => _AgencyFooterState();
}

class _AgencyFooterState extends State<AgencyFooter> {
  Offset _cursorPos = Offset.zero;

  bool _isCopied = false;

  void _scrollToTop(BuildContext context) {
    final ScrollController? primaryController = PrimaryScrollController.of(
      context,
    );

    if (primaryController != null && primaryController.hasClients) {
      primaryController.animateTo(
        0,
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _copyEmail() {
    Clipboard.setData(const ClipboardData(text: 'support@tevah.technology'));

    setState(() {
      _isCopied = true;
    });

    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isCopied = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    final bool isMobile = screenWidth < 768;

    final double padding = isMobile ? 20.0 : 48.0;

    return MouseRegion(
      onHover: (e) {
        setState(() {
          _cursorPos = e.position;
        });
      },
      child: Container(
        color: const Color(0xFF060607),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: FooterAtmospherePainter(cursorPos: _cursorPos),
              ),
            ),

            Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    padding,
                    isMobile ? 40 : 80,
                    padding,
                    40,
                  ),
                  child: Column(
                    children: [
                      if (isMobile) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _BrandSummary(),

                            const SizedBox(height: 28),

                            _MajorEmailSection(
                              isCopied: _isCopied,
                              onCopy: _copyEmail,
                            ),

                            const SizedBox(height: 40),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _FooterInteractiveNavColumn(
                                  title: 'SERVICES',
                                  links: const [
                                    {'label': 'Web Development'},
                                    {'label': 'Mobile Apps'},
                                    {'label': 'AI & Automation'},
                                    {'label': 'UI/UX Design'},
                                    {'label': 'Brand Identity'},
                                    {'label': 'Video & Motion'},
                                    {'label': 'WordPress'},
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 36),

                            _SocialConnectColumn(),
                          ],
                        ),
                      ] else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _BrandSummary(),

                                  const SizedBox(height: 36),

                                  _MajorEmailSection(
                                    isCopied: _isCopied,
                                    onCopy: _copyEmail,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 40),

                            const SizedBox(width: 60),

                            _FooterInteractiveNavColumn(
                              title: 'SERVICES',
                              links: const [
                                {'label': 'Web Development'},
                                {'label': 'Mobile Applications'},
                                {'label': 'AI & Automation'},
                                {'label': 'UI / UX Design'},
                                {'label': 'Brand Identity'},
                                {'label': 'Video & Motion'},
                                {'label': 'WordPress'},
                              ],
                            ),

                            const SizedBox(width: 60),

                            _SocialConnectColumn(),
                          ],
                        ),
                      ],

                      SizedBox(height: isMobile ? 40 : 80),

                      const Divider(color: AppTheme.greyBorder),

                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '© 2026 TEVAH TECH SOLUTIONS PRIVATE LIMITED',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: isMobile ? 10 : 12,
                                color: Colors.white38,
                              ),
                            ),
                          ),

                          _BackToTopButton(
                            onTap: () {
                              _scrollToTop(context);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// FOOTER - BRAND SUMMARY
// ============================================================================

class _BrandSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TEVAH',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Technology.\n'
          'Creativity.\n'
          'Intelligence.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            height: 1.5,
            color: Colors.white38,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// FOOTER - EMAIL
// ============================================================================

class _MajorEmailSection extends StatelessWidget {
  final bool isCopied;
  final VoidCallback onCopy;

  const _MajorEmailSection({required this.isCopied, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HAVE A PROJECT?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppTheme.brandRed,
            letterSpacing: 2.0,
          ),
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'support@tevah.tech',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(width: 12),

            InkWell(
              onTap: onCopy,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isCopied
                      ? AppTheme.brandRed
                      : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCopied ? Icons.check : Icons.copy_rounded,
                      size: 12,
                      color: Colors.white,
                    ),

                    const SizedBox(width: 4),

                    Text(
                      isCopied ? 'COPIED' : ' ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// FOOTER NAVIGATION COLUMN
// ============================================================================

class _FooterInteractiveNavColumn extends StatelessWidget {
  final String title;

  final List<Map<String, dynamic>> links;

  const _FooterInteractiveNavColumn({required this.title, required this.links});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppTheme.brandRed,
            letterSpacing: 2.0,
          ),
        ),

        const SizedBox(height: 20),

        ...links.map((link) {
          return _FooterLinkRow(
            label: link['label'] as String,
            route: link['route'] as NavRoute?,
          );
        }),
      ],
    );
  }
}

// ============================================================================
// FOOTER LINK ROW
// ============================================================================

class _FooterLinkRow extends StatefulWidget {
  final String label;
  final NavRoute? route;

  const _FooterLinkRow({required this.label, this.route});

  @override
  State<_FooterLinkRow> createState() => _FooterLinkRowState();
}

class _FooterLinkRowState extends State<_FooterLinkRow> {
  bool _isHovered = false;

  void _navigate(BuildContext context) {
    if (widget.route == null) {
      return;
    }

    if (widget.route == NavRoute.dropbox) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const DropboxPage()));

      return;
    }

    Widget page;

    switch (widget.route!) {
      case NavRoute.home:
        page = const MainAgencyScreen();
        break;

      case NavRoute.about:
        page = const AboutScreen();
        break;

      case NavRoute.portfolio:
        page = const PortfolioScreen();
        break;

      default:
        return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.route != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
      },
      child: GestureDetector(
        onTap: () {
          _navigate(context);
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.translationValues(_isHovered ? 8 : 0, 0, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _isHovered ? AppTheme.brandRed : Colors.white70,
                  ),
                ),

                const SizedBox(width: 6),

                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isHovered ? 1.0 : 0.0,
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: AppTheme.brandRed,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SOCIAL CONNECT
// ============================================================================

class _SocialConnectColumn extends StatelessWidget {
  static const List<Map<String, String>> socials = [
    {'name': 'Instagram', 'url': 'https://instagram.com'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONNECT',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppTheme.brandRed,
            letterSpacing: 2.0,
          ),
        ),

        const SizedBox(height: 20),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: socials.map((social) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: _MagneticSocialBadge(
                name: social['name']!,
                url: social['url']!,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ============================================================================
// SOCIAL BADGE
// ============================================================================

class _MagneticSocialBadge extends StatefulWidget {
  final String name;
  final String url;

  const _MagneticSocialBadge({required this.name, required this.url});

  @override
  State<_MagneticSocialBadge> createState() => _MagneticSocialBadgeState();
}

class _MagneticSocialBadgeState extends State<_MagneticSocialBadge> {
  bool _isHovered = false;

  Future<void> _launchSocial() async {
    final Uri uri = Uri.parse(widget.url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
      },
      child: GestureDetector(
        onTap: _launchSocial,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppTheme.brandRed
                : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered ? AppTheme.brandRed : AppTheme.greyBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _isHovered ? 8 : 6,
                height: _isHovered ? 8 : 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isHovered ? Colors.white : AppTheme.brandRed,
                ),
              ),

              const SizedBox(width: 8),

              Text(
                widget.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _isHovered ? Colors.white : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// BACK TO TOP BUTTON
// ============================================================================

class _BackToTopButton extends StatefulWidget {
  final VoidCallback onTap;

  const _BackToTopButton({required this.onTap});

  @override
  State<_BackToTopButton> createState() => _BackToTopButtonState();
}

class _BackToTopButtonState extends State<_BackToTopButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppTheme.brandRed
                : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _isHovered ? AppTheme.brandRed : AppTheme.greyBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'BACK TO TOP',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _isHovered ? Colors.white : Colors.white60,
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(width: 8),

              AnimatedRotation(
                turns: _isHovered ? -0.125 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  Icons.arrow_upward_rounded,
                  size: 14,
                  color: _isHovered ? Colors.white : Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// FLOATING WHATSAPP BUTTON
// GLOBAL OVERLAY
// ============================================================================

class FloatingWhatsAppButton extends StatefulWidget {
  final String phoneNumber;
  final String defaultMessage;

  const FloatingWhatsAppButton({
    super.key,
    this.phoneNumber = '9188075549',
    this.defaultMessage =
        'Hello TEVAH team, I would like to discuss a project!',
  });

  @override
  State<FloatingWhatsAppButton> createState() => _FloatingWhatsAppButtonState();
}

class _FloatingWhatsAppButtonState extends State<FloatingWhatsAppButton> {
  bool _isHovered = false;

  Future<void> _openWhatsApp() async {
    final String encodedMsg = Uri.encodeComponent(widget.defaultMessage);

    final Uri url = Uri.parse(
      'https://wa.me/${widget.phoneNumber}?text=$encodedMsg',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    final bool isMobile = screenWidth < 768;

    return Positioned(
      bottom: isMobile ? 20 : 32,
      right: isMobile ? 16 : 32,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          setState(() {
            _isHovered = true;
          });
        },
        onExit: (_) {
          setState(() {
            _isHovered = false;
          });
        },
        child: GestureDetector(
          onTap: _openWhatsApp,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, _isHovered ? -6 : 0, 0),
            padding: EdgeInsets.symmetric(
              horizontal: _isHovered && !isMobile ? 20 : 14,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF25D366),
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFF25D366,
                  ).withOpacity(_isHovered ? 0.5 : 0.3),
                  blurRadius: _isHovered ? 20 : 12,
                  spreadRadius: _isHovered ? 2 : 0,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FaIcon(
                  FontAwesomeIcons.whatsapp,
                  color: Colors.white,
                  size: 28,
                ),

                if (_isHovered && !isMobile) ...[
                  const SizedBox(width: 10),
                  Text(
                    'Chat on WhatsApp',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// FOOTER ATMOSPHERE PAINTER
// ============================================================================

class FooterAtmospherePainter extends CustomPainter {
  final Offset cursorPos;

  FooterAtmospherePainter({required this.cursorPos});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [AppTheme.brandRed.withOpacity(0.12), Colors.transparent],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width / 2, size.height * 0.35),
              radius: size.width * 0.5,
            ),
          );

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);

    final Paint gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.018)
      ..strokeWidth = 1.0;

    const double step = 70.0;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant FooterAtmospherePainter oldDelegate) =>
      oldDelegate.cursorPos != cursorPos;
}

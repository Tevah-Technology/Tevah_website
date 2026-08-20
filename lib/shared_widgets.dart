import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tevahweb/portfolio_availability.dart';
import 'package:url_launcher/url_launcher.dart';

import 'about_screen.dart';
import 'dropbox.dart';
import 'home_screen.dart';
import 'legal_screen.dart';
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
  legal,
}

// ============================================================================
// CENTRAL BRAND PALETTE
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
// ============================================================================

class TevahNavbar extends StatefulWidget {
  final NavRoute currentRoute;
  final ValueChanged<bool>? onHoverItem;

  const TevahNavbar({super.key, required this.currentRoute, this.onHoverItem});

  @override
  State<TevahNavbar> createState() => _TevahNavbarState();
}

class _TevahNavbarState extends State<TevahNavbar> {
  bool _portfolioAvailable = false;
  bool _checkingPortfolio = true;

  @override
  void initState() {
    super.initState();
    _checkPortfolioAvailability();
  }

  Future<void> _checkPortfolioAvailability() async {
    try {
      final bool available =
      await PortfolioAvailabilityService.isPortfolioAvailable();

      if (!mounted) return;

      setState(() {
        _portfolioAvailable = available;
        _checkingPortfolio = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _portfolioAvailable = false;
        _checkingPortfolio = false;
      });
    }
  }

  void _navigate(BuildContext context, NavRoute target) {
    if (target == widget.currentRoute) return;

    if (target == NavRoute.portfolio && !_portfolioAvailable) return;

    if (target == NavRoute.dropbox) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const DropboxPage()));
      return;
    }

    switch (target) {
      case NavRoute.home:
        context.go('/home');
        break;
      case NavRoute.about:
        context.go('/about');
        break;
      case NavRoute.portfolio:
        context.go('/portfolio');
        break;
      case NavRoute.legal:
        context.go('/terms-and-conditions');
        break;
      default:
        break;
    }
  }

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
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _MobileNavItem(
                text: 'Home',
                isActive: widget.currentRoute == NavRoute.home,
                onTap: () {
                  Navigator.of(context).pop();
                  _navigate(context, NavRoute.home);
                },
              ),
              _MobileNavItem(
                text: 'About Us',
                isActive: widget.currentRoute == NavRoute.about,
                onTap: () {
                  Navigator.of(context).pop();
                  _navigate(context, NavRoute.about);
                },
              ),
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
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _navigate(context, NavRoute.home),
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
          if (isMobile) ...[
            IconButton(
              icon: const Icon(
                Icons.menu_rounded,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () => _openMobileMenu(context),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: AppTheme.greyBorder),
              ),
              child: Row(
                children: [
                  _NavItem(
                    text: 'Home',
                    isActive: widget.currentRoute == NavRoute.home,
                    onTap: () => _navigate(context, NavRoute.home),
                    onHover: (h) => widget.onHoverItem?.call(h),
                  ),
                  const SizedBox(width: 24),
                  _NavItem(
                    text: 'About Us',
                    isActive: widget.currentRoute == NavRoute.about,
                    onTap: () => _navigate(context, NavRoute.about),
                    onHover: (h) => widget.onHoverItem?.call(h),
                  ),
                  if (_portfolioAvailable) ...[
                    const SizedBox(width: 24),
                    _NavItem(
                      text: 'Portfolio',
                      isActive: widget.currentRoute == NavRoute.portfolio,
                      onTap: () => _navigate(context, NavRoute.portfolio),
                      onHover: (h) => widget.onHoverItem?.call(h),
                    ),
                  ],
                ],
              ),
            ),
            _MagneticPillButton(
              label: "Let's Talk",
              onHover: (h) => widget.onHoverItem?.call(h),
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
        setState(() => _hovered = true);
        widget.onHover(true);
      },
      onExit: (_) {
        setState(() => _hovered = false);
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
        setState(() => _hovered = true);
        widget.onHover(true);
      },
      onExit: (_) {
        setState(() => _hovered = false);
        widget.onHover(false);
      },
      child: GestureDetector(
        onTap: () => openLetsTalkModal(context),
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
  final String careersUrl;
  final String whatsappNumber;
  final ScrollController? scrollController;
  final VoidCallback? onBackToTop;

  const AgencyFooter({
    super.key,
    this.careersUrl = 'https://tevah.technology/careers',
    this.whatsappNumber = '919188075549',
    this.scrollController,
    this.onBackToTop,
  });

  @override
  State<AgencyFooter> createState() => _AgencyFooterState();
}

class _AgencyFooterState extends State<AgencyFooter> {
  Offset _cursorPos = Offset.zero;
  bool _isCopied = false;

  void _scrollToTop(BuildContext context) {
    if (widget.onBackToTop != null) {
      widget.onBackToTop!();
      return;
    }

    if (widget.scrollController != null &&
        widget.scrollController!.hasClients) {
      widget.scrollController!.animateTo(
        0,
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOutCubic,
      );
      return;
    }

    final ScrollController? primaryController =
    PrimaryScrollController.maybeOf(context);
    if (primaryController != null && primaryController.hasClients) {
      primaryController.animateTo(
        0,
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOutCubic,
      );
      return;
    }

    final ScrollableState? scrollable = Scrollable.maybeOf(context);
    if (scrollable != null && scrollable.position.hasContentDimensions) {
      scrollable.position.animateTo(
        0,
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _copyEmail() {
    Clipboard.setData(const ClipboardData(text: 'info@tevah.technology'));
    setState(() => _isCopied = true);

    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isCopied = false);
      }
    });
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openMediaConsultationWhatsApp() async {
    final String cleanNumber =
    widget.whatsappNumber.replaceAll(RegExp(r'[^0-9]'), '');
    const String msg =
        'Hello TEVAH team, I would like to request a free consultation for our media and digital needs.';
    final String encodedMsg = Uri.encodeComponent(msg);
    final Uri url = Uri.parse('https://wa.me/$cleanNumber?text=$encodedMsg');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _openWorkRequestModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) =>
          _WorkRequestModal(whatsappNumber: widget.whatsappNumber),
    );
  }

  void _navigateToLegal(BuildContext context, LegalSection section) {
    switch (section) {
      case LegalSection.terms:
        context.go('/terms-and-conditions');
        break;
      case LegalSection.privacy:
        context.go('/privacy-policy');
        break;
      case LegalSection.refund:
        context.go('/refund-and-cancellation');
        break;
      case LegalSection.contact:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;
    final double padding = isMobile ? 20.0 : 56.0;
    final int currentYear = DateTime.now().year;

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

            // Background Watermark
            Positioned(
              bottom: isMobile ? 60 : 40,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'TEVAH',
                  style: TextStyle(
                    fontFamily: 'Thunder',
                    fontSize: isMobile ? screenWidth * 0.28 : 220,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4.0,
                    color: Colors.white.withOpacity(0.018),
                    height: 0.8,
                  ),
                ),
              ),
            ),

            Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    padding,
                    isMobile ? 50 : 90,
                    padding,
                    36,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _AvailabilityStatusBadge(),
                      const SizedBox(height: 28),
                      if (isMobile) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _BrandSummary(),
                            const SizedBox(height: 24),
                            _EmailInteractiveBentoCard(
                              isCopied: _isCopied,
                              onCopy: _copyEmail,
                            ),
                            const SizedBox(height: 24),
                            _FooterActionCards(
                              onCareersTap: () => _launchURL(widget.careersUrl),
                              onWorkRequestTap: () =>
                                  _openWorkRequestModal(context),
                              onConsultationTap:
                              _openMediaConsultationWhatsApp,
                            ),
                            const SizedBox(height: 36),
                            const _ServicesGridSection(),
                            const SizedBox(height: 36),
                            _SocialConnectSection(),
                          ],
                        ),
                      ] else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _BrandSummary(),
                                  const SizedBox(height: 28),
                                  _EmailInteractiveBentoCard(
                                    isCopied: _isCopied,
                                    onCopy: _copyEmail,
                                  ),
                                  const SizedBox(height: 20),
                                  _FooterActionCards(
                                    onCareersTap: () =>
                                        _launchURL(widget.careersUrl),
                                    onWorkRequestTap: () =>
                                        _openWorkRequestModal(context),
                                    onConsultationTap:
                                    _openMediaConsultationWhatsApp,
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(flex: 1),
                            const Expanded(
                              flex: 4,
                              child: _ServicesGridSection(),
                            ),
                            const SizedBox(width: 48),
                            Expanded(
                              flex: 3,
                              child: _SocialConnectSection(),
                            ),
                          ],
                        ),
                      ],
                      SizedBox(height: isMobile ? 48 : 80),
                      const Divider(color: AppTheme.greyBorder),
                      const SizedBox(height: 24),

                      // Copyright & Interactive Legal Anchor Links
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          Text(
                            '© $currentYear TEVAH TECH SOLUTIONS PRIVATE LIMITED',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: isMobile ? 10 : 12,
                              color: Colors.white30,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Wrap(
                            spacing: 18,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _LegalFooterLink(
                                title: 'Terms & Conditions',
                                onTap: () => _navigateToLegal(
                                  context,
                                  LegalSection.terms,
                                ),
                              ),
                              _LegalFooterLink(
                                title: 'Privacy Policy',
                                onTap: () => _navigateToLegal(
                                  context,
                                  LegalSection.privacy,
                                ),
                              ),
                              _LegalFooterLink(
                                title: 'Refund & Cancellation',
                                onTap: () => _navigateToLegal(
                                  context,
                                  LegalSection.refund,
                                ),
                              ),
                            ],
                          ),
                          _BackToTopButton(
                            onTap: () => _scrollToTop(context),
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
// FOOTER LEGAL LINK WITH GLOWING BULLET INDICATOR
// ============================================================================

class _LegalFooterLink extends StatefulWidget {
  final String title;
  final VoidCallback onTap;

  const _LegalFooterLink({required this.title, required this.onTap});

  @override
  State<_LegalFooterLink> createState() => _LegalFooterLinkState();
}

class _LegalFooterLinkState extends State<_LegalFooterLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _hovered ? AppTheme.brandRed : Colors.white24,
                boxShadow: _hovered
                    ? [
                  BoxShadow(
                    color: AppTheme.brandRed.withOpacity(0.8),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
                    : [],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: _hovered ? FontWeight.w600 : FontWeight.w500,
                color: _hovered ? Colors.white : Colors.white54,
                decoration:
                _hovered ? TextDecoration.underline : TextDecoration.none,
                decorationColor: AppTheme.brandRed,
              ),
              child: Text(widget.title),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// WORK REQUEST MODAL (DISPATCHES TO WHATSAPP)
// ============================================================================

class _WorkRequestModal extends StatefulWidget {
  final String whatsappNumber;
  const _WorkRequestModal({required this.whatsappNumber});

  @override
  State<_WorkRequestModal> createState() => _WorkRequestModalState();
}

class _WorkRequestModalState extends State<_WorkRequestModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _emailController = TextEditingController();
  final _detailsController = TextEditingController();

  String _selectedService = 'Web Development';
  String _selectedPriority = 'Medium';
  DateTime? _selectedDueDate;

  final List<String> _services = [
    'Web Development',
    'Mobile Apps',
    'AI & Automation',
    'UI / UX Design',
    'Video & Motion',
    'Brand Identity',
    'WordPress',
  ];

  final List<String> _priorities = ['High', 'Medium', 'Low'];

  Future<void> _pickDueDate(BuildContext context) async {
    final DateTime initialDate =
        _selectedDueDate ?? DateTime.now().add(const Duration(days: 7));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.brandRed,
              onPrimary: Colors.white,
              surface: Color(0xFF18181D),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF141416),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  Future<void> _sendWorkRequestToWhatsApp() async {
    if (!_formKey.currentState!.validate()) return;

    final String clientName = _nameController.text.trim();
    final String company = _companyController.text.trim().isEmpty
        ? 'Individual'
        : _companyController.text.trim();
    final String email = _emailController.text.trim();
    final String dueDateStr = _selectedDueDate != null
        ? '${_selectedDueDate!.day.toString().padLeft(2, '0')}/${_selectedDueDate!.month.toString().padLeft(2, '0')}/${_selectedDueDate!.year}'
        : 'Flexible / Not specified';
    final String details = _detailsController.text.trim();

    final String formattedMessage = '''
*📩 NEW WORK REQUEST [TEVAH PORTAL]*
━━━━━━━━━━━━━━━━━━━━━
*📌 Service Required:* $_selectedService
*👤 Client / Contact:* $clientName
*🏢 Company / Organization:* $company
*📧 Email Address:* $email
*⚡ Priority Level:* $_selectedPriority
*📅 Target Due Date:* $dueDateStr

*📝 Project Scope & Details:*
$details

━━━━━━━━━━━━━━━━━━━━━
_Sent via TEVAH Work Request Dispatcher_
''';

    final String cleanNumber =
    widget.whatsappNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final String encodedMsg = Uri.encodeComponent(formattedMessage);
    final Uri url = Uri.parse('https://wa.me/$cleanNumber?text=$encodedMsg');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 650;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: isMobile ? screenWidth * 0.92 : 560,
          constraints: const BoxConstraints(maxHeight: 740),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF111114),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.brandRed.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.8),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.brandRed,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'T',
                              style: TextStyle(
                                fontFamily: 'Thunder',
                                fontWeight: FontWeight.w700,
                                fontSize: 22,
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'WORK INQUIRY REQUEST',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.brandRed,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                'Submit Project Brief',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'SELECT SERVICE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedService,
                    dropdownColor: const Color(0xFF18181D),
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.04),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                        const BorderSide(color: AppTheme.greyBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                        const BorderSide(color: AppTheme.greyBorder),
                      ),
                    ),
                    items: _services.map((s) {
                      return DropdownMenuItem(value: s, child: Text(s));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedService = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nameController,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Your Name *',
                            labelStyle: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.04),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                              const BorderSide(color: AppTheme.greyBorder),
                            ),
                          ),
                          validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _companyController,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Company / Org',
                            labelStyle: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.04),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                              const BorderSide(color: AppTheme.greyBorder),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Email Address *',
                      labelStyle: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                        const BorderSide(color: AppTheme.greyBorder),
                      ),
                    ),
                    validator: (v) => v == null || !v.contains('@')
                        ? 'Valid email required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedPriority,
                          dropdownColor: const Color(0xFF18181D),
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Priority',
                            labelStyle: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.04),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                              const BorderSide(color: AppTheme.greyBorder),
                            ),
                          ),
                          items: _priorities.map((p) {
                            return DropdownMenuItem(
                              value: p,
                              child: Text('$p Priority'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedPriority = val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDueDate(context),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.greyBorder),
                            ),
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Due Date',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        color: Colors.white38,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _selectedDueDate != null
                                          ? '${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}'
                                          : 'Select Date',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedDueDate != null
                                            ? Colors.white
                                            : Colors.white60,
                                      ),
                                    ),
                                  ],
                                ),
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 16,
                                  color: AppTheme.brandRed,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _detailsController,
                    maxLines: 3,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Project Brief / Scope Details *',
                      labelStyle: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                        const BorderSide(color: AppTheme.greyBorder),
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? 'Please describe your request'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _sendWorkRequestToWhatsApp,
                      icon: const FaIcon(
                        FontAwesomeIcons.whatsapp,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: Text(
                        'Dispatch Request via WhatsApp',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// FOOTER - ACTION CARDS
// ============================================================================

class _FooterActionCards extends StatelessWidget {
  final VoidCallback onCareersTap;
  final VoidCallback onWorkRequestTap;
  final VoidCallback onConsultationTap;

  const _FooterActionCards({
    required this.onCareersTap,
    required this.onWorkRequestTap,
    required this.onConsultationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _QuickActionCard(
          title: 'Free Media Consultation',
          subtitle: 'Audit, strategy & production advisory for your brand',
          icon: Icons.video_camera_front_outlined,
          onTap: onConsultationTap,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                title: 'Job Portal',
                subtitle: 'Join the team',
                icon: Icons.work_outline_rounded,
                isCompact: true,
                onTap: onCareersTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                title: 'Work Request',
                subtitle: 'Inquire via WhatsApp',
                icon: Icons.post_add_rounded,
                isCompact: true,
                badgeText: 'DISPATCH',
                badgeColor: const Color(0xFF25D366),
                onTap: onWorkRequestTap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isCompact;
  final String? badgeText;
  final Color? badgeColor;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isCompact = false,
    this.badgeText,
    this.badgeColor,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: widget.isCompact ? 12 : 14,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(_isHovered ? 0.05 : 0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? (widget.badgeColor ?? AppTheme.brandRed).withOpacity(0.6)
                  : AppTheme.greyBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isHovered
                      ? (widget.badgeColor ?? AppTheme.brandRed).withOpacity(0.2)
                      : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.icon,
                  size: 16,
                  color: _isHovered
                      ? (widget.badgeColor ?? AppTheme.brandRed)
                      : Colors.white70,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.badgeText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: widget.badgeColor?.withOpacity(0.2) ??
                                  AppTheme.brandRed.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: widget.badgeColor?.withOpacity(0.4) ??
                                    AppTheme.brandRed.withOpacity(0.4),
                              ),
                            ),
                            child: Text(
                              widget.badgeText!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: widget.badgeColor ?? AppTheme.brandRed,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.white38,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_outward_rounded,
                size: 14,
                color: _isHovered
                    ? (widget.badgeColor ?? AppTheme.brandRed)
                    : Colors.white24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// FOOTER - LIVE AVAILABILITY BADGE
// ============================================================================

class _AvailabilityStatusBadge extends StatefulWidget {
  const _AvailabilityStatusBadge();

  @override
  State<_AvailabilityStatusBadge> createState() =>
      _AvailabilityStatusBadgeState();
}

class _AvailabilityStatusBadgeState extends State<_AvailabilityStatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF10B981,
                      ).withOpacity(_pulseController.value * 0.8),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Text(
            'AVAILABLE FOR NEW PROJECTS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: const Color(0xFF34D399),
            ),
          ),
        ],
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
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.brandRed,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'T',
                style: TextStyle(
                  fontFamily: 'Thunder',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'TEVAH',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Technology. Creativity. Intelligence.\nCrafting future-ready digital platforms and experiences.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            height: 1.6,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// FOOTER - EMAIL BENTO CARD
// ============================================================================

class _EmailInteractiveBentoCard extends StatefulWidget {
  final bool isCopied;
  final VoidCallback onCopy;

  const _EmailInteractiveBentoCard({
    required this.isCopied,
    required this.onCopy,
  });

  @override
  State<_EmailInteractiveBentoCard> createState() =>
      _EmailInteractiveBentoCardState();
}

class _EmailInteractiveBentoCardState
    extends State<_EmailInteractiveBentoCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(_isHovered ? 0.04 : 0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? AppTheme.brandRed.withOpacity(0.6)
                : AppTheme.greyBorder,
          ),
          boxShadow: _isHovered
              ? [
            BoxShadow(
              color: AppTheme.brandRed.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                Icon(
                  Icons.arrow_outward_rounded,
                  size: 16,
                  color: _isHovered ? AppTheme.brandRed : Colors.white24,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'info@tevah.technology',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onCopy,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isCopied
                          ? AppTheme.brandRed
                          : Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.isCopied
                              ? Icons.check_rounded
                              : Icons.copy_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          widget.isCopied ? 'COPIED' : 'COPY',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
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
        ),
      ),
    );
  }
}

// ============================================================================
// FOOTER SERVICES GRID & TAGS
// ============================================================================

class _ServicesGridSection extends StatelessWidget {
  const _ServicesGridSection();

  static const List<String> services = [
    'Web Development',
    'Mobile Apps',
    'AI & Automation',
    'UI / UX Design',
    'Brand Identity',
    'Video & Motion',
    'WordPress',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SERVICES',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppTheme.brandRed,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: services.map((s) => _ServiceTag(label: s)).toList(),
        ),
      ],
    );
  }
}

class _ServiceTag extends StatefulWidget {
  final String label;
  const _ServiceTag({required this.label});

  @override
  State<_ServiceTag> createState() => _ServiceTagState();
}

class _ServiceTagState extends State<_ServiceTag> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _hovered
              ? AppTheme.brandRed.withOpacity(0.12)
              : Colors.white.withOpacity(0.025),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _hovered
                ? AppTheme.brandRed.withOpacity(0.5)
                : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Text(
          widget.label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _hovered ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// FOOTER SOCIAL CONNECT
// ============================================================================

class _SocialConnectSection extends StatelessWidget {
  static const List<Map<String, dynamic>> socials = [
    {
      'name': 'Instagram',
      'icon': FontAwesomeIcons.instagram,
      'url':
      'https://www.instagram.com/tevahtechsolutions?igsh=eXV0dDBneXh5ejJw',
    },
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
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: socials.map((social) {
            return _IconSocialBadge(
              name: social['name'] as String,
              icon: social['icon'] as dynamic,
              url: social['url'] as String,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _IconSocialBadge extends StatefulWidget {
  final String name;
  final dynamic icon;
  final String url;

  const _IconSocialBadge({
    required this.name,
    required this.icon,
    required this.url,
  });

  @override
  State<_IconSocialBadge> createState() => _IconSocialBadgeState();
}

class _IconSocialBadgeState extends State<_IconSocialBadge> {
  bool _hovered = false;

  Future<void> _launch() async {
    final Uri uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: _launch,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered
                ? AppTheme.brandRed
                : Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _hovered ? AppTheme.brandRed : AppTheme.greyBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                widget.icon,
                size: 13,
                color: _hovered ? Colors.white : Colors.white70,
              ),
              const SizedBox(width: 8),
              Text(
                widget.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _hovered ? Colors.white : Colors.white70,
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
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
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
// ============================================================================

class FloatingWhatsAppButton extends StatefulWidget {
  final String phoneNumber;
  final String defaultMessage;

  const FloatingWhatsAppButton({
    super.key,
    this.phoneNumber = '919188075549',
    this.defaultMessage =
    'Hello TEVAH team, I would like to discuss a project!',
  });

  @override
  State<FloatingWhatsAppButton> createState() =>
      _FloatingWhatsAppButtonState();
}

class _FloatingWhatsAppButtonState extends State<FloatingWhatsAppButton> {
  bool _isHovered = false;

  Future<void> _openWhatsApp() async {
    final String cleanNumber =
    widget.phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final String encodedMsg = Uri.encodeComponent(widget.defaultMessage);
    final Uri url = Uri.parse(
      'https://wa.me/$cleanNumber?text=$encodedMsg',
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
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
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
      ..shader = RadialGradient(
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
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'shared_widgets.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  final ValueNotifier<double> _scrollNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<Offset> _cursorNotifier = ValueNotifier<Offset>(Offset.zero);
  final ValueNotifier<bool> _isHoveringNotifier = ValueNotifier<bool>(false);

  String _cursorModeText = '';
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        _scrollNotifier.value = _scrollController.offset;
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollNotifier.dispose();
    _cursorNotifier.dispose();
    _isHoveringNotifier.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _updateCursor({required bool hovering, String text = ''}) {
    _isHoveringNotifier.value = hovering;
    _cursorModeText = text;
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;

    return MouseRegion(
      cursor: isMobile ? MouseCursor.defer : SystemMouseCursors.none,
      onHover: (e) => _cursorNotifier.value = e.position,
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Stack(
          children: [
            // 01. HARDWARE-ACCELERATED BACKGROUND CANVAS
            RepaintBoundary(
              child: ValueListenableBuilder<Offset>(
                valueListenable: _cursorNotifier,
                builder: (context, cursorPos, child) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: LightGridPainter(cursorPos: cursorPos),
                  );
                },
              ),
            ),

            // 02. NATIVE HARDWARE SMOOTH SCROLL VIEW
            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: TevahNavbar(
                    currentRoute: NavRoute.about,
                    onHoverItem: (hovering) => _updateCursor(hovering: hovering),
                  ),
                ),

                // HERO SECTION ("SINCE 2012")
                SliverToBoxAdapter(
                  child: ValueListenableBuilder<double>(
                    valueListenable: _scrollNotifier,
                    builder: (context, scrollOffset, child) {
                      return _Since2012HeroSection(scrollOffset: scrollOffset);
                    },
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: isMobile ? 60 : 100)),

                SliverToBoxAdapter(
                  child: ContinuousTickerStrip(
                    text: 'ESTABLISHED 2012 • DIGITAL SYSTEMS • CREATIVE TECHNOLOGY • ',
                    directionRight: true,
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: isMobile ? 60 : 100)),

                // KINETIC BRAND STATEMENT
                SliverToBoxAdapter(
                  child: ValueListenableBuilder<double>(
                    valueListenable: _scrollNotifier,
                    builder: (context, scrollOffset, child) {
                      return _KineticBrandStatementSection(scrollOffset: scrollOffset);
                    },
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: isMobile ? 80 : 140)),

                // CINEMATIC HORIZONTAL GALLERY
                SliverToBoxAdapter(
                  child: ValueListenableBuilder<double>(
                    valueListenable: _scrollNotifier,
                    builder: (context, scrollOffset, child) {
                      return _CinematicGalleryTrackSection(
                        scrollOffset: scrollOffset,
                        onHoverItem: (h, text) => _updateCursor(hovering: h, text: text),
                      );
                    },
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: isMobile ? 80 : 160)),

                // INTERACTIVE APPROACH TIMELINE
                SliverToBoxAdapter(
                  child: ValueListenableBuilder<double>(
                    valueListenable: _scrollNotifier,
                    builder: (context, scrollOffset, child) {
                      return _ApproachTimelineSection(scrollOffset: scrollOffset);
                    },
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: isMobile ? 80 : 160)),

                // GIANT WORD STATEMENT
                SliverToBoxAdapter(
                  child: ValueListenableBuilder<double>(
                    valueListenable: _scrollNotifier,
                    builder: (context, scrollOffset, child) {
                      return _GiantWordStatementSection(scrollOffset: scrollOffset);
                    },
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: isMobile ? 80 : 160)),

                // STATS SECTION
                SliverToBoxAdapter(
                  child: ValueListenableBuilder<double>(
                    valueListenable: _scrollNotifier,
                    builder: (context, scrollOffset, child) {
                      return _EditorialStatsSection(scrollOffset: scrollOffset);
                    },
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: isMobile ? 80 : 160)),

                // COMBINED CINEMATIC VISION & COLLABORATION PARALLAX PANEL
                SliverToBoxAdapter(
                  child: ValueListenableBuilder<double>(
                    valueListenable: _scrollNotifier,
                    builder: (context, scrollOffset, child) {
                      return CombinedVisionParallaxSection(scrollOffset: scrollOffset);
                    },
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: isMobile ? 80 : 160)),

                // INTERACTIVE 3D TEAM CARDS
                SliverToBoxAdapter(
                  child: _InteractiveTeamSection(
                    onHoverItem: (h, text) => _updateCursor(hovering: h, text: text),
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: isMobile ? 80 : 160)),

                // FINAL CTA
                SliverToBoxAdapter(
                  child: _FinalCtaSection(
                    onHoverItem: (h, text) => _updateCursor(hovering: h, text: text),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),

                const SliverToBoxAdapter(
                  child: AgencyFooter(),
                ),
              ],
            ),

            const FloatingWhatsAppButton(),
            // SMOOTH CURSOR OVERLAY (Desktop Only)
            if (!isMobile)
              ValueListenableBuilder<Offset>(
                valueListenable: _cursorNotifier,
                builder: (context, cursorPos, child) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: _isHoveringNotifier,
                    builder: (context, isHovering, child) {
                      return Positioned(
                        left: cursorPos.dx - (isHovering ? 40 : 12),
                        top: cursorPos.dy - (isHovering ? 40 : 12),
                        child: IgnorePointer(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            curve: Curves.easeOutCubic,
                            width: isHovering ? 80 : 24,
                            height: isHovering ? 80 : 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isHovering ? AppTheme.brandRed.withOpacity(0.9) : Colors.transparent,
                              border: Border.all(
                                color: isHovering ? Colors.transparent : Colors.white.withOpacity(0.6),
                                width: 1.5,
                              ),
                            ),
                            child: isHovering && _cursorModeText.isNotEmpty
                                ? Center(
                              child: Text(
                                _cursorModeText,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            )
                                : null,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// MARQUEE TICKER WIDGET
class ContinuousTickerStrip extends StatefulWidget {
  final String text;
  final bool directionRight;

  const ContinuousTickerStrip({
    super.key,
    required this.text,
    this.directionRight = true,
  });

  @override
  State<ContinuousTickerStrip> createState() => _ContinuousTickerStripState();
}

class _ContinuousTickerStripState extends State<ContinuousTickerStrip>
    with SingleTickerProviderStateMixin {
  late AnimationController _tickerController;

  @override
  void initState() {
    super.initState();
    _tickerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _tickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: AnimatedBuilder(
          animation: _tickerController,
          builder: (context, child) {
            final double offset = _tickerController.value * 600;
            final double finalX = widget.directionRight ? offset : -offset;

            return OverflowBox(
              minWidth: 0,
              maxWidth: double.infinity,
              alignment: Alignment.centerLeft,
              child: Transform.translate(
                offset: Offset(finalX % 600 - 300, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(8, (index) {
                    return Text(
                      widget.text,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4.0,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    );
                  }),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// OPTIMIZED PAINTER
class LightGridPainter extends CustomPainter {
  final Offset cursorPos;

  LightGridPainter({required this.cursorPos});

  @override
  void paint(Canvas canvas, Size size) {
    if (cursorPos != Offset.zero) {
      final Paint glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            AppTheme.brandRed.withOpacity(0.12),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: cursorPos, radius: 350));
      canvas.drawCircle(cursorPos, 350, glowPaint);
    }

    final Paint gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1.0;

    const double step = 80.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant LightGridPainter oldDelegate) =>
      oldDelegate.cursorPos != cursorPos;
}

// HERO INTRO
class _Since2012HeroSection extends StatelessWidget {
  final double scrollOffset;

  const _Since2012HeroSection({required this.scrollOffset});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;
    final double padding = isMobile ? 16.0 : 48.0;

    final double progress = (scrollOffset / 500.0).clamp(0.0, 1.0);
    final double sinceShift = progress * -60.0;
    final double yearShift = progress * 60.0;

    final double sinceFontSize = isMobile ? 64.0 : 140.0;
    final double yearFontSize = isMobile ? 80.0 : 160.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 20, padding, 20),
      child: Column(
        children: [
          Text(
            'TEVAH',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.brandRed,
              letterSpacing: 4.0,
            ),
          ),
          const SizedBox(height: 32),
          Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: Offset(sinceShift, isMobile ? -10 : -20),
                child: Text(
                  'SINCE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: sinceFontSize,
                    fontWeight: FontWeight.w900,
                    height: 0.8,
                    color: Colors.white.withOpacity(1.0 - progress),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(yearShift, isMobile ? 40 : 80),
                child: Text(
                  '2012',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: yearFontSize,
                    fontWeight: FontWeight.w900,
                    height: 0.8,
                    color: AppTheme.brandRed,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 100 : 180),
          Text(
            'DIGITAL PRODUCTS / CREATIVE TECHNOLOGY',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 10 : 12,
              fontWeight: FontWeight.bold,
              color: Colors.white60,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }
}

// KINETIC BRAND STATEMENT
class _KineticBrandStatementSection extends StatelessWidget {
  final double scrollOffset;

  const _KineticBrandStatementSection({required this.scrollOffset});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;
    final double padding = isMobile ? 16.0 : 80.0;
    final double titleFontSize = isMobile ? 32.0 : 56.0;

    const double triggerOffset = 400.0;
    final double progress = ((scrollOffset - triggerOffset) / 400.0).clamp(0.0, 1.0);

    final double leftShift = (1.0 - progress) * -60.0;
    final double rightShift = (1.0 - progress) * 60.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '01 / OUR STORY',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.brandRed,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 32),
          Transform.translate(
            offset: Offset(leftShift, 0),
            child: Text(
              'CRAFTING DIGITAL PRODUCTS',
              style: GoogleFonts.plusJakartaSans(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w900,
                height: 1.1,
                letterSpacing: isMobile ? -0.5 : -1.0,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Transform.translate(
            offset: Offset(rightShift, 0),
            child: Text(
              'WITH A DIFFERENT POINT OF VIEW.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w900,
                height: 1.1,
                letterSpacing: isMobile ? -0.5 : -1.0,
                color: AppTheme.brandRed,
              ),
            ),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: 700,
            child: Text(
              'TEVAH is a global digital studio based in Kerala, India, bringing purposeful technology, high-scale platform engineering, and creative media to partners worldwide.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: isMobile ? 15 : 18,
                height: 1.6,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// CINEMATIC GALLERY TRACK
class _CinematicGalleryTrackSection extends StatelessWidget {
  final double scrollOffset;
  final Function(bool, String) onHoverItem;

  const _CinematicGalleryTrackSection({
    required this.scrollOffset,
    required this.onHoverItem,
  });

  static const List<Map<String, String>> wallItems = [
    {
      'num': '01',
      'title': 'SaaS Enterprise Hub',
      'imageUrl': 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?auto=format&fit=crop&w=800&q=80',
    },
    {
      'num': '02',
      'title': 'Fintech Native App',
      'imageUrl': 'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?auto=format&fit=crop&w=800&q=80',
    },
    {
      'num': '03',
      'title': 'Autonomous Supply Engine',
      'imageUrl': 'https://images.unsplash.com/photo-1531482615713-2afd69097998?auto=format&fit=crop&w=800&q=80',
    },
    {
      'num': '04',
      'title': 'Minimalist Identity System',
      'imageUrl': 'https://images.unsplash.com/photo-1556761175-5973dc0f32e7?auto=format&fit=crop&w=800&q=80',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;

    final List<Map<String, String>> items = [...wallItems, ...wallItems];
    final double cardWidth = isMobile ? 300.0 : 440.0;
    final double totalWidth = cardWidth * wallItems.length;
    final double horizontalShift = (scrollOffset * 0.5) % totalWidth;

    return SizedBox(
      height: isMobile ? 360 : 480,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Transform.translate(
          offset: Offset(-horizontalShift, 0),
          child: Row(
            children: List.generate(items.length, (index) {
              return MouseRegion(
                onEnter: (_) => onHoverItem(true, 'VIEW'),
                onExit: (_) => onHoverItem(false, ''),
                child: Container(
                  width: cardWidth,
                  height: isMobile ? 340 : 440,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 8.0 : 14.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.greyBorder),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image(
                            image: ResizeImage(
                              NetworkImage(items[index]['imageUrl']!),
                              width: 600,
                            ),
                            fit: BoxFit.cover,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withOpacity(0.85),
                                  Colors.transparent,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 24,
                            left: 24,
                            right: 24,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  items[index]['num']!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.brandRed,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  items[index]['title']!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: isMobile ? 18 : 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// APPROACH TIMELINE
class _ApproachTimelineSection extends StatelessWidget {
  final double scrollOffset;

  const _ApproachTimelineSection({required this.scrollOffset});

  static const List<Map<String, dynamic>> stages = [
    {
      'num': '01',
      'title': 'DISCOVER',
      'items': ['Usability Studies', 'User Interviews', 'Stakeholder Alignment'],
    },
    {
      'num': '02',
      'title': 'DESIGN',
      'items': ['Architecture Sitemaps', 'Concept Prototypes', 'UI Token Systems'],
    },
    {
      'num': '03',
      'title': 'BUILD',
      'items': ['Frontend Engineering', 'System Integrations', 'Interactive Animations'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;
    final double padding = isMobile ? 16.0 : 48.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '02 / OUR APPROACH',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.brandRed,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 36),
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(stages.length, (index) {
                final stage = stages[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _ApproachHoverCard(
                    stage: stage,
                  ),
                );
              }),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(stages.length, (index) {
                final stage = stages[index];

                return Expanded(
                  child: _ApproachHoverCard(
                    stage: stage,
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}

class _ApproachHoverCard extends StatefulWidget {
  final Map<String, dynamic> stage;

  const _ApproachHoverCard({
    required this.stage,
  });

  @override
  State<_ApproachHoverCard> createState() => _ApproachHoverCardState();
}

class _ApproachHoverCardState extends State<_ApproachHoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;

    return MouseRegion(
      onEnter: (_) {
        if (!isMobile) {
          setState(() => _isHovered = true);
        }
      },
      onExit: (_) {
        setState(() => _isHovered = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,

        margin: EdgeInsets.only(
          right: isMobile ? 0 : 24,
        ),

        padding: EdgeInsets.all(
          isMobile ? 22 : 32,
        ),

        transform: Matrix4.translationValues(
          0,
          _isHovered ? -8 : 0,
          0,
        ),

        decoration: BoxDecoration(
          color: _isHovered
              ? AppTheme.darkSurface
              : AppTheme.darkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isHovered
                ? AppTheme.brandRed.withOpacity(0.5)
                : AppTheme.greyBorder,
          ),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.stage['num'],
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.brandRed,
                letterSpacing: 1.0,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              widget.stage['title'],
              style: GoogleFonts.plusJakartaSans(
                fontSize: isMobile ? 20 : 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 18),

            ...((widget.stage['items'] as List<String>).map(
                  (item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Text(
                    '• $item',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 13 : 13,
                      height: 1.35,
                      color: Colors.white70,
                    ),
                  ),
                );
              },
            )),
          ],
        ),
      ),
    );
  }
}

// STATEMENT SECTION
class _GiantWordStatementSection extends StatelessWidget {
  final double scrollOffset;

  const _GiantWordStatementSection({required this.scrollOffset});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;
    final double padding = isMobile ? 16.0 : 80.0;
    final double fontSize = isMobile ? 32.0 : 58.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WE DON\'T JUST BUILD WEBSITES.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'WE BUILD EXPERIENCES.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: AppTheme.brandRed,
            ),
          ),
        ],
      ),
    );
  }
}

// STATS SECTION
class _EditorialStatsSection extends StatelessWidget {
  final double scrollOffset;

  const _EditorialStatsSection({required this.scrollOffset});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;
    final double padding = isMobile ? 16.0 : 48.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: isMobile
          ? Column(
        children: const [
          _StatCard(numStr: '4.9', label: '35+ Google Reviews'),
          SizedBox(height: 16),
          _StatCard(numStr: '1,800+', label: 'Global Clients'),
          SizedBox(height: 16),
          _StatCard(numStr: '1,700+', label: 'Completed Projects'),
          SizedBox(height: 16),
          _StatCard(numStr: '95%', label: 'Retention Rate'),
        ],
      )
          : Row(
        children: const [
          Expanded(child: _StatCard(numStr: '4.9', label: '35+ Google Reviews')),
          SizedBox(width: 16),
          Expanded(child: _StatCard(numStr: '1,800+', label: 'Global Clients')),
          SizedBox(width: 16),
          Expanded(child: _StatCard(numStr: '1,700+', label: 'Completed Projects')),
          SizedBox(width: 16),
          Expanded(child: _StatCard(numStr: '95%', label: 'Retention Rate')),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String numStr;
  final String label;

  const _StatCard({required this.numStr, required this.label});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.greyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white38),
          ),
          const SizedBox(height: 16),
          Text(
            numStr,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 32 : 44,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// COMBINED CINEMATIC VISION & COLLABORATION PARALLAX PANEL
class CombinedVisionParallaxSection extends StatelessWidget {
  final double scrollOffset;

  const CombinedVisionParallaxSection({
    super.key,
    required this.scrollOffset,
  });

  static const List<Map<String, String>> frames = [
    {
      'title': 'COLLABORATE',
      'desc': 'Collaborate with a super down-to-earth, mad-talented team. A collective bunch working on incredible projects and building enduring partnerships.',
    },
    {
      'title': 'CREATE',
      'desc': 'Turn raw potential into digital experiences with sub-second response times and intelligent AI workflows built for global scale.',
    },
    {
      'title': 'DELIVER',
      'desc': 'Build scalable products that last and deliver measurable commercial results for enterprise partners across continents.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;
    final double padding = isMobile ? 16.0 : 48.0;

    const double containerHeight = 520.0;
    const double imageHeight = 720.0;
    const double overflowAmount = imageHeight - containerHeight;

    const double targetStartScroll = 2400.0;
    const double scrollDistance = 800.0;
    final double rawProgress = ((scrollOffset - targetStartScroll) / scrollDistance).clamp(0.0, 1.0);

    final double innerTranslation = -rawProgress * overflowAmount * 0.7;
    final int frameIndex = (rawProgress * 2.99).floor().clamp(0, 2);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Container(
        height: isMobile ? null : containerHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.greyBorder),
          color: AppTheme.darkCard,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: isMobile
              ? Column(
            children: [
              SizedBox(
                height: 240,
                width: double.infinity,
                child: Image.network(
                  'https://images.unsplash.com/photo-1522071820081-009f0129c71c?auto=format&fit=crop&w=1200&q=80',
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '04 / VISION & TEAM',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brandRed,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      frames[frameIndex]['title']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      frames[frameIndex]['desc']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
              : Row(
            children: [
              Expanded(
                flex: 1,
                child: ClipRect(
                  child: SizedBox(
                    height: containerHeight,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: imageHeight,
                          child: Transform.translate(
                            offset: Offset(0, innerTranslation),
                            child: const Image(
                              image: ResizeImage(
                                NetworkImage('https://images.unsplash.com/photo-1522071820081-009f0129c71c?auto=format&fit=crop&w=1200&q=80'),
                                width: 1000,
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  color: AppTheme.darkCard,
                  padding: const EdgeInsets.symmetric(horizontal: 56.0, vertical: 48.0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Column(
                      key: ValueKey<int>(frameIndex),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '04 / VISION & TEAM',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.brandRed,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          frames[frameIndex]['title']!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          frames[frameIndex]['desc']!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            height: 1.6,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// INTERACTIVE TEAM SECTION
class _InteractiveTeamSection extends StatelessWidget {
  final Function(bool, String) onHoverItem;

  const _InteractiveTeamSection({required this.onHoverItem});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;
    final double padding = isMobile ? 16.0 : 48.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Column(
        // remove upper column and uncomment
        children: [
          // Column(
          //   crossAxisAlignment: CrossAxisAlignment.start,
          //   children: [
          //     Text(
          //       'TEAM',
          //       style: GoogleFonts.plusJakartaSans(
          //         fontSize: 11,
          //         fontWeight: FontWeight.bold,
          //         color: Colors.white38,
          //       ),
          //     ),
          //     const SizedBox(height: 36),
          //     if (isMobile)
          //       Column(
          //         children: [
          //           _Team3DCardItem(
          //             name: 'Shyju Satheeshan',
          //             role: 'Lead Designer',
          //             imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=600&q=80',
          //             onHoverItem: onHoverItem,
          //           ),
          //           const SizedBox(height: 20),
          //           _Team3DCardItem(
          //             name: 'James David',
          //             role: 'CEO & Founder',
          //             imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=600&q=80',
          //             onHoverItem: onHoverItem,
          //           ),
          //           const SizedBox(height: 20),
          //           _Team3DCardItem(
          //             name: 'Brenda C. Janet',
          //             role: 'Lead Developer',
          //             imageUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=600&q=80',
          //             onHoverItem: onHoverItem,
          //           ),
          //           const SizedBox(height: 20),
          //           _Team3DCardItem(
          //             name: 'Martin Carlos',
          //             role: 'Lead Designer',
          //             imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=600&q=80',
          //             onHoverItem: onHoverItem,
          //           ),
          //           const SizedBox(height: 20),
          //           _Team3DCardItem(
          //             name: 'Martin Carlos',
          //             role: 'Lead Designer',
          //             imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=600&q=80',
          //             onHoverItem: onHoverItem,
          //           ),
          //           const SizedBox(height: 20),
          //           _Team3DCardItem(
          //             name: 'Martin Carlos',
          //             role: 'Lead Designer',
          //             imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=600&q=80',
          //             onHoverItem: onHoverItem,
          //           ),
          //           const SizedBox(height: 20),
          //           _Team3DCardItem(
          //             name: 'Martin Carlos',
          //             role: 'Lead Designer',
          //             imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=600&q=80',
          //             onHoverItem: onHoverItem,
          //           ),
          //           const SizedBox(height: 20),
          //           _Team3DCardItem(
          //             name: 'Martin Carlos',
          //             role: 'Lead Designer',
          //             imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=600&q=80',
          //             onHoverItem: onHoverItem,
          //           ),
          //
          //         ],
          //       )
          //     else
          //       Row(
          //         children: [
          //           Expanded(
          //             child: _Team3DCardItem(
          //               name: 'Shyju',
          //               role: 'Founder',
          //               imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=600&q=80',
          //               onHoverItem: onHoverItem,
          //             ),
          //           ),
          //           const SizedBox(width: 20),
          //           Expanded(
          //             child: _Team3DCardItem(
          //               name: 'Geetha',
          //               role: '  ',
          //               imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=600&q=80',
          //               onHoverItem: onHoverItem,
          //             ),
          //           ),
          //           const SizedBox(width: 20),
          //           Expanded(
          //             child: _Team3DCardItem(
          //               name: 'Jojin',
          //               role: 'Developer',
          //               imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=600&q=80',
          //               onHoverItem: onHoverItem,
          //             ),
          //           ),
          //           const SizedBox(width: 20),
          //           Expanded(
          //             child: _Team3DCardItem(
          //               name: 'Febin',
          //               role: 'Designer',
          //               imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=600&q=80',
          //               onHoverItem: onHoverItem,
          //             ),
          //           ),
          //           const SizedBox(width: 20),
          //           Expanded(
          //             child: _Team3DCardItem(
          //               name: 'Milan',
          //               role: 'Developer',
          //               imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=600&q=80',
          //               onHoverItem: onHoverItem,
          //             ),
          //           ), const SizedBox(width: 20),
          //           Expanded(
          //             child: _Team3DCardItem(
          //               name: 'Godwin',
          //               role: 'Designer',
          //               imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=600&q=80',
          //               onHoverItem: onHoverItem,
          //             ),
          //           ),
          //           const SizedBox(width: 20),
          //           Expanded(
          //             child: _Team3DCardItem(
          //               name: 'Akhil',
          //               role: 'Developer',
          //               imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=600&q=80',
          //               onHoverItem: onHoverItem,
          //             ),
          //           ),
          //         ],
          //       ),
          //   ],
          // ),
        ],
      ),
    );
  }
}

class _Team3DCardItem extends StatefulWidget {
  final String name;
  final String role;
  final String imageUrl;
  final Function(bool, String) onHoverItem;

  const _Team3DCardItem({
    required this.name,
    required this.role,
    required this.imageUrl,
    required this.onHoverItem,
  });

  @override
  State<_Team3DCardItem> createState() => _Team3DCardItemState();
}

class _Team3DCardItemState extends State<_Team3DCardItem> {
  Offset _localCursor = Offset.zero;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        widget.onHoverItem(true, 'TEAM');
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
          _localCursor = Offset.zero;
        });
        widget.onHoverItem(false, '');
      },
      onHover: (e) {
        if (!isMobile) {
          final RenderBox box = context.findRenderObject() as RenderBox;
          final Offset center = box.size.center(Offset.zero);
          setState(() {
            _localCursor = (e.localPosition - center) * 0.08;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(
          _localCursor.dx,
          _isHovered ? -12.0 + _localCursor.dy : 0.0,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: isMobile ? 280 : 380,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface,
                  boxShadow: _isHovered
                      ? [
                    BoxShadow(
                      color: AppTheme.brandRed.withOpacity(0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ]
                      : [],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimatedScale(
                      scale: _isHovered ? 1.05 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: Image(
                        image: ResizeImage(
                          NetworkImage(widget.imageUrl),
                          width: 600,
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (_isHovered)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.brandRed,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'VIEW',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _isHovered ? AppTheme.brandRed : Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.role,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.white38,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isHovered ? 40 : 0,
              height: 2,
              color: AppTheme.brandRed,
            ),
          ],
        ),
      ),
    );
  }
}

// FINAL CTA
class _FinalCtaSection extends StatelessWidget {
  final Function(bool, String) onHoverItem;

  const _FinalCtaSection({required this.onHoverItem});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;
    final double padding = isMobile ? 16.0 : 48.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isMobile ? 60 : 80, horizontal: isMobile ? 24 : 60),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppTheme.greyBorder),
        ),
        child: Column(
          children: [
            Text(
              'LET\'S BUILD SOMETHING GREAT.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.brandRed,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "LET'S CONNECT.",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: isMobile ? 42 : 64,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'dart:async';
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'shared_widgets.dart';
import 'about_screen.dart';

class MainAgencyScreen extends StatefulWidget {
  const MainAgencyScreen({super.key});

  @override
  State<MainAgencyScreen> createState() => _MainAgencyScreenState();
}

class _MainAgencyScreenState extends State<MainAgencyScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  double _targetScroll = 0.0;
  double _smoothScroll = 0.0;
  Timer? _scrollTicker;
  double _scrollVelocity = 0.0;

  final ValueNotifier<double> _scrollNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<double> _velocityNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<Offset> _rawCursorNotifier = ValueNotifier<Offset>(Offset.zero);
  final ValueNotifier<Offset> _smoothCursorNotifier = ValueNotifier<Offset>(Offset.zero);
  final ValueNotifier<bool> _isHoveringNotifier = ValueNotifier<bool>(false);

  String _cursorText = '';
  late AnimationController _badgeRotateController;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();

    _badgeRotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Standard listener to keep animations synchronized on mobile touch drag
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        _scrollNotifier.value = _scrollController.offset;

        // Synchronize custom ticker variables with native touch drag on mobile
        final double screenWidth = MediaQuery.of(context).size.width;
        if (screenWidth < 768) {
          _targetScroll = _scrollController.offset;
          _smoothScroll = _scrollController.offset;
        }
      }
    });

    _scrollTicker = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      final double screenWidth = MediaQuery.of(context).size.width;
      if (screenWidth >= 768) {
        _updateSmoothScroll();
      }
      _updateSmoothCursor();
    });
  }

  void _updateSmoothScroll() {
    if (!mounted || !_scrollController.hasClients) return;

    final double maxScroll = _scrollController.position.maxScrollExtent;
    _targetScroll = _targetScroll.clamp(0.0, maxScroll);

    final double difference = _targetScroll - _smoothScroll;
    _scrollVelocity = difference * 0.08;
    _smoothScroll += _scrollVelocity;

    if (difference.abs() > 0.1) {
      _scrollController.jumpTo(_smoothScroll);
      _scrollNotifier.value = _smoothScroll;
      _velocityNotifier.value = _scrollVelocity;
    }
  }

  void _updateSmoothCursor() {
    final Offset target = _rawCursorNotifier.value;
    final Offset current = _smoothCursorNotifier.value;
    final Offset diff = target - current;

    if (diff.distance > 0.1) {
      _smoothCursorNotifier.value = current + (diff * 0.15);
    }
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      _targetScroll += event.scrollDelta.dy * 0.85;
    }
  }

  @override
  void dispose() {
    _scrollTicker?.cancel();
    _scrollController.dispose();
    _scrollNotifier.dispose();
    _velocityNotifier.dispose();
    _rawCursorNotifier.dispose();
    _smoothCursorNotifier.dispose();
    _isHoveringNotifier.dispose();
    _badgeRotateController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _updateCursor({required bool hovering, String text = ''}) {
    _isHoveringNotifier.value = hovering;
    _cursorText = text;
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;
    final bool isTablet = screenWidth >= 768 && screenWidth < 1024;

    final double horizontalPadding = isMobile ? 16.0 : (isTablet ? 28.0 : 48.0);
    final double initialHeroTop = isMobile ? 540.0 : 460.0;

    return MouseRegion(
      cursor: isMobile ? MouseCursor.defer : SystemMouseCursors.none,
      onHover: (e) => _rawCursorNotifier.value = e.position,
      child: Listener(
        onPointerSignal: _onPointerSignal,
        child: Scaffold(
          backgroundColor: AppTheme.darkBackground,
          body: Stack(
            children: [
              ValueListenableBuilder<Offset>(
                valueListenable: _smoothCursorNotifier,
                builder: (context, cursorPos, child) {
                  return AnimatedBuilder(
                    animation: _particleController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: Size.infinite,
                        painter: HeroGridBackgroundPainter(
                          cursorPos: cursorPos,
                          animationProgress: _particleController.value,
                        ),
                      );
                    },
                  );
                },
              ),

              CustomScrollView(
                controller: _scrollController,
                physics: isMobile
                    ? const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())
                    : const NeverScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: TevahNavbar(
                      currentRoute: NavRoute.home,
                      onHoverItem: (hovering) => _updateCursor(hovering: hovering),
                    ),
                  ),

                  // 01 — HERO SECTION WITH TYPEWRITER & BADGE ANIMATION
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(horizontalPadding, 20, horizontalPadding, 20),
                      child: Column(
                        children: [
                          if (isMobile) ...[
                            Row(
                              children: [
                                RotationTransition(
                                  turns: _badgeRotateController,
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white24, width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.brandRed.withOpacity(0.25),
                                          blurRadius: 15,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        'AI',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const AnimatedTypewriterHeadline(brandRed: AppTheme.brandRed)
                                .animate()
                                .fadeIn(duration: 800.ms, curve: Curves.easeOut),
                            const SizedBox(height: 24),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '99%',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 42,
                                          fontWeight: FontWeight.w700,
                                          height: 1.0,
                                          color: Colors.white,
                                          letterSpacing: -1.0,
                                        ),
                                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                                      const SizedBox(height: 6),
                                      Text(
                                        'UPTIME',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white60,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '150+',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 42,
                                          fontWeight: FontWeight.w700,
                                          height: 1.0,
                                          color: Colors.white,
                                          letterSpacing: -1.0,
                                        ),
                                      ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2, end: 0),
                                      const SizedBox(height: 6),
                                      Text(
                                        'SOLUTIONS',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white60,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "TEVAH TECH SOLUTIONS PRIVATE LIMITED is a global leader delivering next-generation Platform Engineering, AI Automation, and Creative Production.",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: Colors.white70,
                                height: 1.5,
                              ),
                            ),
                          ] else ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RotationTransition(
                                  turns: _badgeRotateController,
                                  child: Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white24, width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.brandRed.withOpacity(0.35),
                                          blurRadius: 20,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        'AI',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 48),
                                Expanded(
                                  flex: 5,
                                  child: const AnimatedTypewriterHeadline(brandRed: AppTheme.brandRed)
                                      .animate()
                                      .fadeIn(duration: 800.ms, curve: Curves.easeOut)
                                      .slideX(begin: -0.15, end: 0, duration: 900.ms, curve: Curves.easeOutCubic),
                                ),
                                const SizedBox(width: 48),
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 10),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '99%',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 72,
                                                    fontWeight: FontWeight.w700,
                                                    height: 1.0,
                                                    color: Colors.white,
                                                    letterSpacing: -2.0,
                                                  ),
                                                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'UPTIME',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white60,
                                                    letterSpacing: 1.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '150+',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 72,
                                                    fontWeight: FontWeight.w700,
                                                    height: 1.0,
                                                    color: Colors.white,
                                                    letterSpacing: -2.0,
                                                  ),
                                                ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2, end: 0),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'SOLUTIONS',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white60,
                                                    letterSpacing: 1.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 32),
                                      const Divider(color: Colors.white12),
                                      const SizedBox(height: 32),
                                      Text(
                                        "TEVAH TECH SOLUTIONS PRIVATE LIMITED is a global leader delivering next-generation Platform Engineering, AI Automation, and Creative Production.",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          color: Colors.white70,
                                          height: 1.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 60),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'SCROLL TO EXPLORE',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.brandRed,
                                  letterSpacing: 3.0,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(Icons.arrow_downward_rounded, color: AppTheme.brandRed, size: 16)
                                  .animate(onPlay: (c) => c.repeat(reverse: true))
                                  .slideY(begin: -0.2, end: 0.3, duration: 800.ms),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: isMobile ? 140 : 320)),

                  // 02 — GIANT TEVAH SCROLL TARGET
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 40.0),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 20.0 : 60.0, vertical: isMobile ? 32.0 : 60.0),
                        decoration: BoxDecoration(
                          color: AppTheme.darkCard,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppTheme.greyBorder),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: isMobile ? 60 : 180),
                            Text(
                              "TEVAH provides tech solutions for all your needs. From intelligent AI automation frameworks to high-scale platform engineering and digital production, we empower modern enterprises.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: isMobile ? 14 : 18,
                                color: Colors.white70,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 36),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacement(
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) => const AboutScreen(),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      return FadeTransition(opacity: animation, child: child);
                                    },
                                    transitionDuration: const Duration(milliseconds: 400),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                padding: EdgeInsets.symmetric(horizontal: isMobile ? 28 : 36, vertical: isMobile ? 16 : 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                'Learn More',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),

                  SliverToBoxAdapter(
                    child: ContinuousTickerStrip(
                      text: 'DIGITAL • TECHNOLOGY • AI • DESIGN • MOTION • PLATFORMS • ',
                      directionRight: true,
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),

                  // 03 — BIG STATEMENT
                  SliverToBoxAdapter(
                    child: ValueListenableBuilder<double>(
                      valueListenable: _scrollNotifier,
                      builder: (context, scrollOffset, child) {
                        return WordByWordStatementSection(scrollOffset: scrollOffset);
                      },
                    ),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: isMobile ? 80 : 160)),

                  // 04 — WHAT WE BUILD
                  SliverToBoxAdapter(
                    child: InteractiveServicesSection(
                      onHoverItem: (h, text) => _updateCursor(hovering: h, text: text),
                    ),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: isMobile ? 80 : 160)),

                  SliverToBoxAdapter(
                    child: ContinuousTickerStrip(
                      text: 'TEVAH — BUILDING WHAT\'S NEXT — TEVAH — BUILDING WHAT\'S NEXT — ',
                      directionRight: false,
                    ),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: isMobile ? 80 : 160)),

                  // 05 — WHY TEVAH
                  SliverToBoxAdapter(
                    child: ValueListenableBuilder<double>(
                      valueListenable: _scrollNotifier,
                      builder: (context, scrollOffset, child) {
                        return StickyWhyTevahSection(scrollOffset: scrollOffset);
                      },
                    ),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: isMobile ? 80 : 160)),

                  // 06 — AI SPOTLIGHT WITH NEURAL PULSE CORE
                  SliverToBoxAdapter(
                    child: ValueListenableBuilder<double>(
                      valueListenable: _scrollNotifier,
                      builder: (context, scrollOffset, child) {
                        return AiCenterpieceSection(scrollOffset: scrollOffset);
                      },
                    ),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: isMobile ? 80 : 160)),

                  // 07 — IMPACT / STATS
                  SliverToBoxAdapter(
                    child: ValueListenableBuilder<double>(
                      valueListenable: _scrollNotifier,
                      builder: (context, scrollOffset, child) {
                        return ImpactStatsSection(scrollOffset: scrollOffset);
                      },
                    ),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: isMobile ? 80 : 160)),

                  // 08 — TESTIMONIALS
                  SliverToBoxAdapter(
                    child: TestimonialsSection(
                      onHoverItem: (h) => _updateCursor(hovering: h),
                    ),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: isMobile ? 80 : 160)),

                  // 09 — FINAL CTA
                  SliverToBoxAdapter(
                    child: FinalCtaSection(
                      onHoverItem: (h) => _updateCursor(hovering: h, text: 'TALK'),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 80)),

                  // 10 — FOOTER
                  const SliverToBoxAdapter(
                    child: AgencyFooter(),
                  ),
                ],
              ),
              const FloatingWhatsAppButton(),
              // OVERLAY TEVAH
              ValueListenableBuilder<double>(
                valueListenable: _scrollNotifier,
                builder: (context, scrollOffset, child) {
                  const double pinStartScroll = 280.0;
                  const double transitionDistance = 650.0;

                  double clampedOffset = (scrollOffset - pinStartScroll).clamp(0.0, transitionDistance);
                  double rawProgress = clampedOffset / transitionDistance;
                  double easedProgress = Curves.easeInOutCubic.transform(rawProgress);

                  double targetY;
                  if (scrollOffset < pinStartScroll) {
                    targetY = initialHeroTop - scrollOffset;
                  } else {
                    double pinnedBase = initialHeroTop - pinStartScroll;
                    double glideIntoCard = easedProgress * (isMobile ? 180.0 : 420.0);
                    double scrollRelease = (scrollOffset - pinStartScroll);

                    targetY = pinnedBase + glideIntoCard - scrollRelease;
                  }

                  final double textScale = 1.0 - (easedProgress * 0.78);
                  final Color textColor = Color.lerp(AppTheme.brandRed, AppTheme.targetCream, easedProgress)!;
                  final double letterSpacing = isMobile ? (1.0 + easedProgress * 4.0) : (4.0 + easedProgress * 14.0);

                  double textOpacity = isMobile ? 0.35 : 1.0;
                  if (easedProgress >= 0.85) {
                    textOpacity = ((1.0 - easedProgress) / 0.15).clamp(0.0, 1.0);
                  }

                  if (textOpacity <= 0.001) {
                    return const SizedBox.shrink();
                  }

                  final double baseFontSize = isMobile ? 110.0 : (isTablet ? 360.0 : 590.0);

                  return Positioned(
                    top: targetY,
                    left: 16,
                    right: 16,
                    child: IgnorePointer(
                      child: ValueListenableBuilder<double>(
                        valueListenable: _velocityNotifier,
                        builder: (context, velocity, child) {
                          final double velocityShift = (velocity * 0.3).clamp(-15.0, 15.0);

                          return AnimatedOpacity(
                            duration: const Duration(milliseconds: 100),
                            opacity: textOpacity,
                            child: Center(
                              child: Transform.translate(
                                offset: Offset(velocityShift, 0),
                                child: Transform.scale(
                                  scale: textScale,
                                  alignment: Alignment.topCenter,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'TEVAH',
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontFamily: 'Thunder',
                                        fontWeight: FontWeight.w700,
                                        fontSize: baseFontSize,
                                        color: textColor,
                                        letterSpacing: letterSpacing,
                                        height: 0.85,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),

              // CURSOR OVERLAY
              if (!isMobile)
                ValueListenableBuilder<Offset>(
                  valueListenable: _smoothCursorNotifier,
                  builder: (context, cursorPos, child) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: _isHoveringNotifier,
                      builder: (context, isHovering, child) {
                        return Positioned(
                          left: cursorPos.dx - (isHovering ? 40 : 12),
                          top: cursorPos.dy - (isHovering ? 40 : 12),
                          child: IgnorePointer(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
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
                              child: isHovering && _cursorText.isNotEmpty
                                  ? Center(
                                child: Text(
                                  _cursorText,
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
      ),
    );
  }
}

// TYPEWRITER HEADLINE WIDGET
class AnimatedTypewriterHeadline extends StatefulWidget {
  final Color brandRed;

  const AnimatedTypewriterHeadline({super.key, required this.brandRed});

  @override
  State<AnimatedTypewriterHeadline> createState() => _AnimatedTypewriterHeadlineState();
}

class _AnimatedTypewriterHeadlineState extends State<AnimatedTypewriterHeadline>
    with SingleTickerProviderStateMixin {
  late AnimationController _typeController;
  late Animation<int> _characterCount;

  final String line1 = "WE BUILD DIGITAL ";
  final String line2 = "EXPERIENCES ";
  final String line3 = "THAT MOVE BUSINESSES.";

  @override
  void initState() {
    super.initState();
    int totalLength = line1.length + line2.length + line3.length;

    _typeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _characterCount = StepTween(begin: 0, end: totalLength).animate(
      CurvedAnimation(parent: _typeController, curve: Curves.easeInOut),
    );

    _typeController.forward();
  }

  @override
  void dispose() {
    _typeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double headlineSize = (screenWidth * 0.08).clamp(26.0, 58.0);

    return AnimatedBuilder(
      animation: _characterCount,
      builder: (context, child) {
        int currentCount = _characterCount.value;

        String visible1 = "";
        String visible2 = "";
        String visible3 = "";
        bool showBadge = false;

        if (currentCount <= line1.length) {
          visible1 = line1.substring(0, currentCount);
        } else if (currentCount <= line1.length + line2.length) {
          visible1 = line1;
          visible2 = line2.substring(0, currentCount - line1.length);
        } else {
          visible1 = line1;
          visible2 = line2;
          int line3Index = (currentCount - line1.length - line2.length).clamp(0, line3.length);
          visible3 = line3.substring(0, line3Index);
          showBadge = false;
        }

        return RichText(
          text: TextSpan(
            style: GoogleFonts.plusJakartaSans(
              fontSize: headlineSize,
              height: 1.25,
              letterSpacing: 0.2,
              color: Colors.white,
            ),
            children: [
              TextSpan(
                text: visible1,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  color: widget.brandRed,
                ),
              ),
              TextSpan(
                text: visible2,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
              if (showBadge)
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth < 768 ? 8 : 16,
                      vertical: screenWidth < 768 ? 4 : 8,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: widget.brandRed,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: widget.brandRed.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.memory_rounded,
                      color: Colors.white,
                      size: screenWidth < 768 ? 16 : 28,
                    ),
                  ).animate().scale(
                    duration: 400.ms,
                    curve: Curves.elasticOut,
                  ),
                ),
              TextSpan(
                text: visible3,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// CONTINUOUS TICKER
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

class WordByWordStatementSection extends StatelessWidget {
  final double scrollOffset;

  const WordByWordStatementSection({super.key, required this.scrollOffset});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;
    final double statementSize = isMobile ? 36.0 : (screenWidth < 1024 ? 52.0 : 72.0);

    const double triggerOffset = 1100.0;
    final double p1 = ((scrollOffset - triggerOffset) / 200.0).clamp(0.0, 1.0);
    final double p2 = ((scrollOffset - (triggerOffset + 150)) / 200.0).clamp(0.0, 1.0);
    final double p3 = ((scrollOffset - (triggerOffset + 300)) / 200.0).clamp(0.0, 1.0);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16.0 : 80.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WHAT WE BELIEVE',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.brandRed,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 32),
          Opacity(
            opacity: p1,
            child: Transform.translate(
              offset: Offset(0, (1.0 - p1) * 30),
              child: Text(
                "WE DON'T JUST BUILD WEBSITES.",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: statementSize,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                  letterSpacing: isMobile ? -1.0 : -2.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Opacity(
            opacity: p2,
            child: Transform.translate(
              offset: Offset(0, (1.0 - p2) * 30),
              child: Text(
                "WE BUILD DIGITAL SYSTEMS",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: statementSize,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                  letterSpacing: isMobile ? -1.0 : -2.5,
                  color: AppTheme.brandRed,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Opacity(
            opacity: p3,
            child: Transform.translate(
              offset: Offset(0, (1.0 - p3) * 30),
              child: Text(
                "THAT MOVE BUSINESSES FORWARD.",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: statementSize,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                  letterSpacing: isMobile ? -1.0 : -2.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: 700,
            child: Text(
              "Technology, design and intelligence working together to create meaningful digital experiences.",
              style: GoogleFonts.plusJakartaSans(
                fontSize: isMobile ? 16 : 20,
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

class InteractiveServicesSection extends StatelessWidget {
  final Function(bool, String) onHoverItem;

  const InteractiveServicesSection({super.key, required this.onHoverItem});

  static const List<Map<String, String>> services = [
    {
      'number': '01',
      'title': 'WEB EXPERIENCES',
      'subtags': 'UX/UI • FRONTEND • HEADLESS CMS • PERFORMANCE',
      'imageUrl': 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'number': '02',
      'title': 'MOBILE APPLICATIONS',
      'subtags': 'iOS NATIVE • ANDROID • FLUTTER • OFFLINE SYNC',
      'imageUrl': 'https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'number': '03',
      'title': 'AI & AUTOMATION',
      'subtags': 'AI AGENTS • WORKFLOWS • LLM INTEGRATION • BI',
      'imageUrl': 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'number': '04',
      'title': 'BRAND & GRAPHICS',
      'subtags': 'VISUAL IDENTITY • VECTOR SYSTEMS • EDITORIAL',
      'imageUrl': 'https://images.unsplash.com/photo-1626785774573-4b799315345d?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'number': '05',
      'title': 'VIDEO & MOTION',
      'subtags': '3D CGI RENDERS • SHOWREELS • BROADCAST VFX',
      'imageUrl': 'https://images.unsplash.com/photo-1536240478700-b869070f9279?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'number': '06',
      'title': 'DIGITAL PRODUCTS',
      'subtags': 'SAAS ARCHITECTURE • CLOUD • DEVOPS • SCALING',
      'imageUrl': 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?auto=format&fit=crop&w=1200&q=80',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = screenWidth < 768 ? 16.0 : 48.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WHAT WE BUILD',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.brandRed,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 36),
          Column(
            children: services.map((service) {
              return _ServiceExpandableRow(
                number: service['number']!,
                title: service['title']!,
                subtags: service['subtags']!,
                imageUrl: service['imageUrl']!,
                onHoverItem: onHoverItem,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ServiceExpandableRow extends StatefulWidget {
  final String number;
  final String title;
  final String subtags;
  final String imageUrl;
  final Function(bool, String) onHoverItem;

  const _ServiceExpandableRow({
    required this.number,
    required this.title,
    required this.subtags,
    required this.imageUrl,
    required this.onHoverItem,
  });

  @override
  State<_ServiceExpandableRow> createState() => _ServiceExpandableRowState();
}

class _ServiceExpandableRowState extends State<_ServiceExpandableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _isHovered = true);
        widget.onHoverItem(true, 'EXPLORE');
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        widget.onHoverItem(false, '');
      },
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 36,
              vertical: _isHovered ? 36 : 24,
            ),
            decoration: BoxDecoration(
              color: _isHovered ? AppTheme.darkSurface : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                if (_isHovered)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Opacity(
                        opacity: 0.15,
                        child: Image.network(widget.imageUrl, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                if (isMobile) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.number,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _isHovered ? AppTheme.brandRed : Colors.white38,
                            ),
                          ),
                          Icon(
                            Icons.arrow_outward_rounded,
                            color: _isHovered ? AppTheme.brandRed : Colors.white38,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtags,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _isHovered ? AppTheme.brandRed : Colors.white38,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Text(
                        widget.number,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _isHovered ? AppTheme.brandRed : Colors.white38,
                        ),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        flex: 3,
                        child: Text(
                          widget.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          widget.subtags,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _isHovered ? AppTheme.brandRed : Colors.white38,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_outward_rounded,
                        color: _isHovered ? AppTheme.brandRed : Colors.white38,
                        size: 28,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            height: 1,
            color: _isHovered ? AppTheme.brandRed : Colors.white12,
          ),
        ],
      ),
    );
  }
}

class StickyWhyTevahSection extends StatefulWidget {
  final double scrollOffset;

  const StickyWhyTevahSection({super.key, required this.scrollOffset});

  static const List<Map<String, String>> stories = [
    {
      'num': '01',
      'title': 'THINK DIFFERENT.',
      'desc':
      'We challenge legacy assumptions before writing code, ensuring every project delivers commercial leverage.',
    },
    {
      'num': '02',
      'title': 'DESIGN WITH PURPOSE.',
      'desc':
      'Sub-second clarity meets high-conversion visual design built specifically for modern audience retention.',
    },
    {
      'num': '03',
      'title': 'BUILD TO SCALE.',
      'desc':
      'Headless architectures and distributed systems engineered to seamlessly handle high global traffic.',
    },
    {
      'num': '04',
      'title': 'AI NATIVE.',
      'desc':
      'Machine intelligence is integrated directly into system logic, not glued on as a superficial extra.',
    },
    {
      'num': '05',
      'title': 'CREATE IMPACT.',
      'desc':
      'Measurable results: 99.9% uptime, reduced friction, and direct growth acceleration.',
    },
  ];

  @override
  State<StickyWhyTevahSection> createState() => _StickyWhyTevahSectionState();
}

class _StickyWhyTevahSectionState extends State<StickyWhyTevahSection> {
  int _hoveredIndex = -1;
  double _lastScrollOffset = 0.0;
  bool _isScrollingDown = true;

  @override
  void didUpdateWidget(covariant StickyWhyTevahSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scrollOffset != oldWidget.scrollOffset) {
      setState(() {
        _isScrollingDown = widget.scrollOffset > _lastScrollOffset;
        _lastScrollOffset = widget.scrollOffset;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;
    final double padding = isMobile ? 16.0 : 48.0;

    const double sectionTrigger = 3200.0;
    final double relativeScroll = (widget.scrollOffset - sectionTrigger).clamp(0.0, 1500.0);
    final int activeIndex = _hoveredIndex != -1
        ? _hoveredIndex
        : (relativeScroll / 280.0).clamp(0, StickyWhyTevahSection.stories.length - 1).toInt();

    final activeStory = StickyWhyTevahSection.stories[activeIndex];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: isMobile
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WHY TEVAH?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Column(
            children: List.generate(StickyWhyTevahSection.stories.length, (index) {
              final story = StickyWhyTevahSection.stories[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.greyBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story['num']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brandRed,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      story['title']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      story['desc']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        height: 1.5,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      )
          : Stack(
        children: [
          Positioned(
            left: 0,
            top: 20,
            child: IgnorePointer(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.15),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  activeStory['num']!,
                  key: ValueKey<String>(activeStory['num']!),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 280,
                    fontWeight: FontWeight.w900,
                    height: 0.8,
                    color: Colors.white.withOpacity(0.025),
                    letterSpacing: -10.0,
                  ),
                ),
              ),
            ),
          ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WHY\nTEVAH?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2.0,
                        height: 1.05,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _hoveredIndex != -1 ? 100 : 60,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.brandRed,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.brandRed.withOpacity(0.6),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'ENGINEERING RIGOR • AI NATIVE • DESIGN SYSTEMS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brandRed.withOpacity(0.8),
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 40),

              Container(
                width: 24,
                margin: const EdgeInsets.only(top: 10),
                child: Column(
                  children: List.generate(StickyWhyTevahSection.stories.length, (index) {
                    final bool isActive = index == activeIndex;
                    final bool isPassed = index <= activeIndex;

                    return Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: isActive ? 16 : 8,
                          height: isActive ? 16 : 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isPassed ? AppTheme.brandRed : Colors.white24,
                            boxShadow: isActive
                                ? [
                              BoxShadow(
                                color: AppTheme.brandRed.withOpacity(0.9),
                                blurRadius: 14,
                                spreadRadius: 3,
                              ),
                            ]
                                : [],
                          ),
                        ),
                        if (index < StickyWhyTevahSection.stories.length - 1)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 2,
                            height: 210,
                            color: index < activeIndex
                                ? AppTheme.brandRed
                                : Colors.white12,
                          ),
                      ],
                    );
                  }),
                ),
              ),

              const SizedBox(width: 24),

              Expanded(
                flex: 6,
                child: Column(
                  children: List.generate(StickyWhyTevahSection.stories.length, (index) {
                    final story = StickyWhyTevahSection.stories[index];
                    final bool isSelected = activeIndex == index;
                    final bool isHovered = _hoveredIndex == index;

                    double translateX = 0.0;
                    if (isSelected || isHovered) {
                      translateX = _isScrollingDown ? -16.0 : -6.0;
                    }

                    return MouseRegion(
                      onEnter: (_) => setState(() => _hoveredIndex = index),
                      onExit: (_) => setState(() => _hoveredIndex = -1),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: isSelected || isHovered ? 1.0 : 0.40,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.only(bottom: 32),
                          padding: const EdgeInsets.all(40),
                          transform: Matrix4.translationValues(translateX, 0, 0),
                          decoration: BoxDecoration(
                            color: isSelected || isHovered
                                ? AppTheme.darkSurface
                                : AppTheme.darkCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected || isHovered
                                  ? AppTheme.brandRed.withOpacity(0.6)
                                  : AppTheme.greyBorder,
                              width: 1.5,
                            ),
                            boxShadow: isSelected || isHovered
                                ? [
                              BoxShadow(
                                color: AppTheme.brandRed.withOpacity(0.15),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
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
                                    story['num']!,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.brandRed,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_outward_rounded,
                                    size: 20,
                                    color: isSelected || isHovered
                                        ? AppTheme.brandRed
                                        : Colors.white24,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                story['title']!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                story['desc']!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  height: 1.6,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AiCenterpieceSection extends StatelessWidget {
  final double scrollOffset;

  const AiCenterpieceSection({super.key, required this.scrollOffset});

  static const List<String> aiPills = [
    'AI AGENTS',
    'AUTOMATION',
    'LLM',
    'DATA',
    'WORKFLOWS',
  ];

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;
    final double padding = isMobile ? 16.0 : 48.0;

    const double triggerOffset = 3800.0;
    final double rawProgress = ((scrollOffset - triggerOffset) / 600.0).clamp(0.0, 1.0);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: padding),
      padding: EdgeInsets.symmetric(vertical: isMobile ? 40 : 80, horizontal: isMobile ? 20 : 60),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.brandRed.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            '04 / AI ENGINE SPOTLIGHT',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.brandRed,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'INTELLIGENCE, AUTOMATED.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 32 : 64,
              fontWeight: FontWeight.w900,
              letterSpacing: isMobile ? -1.0 : -2.0,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 48),

          Center(
            child: SizedBox(
              width: isMobile ? 180 : 280,
              height: isMobile ? 180 : 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: isMobile ? 180 : 280,
                    height: isMobile ? 180 : 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.brandRed.withOpacity(0.8), width: 1.5),
                    ),
                  ),
                  Container(
                    width: isMobile ? 130 : 210,
                    height: isMobile ? 130 : 210,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2A1114),
                      border: Border.all(color: AppTheme.brandRed.withOpacity(0.4), width: 1),
                    ),
                  ),
                  Container(
                    width: isMobile ? 70 : 110,
                    height: isMobile ? 70 : 110,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.brandRed,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.memory_rounded,
                        color: Colors.white,
                        size: isMobile ? 28 : 42,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),

          if (isMobile)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _PipelineStepNode(label: 'INPUT', active: rawProgress > 0.1),
                _PipelineStepNode(label: 'INTELLIGENCE', active: rawProgress > 0.4),
                _PipelineStepNode(label: 'AUTOMATION', active: rawProgress > 0.7),
                _PipelineStepNode(label: 'RESULT', active: rawProgress > 0.95),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _PipelineStepNode(label: 'INPUT', active: rawProgress > 0.1),
                _PipelineArrow(active: rawProgress > 0.3),
                _PipelineStepNode(label: 'INTELLIGENCE', active: rawProgress > 0.4),
                _PipelineArrow(active: rawProgress > 0.6),
                _PipelineStepNode(label: 'AUTOMATION', active: rawProgress > 0.7),
                _PipelineArrow(active: rawProgress > 0.85),
                _PipelineStepNode(label: 'RESULT', active: rawProgress > 0.95),
              ],
            ),
          const SizedBox(height: 40),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: aiPills.map((pill) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  pill,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PipelineStepNode extends StatelessWidget {
  final String label;
  final bool active;

  const _PipelineStepNode({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: active ? AppTheme.brandRed : AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: active ? AppTheme.brandRed : Colors.white12),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: active ? Colors.white : Colors.white38,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _PipelineArrow extends StatelessWidget {
  final bool active;

  const _PipelineArrow({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: active ? 1.0 : 0.2,
      child: const Icon(Icons.arrow_forward_rounded, color: AppTheme.brandRed, size: 22),
    );
  }
}

class ImpactStatsSection extends StatelessWidget {
  final double scrollOffset;

  const ImpactStatsSection({super.key, required this.scrollOffset});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;
    final double padding = isMobile ? 16.0 : 48.0;

    const double triggerOffset = 5200.0;
    final double progress = ((scrollOffset - triggerOffset) / 400.0).clamp(0.0, 1.0);

    final int years = (progress * 12).round();
    final int projects = (progress * 150).round();
    final int clients = (progress * 30).round();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isMobile ? 32 : 60, horizontal: isMobile ? 16 : 48),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.greyBorder),
        ),
        child: isMobile
            ? Column(
          children: [
            _AnimatedStatDisplay(value: '$years+', label: 'YEARS'),
            const SizedBox(height: 24),
            _AnimatedStatDisplay(value: '$projects+', label: 'PROJECTS'),
            const SizedBox(height: 24),
            _AnimatedStatDisplay(value: '$clients+', label: 'CLIENTS'),
            const SizedBox(height: 24),
            const _AnimatedStatDisplay(value: '∞', label: 'POSSIBILITIES'),
          ],
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _AnimatedStatDisplay(value: '$years+', label: 'YEARS'),
            _AnimatedStatDisplay(value: '$projects+', label: 'PROJECTS'),
            _AnimatedStatDisplay(value: '$clients+', label: 'CLIENTS'),
            const _AnimatedStatDisplay(value: '∞', label: 'POSSIBILITIES'),
          ],
        ),
      ),
    );
  }
}

class _AnimatedStatDisplay extends StatelessWidget {
  final String value;
  final String label;

  const _AnimatedStatDisplay({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;

    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 48 : 72,
            fontWeight: FontWeight.w900,
            color: AppTheme.brandRed,
            letterSpacing: -2.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white60,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }
}

class TestimonialsSection extends StatelessWidget {
  final ValueChanged<bool> onHoverItem;

  const TestimonialsSection({super.key, required this.onHoverItem});

  static const List<Map<String, String>> testimonials = [
    {
      'quote': "TEVAH transformed our idea into something far beyond what we imagined.",
      'author': 'ALEXANDER WRIGHT',
      'company': 'CTO, FINTECH LABS',
    },
    {
      'quote': "The AI automation system designed by TEVAH cut our operational processing overhead by 75% in 3 months.",
      'author': 'SARAH JENKINS',
      'company': 'VP DIGITAL, LOGIX',
    },
    {
      'quote': "Their engineering rigor and attention to aesthetic detail make TEVAH our primary technology partner.",
      'author': 'MARCUS CHEN',
      'company': 'FOUNDER, NEXUS AI',
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
            'WHAT CLIENTS SAY',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.brandRed,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 36),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: testimonials.map((t) {
                return MouseRegion(
                  onEnter: (_) => onHoverItem(true),
                  onExit: (_) => onHoverItem(false),
                  child: Container(
                    width: isMobile ? screenWidth * 0.8 : 500,
                    margin: const EdgeInsets.only(right: 20),
                    padding: EdgeInsets.all(isMobile ? 24 : 40),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.greyBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '"${t['quote']}"',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: isMobile ? 16 : 22,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          t['author']!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.brandRed,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t['company']!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.white38,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class FinalCtaSection extends StatelessWidget {
  final ValueChanged<bool> onHoverItem;

  const FinalCtaSection({super.key, required this.onHoverItem});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;
    final double padding = isMobile ? 16.0 : 48.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isMobile ? 60 : 100, horizontal: isMobile ? 24 : 60),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppTheme.greyBorder),
        ),
        child: Column(
          children: [
            Text(
              'HAVE AN IDEA?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.brandRed,
                letterSpacing: 3.0,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "LET'S\nBUILD IT.",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: isMobile ? 48 : 90,
                fontWeight: FontWeight.w900,
                height: 0.95,
                letterSpacing: isMobile ? -1.0 : -3.0,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            MouseRegion(
              onEnter: (_) => onHoverItem(true),
              onExit: (_) => onHoverItem(false),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandRed,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 32 : 48, vertical: isMobile ? 16 : 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'START A PROJECT',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 13 : 16,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_outward_rounded, size: isMobile ? 18 : 22),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
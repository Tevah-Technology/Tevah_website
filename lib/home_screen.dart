import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'letstalk.dart';
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

  late final Ticker _vsyncTicker;

  double _targetScroll = 0.0;
  double _smoothScroll = 0.0;
  double _scrollVelocity = 0.0;
  bool _isWheeling = false;

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

    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final double current = _scrollController.offset;
        _scrollNotifier.value = current;

        // Synchronize target with native scrollbar drag or touch drag
        if (!_isWheeling) {
          _targetScroll = current;
          _smoothScroll = current;
        }
      }
    });

    // Hardware-accelerated frame update tied to refresh rate
    _vsyncTicker = createTicker((Duration elapsed) {
      _updateSmoothScroll();
      _updateSmoothCursor();
    })..start();
  }

  void _updateSmoothScroll() {
    if (!mounted || !_scrollController.hasClients) return;

    final double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 768) return; // Retain native mobile momentum physics

    final double maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;

    _targetScroll = _targetScroll.clamp(0.0, maxScroll);
    final double difference = _targetScroll - _smoothScroll;

    if (difference.abs() > 0.1) {
      _isWheeling = true;
      _scrollVelocity = difference * 0.12; // Critically damped decay
      _smoothScroll += _scrollVelocity;

      _scrollController.jumpTo(_smoothScroll.clamp(0.0, maxScroll));
      _scrollNotifier.value = _smoothScroll;
      _velocityNotifier.value = _scrollVelocity;
    } else {
      if (_isWheeling) {
        _smoothScroll = _targetScroll;
        _scrollController.jumpTo(_smoothScroll);
        _scrollNotifier.value = _smoothScroll;
        _velocityNotifier.value = 0.0;
        _isWheeling = false;
      }
    }
  }

  void _updateSmoothCursor() {
    final Offset target = _rawCursorNotifier.value;
    final Offset current = _smoothCursorNotifier.value;
    final Offset diff = target - current;

    if (diff.distance > 0.05) {
      _smoothCursorNotifier.value = current + (diff * 0.18);
    }
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent && _scrollController.hasClients) {
      final double maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll <= 0) return;

      final double delta = event.scrollDelta.dy;
      _targetScroll = (_targetScroll + (delta * 1.25)).clamp(0.0, maxScroll);
    }
  }

  @override
  void dispose() {
    _vsyncTicker.dispose();
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
                    ? const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                )
                    : const ClampingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: TevahNavbar(
                      currentRoute: NavRoute.home,
                      onHoverItem: (hovering) =>
                          _updateCursor(hovering: hovering),
                    ),
                  ),

                  // 01 — HERO SECTION WITH TYPEWRITER & BADGE ANIMATION
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        20,
                        horizontalPadding,
                        20,
                      ),
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
                                      border: Border.all(
                                        color: Colors.white24,
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.brandRed.withOpacity(
                                            0.25,
                                          ),
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
                            const AnimatedTypewriterHeadline(
                              brandRed: AppTheme.brandRed,
                            ).animate().fadeIn(
                              duration: 800.ms,
                              curve: Curves.easeOut,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
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
                                      )
                                          .animate()
                                          .fadeIn(delay: 200.ms)
                                          .slideY(begin: 0.2, end: 0),
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
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
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
                                      )
                                          .animate()
                                          .fadeIn(delay: 350.ms)
                                          .slideY(begin: 0.2, end: 0),
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
                                      border: Border.all(
                                        color: Colors.white24,
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.brandRed.withOpacity(
                                            0.35,
                                          ),
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
                                  child:
                                  const AnimatedTypewriterHeadline(
                                    brandRed: AppTheme.brandRed,
                                  )
                                      .animate()
                                      .fadeIn(
                                    duration: 800.ms,
                                    curve: Curves.easeOut,
                                  )
                                      .slideX(
                                    begin: -0.15,
                                    end: 0,
                                    duration: 900.ms,
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                                const SizedBox(width: 48),
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 10),
                                      Row(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '99%',
                                                  style:
                                                  GoogleFonts.plusJakartaSans(
                                                    fontSize: 72,
                                                    fontWeight:
                                                    FontWeight.w700,
                                                    height: 1.0,
                                                    color: Colors.white,
                                                    letterSpacing: -2.0,
                                                  ),
                                                )
                                                    .animate()
                                                    .fadeIn(delay: 200.ms)
                                                    .slideY(begin: 0.2, end: 0),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'UPTIME',
                                                  style:
                                                  GoogleFonts.plusJakartaSans(
                                                    fontSize: 12,
                                                    fontWeight:
                                                    FontWeight.bold,
                                                    color: Colors.white60,
                                                    letterSpacing: 1.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '150+',
                                                  style:
                                                  GoogleFonts.plusJakartaSans(
                                                    fontSize: 72,
                                                    fontWeight:
                                                    FontWeight.w700,
                                                    height: 1.0,
                                                    color: Colors.white,
                                                    letterSpacing: -2.0,
                                                  ),
                                                )
                                                    .animate()
                                                    .fadeIn(delay: 350.ms)
                                                    .slideY(begin: 0.2, end: 0),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'SOLUTIONS',
                                                  style:
                                                  GoogleFonts.plusJakartaSans(
                                                    fontSize: 12,
                                                    fontWeight:
                                                    FontWeight.bold,
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
                              const Icon(
                                Icons.arrow_downward_rounded,
                                color: AppTheme.brandRed,
                                size: 16,
                              )
                                  .animate(
                                onPlay: (c) => c.repeat(reverse: true),
                              )
                                  .slideY(
                                begin: -0.2,
                                end: 0.3,
                                duration: 800.ms,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: SizedBox(height: isMobile ? 140 : 320),
                  ),

                  // 02 — GIANT TEVAH SCROLL TARGET
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 40.0,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 20.0 : 60.0,
                          vertical: isMobile ? 32.0 : 60.0,
                        ),
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
                                    pageBuilder:
                                        (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                        ) => const AboutScreen(),
                                    transitionsBuilder:
                                        (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                        child,
                                        ) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      );
                                    },
                                    transitionDuration: const Duration(
                                      milliseconds: 400,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 28 : 36,
                                  vertical: isMobile ? 16 : 20,
                                ),
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
                      text:
                      'DIGITAL • TECHNOLOGY • AI • DESIGN • MOTION • PLATFORMS • ',
                      directionRight: true,
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),

                  // 03 — BIG STATEMENT
                  SliverToBoxAdapter(
                    child: ValueListenableBuilder<double>(
                      valueListenable: _scrollNotifier,
                      builder: (context, scrollOffset, child) {
                        return WordByWordStatementSection(
                          scrollOffset: scrollOffset,
                        );
                      },
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: SizedBox(height: isMobile ? 80 : 160),
                  ),

                  // 04 — WHAT WE BUILD
                  SliverToBoxAdapter(
                    child: InteractiveServicesSection(
                      onHoverItem: (h, text) =>
                          _updateCursor(hovering: h, text: text),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: SizedBox(height: isMobile ? 80 : 160),
                  ),

                  SliverToBoxAdapter(
                    child: ContinuousTickerStrip(
                      text:
                      'TEVAH — BUILDING WHAT\'S NEXT — TEVAH — BUILDING WHAT\'S NEXT — ',
                      directionRight: false,
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: SizedBox(height: isMobile ? 80 : 160),
                  ),

                  // 05 — WHY TEVAH
                  SliverToBoxAdapter(
                    child: ValueListenableBuilder<double>(
                      valueListenable: _scrollNotifier,
                      builder: (context, scrollOffset, child) {
                        return StickyWhyTevahSection(
                          scrollOffset: scrollOffset,
                        );
                      },
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: SizedBox(height: isMobile ? 80 : 160),
                  ),

                  // 06 — AI SPOTLIGHT WITH NEURAL PULSE CORE
                  SliverToBoxAdapter(
                    child: ValueListenableBuilder<double>(
                      valueListenable: _scrollNotifier,
                      builder: (context, scrollOffset, child) {
                        return AiCenterpieceSection(scrollOffset: scrollOffset);
                      },
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: SizedBox(height: isMobile ? 80 : 160),
                  ),

                  // 07 — IMPACT / STATS
                  SliverToBoxAdapter(
                    child: ValueListenableBuilder<double>(
                      valueListenable: _scrollNotifier,
                      builder: (context, scrollOffset, child) {
                        return ImpactStatsSection(scrollOffset: scrollOffset);
                      },
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: SizedBox(height: isMobile ? 80 : 160),
                  ),

                  // 08 — TESTIMONIALS
                  SliverToBoxAdapter(
                    child: TestimonialsSection(
                      onHoverItem: (h) => _updateCursor(hovering: h),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: SizedBox(height: isMobile ? 80 : 160),
                  ),

                  // 09 — FINAL CTA
                  SliverToBoxAdapter(
                    child: FinalCtaSection(
                      onHoverItem: (h) =>
                          _updateCursor(hovering: h, text: 'TALK'),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 80)),

                  // 10 — FOOTER
                  const SliverToBoxAdapter(child: AgencyFooter()),
                ],
              ),
              const FloatingWhatsAppButton(),

              // OVERLAY TEVAH
              ValueListenableBuilder<double>(
                valueListenable: _scrollNotifier,
                builder: (context, scrollOffset, child) {
                  const double pinStartScroll = 280.0;
                  const double transitionDistance = 650.0;

                  double clampedOffset = (scrollOffset - pinStartScroll).clamp(
                    0.0,
                    transitionDistance,
                  );
                  double rawProgress = clampedOffset / transitionDistance;
                  double easedProgress = Curves.easeInOutCubic.transform(
                    rawProgress,
                  );

                  double targetY;
                  if (scrollOffset < pinStartScroll) {
                    targetY = initialHeroTop - scrollOffset;
                  } else {
                    double pinnedBase = initialHeroTop - pinStartScroll;
                    double glideIntoCard =
                        easedProgress * (isMobile ? 180.0 : 420.0);
                    double scrollRelease = (scrollOffset - pinStartScroll);

                    targetY = pinnedBase + glideIntoCard - scrollRelease;
                  }

                  final double textScale = 1.0 - (easedProgress * 0.78);
                  final Color textColor = Color.lerp(
                    AppTheme.brandRed,
                    AppTheme.targetCream,
                    easedProgress,
                  )!;
                  final double letterSpacing = isMobile
                      ? (1.0 + easedProgress * 4.0)
                      : (4.0 + easedProgress * 14.0);

                  double textOpacity = isMobile ? 0.35 : 1.0;
                  if (easedProgress >= 0.85) {
                    textOpacity = ((1.0 - easedProgress) / 0.15).clamp(
                      0.0,
                      1.0,
                    );
                  }

                  if (textOpacity <= 0.001) {
                    return const SizedBox.shrink();
                  }

                  final double baseFontSize = isMobile
                      ? 110.0
                      : (isTablet ? 360.0 : 590.0);

                  return Positioned(
                    top: targetY,
                    left: 16,
                    right: 16,
                    child: IgnorePointer(
                      child: ValueListenableBuilder<double>(
                        valueListenable: _velocityNotifier,
                        builder: (context, velocity, child) {
                          final double velocityShift = (velocity * 0.3).clamp(
                            -15.0,
                            15.0,
                          );

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

              // ============================================================
              // DUAL-LAYER CIRCULAR RING CURSOR (SMOOTH OUTER + PIN DOT)
              // ============================================================
              if (!isMobile) ...[
                // 1. Outer Smooth Trailing Ring with Specular Glow & Morph
                ValueListenableBuilder<Offset>(
                  valueListenable: _smoothCursorNotifier,
                  builder: (context, cursorPos, child) {
                    if (cursorPos == Offset.zero) return const SizedBox.shrink();

                    return ValueListenableBuilder<bool>(
                      valueListenable: _isHoveringNotifier,
                      builder: (context, isHovering, child) {
                        final double ringSize = isHovering ? 76.0 : 36.0;

                        return Positioned(
                          left: cursorPos.dx - (ringSize / 2),
                          top: cursorPos.dy - (ringSize / 2),
                          child: IgnorePointer(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              width: ringSize,
                              height: ringSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isHovering
                                    ? AppTheme.brandRed.withOpacity(0.85)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isHovering
                                      ? Colors.white.withOpacity(0.9)
                                      : Colors.white.withOpacity(0.85),
                                  width: isHovering ? 1.6 : 1.3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isHovering ? AppTheme.brandRed : Colors.white)
                                        .withOpacity(isHovering ? 0.45 : 0.2),
                                    blurRadius: isHovering ? 22 : 8,
                                    spreadRadius: isHovering ? 2 : 0,
                                  ),
                                ],
                              ),
                              child: isHovering && _cursorText.isNotEmpty
                                  ? Center(
                                child: Text(
                                  _cursorText,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
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

                // 2. Inner Precise Solid Pin Dot (0ms latency direct tracker)
                ValueListenableBuilder<Offset>(
                  valueListenable: _rawCursorNotifier,
                  builder: (context, rawPos, child) {
                    if (rawPos == Offset.zero) return const SizedBox.shrink();

                    return ValueListenableBuilder<bool>(
                      valueListenable: _isHoveringNotifier,
                      builder: (context, isHovering, child) {
                        return Positioned(
                          left: rawPos.dx - 3.5,
                          top: rawPos.dy - 3.5,
                          child: IgnorePointer(
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 140),
                              opacity: isHovering ? 0.0 : 1.0,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.8),
                                      blurRadius: 5,
                                      spreadRadius: 0.5,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
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
  State<AnimatedTypewriterHeadline> createState() =>
      _AnimatedTypewriterHeadlineState();
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
          int line3Index = (currentCount - line1.length - line2.length).clamp(
            0,
            line3.length,
          );
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
                  ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                ),
              TextSpan(
                text: visible3,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
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
    final double statementSize = isMobile
        ? 36.0
        : (screenWidth < 1024 ? 52.0 : 72.0);

    const double triggerOffset = 1100.0;
    final double p1 = ((scrollOffset - triggerOffset) / 200.0).clamp(0.0, 1.0);
    final double p2 = ((scrollOffset - (triggerOffset + 150)) / 200.0).clamp(
      0.0,
      1.0,
    );
    final double p3 = ((scrollOffset - (triggerOffset + 300)) / 200.0).clamp(
      0.0,
      1.0,
    );

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

// ============================================================================
// INTERACTIVE SERVICES SECTION (ENHANCED AWWWARDS STYLE)
// ============================================================================

class InteractiveServicesSection extends StatefulWidget {
  final Function(bool, String) onHoverItem;

  const InteractiveServicesSection({super.key, required this.onHoverItem});

  static const List<Map<String, dynamic>> services = [
    {
      'number': '01',
      'title': 'WEB EXPERIENCES',
      'subtags': ['UX / UI', 'FRONTEND', 'HEADLESS CMS', 'PERFORMANCE'],
      'imageUrl':
      'https://images.unsplash.com/photo-1460925895917-afdab827c52f?auto=format&fit=crop&w=800&q=80',
    },
    {
      'number': '02',
      'title': 'MOBILE APPLICATIONS',
      'subtags': ['iOS NATIVE', 'ANDROID', 'FLUTTER', 'OFFLINE SYNC'],
      'imageUrl':
      'https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?auto=format&fit=crop&w=800&q=80',
    },
    {
      'number': '03',
      'title': 'AI & AUTOMATION',
      'subtags': ['AI AGENTS', 'WORKFLOWS', 'LLM INTEGRATION', 'BI'],
      'imageUrl':
      'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=800&q=80',
    },
    {
      'number': '04',
      'title': 'BRAND & GRAPHICS',
      'subtags': ['VISUAL IDENTITY', 'VECTOR SYSTEMS', 'EDITORIAL'],
      'imageUrl':
      'https://images.unsplash.com/photo-1626785774573-4b799315345d?auto=format&fit=crop&w=800&q=80',
    },
    {
      'number': '05',
      'title': 'VIDEO & MOTION',
      'subtags': ['3D CGI RENDERS', 'SHOWREELS', 'BROADCAST VFX'],
      'imageUrl':
      'https://images.unsplash.com/photo-1626785774573-4b799315345d?auto=format&fit=crop&w=800&q=80',
    },
    {
      'number': '06',
      'title': 'DIGITAL PRODUCTS',
      'subtags': ['SAAS ARCHITECTURE', 'CLOUD', 'DEVOPS', 'SCALING'],
      'imageUrl':
      'https://images.unsplash.com/photo-1551288049-bebda4e38f71?auto=format&fit=crop&w=800&q=80',
    },
  ];

  @override
  State<InteractiveServicesSection> createState() =>
      _InteractiveServicesSectionState();
}

class _InteractiveServicesSectionState
    extends State<InteractiveServicesSection> {
  int _activeHoverIndex = -1;
  Offset _mouseLocalPos = Offset.zero;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '03 / CAPABILITIES',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.brandRed,
                  letterSpacing: 2.5,
                ),
              ),
              Text(
                'DISCIPLINES & EXPERTISE',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white38,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          MouseRegion(
            onHover: (e) => setState(() => _mouseLocalPos = e.localPosition),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // List of interactive rows
                Column(
                  children: List.generate(
                    InteractiveServicesSection.services.length,
                        (index) {
                      final item = InteractiveServicesSection.services[index];
                      final bool isHovered = _activeHoverIndex == index;

                      return _ServiceInteractiveRow(
                        number: item['number'] as String,
                        title: item['title'] as String,
                        subtags: item['subtags'] as List<String>,
                        isHovered: isHovered,
                        onHover: (h) {
                          setState(() => _activeHoverIndex = h ? index : -1);
                          widget.onHoverItem(h, h ? 'VIEW' : '');
                        },
                      );
                    },
                  ),
                ),

                // Floating Image Preview Portal (Desktop Only)
                if (!isMobile && _activeHoverIndex != -1)
                  Positioned(
                    left: _mouseLocalPos.dx + 25,
                    top: _mouseLocalPos.dy - 100,
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _activeHoverIndex != -1 ? 1.0 : 0.0,
                        child: Container(
                          width: 240,
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.brandRed.withOpacity(0.5),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.brandRed.withOpacity(0.35),
                                blurRadius: 30,
                                spreadRadius: 2,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.8),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  InteractiveServicesSection
                                      .services[_activeHoverIndex]['imageUrl']
                                  as String,
                                  fit: BoxFit.cover,
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.6),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// INDIVIDUAL EXPANDING ROW
// ============================================================================

class _ServiceInteractiveRow extends StatelessWidget {
  final String number;
  final String title;
  final List<String> subtags;
  final bool isHovered;
  final ValueChanged<bool> onHover;

  const _ServiceInteractiveRow({
    required this.number,
    required this.title,
    required this.subtags,
    required this.isHovered,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(
              isHovered && !isMobile ? 12 : 0,
              0,
              0,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 24,
              vertical: isHovered ? (isMobile ? 24 : 32) : (isMobile ? 18 : 26),
            ),
            decoration: BoxDecoration(
              color: isHovered
                  ? Colors.white.withOpacity(0.035)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border(
                left: BorderSide(
                  color: isHovered ? AppTheme.brandRed : Colors.transparent,
                  width: 3.5,
                ),
              ),
            ),
            child: isMobile
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      number,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isHovered
                            ? AppTheme.brandRed
                            : Colors.white30,
                      ),
                    ),
                    _ArrowCircleBadge(isHovered: isHovered, size: 28),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isHovered
                        ? Colors.white
                        : Colors.white.withOpacity(0.9),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: subtags
                      .map(
                        (tag) =>
                        _MiniTagPill(tag: tag, isHovered: isHovered),
                  )
                      .toList(),
                ),
              ],
            )
                : Row(
              children: [
                Text(
                  number,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isHovered ? AppTheme.brandRed : Colors.white30,
                  ),
                ),
                const SizedBox(width: 36),
                Expanded(
                  flex: 5,
                  child: Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                      color: isHovered
                          ? Colors.white
                          : Colors.white.withOpacity(0.85),
                    ),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: subtags
                        .map(
                          (tag) => _MiniTagPill(
                        tag: tag,
                        isHovered: isHovered,
                      ),
                    )
                        .toList(),
                  ),
                ),
                const SizedBox(width: 24),
                _ArrowCircleBadge(isHovered: isHovered, size: 38),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 1,
            color: isHovered
                ? AppTheme.brandRed.withOpacity(0.6)
                : Colors.white.withOpacity(0.08),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ACCENT COMPONENTS
// ============================================================================

class _MiniTagPill extends StatelessWidget {
  final String tag;
  final bool isHovered;

  const _MiniTagPill({required this.tag, required this.isHovered});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isHovered
            ? AppTheme.brandRed.withOpacity(0.15)
            : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isHovered
              ? AppTheme.brandRed.withOpacity(0.4)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Text(
        tag,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: isHovered ? AppTheme.brandRed : Colors.white54,
        ),
      ),
    );
  }
}

class _ArrowCircleBadge extends StatelessWidget {
  final bool isHovered;
  final double size;

  const _ArrowCircleBadge({required this.isHovered, required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isHovered ? AppTheme.brandRed : Colors.white.withOpacity(0.04),
        border: Border.all(
          color: isHovered ? AppTheme.brandRed : Colors.white12,
        ),
        boxShadow: isHovered
            ? [
          BoxShadow(
            color: AppTheme.brandRed.withOpacity(0.4),
            blurRadius: 12,
          ),
        ]
            : [],
      ),
      child: AnimatedRotation(
        turns: isHovered ? 0.125 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: Icon(
          Icons.arrow_outward_rounded,
          size: size * 0.5,
          color: isHovered ? Colors.white : Colors.white38,
        ),
      ),
    );
  }
}

// ============================================================================
// ULTRA-PREMIUM WHY TEVAH SECTION (AWARDS TIER TILT + HUD CIRCUIT LASER)
// ============================================================================

class StickyWhyTevahSection extends StatefulWidget {
  final double scrollOffset;

  const StickyWhyTevahSection({super.key, required this.scrollOffset});

  static const List<Map<String, dynamic>> stories = [
    {
      'num': '01',
      'title': 'THINK DIFFERENT.',
      'tagline': 'FIRST PRINCIPLES ARCHITECTURE',
      'desc':
      'We challenge legacy assumptions before writing code, transforming complex business logic into high-leverage digital assets.',
      'tags': ['FIRST PRINCIPLES', 'PROFIT ARCHITECTURE', 'DE-RISKED CORE'],
      'metric': '4.2x ROI LEVERAGE',
    },
    {
      'num': '02',
      'title': 'DESIGN WITH PURPOSE.',
      'tagline': 'SUB-SECOND INTERACTION PHYSICS',
      'desc':
      'Sub-second cognitive clarity meets high-conversion visual design built specifically for modern audience retention.',
      'tags': ['SUB-10MS LATENCY', 'RETENTION MATRIX', 'MICRO-PHYSICS'],
      'metric': '99.8% USER RETENTION',
    },
    {
      'num': '03',
      'title': 'BUILD TO SCALE.',
      'tagline': 'DISTRIBUTED EDGE SYSTEMS',
      'desc':
      'Headless architectures and distributed edge deployments engineered to effortlessly handle multi-million global traffic spikes.',
      'tags': ['DISTRIBUTED EDGE', '99.99% UPTIME', 'AUTO-BALANCED'],
      'metric': '10M+ REQ / SEC',
    },
    {
      'num': '04',
      'title': 'AI NATIVE.',
      'tagline': 'NEURAL PIPELINE INTEGRATION',
      'desc':
      'Machine intelligence and autonomous agent logic baked directly into core system logic—never glued on as a superficial add-on.',
      'tags': ['LLM AGENTS', 'EVENT-DRIVEN BI', 'VECTOR PIPELINES'],
      'metric': '75% OPS AUTOMATED',
    },
    {
      'num': '05',
      'title': 'CREATE IMPACT.',
      'tagline': 'COMPOUND BUSINESS VELOCITY',
      'desc':
      'Radically reduced operational friction, ultra-low latencies, and accelerated digital expansion.',
      'tags': ['COMPOUND GROWTH', 'ENTERPRISE READY', 'SCALED VELOCITY'],
      'metric': '100% AUDIT ACCREDITED',
    },
  ];

  @override
  State<StickyWhyTevahSection> createState() => _StickyWhyTevahSectionState();
}

class _StickyWhyTevahSectionState extends State<StickyWhyTevahSection>
    with SingleTickerProviderStateMixin {
  int _hoveredIndex = -1;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;
    final double padding = isMobile ? 16.0 : 56.0;

    const double sectionTrigger = 3200.0;
    final double relativeScroll = (widget.scrollOffset - sectionTrigger).clamp(
      0.0,
      1800.0,
    );

    final double scrollProgress = (relativeScroll / 340.0).clamp(
      0.0,
      (StickyWhyTevahSection.stories.length - 1).toDouble(),
    );

    final int activeIndex = _hoveredIndex != -1
        ? _hoveredIndex
        : scrollProgress.round().clamp(
      0,
      StickyWhyTevahSection.stories.length - 1,
    );

    final activeStory = StickyWhyTevahSection.stories[activeIndex];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: isMobile
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WHY\nTEVAH?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 24),
          Column(
            children: List.generate(
              StickyWhyTevahSection.stories.length,
                  (index) {
                final story = StickyWhyTevahSection.stories[index];
                final bool isSelected = activeIndex == index;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF141419)
                        : const Color(0xFF0C0C0E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.brandRed
                          : Colors.white10,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            story['num'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.brandRed,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.brandRed.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              story['metric'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.brandRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        story['title'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        story['desc'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          height: 1.5,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      )
          : Stack(
        clipBehavior: Clip.none,
        children: [
          // Huge Watermark HUD Digits
          Positioned(
            left: -40,
            top: -20,
            child: IgnorePointer(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.92,
                        end: 1.0,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  activeStory['num'] as String,
                  key: ValueKey<String>(activeStory['num'] as String),
                  style: TextStyle(
                    fontFamily: 'Thunder',
                    fontSize: 420,
                    fontWeight: FontWeight.w900,
                    height: 0.7,
                    color: Colors.white.withOpacity(0.015),
                    letterSpacing: -10.0,
                  ),
                ),
              ),
            ),
          ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sticky Left Header
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.brandRed,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SYSTEM ARCHITECTURE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.brandRed,
                            letterSpacing: 2.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'WHY\nTEVAH?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 72,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -3.0,
                        height: 0.95,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      height: 3,
                      width: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.brandRed, Colors.transparent],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 36),
                    Text(
                      'ENGINEERING RIGOR\nAI NATIVE SYSTEMS\nHIGH CONVERSION UI',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        height: 1.8,
                        color: Colors.white38,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Live Telemetry Widget
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.bolt_rounded,
                                size: 14,
                                color: AppTheme.brandRed,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'TELEMETRY CORE',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white60,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            activeStory['metric'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 32),

              // Circuit + Card Stack Column
              Expanded(
                flex: 7,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Circuit Track Custom Paint
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: _CyberMotherboardPainter(
                              totalItems:
                              StickyWhyTevahSection.stories.length,
                              activeIndex: activeIndex,
                              scrollProgress: _hoveredIndex != -1
                                  ? _hoveredIndex.toDouble()
                                  : scrollProgress,
                              pulseValue: _pulseController.value,
                              brandColor: AppTheme.brandRed,
                            ),
                          );
                        },
                      ),
                    ),

                    // Cards List
                    Padding(
                      padding: const EdgeInsets.only(left: 48.0),
                      child: Column(
                        children: List.generate(
                          StickyWhyTevahSection.stories.length,
                              (index) {
                            final story =
                            StickyWhyTevahSection.stories[index];
                            final bool isSelected = activeIndex == index;
                            final bool isHovered = _hoveredIndex == index;

                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: 28.0,
                              ),
                              child: _FuturisticTiltCard(
                                story: story,
                                isSelected: isSelected,
                                isHovered: isHovered,
                                onHover: (h) {
                                  setState(() {
                                    _hoveredIndex = h ? index : -1;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CYBER MOTHERBOARD CIRCUIT PAINTER
// ============================================================================

class _CyberMotherboardPainter extends CustomPainter {
  final int totalItems;
  final int activeIndex;
  final double scrollProgress;
  final double pulseValue;
  final Color brandColor;

  _CyberMotherboardPainter({
    required this.totalItems,
    required this.activeIndex,
    required this.scrollProgress,
    required this.pulseValue,
    required this.brandColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double laserX = 14.0;
    const double cardLeftEdge = 48.0;
    const double cardHeight = 240.0;
    const double cardGap = 28.0;
    const double totalCardStep = cardHeight + cardGap;
    final double totalHeight = (totalItems - 1) * totalCardStep;

    // Dark Circuit Substrate
    final Paint trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw Inactive Backbone
    canvas.drawLine(
      const Offset(laserX, 40),
      Offset(laserX, 40 + totalHeight),
      trackPaint,
    );

    // Draw Inactive Branch Connectors
    for (int i = 0; i < totalItems; i++) {
      final double nodeY = 40 + (i * totalCardStep);

      final Path branchPath = Path()
        ..moveTo(laserX, nodeY)
        ..lineTo(laserX + 16, nodeY)
        ..lineTo(laserX + 24, nodeY + 12)
        ..lineTo(cardLeftEdge, nodeY + 12);

      canvas.drawPath(branchPath, trackPaint);

      // Junction Solder Pad
      canvas.drawCircle(
        Offset(laserX, nodeY),
        4.0,
        Paint()..color = Colors.white12,
      );
    }

    // Active Laser Glow Paints
    final double filledHeight = (scrollProgress * totalCardStep).clamp(
      0.0,
      totalHeight,
    );

    final Paint neonAura = Paint()
      ..color = brandColor.withOpacity(0.4)
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final Paint neonCore = Paint()
      ..color = brandColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Draw active vertical laser
    canvas.drawLine(
      const Offset(laserX, 40),
      Offset(laserX, 40 + filledHeight),
      neonAura,
    );
    canvas.drawLine(
      const Offset(laserX, 40),
      Offset(laserX, 40 + filledHeight),
      neonCore,
    );

    // Draw Active Selected Node Circuits
    for (int i = 0; i < totalItems; i++) {
      final double nodeY = 40 + (i * totalCardStep);
      final bool isCurrent = i == activeIndex;
      final bool isPassed = i <= activeIndex;

      if (isPassed) {
        final Path branchPath = Path()
          ..moveTo(laserX, nodeY)
          ..lineTo(laserX + 16, nodeY)
          ..lineTo(laserX + 24, nodeY + 12)
          ..lineTo(cardLeftEdge, nodeY + 12);

        if (isCurrent) {
          canvas.drawPath(branchPath, neonAura);
          canvas.drawPath(branchPath, neonCore);
        } else {
          canvas.drawPath(
            branchPath,
            Paint()
              ..color = brandColor.withOpacity(0.5)
              ..strokeWidth = 2.0
              ..style = PaintingStyle.stroke,
          );
        }
      }

      // Active Node Reactor
      if (isCurrent) {
        // High-energy particle pulse
        canvas.drawCircle(
          Offset(laserX, nodeY),
          8.0 + (pulseValue * 6.0),
          Paint()
            ..color = brandColor.withOpacity(0.4 * (1.0 - pulseValue))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );

        // Core Reactor Ring
        canvas.drawCircle(
          Offset(laserX, nodeY),
          5.5,
          Paint()..color = Colors.white,
        );

        // Electric Spark at Card Entry
        canvas.drawCircle(
          Offset(cardLeftEdge, nodeY + 12),
          4.0,
          Paint()..color = brandColor,
        );
      } else if (isPassed) {
        canvas.drawCircle(
          Offset(laserX, nodeY),
          4.0,
          Paint()..color = brandColor,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CyberMotherboardPainter oldDelegate) =>
      oldDelegate.scrollProgress != scrollProgress ||
          oldDelegate.activeIndex != activeIndex ||
          oldDelegate.pulseValue != pulseValue;
}

// ============================================================================
// 3D PERSPECTIVE TILT CARD WITH GLASS REFLECTION
// ============================================================================

class _FuturisticTiltCard extends StatefulWidget {
  final Map<String, dynamic> story;
  final bool isSelected;
  final bool isHovered;
  final ValueChanged<bool> onHover;

  const _FuturisticTiltCard({
    required this.story,
    required this.isSelected,
    required this.isHovered,
    required this.onHover,
  });

  @override
  State<_FuturisticTiltCard> createState() => _FuturisticTiltCardState();
}

class _FuturisticTiltCardState extends State<_FuturisticTiltCard> {
  Offset _localPos = Offset.zero;
  double _rotateX = 0.0;
  double _rotateY = 0.0;

  void _onPointerMove(PointerEvent e, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    setState(() {
      _localPos = e.localPosition;
      // 3D tilt calculation
      _rotateX = (centerY - e.localPosition.dy) / centerY * 0.08;
      _rotateY = (e.localPosition.dx - centerX) / centerX * 0.08;
    });
  }

  void _resetTilt() {
    setState(() {
      _localPos = Offset.zero;
      _rotateX = 0.0;
      _rotateY = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool highlighted = widget.isSelected || widget.isHovered;
    final List<String> tags = widget.story['tags'] as List<String>;

    return MouseRegion(
      onEnter: (_) => widget.onHover(true),
      onExit: (_) {
        widget.onHover(false);
        _resetTilt();
      },
      child: Listener(
        onPointerMove: (e) {
          final RenderBox? box = context.findRenderObject() as RenderBox?;
          if (box != null) _onPointerMove(e, box.size);
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: highlighted ? 1.0 : 0.35,
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateX(_rotateX)
              ..rotateY(_rotateY)
              ..translate(highlighted ? 12.0 : 0.0, 0.0, 0.0),
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: highlighted
                      ? [const Color(0xFF181820), const Color(0xFF0F0F14)]
                      : [const Color(0xFF0F0F12), const Color(0xFF0A0A0C)],
                ),
                border: Border.all(
                  color: highlighted
                      ? AppTheme.brandRed.withOpacity(0.8)
                      : Colors.white10,
                  width: highlighted ? 1.5 : 1.0,
                ),
                boxShadow: highlighted
                    ? [
                  BoxShadow(
                    color: AppTheme.brandRed.withOpacity(0.22),
                    blurRadius: 40,
                    offset: const Offset(0, 14),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.8),
                    blurRadius: 30,
                  ),
                ]
                    : [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(23),
                child: Stack(
                  children: [
                    // Dynamic Specular Glare Follower
                    if (highlighted && _localPos != Offset.zero)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _DynamicGlarePainter(cursorPos: _localPos),
                        ),
                      ),

                    // Card Content
                    Padding(
                      padding: const EdgeInsets.all(36),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    widget.story['num'] as String,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.brandRed,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    widget.story['tagline'] as String,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white38,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                              AnimatedRotation(
                                turns: highlighted ? 0.125 : 0.0,
                                duration: const Duration(milliseconds: 250),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: highlighted
                                        ? AppTheme.brandRed
                                        : Colors.white.withOpacity(0.04),
                                  ),
                                  child: Icon(
                                    Icons.arrow_outward_rounded,
                                    size: 16,
                                    color: highlighted
                                        ? Colors.white
                                        : Colors.white30,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.story['title'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.0,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.story['desc'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              height: 1.6,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Tech Chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: tags.map((t) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: highlighted
                                      ? AppTheme.brandRed.withOpacity(0.12)
                                      : Colors.white.withOpacity(0.03),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: highlighted
                                        ? AppTheme.brandRed.withOpacity(0.4)
                                        : Colors.white.withOpacity(0.06),
                                  ),
                                ),
                                child: Text(
                                  t,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: highlighted
                                        ? Colors.white
                                        : Colors.white54,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// DYNAMIC GLARE PAINTER
// ============================================================================

class _DynamicGlarePainter extends CustomPainter {
  final Offset cursorPos;

  _DynamicGlarePainter({required this.cursorPos});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint glare = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.08),
          AppTheme.brandRed.withOpacity(0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: cursorPos, radius: 260));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glare);
  }

  @override
  bool shouldRepaint(covariant _DynamicGlarePainter oldDelegate) =>
      oldDelegate.cursorPos != cursorPos;
}

// ============================================================================
// ELEVATED AI SPOTLIGHT & NEURAL ENGINE CENTERPIECE
// ============================================================================

class AiCenterpieceSection extends StatefulWidget {
  final double scrollOffset;

  const AiCenterpieceSection({super.key, required this.scrollOffset});

  static const List<Map<String, dynamic>> pipelineSteps = [
    {
      'code': '01',
      'label': 'INGESTION',
      'title': 'Raw Multimodal Stream',
      'desc':
      'Real-time extraction across vector stores, APIs & unstructured data.',
      'icon': Icons.input_rounded,
    },
    {
      'code': '02',
      'label': 'NEURAL REASONING',
      'title': 'Cognitive LLM Routing',
      'desc': 'Dynamic sub-10ms agent orchestration and intent clustering.',
      'icon': Icons.psychology_rounded,
    },
    {
      'code': '03',
      'label': 'AUTONOMOUS CORE',
      'title': 'Deterministic Execution',
      'desc': 'Automated workflow pipelines with self-healing feedback loops.',
      'icon': Icons.bolt_rounded,
    },
    {
      'code': '04',
      'label': 'IMPACT OUTPUT',
      'title': 'High-Leverage Results',
      'desc':
      'Direct business intelligence insights and zero-friction execution.',
      'icon': Icons.auto_awesome_rounded,
    },
  ];

  static const List<String> aiPills = [
    'AUTONOMOUS AGENTS',
    'EVENT-DRIVEN WORKFLOWS',
    'FINE-TUNED LLMS',
    'VECTOR DATABASES',
    'REALTIME BI',
    'SELF-HEALING PIPELINES',
  ];

  @override
  State<AiCenterpieceSection> createState() => _AiCenterpieceSectionState();
}

class _AiCenterpieceSectionState extends State<AiCenterpieceSection>
    with TickerProviderStateMixin {
  late AnimationController _orbitController;
  late AnimationController _pulseController;
  int _selectedStep = 1;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;
    final double padding = isMobile ? 16.0 : 48.0;

    const double triggerOffset = 3800.0;
    final double scrollProgress =
    ((widget.scrollOffset - triggerOffset) / 500.0).clamp(0.0, 1.0);

    final int autoActiveStep =
    (scrollProgress * (AiCenterpieceSection.pipelineSteps.length - 1))
        .round();
    final int currentStep = _selectedStep.clamp(
      0,
      AiCenterpieceSection.pipelineSteps.length - 1,
    );
    final activeData = AiCenterpieceSection.pipelineSteps[currentStep];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: padding),
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 48 : 80,
        horizontal: isMobile ? 20 : 64,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0C0E),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: AppTheme.brandRed.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandRed.withOpacity(0.08),
            blurRadius: 60,
            spreadRadius: 2,
            offset: const Offset(0, 16),
          ),
          BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 40),
        ],
      ),
      child: Stack(
        children: [
          // Background Matrix Glow
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _NeuralCoreGridPainter(
                  pulseValue: _pulseController.value,
                ),
              ),
            ),
          ),

          Column(
            children: [
              // Section Subtitle Pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.brandRed.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.brandRed.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.brandRed,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '04 / AI NEURAL ENGINE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Title
              Text(
                'INTELLIGENCE, AUTOMATED.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 32 : 64,
                  fontWeight: FontWeight.w900,
                  letterSpacing: isMobile ? -1.0 : -2.5,
                  height: 1.05,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: 600,
                child: Text(
                  'End-to-end cognitive architectures built for automated reasoning, instant data orchestration, and autonomous execution.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 13 : 15,
                    height: 1.6,
                    color: Colors.white60,
                  ),
                ),
              ),

              const SizedBox(height: 56),

              // Orbiting Reactor Core
              SizedBox(
                width: isMobile ? 220 : 320,
                height: isMobile ? 220 : 320,
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _orbitController,
                    _pulseController,
                  ]),
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _OrbitalReactorPainter(
                        orbitProgress: _orbitController.value,
                        pulseProgress: _pulseController.value,
                      ),
                      child: Center(
                        child: Container(
                          width: isMobile ? 74 : 100,
                          height: isMobile ? 74 : 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [Color(0xFFE50914), AppTheme.brandRed],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.brandRed.withOpacity(
                                  0.6 + (_pulseController.value * 0.4),
                                ),
                                blurRadius: 36 + (_pulseController.value * 16),
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.memory_rounded,
                            color: Colors.white,
                            size: isMobile ? 32 : 44,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 56),

              // Interactive Stepper Pipeline
              if (isMobile)
                Column(
                  children: List.generate(
                    AiCenterpieceSection.pipelineSteps.length,
                        (index) {
                      final item = AiCenterpieceSection.pipelineSteps[index];
                      final bool isSelected = _selectedStep == index;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _PipelineNodeCard(
                          item: item,
                          isSelected: isSelected,
                          onTap: () => setState(() => _selectedStep = index),
                        ),
                      );
                    },
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    AiCenterpieceSection.pipelineSteps.length * 2 - 1,
                        (i) {
                      if (i.isOdd) {
                        final int stepIndex = i ~/ 2;
                        final bool active = stepIndex < _selectedStep;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: _InteractivePipelineConnector(
                            isActive: active,
                          ),
                        );
                      }

                      final int index = i ~/ 2;
                      final item = AiCenterpieceSection.pipelineSteps[index];
                      final bool isSelected = _selectedStep == index;

                      return _PipelineNodeCard(
                        item: item,
                        isSelected: isSelected,
                        onTap: () => setState(() => _selectedStep = index),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 32),

              // Real-Time Telemetry Insight Display Card
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isMobile ? double.infinity : 680,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF14141A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.brandRed.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.brandRed.withOpacity(0.1),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.brandRed.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        activeData['icon'] as IconData,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                activeData['title'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'STAGE ${activeData['code']}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.brandRed,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activeData['desc'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              height: 1.4,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 44),

              // Capabilities Tags Pill Grid
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: AiCenterpieceSection.aiPills.map((pill) {
                  return _InteractiveTechPill(label: pill);
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// STEP CARD NODE
// ============================================================================

class _PipelineNodeCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isSelected;
  final VoidCallback onTap;

  const _PipelineNodeCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.brandRed : const Color(0xFF16161D),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected ? AppTheme.brandRed : Colors.white12,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: AppTheme.brandRed.withOpacity(0.4),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item['code'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white70 : Colors.white30,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item['label'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.0,
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
// PIPELINE CONNECTOR LASER
// ============================================================================

class _InteractivePipelineConnector extends StatelessWidget {
  final bool isActive;

  const _InteractivePipelineConnector({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 24,
      height: 2,
      decoration: BoxDecoration(
        color: isActive ? AppTheme.brandRed : Colors.white12,
        boxShadow: isActive
            ? [
          BoxShadow(
            color: AppTheme.brandRed.withOpacity(0.8),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ]
            : [],
      ),
    );
  }
}

// ============================================================================
// TECH PILL
// ============================================================================

class _InteractiveTechPill extends StatefulWidget {
  final String label;

  const _InteractiveTechPill({required this.label});

  @override
  State<_InteractiveTechPill> createState() => _InteractiveTechPillState();
}

class _InteractiveTechPillState extends State<_InteractiveTechPill> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: _isHovered
              ? AppTheme.brandRed.withOpacity(0.14)
              : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isHovered
                ? AppTheme.brandRed.withOpacity(0.6)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Text(
          widget.label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _isHovered ? Colors.white : Colors.white60,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ORBITAL REACTOR CUSTOM PAINTER
// ============================================================================

class _OrbitalReactorPainter extends CustomPainter {
  final double orbitProgress;
  final double pulseProgress;

  _OrbitalReactorPainter({
    required this.orbitProgress,
    required this.pulseProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double maxRadius = size.width / 2;

    // Ambient Outer Radial Aura
    final Paint glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.brandRed.withOpacity(0.18 + (pulseProgress * 0.1)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));
    canvas.drawCircle(center, maxRadius, glowPaint);

    // Ring 1 (Outer Dash Ring)
    final Paint ring1 = Paint()
      ..color = AppTheme.brandRed.withOpacity(0.25)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, maxRadius * 0.95, ring1);

    // Ring 2 (Middle Solid Ring)
    final Paint ring2 = Paint()
      ..color = AppTheme.brandRed.withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, maxRadius * 0.68, ring2);

    // Orbiting Synapse Particles
    final double angle1 = orbitProgress * 2 * math.pi;
    final double angle2 = -orbitProgress * 2 * math.pi * 1.5;

    final Offset p1 = Offset(
      center.dx + (maxRadius * 0.95) * math.cos(angle1),
      center.dy + (maxRadius * 0.95) * math.sin(angle1),
    );
    final Offset p2 = Offset(
      center.dx + (maxRadius * 0.68) * math.cos(angle2),
      center.dy + (maxRadius * 0.68) * math.sin(angle2),
    );

    // Particle 1 Glow & Dot
    canvas.drawCircle(
      p1,
      6.0,
      Paint()
        ..color = AppTheme.brandRed.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(p1, 3.5, Paint()..color = Colors.white);

    // Particle 2 Glow & Dot
    canvas.drawCircle(
      p2,
      5.0,
      Paint()
        ..color = AppTheme.brandRed.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(p2, 3.0, Paint()..color = const Color(0xFFFF6B6B));
  }

  @override
  bool shouldRepaint(covariant _OrbitalReactorPainter oldDelegate) => true;
}

// ============================================================================
// BACKGROUND HUD GRID PAINTER
// ============================================================================

class _NeuralCoreGridPainter extends CustomPainter {
  final double pulseValue;

  _NeuralCoreGridPainter({required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.015)
      ..strokeWidth = 1.0;

    const double step = 45.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NeuralCoreGridPainter oldDelegate) => false;
}

// ============================================================================
// ELEVATED IMPACT / METRICS SECTION
// ============================================================================

class ImpactStatsSection extends StatefulWidget {
  final double scrollOffset;

  const ImpactStatsSection({super.key, required this.scrollOffset});

  @override
  State<ImpactStatsSection> createState() => _ImpactStatsSectionState();
}

class _ImpactStatsSectionState extends State<ImpactStatsSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _countController;
  late Animation<double> _animation;
  final GlobalKey _sectionKey = GlobalKey();
  bool _hasTriggered = false;

  @override
  void initState() {
    super.initState();
    _countController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _animation = CurvedAnimation(
      parent: _countController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant ImpactStatsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkVisibility();
  }

  void _checkVisibility() {
    if (_hasTriggered) return;

    final RenderObject? renderObject = _sectionKey.currentContext
        ?.findRenderObject();
    if (renderObject is RenderBox) {
      final position = renderObject.localToGlobal(Offset.zero);
      final screenHeight = MediaQuery.of(context).size.height;

      // Trigger animation once the section enters the bottom 85% of viewport
      if (position.dy < screenHeight * 0.85 &&
          position.dy > -renderObject.size.height) {
        _hasTriggered = true;
        _countController.forward();
      }
    }
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;
    final double padding = isMobile ? 16.0 : 48.0;

    return Padding(
      key: _sectionKey,
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '05 / PROVEN IMPACT',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.brandRed,
                  letterSpacing: 2.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  'GLOBAL BENCHMARKS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white54,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final double progress = _animation.value;
              final int years = (progress * 12).round();
              final int projects = (progress * 150).round();
              final int clients = (progress * 30).round();

              if (isMobile) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _ImpactBentoCard(
                            value: '$years+',
                            label: 'YEARS EXPERIENCE',
                            subtitle: 'Industry standard engineering',
                            icon: Icons.history_edu_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ImpactBentoCard(
                            value: '$projects+',
                            label: 'DEPLOYED PROJECTS',
                            subtitle: 'Enterprise digital systems',
                            icon: Icons.rocket_launch_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ImpactBentoCard(
                            value: '$clients+',
                            label: 'ACTIVE CLIENTS',
                            subtitle: 'Across global markets',
                            icon: Icons.groups_2_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: _ImpactBentoCard(
                            value: '∞',
                            label: 'POSSIBILITIES',
                            subtitle: 'Powered by AI intelligence',
                            icon: Icons.all_inclusive_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _ImpactBentoCard(
                      value: '$years+',
                      label: 'YEARS IN TECH',
                      subtitle: 'Continuous engineering mastery',
                      icon: Icons.history_edu_rounded,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ImpactBentoCard(
                      value: '$projects+',
                      label: 'SOLUTIONS BUILT',
                      subtitle: 'Global digital applications',
                      icon: Icons.rocket_launch_rounded,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ImpactBentoCard(
                      value: '$clients+',
                      label: 'CLIENT RETENTION',
                      subtitle: 'Long-term strategic partners',
                      icon: Icons.groups_2_rounded,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: _ImpactBentoCard(
                      value: '∞',
                      label: 'POSSIBILITIES',
                      subtitle: 'Automated scalable growth',
                      icon: Icons.all_inclusive_rounded,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// IMPACT BENTO CARD WITH HOVER GLOW
// ============================================================================

class _ImpactBentoCard extends StatefulWidget {
  final String value;
  final String label;
  final String subtitle;
  final IconData icon;

  const _ImpactBentoCard({
    required this.value,
    required this.label,
    required this.subtitle,
    required this.icon,
  });

  @override
  State<_ImpactBentoCard> createState() => _ImpactBentoCardState();
}

class _ImpactBentoCardState extends State<_ImpactBentoCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
        padding: EdgeInsets.all(isMobile ? 18 : 28),
        decoration: BoxDecoration(
          color: _isHovered ? AppTheme.darkSurface : AppTheme.darkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isHovered
                ? AppTheme.brandRed.withOpacity(0.6)
                : AppTheme.greyBorder,
            width: 1.2,
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
                Icon(
                  widget.icon,
                  size: isMobile ? 18 : 22,
                  color: _isHovered ? AppTheme.brandRed : Colors.white24,
                ),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isHovered ? AppTheme.brandRed : Colors.white10,
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 16 : 24),
            Text(
              widget.value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: isMobile ? 36 : 56,
                fontWeight: FontWeight.w900,
                height: 1.0,
                color: _isHovered ? Colors.white : AppTheme.brandRed,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: isMobile ? 10 : 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: isMobile ? 10 : 12,
                color: Colors.white38,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ELEVATED TESTIMONIALS & SOCIAL PROOF SECTION
// ============================================================================

class TestimonialsSection extends StatefulWidget {
  final ValueChanged<bool> onHoverItem;

  const TestimonialsSection({super.key, required this.onHoverItem});

  static const List<Map<String, dynamic>> testimonials = [
    {
      'quote':
      "TEVAH transformed our core infrastructure into something far beyond our original roadmap. Their precision engineering is unmatched.",
      'author': 'ALEXANDER WRIGHT',
      'role': 'CHIEF TECHNOLOGY OFFICER',
      'company': 'FINTECH LABS',
      'impact': '+240% CONVERSION',
      'avatar': 'AW',
    },
    {
      'quote':
      "The autonomous AI engine deployed by TEVAH slashed our operational processing overhead by 75% inside the first quarter alone.",
      'author': 'SARAH JENKINS',
      'role': 'VP OF DIGITAL SYSTEMS',
      'company': 'LOGIX GLOBAL',
      'impact': '75% OPS AUTOMATED',
      'avatar': 'SJ',
    },
    {
      'quote':
      "Their rigorous adherence to micro-interaction physics and high-scale architectures makes TEVAH our primary technology partner.",
      'author': 'MARCUS CHEN',
      'role': 'FOUNDER & CEO',
      'company': 'NEXUS AI SYSTEMS',
      'impact': '99.99% RESILIENCE',
      'avatar': 'MC',
    },
    {
      'quote':
      "From wireframes to edge deployment, TEVAH delivered a sub-second response platform that seamlessly handles our global volume.",
      'author': 'ELENA ROSTOVA',
      'role': 'HEAD OF PRODUCT',
      'company': 'AURORA CLOUD',
      'impact': 'SUB-10MS LATENCY',
      'avatar': 'ER',
    },
  ];

  @override
  State<TestimonialsSection> createState() => _TestimonialsSectionState();
}

class _TestimonialsSectionState extends State<TestimonialsSection> {
  final ScrollController _cardsScrollController = ScrollController();
  int _activeCardIndex = 0;

  void _scrollNext() {
    if (_cardsScrollController.hasClients) {
      final double target = (_cardsScrollController.offset + 440).clamp(
        0.0,
        _cardsScrollController.position.maxScrollExtent,
      );
      _cardsScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _scrollPrev() {
    if (_cardsScrollController.hasClients) {
      final double target = (_cardsScrollController.offset - 440).clamp(
        0.0,
        _cardsScrollController.position.maxScrollExtent,
      );
      _cardsScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _cardsScrollController.dispose();
    super.dispose();
  }

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
          // Section Header & Navigation Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.brandRed,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '06 / PROVEN VALIDATION',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.brandRed,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'WHAT CLIENTS SAY',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 28 : 44,
                      fontWeight: FontWeight.w900,
                      letterSpacing: isMobile ? -1.0 : -1.8,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              // Navigation Arrow Controls (Desktop)
              if (!isMobile)
                Row(
                  children: [
                    _TestimonialNavButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: _scrollPrev,
                    ),
                    const SizedBox(width: 12),
                    _TestimonialNavButton(
                      icon: Icons.arrow_forward_rounded,
                      onTap: _scrollNext,
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 36),

          // Horizontal Cards Carousel
          SingleChildScrollView(
            controller: _cardsScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(
                TestimonialsSection.testimonials.length,
                    (index) {
                  final t = TestimonialsSection.testimonials[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 24.0, bottom: 8.0),
                    child: _TestimonialCard(
                      data: t,
                      isMobile: isMobile,
                      onHover: widget.onHoverItem,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// INDIVIDUAL TESTIMONIAL CARD WITH SPECULAR SHEEN
// ============================================================================

class _TestimonialCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isMobile;
  final ValueChanged<bool> onHover;

  const _TestimonialCard({
    required this.data,
    required this.isMobile,
    required this.onHover,
  });

  @override
  State<_TestimonialCard> createState() => _TestimonialCardState();
}

class _TestimonialCardState extends State<_TestimonialCard> {
  bool _isHovered = false;
  Offset _localCursor = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final double cardWidth = widget.isMobile
        ? MediaQuery.of(context).size.width * 0.84
        : 480;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        widget.onHover(true);
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
          _localCursor = Offset.zero;
        });
        widget.onHover(false);
      },
      onHover: (e) => setState(() => _localCursor = e.localPosition),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        width: cardWidth,
        transform: Matrix4.translationValues(0, _isHovered ? -6 : 0, 0),
        padding: EdgeInsets.all(widget.isMobile ? 24 : 36),
        decoration: BoxDecoration(
          color: _isHovered ? const Color(0xFF141419) : AppTheme.darkCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isHovered
                ? AppTheme.brandRed.withOpacity(0.7)
                : AppTheme.greyBorder,
            width: _isHovered ? 1.5 : 1.0,
          ),
          boxShadow: _isHovered
              ? [
            BoxShadow(
              color: AppTheme.brandRed.withOpacity(0.18),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 20,
            ),
          ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: Stack(
            children: [
              // Subtle background watermark quote
              Positioned(
                right: -10,
                top: -20,
                child: Text(
                  '“',
                  style: TextStyle(
                    fontFamily: 'Thunder',
                    fontSize: 160,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withOpacity(0.02),
                    height: 1.0,
                  ),
                ),
              ),

              // Specular mouse sheen
              if (_isHovered && _localCursor != Offset.zero)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TestimonialGlarePainter(cursorPos: _localCursor),
                  ),
                ),

              // Content layout
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Stars + Impact Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 5 Stars
                      Row(
                        children: List.generate(
                          5,
                              (i) => const Padding(
                            padding: EdgeInsets.only(right: 3.0),
                            child: Icon(
                              Icons.star_rounded,
                              color: AppTheme.brandRed,
                              size: 16,
                            ),
                          ),
                        ),
                      ),

                      // Quantified Impact Chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.brandRed.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppTheme.brandRed.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          widget.data['impact'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Quote Body
                  Text(
                    '"${widget.data['quote']}"',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: widget.isMobile ? 15 : 18,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.92),
                    ),
                  ),

                  const SizedBox(height: 32),

                  const Divider(color: Colors.white10, height: 1),

                  const SizedBox(height: 20),

                  // Author Info Block
                  Row(
                    children: [
                      // Initials Avatar Ring
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.04),
                          border: Border.all(
                            color: _isHovered
                                ? AppTheme.brandRed
                                : Colors.white12,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            widget.data['avatar'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _isHovered ? Colors.white : Colors.white60,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.data['author'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 13,
                                  color: Color(0xFF10B981),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "${widget.data['role']} • ${widget.data['company']}",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white38,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// CAROUSEL NAVIGATION BUTTON
// ============================================================================

class _TestimonialNavButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TestimonialNavButton({required this.icon, required this.onTap});

  @override
  State<_TestimonialNavButton> createState() => _TestimonialNavButtonState();
}

class _TestimonialNavButtonState extends State<_TestimonialNavButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _hovered ? AppTheme.brandRed : Colors.white.withOpacity(0.04),
            border: Border.all(
              color: _hovered ? AppTheme.brandRed : Colors.white12,
            ),
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: _hovered ? Colors.white : Colors.white60,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SPECULAR CARD GLARE PAINTER
// ============================================================================

class _TestimonialGlarePainter extends CustomPainter {
  final Offset cursorPos;

  _TestimonialGlarePainter({required this.cursorPos});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint glare = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.04),
          AppTheme.brandRed.withOpacity(0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 1.0],
      ).createShader(Rect.fromCircle(center: cursorPos, radius: 220));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glare);
  }

  @override
  bool shouldRepaint(covariant _TestimonialGlarePainter oldDelegate) =>
      oldDelegate.cursorPos != cursorPos;
}

// ============================================================================
// FINAL CALL TO ACTION SECTION
// ============================================================================

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
        padding: EdgeInsets.symmetric(
          vertical: isMobile ? 60 : 100,
          horizontal: isMobile ? 24 : 60,
        ),
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
                onPressed: () {
                  debugPrint('🚀 START A PROJECT CLICKED');
                  openLetsTalkModal(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandRed,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 32 : 48,
                    vertical: isMobile ? 16 : 24,
                  ),
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
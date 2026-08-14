import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'portfolio_service.dart';
import 'shared_widgets.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final ScrollController _scrollController = ScrollController();

  final ValueNotifier<Offset> _cursorPosNotifier =
  ValueNotifier<Offset>(Offset.zero);

  final ValueNotifier<bool> _isHoveringNotifier =
  ValueNotifier<bool>(false);

  final ValueNotifier<double> _scrollOffsetNotifier =
  ValueNotifier<double>(0);

  final PortfolioService _portfolioService = PortfolioService();

  String _selectedCategory = 'ALL';
  String _cursorText = '';

  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _allPortfolioItems = [];

  final List<String> _categories = [
    'ALL',
    'APP',
    'WEBSITE',
    'LOGO',
    'VIDEO',
    'GRAPHIC DESIGNS',
  ];

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);

    _loadPortfolio();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      _scrollOffsetNotifier.value = _scrollController.offset;
    }
  }

  Future<void> _loadPortfolio() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final items = await _portfolioService.getPortfolio();

      if (!mounted) return;

      setState(() {
        _allPortfolioItems = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _updateCursor({
    required bool hovering,
    String text = '',
  }) {
    _isHoveringNotifier.value = hovering;

    setState(() {
      _cursorText = text;
    });
  }

  void _openDetailsPage(Map<String, dynamic> item) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (
            context,
            animation,
            secondaryAnimation,
            ) {
          return AppDetailsPage(item: item);
        },
        transitionsBuilder: (
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
  }

  List<Map<String, dynamic>> get _filteredItems {
    if (_selectedCategory == 'ALL') {
      return List<Map<String, dynamic>>.from(
        _allPortfolioItems,
      );
    }

    return _allPortfolioItems.where((item) {
      final category =
          item['category']?.toString().toUpperCase() ?? '';

      return category == _selectedCategory;
    }).toList();
  }

  Map<String, dynamic>? get _featuredItem {
    if (_allPortfolioItems.isEmpty) {
      return null;
    }

    for (final item in _allPortfolioItems) {
      if (item['isFeatured'] == true ||
          item['isDataFeatured'] == true) {
        return item;
      }
    }

    return _allPortfolioItems.first;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();

    _cursorPosNotifier.dispose();
    _isHoveringNotifier.dispose();
    _scrollOffsetNotifier.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final bool isMobile = screenWidth < 768;

    final double horizontalPadding =
    isMobile ? 16 : 48;

    return MouseRegion(
      cursor: isMobile
          ? MouseCursor.defer
          : SystemMouseCursors.none,
      onHover: (event) {
        _cursorPosNotifier.value = event.position;
      },
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ============================================================
                // NAVBAR
                // ============================================================

                SliverToBoxAdapter(
                  child: TevahNavbar(
                    currentRoute: NavRoute.portfolio,
                    onHoverItem: (hovering) {
                      _updateCursor(
                        hovering: hovering,
                      );
                    },
                  ),
                ),

                // ============================================================
                // LOADING
                // ============================================================

                if (_isLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _PortfolioLoading(),
                  )

                // ============================================================
                // ERROR
                // ============================================================

                else if (_error != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _PortfolioError(
                      error: _error!,
                      onRetry: _loadPortfolio,
                    ),
                  )

                // ============================================================
                // EMPTY
                // ============================================================

                else if (_allPortfolioItems.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _PortfolioEmpty(),
                    )

                  // ============================================================
                  // PORTFOLIO
                  // ============================================================

                  else ...[
                      // ==========================================================
                      // HERO
                      // ==========================================================

                      SliverToBoxAdapter(
                        child: ValueListenableBuilder<double>(
                          valueListenable:
                          _scrollOffsetNotifier,
                          builder: (
                              context,
                              scrollOffset,
                              child,
                              ) {
                            return _CinematicPortfolioHero(
                              totalProjects:
                              _allPortfolioItems.length,
                              scrollOffset: scrollOffset,
                            );
                          },
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: isMobile ? 30 : 60,
                        ),
                      ),

                      // ==========================================================
                      // FILTER
                      // ==========================================================

                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          child: SingleChildScrollView(
                            scrollDirection:
                            Axis.horizontal,
                            child: Row(
                              children:
                              _categories.map((category) {
                                final selected =
                                    _selectedCategory ==
                                        category;

                                return Padding(
                                  padding:
                                  const EdgeInsets.only(
                                    right: 10,
                                  ),
                                  child: ChoiceChip(
                                    label: Text(category),
                                    selected: selected,
                                    onSelected: (value) {
                                      if (!value) return;

                                      setState(() {
                                        _selectedCategory =
                                            category;
                                      });
                                    },
                                    selectedColor:
                                    AppTheme.brandRed,
                                    backgroundColor:
                                    AppTheme.darkCard,
                                    labelStyle:
                                    GoogleFonts
                                        .plusJakartaSans(
                                      fontSize:
                                      isMobile
                                          ? 11
                                          : 12,
                                      fontWeight:
                                      FontWeight.bold,
                                      color: selected
                                          ? Colors.white
                                          : Colors.white70,
                                    ),
                                    shape:
                                    RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(
                                        30,
                                      ),
                                      side: BorderSide(
                                        color: selected
                                            ? AppTheme
                                            .brandRed
                                            : AppTheme
                                            .greyBorder,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: isMobile ? 50 : 90,
                        ),
                      ),

                      // ==========================================================
                      // FEATURED
                      // ==========================================================

                      if (_selectedCategory == 'ALL')
                        SliverToBoxAdapter(
                          child: Padding(
                            padding:
                            EdgeInsets.symmetric(
                              horizontal:
                              horizontalPadding,
                            ),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                _SectionLabel(
                                  text:
                                  '01 / FEATURED PROJECT',
                                ),

                                const SizedBox(height: 24),

                                if (_featuredItem != null)
                                  _FeaturedProjectHeroCard(
                                    item: _featuredItem!,
                                    onTap: () {
                                      _openDetailsPage(
                                        _featuredItem!,
                                      );
                                    },
                                    onHoverChange:
                                        (
                                        hovering,
                                        text,
                                        ) {
                                      _updateCursor(
                                        hovering: hovering,
                                        text: text,
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),

                      if (_selectedCategory == 'ALL')
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: isMobile ? 70 : 130,
                          ),
                        ),

                      // ==========================================================
                      // REEL
                      // ==========================================================

                      if (_selectedCategory == 'ALL')
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                EdgeInsets.symmetric(
                                  horizontal:
                                  horizontalPadding,
                                ),
                                child: const _SectionLabel(
                                  text:
                                  '02 / SELECTED REEL',
                                ),
                              ),

                              const SizedBox(height: 30),

                              ValueListenableBuilder<double>(
                                valueListenable:
                                _scrollOffsetNotifier,
                                builder: (
                                    context,
                                    offset,
                                    child,
                                    ) {
                                  return _HorizontalProjectReel(
                                    scrollOffset: offset,
                                    items:
                                    _allPortfolioItems,
                                    onTapItem: (item) {
                                      _openDetailsPage(
                                        item,
                                      );
                                    },
                                    onHoverItem:
                                        (
                                        hovering,
                                        text,
                                        ) {
                                      _updateCursor(
                                        hovering: hovering,
                                        text: text,
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                      if (_selectedCategory == 'ALL')
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: isMobile ? 70 : 130,
                          ),
                        ),

                      // ==========================================================
                      // ARCHIVE TITLE
                      // ==========================================================

                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                          EdgeInsets.symmetric(
                            horizontal:
                            horizontalPadding,
                          ),
                          child: _SectionLabel(
                            text:
                            _selectedCategory == 'ALL'
                                ? '03 / ARCHIVE GRID'
                                : 'ARCHIVE / $_selectedCategory',
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(
                        child: SizedBox(height: 30),
                      ),

                      // ==========================================================
                      // GRID
                      // ==========================================================

                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal:
                          horizontalPadding,
                        ),
                        sliver: SliverGrid(
                          gridDelegate:
                          SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 620,
                            mainAxisSpacing:
                            isMobile ? 20 : 36,
                            crossAxisSpacing:
                            isMobile ? 16 : 36,
                            childAspectRatio:
                            isMobile ? 0.85 : 1.15,
                          ),
                          delegate:
                          SliverChildBuilderDelegate(
                                (context, index) {
                              final item =
                              _filteredItems[index];

                              return _EditorialGridCard(
                                item: item,
                                onTap: () {
                                  _openDetailsPage(
                                    item,
                                  );
                                },
                                onHoverChange:
                                    (
                                    hovering,
                                    text,
                                    ) {
                                  _updateCursor(
                                    hovering: hovering,
                                    text: text,
                                  );
                                },
                              )
                                  .animate()
                                  .fadeIn(
                                duration: 350.ms,
                              )
                                  .slideY(
                                begin: 0.08,
                                end: 0,
                                duration: 400.ms,
                              );
                            },
                            childCount:
                            _filteredItems.length,
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: isMobile ? 90 : 160,
                        ),
                      ),

                      // ==========================================================
                      // CLIENTS
                      // ==========================================================

                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                          EdgeInsets.symmetric(
                            horizontal:
                            horizontalPadding,
                          ),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TRUSTED BY GLOBAL PARTNERS',
                                style: GoogleFonts
                                    .plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight:
                                  FontWeight.bold,
                                  color: Colors.white38,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 30),
                              Wrap(
                                spacing:
                                isMobile ? 20 : 40,
                                runSpacing:
                                isMobile ? 18 : 25,
                                children: const [
                                  _ClientLogo(
                                    name: 'FINTECH LABS',
                                  ),
                                  _ClientLogo(
                                    name: 'LOGIX GLOBAL',
                                  ),
                                  _ClientLogo(
                                    name: 'NEXUS AI',
                                  ),
                                  _ClientLogo(
                                    name: 'AURA VISUALS',
                                  ),
                                  _ClientLogo(
                                    name:
                                    'HEALTHCARE DIGITAL',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: isMobile ? 90 : 160,
                        ),
                      ),

                      // ==========================================================
                      // CTA
                      // ==========================================================

                      SliverToBoxAdapter(
                        child: _PortfolioFinalCta(
                          onHoverItem:
                              (hovering, text) {
                            _updateCursor(
                              hovering: hovering,
                              text: text,
                            );
                          },
                        ),
                      ),

                      const SliverToBoxAdapter(
                        child: SizedBox(height: 120),
                      ),

                      // ==========================================================
                      // FOOTER
                      // ==========================================================

                      const SliverToBoxAdapter(
                        child: AgencyFooter(),
                      ),

                      const SliverToBoxAdapter(
                        child: SizedBox(height: 40),
                      ),
                    ],
              ],
            ),

            // ================================================================
            // IMPORTANT:
            //
            // FloatingWhatsAppButton ALREADY contains Positioned.
            //
            // Therefore DO NOT put another Positioned around it.
            // ================================================================

            if (!isMobile)
              const FloatingWhatsAppButton(),

            // ================================================================
            // MOBILE WHATSAPP
            // ================================================================

            if (isMobile)
              const FloatingWhatsAppButton(),

            // ================================================================
            // CUSTOM CURSOR
            // ================================================================

            if (!isMobile)
              ValueListenableBuilder<Offset>(
                valueListenable:
                _cursorPosNotifier,
                builder: (
                    context,
                    cursorPosition,
                    child,
                    ) {
                  return ValueListenableBuilder<bool>(
                    valueListenable:
                    _isHoveringNotifier,
                    builder: (
                        context,
                        hovering,
                        child,
                        ) {
                      final double size =
                      hovering ? 90 : 24;

                      return Positioned(
                        left:
                        cursorPosition.dx -
                            size / 2,
                        top:
                        cursorPosition.dy -
                            size / 2,
                        child: IgnorePointer(
                          child: AnimatedContainer(
                            duration:
                            const Duration(
                              milliseconds: 120,
                            ),
                            curve:
                            Curves.easeOutCubic,
                            width: size,
                            height: size,
                            decoration:
                            BoxDecoration(
                              shape:
                              BoxShape.circle,
                              color: hovering
                                  ? AppTheme
                                  .brandRed
                                  .withOpacity(
                                0.9,
                              )
                                  : Colors.transparent,
                              border: Border.all(
                                color: hovering
                                    ? Colors.transparent
                                    : Colors.white
                                    .withOpacity(
                                  0.6,
                                ),
                                width: 1.5,
                              ),
                            ),
                            child: hovering &&
                                _cursorText
                                    .isNotEmpty
                                ? Center(
                              child: Text(
                                _cursorText,
                                textAlign:
                                TextAlign
                                    .center,
                                style: GoogleFonts
                                    .plusJakartaSans(
                                  fontWeight:
                                  FontWeight
                                      .bold,
                                  fontSize: 10,
                                  color:
                                  Colors.white,
                                  letterSpacing:
                                  0.8,
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

// ============================================================================
// SECTION LABEL
// ============================================================================

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppTheme.brandRed,
        letterSpacing: 2.5,
      ),
    );
  }
}

// ============================================================================
// LOADING
// ============================================================================

class _PortfolioLoading extends StatelessWidget {
  const _PortfolioLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 45,
            height: 45,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.brandRed,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'LOADING WORK',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ERROR
// ============================================================================

class _PortfolioError extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _PortfolioError({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 55,
              color: AppTheme.brandRed,
            ),
            const SizedBox(height: 20),
            Text(
              'COULD NOT LOAD PORTFOLIO',
              textAlign: TextAlign.center,
              style:
              GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style:
              GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                AppTheme.brandRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('RETRY'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// EMPTY
// ============================================================================

class _PortfolioEmpty extends StatelessWidget {
  const _PortfolioEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'NO PROJECTS AVAILABLE',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white54,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

// ============================================================================
// CINEMATIC HERO
// ============================================================================

class _CinematicPortfolioHero extends StatelessWidget {
  final int totalProjects;
  final double scrollOffset;

  const _CinematicPortfolioHero({
    required this.totalProjects,
    required this.scrollOffset,
  });

  @override
  Widget build(BuildContext context) {
    final width =
        MediaQuery.of(context).size.width;

    final mobile = width < 768;

    final parallax =
    (scrollOffset * 0.12).clamp(0, 80);

    return SizedBox(
      height: mobile ? 520 : 650,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _PortfolioGlowPainter(
                progress:
                scrollOffset / 1000,
              ),
            ),
          ),

          Positioned(
            top: 80.0 - parallax.toDouble(),
            left: mobile ? 20 : 60,
            right: mobile ? 20 : 60,
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'THEVAH / PORTFOLIO',
                  style:
                  GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight:
                    FontWeight.bold,
                    color:
                    AppTheme.brandRed,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'WE BUILD\nDIGITAL\nEXPERIENCES.',
                  style:
                  GoogleFonts.plusJakartaSans(
                    fontSize:
                    mobile ? 54 : 96,
                    height: 0.92,
                    fontWeight:
                    FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -4,
                  ),
                ),
                const SizedBox(height: 30),
                ConstrainedBox(
                  constraints:
                  const BoxConstraints(
                    maxWidth: 600,
                  ),
                  child: Text(
                    'A selection of websites, applications, identities, videos and digital experiences created by Thevah.',
                    style: GoogleFonts
                        .plusJakartaSans(
                      fontSize:
                      mobile ? 14 : 16,
                      height: 1.7,
                      color:
                      Colors.white54,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 35,
            left: mobile ? 20 : 60,
            right: mobile ? 20 : 60,
            child: Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$totalProjects PROJECTS',
                  style: GoogleFonts
                      .plusJakartaSans(
                    fontSize: 10,
                    fontWeight:
                    FontWeight.bold,
                    color: Colors.white38,
                    letterSpacing: 2,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 45,
                      height: 1,
                      color: Colors.white24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'SCROLL TO EXPLORE',
                      style: GoogleFonts
                          .plusJakartaSans(
                        fontSize: 9,
                        fontWeight:
                        FontWeight.bold,
                        color:
                        Colors.white38,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
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
// GLOW PAINTER
// ============================================================================

class _PortfolioGlowPainter
    extends CustomPainter {
  final double progress;

  _PortfolioGlowPainter({
    required this.progress,
  });

  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    final center = Offset(
      size.width * 0.78,
      size.height * 0.38,
    );

    final radius =
        size.width * 0.30;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.brandRed.withOpacity(
            0.25,
          ),
          AppTheme.brandRed.withOpacity(
            0.08,
          ),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
      );

    canvas.drawCircle(
      center,
      radius,
      paint,
    );
  }

  @override
  bool shouldRepaint(
      covariant _PortfolioGlowPainter oldDelegate,
      ) {
    return oldDelegate.progress != progress;
  }
}

// ============================================================================
// FEATURED CARD
// ============================================================================

class _FeaturedProjectHeroCard
    extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final Function(bool, String)
  onHoverChange;

  const _FeaturedProjectHeroCard({
    required this.item,
    required this.onTap,
    required this.onHoverChange,
  });

  @override
  State<_FeaturedProjectHeroCard>
  createState() =>
      _FeaturedProjectHeroCardState();
}

class _FeaturedProjectHeroCardState
    extends State<_FeaturedProjectHeroCard> {
  bool hovering = false;

  String _string(
      String key,
      ) {
    return widget.item[key]?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final title =
    _string('title').isEmpty
        ? _string('name')
        : _string('title');

    final image =
    _string('thumbnailUrl').isNotEmpty
        ? _string('thumbnailUrl')
        : _string('imageUrl');

    final category =
    _string('category').toUpperCase();

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          hovering = true;
        });

        widget.onHoverChange(
          true,
          'VIEW',
        );
      },
      onExit: (_) {
        setState(() {
          hovering = false;
        });

        widget.onHoverChange(
          false,
          '',
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration:
          const Duration(
            milliseconds: 400,
          ),
          curve:
          Curves.easeOutCubic,
          height:
          MediaQuery.of(context)
              .size
              .width <
              768
              ? 430
              : 560,
          decoration:
          BoxDecoration(
            borderRadius:
            BorderRadius.circular(
              24,
            ),
            border: Border.all(
              color: hovering
                  ? AppTheme.brandRed
                  : Colors.white10,
            ),
          ),
          child: ClipRRect(
            borderRadius:
            BorderRadius.circular(
              24,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _PortfolioMedia(
                  url: image,
                  fit: BoxFit.cover,
                ),

                Container(
                  decoration:
                  BoxDecoration(
                    gradient:
                    LinearGradient(
                      begin:
                      Alignment.topCenter,
                      end:
                      Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black
                            .withOpacity(
                          0.85,
                        ),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  left: 28,
                  right: 28,
                  bottom: 28,
                  child: Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          children: [
                            Text(
                              category,
                              style: GoogleFonts
                                  .plusJakartaSans(
                                fontSize: 10,
                                fontWeight:
                                FontWeight.bold,
                                color:
                                AppTheme
                                    .brandRed,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Text(
                              title.isEmpty
                                  ? 'PROJECT'
                                  : title,
                              style: GoogleFonts
                                  .plusJakartaSans(
                                fontSize: 32,
                                fontWeight:
                                FontWeight
                                    .w700,
                                color:
                                Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration:
                        const Duration(
                          milliseconds: 300,
                        ),
                        width:
                        hovering ? 64 : 52,
                        height:
                        hovering ? 64 : 52,
                        decoration:
                        BoxDecoration(
                          shape:
                          BoxShape.circle,
                          color:
                          AppTheme.brandRed,
                        ),
                        child: const Icon(
                          Icons.arrow_outward,
                          color:
                          Colors.white,
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
  }
}

// ============================================================================
// HORIZONTAL REEL
// ============================================================================

class _HorizontalProjectReel
    extends StatelessWidget {
  final double scrollOffset;
  final List<Map<String, dynamic>> items;
  final Function(Map<String, dynamic>)
  onTapItem;
  final Function(bool, String)
  onHoverItem;

  const _HorizontalProjectReel({
    required this.scrollOffset,
    required this.items,
    required this.onTapItem,
    required this.onHoverItem,
  });

  @override
  Widget build(BuildContext context) {
    final width =
        MediaQuery.of(context).size.width;

    final mobile = width < 768;

    final visibleItems =
    items.take(8).toList();

    return SizedBox(
      height: mobile ? 300 : 400,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics:
        const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: mobile ? 16 : 48,
        ),
        itemCount:
        visibleItems.length,
        itemBuilder: (
            context,
            index,
            ) {
          final item =
          visibleItems[index];

          final title =
              item['title']?.toString() ??
                  item['name']?.toString() ??
                  'PROJECT';

          final image =
              item['thumbnailUrl']
                  ?.toString() ??
                  item['imageUrl']
                      ?.toString() ??
                  '';

          return Padding(
            padding:
            const EdgeInsets.only(
              right: 20,
            ),
            child: _ReelCard(
              title: title,
              image: image,
              category:
              item['category']
                  ?.toString() ??
                  '',
              onTap: () {
                onTapItem(item);
              },
              onHover: (
                  hovering,
                  ) {
                onHoverItem(
                  hovering,
                  'VIEW',
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ReelCard
    extends StatefulWidget {
  final String title;
  final String image;
  final String category;
  final VoidCallback onTap;
  final Function(bool) onHover;

  const _ReelCard({
    required this.title,
    required this.image,
    required this.category,
    required this.onTap,
    required this.onHover,
  });

  @override
  State<_ReelCard> createState() =>
      _ReelCardState();
}

class _ReelCardState
    extends State<_ReelCard> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          hovering = true;
        });

        widget.onHover(true);
      },
      onExit: (_) {
        setState(() {
          hovering = false;
        });

        widget.onHover(false);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration:
          const Duration(
            milliseconds: 300,
          ),
          width:
          MediaQuery.of(context)
              .size
              .width <
              768
              ? 250
              : 360,
          transform:
          Matrix4.identity()
            ..translate(
              0.0,
              hovering ? -8.0 : 0.0,
            ),
          decoration:
          BoxDecoration(
            borderRadius:
            BorderRadius.circular(
              20,
            ),
            border: Border.all(
              color: hovering
                  ? AppTheme.brandRed
                  : Colors.white10,
            ),
          ),
          child: ClipRRect(
            borderRadius:
            BorderRadius.circular(
              20,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _PortfolioMedia(
                  url: widget.image,
                  fit: BoxFit.cover,
                ),
                Container(
                  decoration:
                  BoxDecoration(
                    gradient:
                    LinearGradient(
                      begin:
                      Alignment.topCenter,
                      end:
                      Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black
                            .withOpacity(
                          0.85,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  bottom: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      Text(
                        widget.category
                            .toUpperCase(),
                        style: GoogleFonts
                            .plusJakartaSans(
                          fontSize: 9,
                          fontWeight:
                          FontWeight.bold,
                          color:
                          AppTheme
                              .brandRed,
                          letterSpacing:
                          2,
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        widget.title,
                        maxLines: 2,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style: GoogleFonts
                            .plusJakartaSans(
                          fontSize: 20,
                          fontWeight:
                          FontWeight.w700,
                          color:
                          Colors.white,
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
  }
}

// ============================================================================
// GRID CARD
// ============================================================================

class _EditorialGridCard
    extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final Function(bool, String)
  onHoverChange;

  const _EditorialGridCard({
    required this.item,
    required this.onTap,
    required this.onHoverChange,
  });

  @override
  State<_EditorialGridCard>
  createState() =>
      _EditorialGridCardState();
}

class _EditorialGridCardState
    extends State<_EditorialGridCard> {
  bool hovering = false;

  String _getString(
      String key,
      ) {
    return widget.item[key]?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final title =
    _getString('title').isNotEmpty
        ? _getString('title')
        : _getString('name');

    final image =
    _getString('thumbnailUrl')
        .isNotEmpty
        ? _getString('thumbnailUrl')
        : _getString('imageUrl');

    final category =
    _getString('category');

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          hovering = true;
        });

        widget.onHoverChange(
          true,
          'OPEN',
        );
      },
      onExit: (_) {
        setState(() {
          hovering = false;
        });

        widget.onHoverChange(
          false,
          '',
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration:
          const Duration(
            milliseconds: 350,
          ),
          transform:
          Matrix4.identity()
            ..translate(
              0.0,
              hovering ? -6.0 : 0.0,
            ),
          decoration:
          BoxDecoration(
            color:
            AppTheme.darkCard,
            borderRadius:
            BorderRadius.circular(
              20,
            ),
            border: Border.all(
              color: hovering
                  ? AppTheme.brandRed
                  : AppTheme.greyBorder,
            ),
          ),
          child: ClipRRect(
            borderRadius:
            BorderRadius.circular(
              20,
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _PortfolioMedia(
                        url: image,
                        fit:
                        BoxFit.cover,
                      ),
                      if (hovering)
                        Container(
                          color: AppTheme
                              .brandRed
                              .withOpacity(
                            0.10,
                          ),
                        ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child:
                        AnimatedContainer(
                          duration:
                          const Duration(
                            milliseconds:
                            250,
                          ),
                          width:
                          hovering
                              ? 48
                              : 40,
                          height:
                          hovering
                              ? 48
                              : 40,
                          decoration:
                          BoxDecoration(
                            shape:
                            BoxShape.circle,
                            color: AppTheme
                                .brandRed,
                          ),
                          child:
                          const Icon(
                            Icons
                                .arrow_outward,
                            size: 18,
                            color:
                            Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                  const EdgeInsets.all(
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      Text(
                        category
                            .toUpperCase(),
                        style: GoogleFonts
                            .plusJakartaSans(
                          fontSize: 9,
                          fontWeight:
                          FontWeight.bold,
                          color:
                          AppTheme
                              .brandRed,
                          letterSpacing:
                          2,
                        ),
                      ),
                      const SizedBox(
                        height: 7,
                      ),
                      Text(
                        title.isEmpty
                            ? 'PROJECT'
                            : title,
                        maxLines: 1,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style: GoogleFonts
                            .plusJakartaSans(
                          fontSize: 19,
                          fontWeight:
                          FontWeight.w700,
                          color:
                          Colors.white,
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
  }
}

// ============================================================================
// PORTFOLIO MEDIA
// ============================================================================

class _PortfolioMedia
    extends StatelessWidget {
  final String url;
  final BoxFit fit;

  const _PortfolioMedia({
    required this.url,
    required this.fit,
  });

  bool get _isImage {
    final lower =
    url.toLowerCase();

    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.contains('image');
  }

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        color: AppTheme.darkCard,
        child: Center(
          child: Icon(
            Icons.image_outlined,
            size: 50,
            color: Colors.white24,
          ),
        ),
      );
    }

    if (!_isImage) {
      return Container(
        color: AppTheme.darkCard,
        child: Stack(
          alignment:
          Alignment.center,
          children: [
            const Icon(
              Icons.play_circle_outline,
              size: 70,
              color: Colors.white54,
            ),
            Positioned(
              bottom: 18,
              left: 18,
              right: 18,
              child: Text(
                'VIDEO',
                textAlign:
                TextAlign.center,
                style: GoogleFonts
                    .plusJakartaSans(
                  fontSize: 9,
                  fontWeight:
                  FontWeight.bold,
                  color:
                  Colors.white38,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Image.network(
      url,
      fit: fit,
      errorBuilder: (
          context,
          error,
          stackTrace,
          ) {
        return Container(
          color:
          AppTheme.darkCard,
          child: const Center(
            child: Icon(
              Icons.broken_image_outlined,
              color:
              Colors.white30,
              size: 45,
            ),
          ),
        );
      },
      loadingBuilder: (
          context,
          child,
          progress,
          ) {
        if (progress == null) {
          return child;
        }

        return Container(
          color:
          AppTheme.darkCard,
          child: Center(
            child:
            CircularProgressIndicator(
              strokeWidth: 2,
              color:
              AppTheme.brandRed,
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// CLIENT LOGO
// ============================================================================

class _ClientLogo
    extends StatelessWidget {
  final String name;

  const _ClientLogo({
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Colors.white24,
        letterSpacing: 1.5,
      ),
    );
  }
}

// ============================================================================
// FINAL CTA
// ============================================================================

class _PortfolioFinalCta
    extends StatefulWidget {
  final Function(bool, String)
  onHoverItem;

  const _PortfolioFinalCta({
    required this.onHoverItem,
  });

  @override
  State<_PortfolioFinalCta>
  createState() =>
      _PortfolioFinalCtaState();
}

class _PortfolioFinalCtaState
    extends State<_PortfolioFinalCta> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    final mobile =
        MediaQuery.of(context)
            .size
            .width <
            768;

    return Padding(
      padding:
      EdgeInsets.symmetric(
        horizontal:
        mobile ? 16 : 48,
      ),
      child: MouseRegion(
        onEnter: (_) {
          setState(() {
            hovering = true;
          });

          widget.onHoverItem(
            true,
            'START',
          );
        },
        onExit: (_) {
          setState(() {
            hovering = false;
          });

          widget.onHoverItem(
            false,
            '',
          );
        },
        child: GestureDetector(
          onTap: () {
            // Add your contact navigation here.
          },
          child: AnimatedContainer(
            duration:
            const Duration(
              milliseconds: 400,
            ),
            padding:
            EdgeInsets.symmetric(
              horizontal:
              mobile ? 24 : 60,
              vertical:
              mobile ? 50 : 80,
            ),
            decoration:
            BoxDecoration(
              borderRadius:
              BorderRadius.circular(
                28,
              ),
              color: hovering
                  ? AppTheme.brandRed
                  : AppTheme.darkCard,
              border: Border.all(
                color: hovering
                    ? AppTheme.brandRed
                    : AppTheme.greyBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'HAVE AN IDEA?',
                  style: GoogleFonts
                      .plusJakartaSans(
                    fontSize: 11,
                    fontWeight:
                    FontWeight.bold,
                    color: hovering
                        ? Colors.white70
                        : AppTheme.brandRed,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'LET’S MAKE\nIT REAL.',
                  style: GoogleFonts
                      .plusJakartaSans(
                    fontSize:
                    mobile ? 48 : 80,
                    height: 0.9,
                    fontWeight:
                    FontWeight.w800,
                    color:
                    Colors.white,
                    letterSpacing: -3,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Text(
                      'START A PROJECT',
                      style: GoogleFonts
                          .plusJakartaSans(
                        fontSize: 11,
                        fontWeight:
                        FontWeight.bold,
                        color:
                        Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Icon(
                      Icons
                          .arrow_forward,
                      color:
                      Colors.white,
                      size: 20,
                    ),
                  ],
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
// DETAILS PAGE
// ============================================================================

class AppDetailsPage
    extends StatelessWidget {
  final Map<String, dynamic> item;

  const AppDetailsPage({
    super.key,
    required this.item,
  });

  String _value(
      String key,
      ) {
    return item[key]?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final title =
    _value('title').isNotEmpty
        ? _value('title')
        : _value('name');

    final description =
    _value('description');

    final category =
    _value('category')
        .toUpperCase();

    final image =
    _value('thumbnailUrl')
        .isNotEmpty
        ? _value('thumbnailUrl')
        : _value('imageUrl');

    final video =
    _value('videoUrl').isNotEmpty
        ? _value('videoUrl')
        : _value('fileUrl');

    return Scaffold(
      backgroundColor:
      AppTheme.darkBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor:
            AppTheme.darkBackground,
            elevation: 0,
            pinned: true,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
            ),
            title: Text(
              'PROJECT',
              style: GoogleFonts
                  .plusJakartaSans(
                fontSize: 11,
                fontWeight:
                FontWeight.bold,
                letterSpacing: 2,
                color:
                Colors.white54,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding:
              const EdgeInsets.fromLTRB(
                20,
                50,
                20,
                100,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  Text(
                    category,
                    style: GoogleFonts
                        .plusJakartaSans(
                      fontSize: 11,
                      fontWeight:
                      FontWeight.bold,
                      color:
                      AppTheme.brandRed,
                      letterSpacing:
                      2.5,
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  Text(
                    title.isEmpty
                        ? 'PROJECT'
                        : title,
                    style: GoogleFonts
                        .plusJakartaSans(
                      fontSize:
                      MediaQuery.of(
                        context,
                      )
                          .size
                          .width <
                          768
                          ? 48
                          : 90,
                      height: 0.95,
                      fontWeight:
                      FontWeight.w800,
                      color:
                      Colors.white,
                      letterSpacing: -3,
                    ),
                  ),

                  const SizedBox(
                    height: 35,
                  ),

                  if (description
                      .isNotEmpty)
                    ConstrainedBox(
                      constraints:
                      const BoxConstraints(
                        maxWidth: 750,
                      ),
                      child: Text(
                        description,
                        style: GoogleFonts
                            .plusJakartaSans(
                          fontSize: 16,
                          height: 1.8,
                          color:
                          Colors.white54,
                        ),
                      ),
                    ),

                  const SizedBox(
                    height: 50,
                  ),

                  if (image.isNotEmpty)
                    ClipRRect(
                      borderRadius:
                      BorderRadius.circular(
                        25,
                      ),
                      child:
                      _PortfolioMedia(
                        url: image,
                        fit: BoxFit.cover,
                      ),
                    ),

                  if (video.isNotEmpty) ...[
                    const SizedBox(
                      height: 30,
                    ),
                    Container(
                      padding:
                      const EdgeInsets.all(
                        20,
                      ),
                      decoration:
                      BoxDecoration(
                        color:
                        AppTheme.darkCard,
                        borderRadius:
                        BorderRadius
                            .circular(
                          20,
                        ),
                        border:
                        Border.all(
                          color:
                          Colors.white10,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .play_circle_outline,
                            color:
                            AppTheme
                                .brandRed,
                            size: 35,
                          ),
                          const SizedBox(
                            width: 15,
                          ),
                          Expanded(
                            child: Text(
                              'PROJECT VIDEO AVAILABLE',
                              style: GoogleFonts
                                  .plusJakartaSans(
                                fontSize: 12,
                                fontWeight:
                                FontWeight
                                    .bold,
                                color:
                                Colors
                                    .white,
                                letterSpacing:
                                1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(
                    height: 60,
                  ),

                  _DetailsInfoRow(
                    label: 'CATEGORY',
                    value:
                    category.isEmpty
                        ? '—'
                        : category,
                  ),

                  _DetailsInfoRow(
                    label: 'PROJECT',
                    value:
                    title.isEmpty
                        ? '—'
                        : title,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsInfoRow
    extends StatelessWidget {
  final String label;
  final String value;

  const _DetailsInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        vertical: 20,
      ),
      decoration:
      const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white10,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts
                  .plusJakartaSans(
                fontSize: 10,
                fontWeight:
                FontWeight.bold,
                color:
                Colors.white38,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts
                  .plusJakartaSans(
                fontSize: 13,
                fontWeight:
                FontWeight.w600,
                color:
                Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
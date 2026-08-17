import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import 'portfolio_service.dart';
import 'shared_widgets.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  // ============================================================
  // CONTROLLERS & NOTIFIERS
  // ============================================================
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<Offset> _cursorPosNotifier = ValueNotifier<Offset>(Offset.zero);
  final ValueNotifier<bool> _isHoveringNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<double> _scrollOffsetNotifier = ValueNotifier<double>(0);

  // ============================================================
  // SERVICE & STATE
  // ============================================================
  final PortfolioService _portfolioService = PortfolioService();

  String _selectedCategory = 'ALL';
  String _cursorText = '';
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _allPortfolioItems = [];

  // ============================================================
  // LAZY LOADING
  // ============================================================
  int _visibleProjectCount = 5;
  bool _isLoadingMore = false;
  bool _hasMoreProjects = true;

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
        _visibleProjectCount = items.length > 5 ? 5 : items.length;
        _hasMoreProjects = items.length > 5;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error.toString();
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    _scrollOffsetNotifier.value = offset;

    final maxExtent = _scrollController.position.maxScrollExtent;
    if (offset >= maxExtent - 500) {
      _loadMoreProjects();
    }
  }

  Future<void> _loadMoreProjects() async {
    if (_isLoadingMore || !_hasMoreProjects) return;

    final total = _getFilteredAllItems().length;
    if (_visibleProjectCount >= total) {
      if (mounted) setState(() => _hasMoreProjects = false);
      return;
    }

    if (mounted) setState(() => _isLoadingMore = true);

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    setState(() {
      _visibleProjectCount += 5;
      if (_visibleProjectCount >= total) {
        _visibleProjectCount = total;
        _hasMoreProjects = false;
      }
      _isLoadingMore = false;
    });
  }

  List<Map<String, dynamic>> _getFilteredAllItems() {
    if (_selectedCategory == 'ALL') {
      return List<Map<String, dynamic>>.from(_allPortfolioItems);
    }
    return _allPortfolioItems.where((item) {
      final category = item['category']?.toString().toUpperCase() ?? '';
      return category == _selectedCategory;
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredItems {
    final filtered = _getFilteredAllItems();
    final count = _visibleProjectCount.clamp(0, filtered.length);
    return filtered.take(count).toList();
  }

  Map<String, dynamic>? get _featuredItem {
    if (_allPortfolioItems.isEmpty) return null;
    for (final item in _allPortfolioItems) {
      if (item['isFeatured'] == true || item['isDataFeatured'] == true) {
        return item;
      }
    }
    return _allPortfolioItems.first;
  }

  void _updateCursor({required bool hovering, String text = ''}) {
    _isHoveringNotifier.value = hovering;
    if (mounted) {
      setState(() => _cursorText = text);
    }
  }

  void _openDetailsPage(Map<String, dynamic> item) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AppDetailsPage(item: item),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
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
    final double horizontalPadding = isMobile ? 20 : 64;

    return MouseRegion(
      cursor: isMobile ? MouseCursor.defer : SystemMouseCursors.none,
      onHover: (event) => _cursorPosNotifier.value = event.position,
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Stack(
          children: [
            // Ambient Radial Gradient
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.85, -0.65),
                      radius: 1.3,
                      colors: [
                        AppTheme.brandRed.withOpacity(0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: TevahNavbar(
                    currentRoute: NavRoute.portfolio,
                    onHoverItem: (hovering) => _updateCursor(hovering: hovering),
                  ),
                ),
                if (_isLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _PortfolioLoading(),
                  )
                else if (_error != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _PortfolioError(error: _error!, onRetry: _loadPortfolio),
                  )
                else if (_allPortfolioItems.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _PortfolioEmpty(),
                    )
                  else ...[
                      // HERO SECTION
                      SliverToBoxAdapter(
                        child: ValueListenableBuilder<double>(
                          valueListenable: _scrollOffsetNotifier,
                          builder: (context, scrollOffset, child) {
                            return _CinematicPortfolioHero(
                              totalProjects: _allPortfolioItems.length,
                              scrollOffset: scrollOffset,
                            );
                          },
                        ),
                      ),

                      SliverToBoxAdapter(child: SizedBox(height: isMobile ? 32 : 56)),

                      // CATEGORIES
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: _categories.map((category) {
                                final selected = _selectedCategory == category;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: selected
                                          ? [
                                        BoxShadow(
                                          color: AppTheme.brandRed.withOpacity(0.4),
                                          blurRadius: 18,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                          : [],
                                    ),
                                    child: ChoiceChip(
                                      label: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        child: Text(category),
                                      ),
                                      selected: selected,
                                      onSelected: (value) {
                                        if (!value) return;
                                        setState(() {
                                          _selectedCategory = category;
                                          _visibleProjectCount = 5;
                                          _isLoadingMore = false;
                                          _hasMoreProjects = true;
                                        });
                                      },
                                      selectedColor: AppTheme.brandRed,
                                      backgroundColor: AppTheme.darkCard.withOpacity(0.8),
                                      labelStyle: GoogleFonts.plusJakartaSans(
                                        fontSize: isMobile ? 11 : 12,
                                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                        letterSpacing: 0.8,
                                        color: selected ? Colors.white : Colors.white70,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                        side: BorderSide(
                                          color: selected
                                              ? AppTheme.brandRed
                                              : Colors.white.withOpacity(0.08),
                                          width: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(child: SizedBox(height: isMobile ? 48 : 80)),

                      // FEATURED SPOTLIGHT
                      if (_selectedCategory == 'ALL' && _featuredItem != null) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _SectionLabel(text: '01 // FEATURED SPOTLIGHT'),
                                const SizedBox(height: 22),
                                _FeaturedProjectHeroCard(
                                  item: _featuredItem!,
                                  onTap: () => _openDetailsPage(_featuredItem!),
                                  onHoverChange: (hovering, text) =>
                                      _updateCursor(hovering: hovering, text: text),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(child: SizedBox(height: isMobile ? 64 : 100)),
                      ],

                      // REEL SECTION
                      if (_selectedCategory == 'ALL') ...[
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                                child: const _SectionLabel(text: '02 // SELECTED REEL'),
                              ),
                              const SizedBox(height: 24),
                              _HorizontalProjectReel(
                                items: _allPortfolioItems,
                                onTapItem: (item) => _openDetailsPage(item),
                                onHoverItem: (hovering, text) =>
                                    _updateCursor(hovering: hovering, text: text),
                              ),
                            ],
                          ),
                        ),
                        SliverToBoxAdapter(child: SizedBox(height: isMobile ? 64 : 100)),
                      ],

                      // ARCHIVE MATRIX
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                          child: _SectionLabel(
                            text: _selectedCategory == 'ALL'
                                ? '03 // ARCHIVE MATRIX'
                                : 'ARCHIVE // $_selectedCategory',
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 28)),

                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                        sliver: SliverGrid(
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 640,
                            mainAxisSpacing: isMobile ? 22 : 32,
                            crossAxisSpacing: isMobile ? 18 : 32,
                            childAspectRatio: isMobile ? 1.02 : 1.32,
                          ),
                          delegate: SliverChildBuilderDelegate(
                                (context, index) {
                              final item = _filteredItems[index];
                              return _EditorialGridCard(
                                item: item,
                                onTap: () => _openDetailsPage(item),
                                onHoverChange: (hovering, text) =>
                                    _updateCursor(hovering: hovering, text: text),
                              )
                                  .animate()
                                  .fadeIn(duration: 350.ms)
                                  .slideY(begin: 0.06, end: 0, duration: 400.ms);
                            },
                            childCount: _filteredItems.length,
                          ),
                        ),
                      ),

                      // SKELETON
                      if (_isLoadingMore)
                        SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 32),
                          sliver: SliverGrid(
                            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 640,
                              mainAxisSpacing: isMobile ? 22 : 32,
                              crossAxisSpacing: isMobile ? 18 : 32,
                              childAspectRatio: isMobile ? 1.02 : 1.32,
                            ),
                            delegate: SliverChildBuilderDelegate(
                                  (context, index) => const _PortfolioSkeletonCard(),
                              childCount: 4,
                            ),
                          ),
                        ),

                      if (!_hasMoreProjects && _filteredItems.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 48),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.03),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                                ),
                                child: Text(
                                  '✦ ALL PROJECTS LOADED ✦',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white30,
                                    letterSpacing: 2.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      SliverToBoxAdapter(child: SizedBox(height: isMobile ? 80 : 130)),

                      // PARTNERS
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
                                  const SizedBox(width: 10),
                                  Text(
                                    'TRUSTED BY GLOBAL INNOVATORS',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white38,
                                      letterSpacing: 2.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 30),
                              Wrap(
                                spacing: isMobile ? 24 : 48,
                                runSpacing: isMobile ? 20 : 28,
                                children: const [
                                  _ClientLogo(name: 'FINTECH LABS'),
                                  _ClientLogo(name: 'LOGIX GLOBAL'),
                                  _ClientLogo(name: 'NEXUS AI'),
                                  _ClientLogo(name: 'AURA VISUALS'),
                                  _ClientLogo(name: 'HEALTHCARE DIGITAL'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(child: SizedBox(height: isMobile ? 80 : 130)),

                      // CTA
                      SliverToBoxAdapter(
                        child: _PortfolioFinalCta(
                          onHoverItem: (hovering, text) =>
                              _updateCursor(hovering: hovering, text: text),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      const SliverToBoxAdapter(child: AgencyFooter()),
                      const SliverToBoxAdapter(child: SizedBox(height: 30)),
                    ],
              ],
            ),

            const FloatingWhatsAppButton(),

            // CURSOR
            if (!isMobile)
              ValueListenableBuilder<Offset>(
                valueListenable: _cursorPosNotifier,
                builder: (context, cursorPosition, child) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: _isHoveringNotifier,
                    builder: (context, hovering, child) {
                      final size = hovering ? 86.0 : 20.0;
                      return Positioned(
                        left: cursorPosition.dx - size / 2,
                        top: cursorPosition.dy - size / 2,
                        child: IgnorePointer(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            curve: Curves.easeOutCubic,
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hovering
                                  ? AppTheme.brandRed.withOpacity(0.92)
                                  : Colors.transparent,
                              border: Border.all(
                                color: hovering
                                    ? Colors.transparent
                                    : Colors.white.withOpacity(0.65),
                                width: 1.5,
                              ),
                              boxShadow: hovering
                                  ? [
                                BoxShadow(
                                  color: AppTheme.brandRed.withOpacity(0.5),
                                  blurRadius: 24,
                                  spreadRadius: 2,
                                ),
                              ]
                                  : [],
                            ),
                            child: hovering && _cursorText.isNotEmpty
                                ? Center(
                              child: Text(
                                _cursorText,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
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

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 4,
          height: 14,
          decoration: BoxDecoration(
            color: AppTheme.brandRed,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.brandRed,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// LOADING & ERROR & EMPTY STATES
// ============================================================================
class _PortfolioLoading extends StatelessWidget {
  const _PortfolioLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.brandRed.withOpacity(0.1),
              border: Border.all(color: AppTheme.brandRed.withOpacity(0.3)),
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppTheme.brandRed,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'CURATING THEVAH ARCHIVE...',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
}

class _PortfolioError extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _PortfolioError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.brandRed.withOpacity(0.12),
              ),
              child: const Icon(Icons.cloud_off_rounded, size: 40, color: AppTheme.brandRed),
            ),
            const SizedBox(height: 20),
            Text(
              'COULD NOT LOAD PORTFOLIO',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              error,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.5, color: Colors.white54),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 8,
                shadowColor: AppTheme.brandRed.withOpacity(0.4),
              ),
              child: Text(
                'TRY AGAIN',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortfolioEmpty extends StatelessWidget {
  const _PortfolioEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'NO PROJECTS AVAILABLE',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white54,
              letterSpacing: 2,
            ),
          ),
        ],
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
    final width = MediaQuery.of(context).size.width;
    final mobile = width < 768;
    final parallax = (scrollOffset * 0.12).clamp(0, 80);

    return SizedBox(
      height: mobile ? 480 : 590,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _PortfolioGlowPainter(progress: scrollOffset / 1000),
            ),
          ),
          Positioned(
            top: 70.0 - parallax.toDouble(),
            left: mobile ? 20 : 64,
            right: mobile ? 20 : 64,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.brandRed.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.brandRed.withOpacity(0.3)),
                  ),
                  child: Text(
                    'THEVAH // PORTFOLIO',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.brandRed,
                      letterSpacing: 2.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'WE BUILD\nDIGITAL\nEXPERIENCES.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: mobile ? 46 : 84,
                    height: 0.94,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -3.5,
                  ),
                ),
                const SizedBox(height: 24),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: Text(
                    'A curated showcase of high-performance web systems, bespoke mobile architectures, and immersive brand designs.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: mobile ? 14 : 16,
                      height: 1.7,
                      color: Colors.white60,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 25,
            left: mobile ? 20 : 64,
            right: mobile ? 20 : 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      '$totalProjects WORKS ARCHIVED',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white54,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                if (!mobile)
                  Row(
                    children: [
                      Container(width: 45, height: 1, color: Colors.white24),
                      const SizedBox(width: 14),
                      Text(
                        'EXPLORE ARCHIVE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white38,
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

class _PortfolioGlowPainter extends CustomPainter {
  final double progress;

  _PortfolioGlowPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.82, size.height * 0.35);
    final radius = size.width * 0.35;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.brandRed.withOpacity(0.20),
          AppTheme.brandRed.withOpacity(0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _PortfolioGlowPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ============================================================================
// FEATURED HERO CARD
// ============================================================================
class _FeaturedProjectHeroCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final Function(bool, String) onHoverChange;

  const _FeaturedProjectHeroCard({
    required this.item,
    required this.onTap,
    required this.onHoverChange,
  });

  @override
  State<_FeaturedProjectHeroCard> createState() => _FeaturedProjectHeroCardState();
}

class _FeaturedProjectHeroCardState extends State<_FeaturedProjectHeroCard> {
  bool hovering = false;

  String _string(String key) => widget.item[key]?.toString() ?? '';

  @override
  Widget build(BuildContext context) {
    final title = _string('title').isNotEmpty ? _string('title') : _string('name');
    final mediaUrl = _getMediaUrl(widget.item);
    final category = _string('category').toUpperCase();
    final screenWidth = MediaQuery.of(context).size.width;
    final height = screenWidth < 768 ? 260.0 : 440.0;

    return MouseRegion(
      onEnter: (_) {
        setState(() => hovering = true);
        widget.onHoverChange(true, 'EXPLORE');
      },
      onExit: (_) {
        setState(() => hovering = false);
        widget.onHoverChange(false, '');
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          height: height,
          transform: Matrix4.identity()..translate(0.0, hovering ? -6.0 : 0.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: hovering ? AppTheme.brandRed.withOpacity(0.8) : Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: hovering
                    ? AppTheme.brandRed.withOpacity(0.22)
                    : Colors.black.withOpacity(0.6),
                blurRadius: hovering ? 36 : 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _PortfolioMedia(
                  url: mediaUrl,
                  fit: BoxFit.cover,
                  autoplay: true,
                  muted: true,
                  loop: true,
                  showControls: false,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.15),
                        Colors.black.withOpacity(0.4),
                        Colors.black.withOpacity(0.92),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: 28,
                  right: 28,
                  bottom: 28,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.brandRed.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.brandRed.withOpacity(0.4)),
                              ),
                              child: Text(
                                category.isEmpty ? 'FEATURED' : category,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.brandRed,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              title.isEmpty ? 'PROJECT' : title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: screenWidth < 768 ? 24 : 34,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: hovering ? 56 : 48,
                        height: hovering ? 56 : 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.brandRed,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.brandRed.withOpacity(0.5),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_outward_rounded,
                          color: Colors.white,
                          size: 22,
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
class _HorizontalProjectReel extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Function(Map<String, dynamic>) onTapItem;
  final Function(bool, String) onHoverItem;

  const _HorizontalProjectReel({
    required this.items,
    required this.onTapItem,
    required this.onHoverItem,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final mobile = width < 768;
    final visibleItems = items.take(8).toList();

    return SizedBox(
      height: mobile ? 240 : 320,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: mobile ? 18 : 64),
        itemCount: visibleItems.length,
        itemBuilder: (context, index) {
          final item = visibleItems[index];
          final title = item['title']?.toString() ?? item['name']?.toString() ?? 'PROJECT';
          final media = _getMediaUrl(item);

          return Padding(
            padding: const EdgeInsets.only(right: 20),
            child: _ReelCard(
              title: title,
              media: media,
              category: item['category']?.toString() ?? '',
              onTap: () => onTapItem(item),
              onHover: (hovering) => onHoverItem(hovering, 'VIEW'),
            ),
          );
        },
      ),
    );
  }
}

class _ReelCard extends StatefulWidget {
  final String title;
  final String media;
  final String category;
  final VoidCallback onTap;
  final Function(bool) onHover;

  const _ReelCard({
    required this.title,
    required this.media,
    required this.category,
    required this.onTap,
    required this.onHover,
  });

  @override
  State<_ReelCard> createState() => _ReelCardState();
}

class _ReelCardState extends State<_ReelCard> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth < 768 ? 220.0 : 310.0;

    return MouseRegion(
      onEnter: (_) {
        setState(() => hovering = true);
        widget.onHover(true);
      },
      onExit: (_) {
        setState(() => hovering = false);
        widget.onHover(false);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: cardWidth,
          transform: Matrix4.identity()..translate(0.0, hovering ? -8.0 : 0.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: hovering ? AppTheme.brandRed : Colors.white.withOpacity(0.08),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: hovering
                    ? AppTheme.brandRed.withOpacity(0.18)
                    : Colors.black.withOpacity(0.4),
                blurRadius: hovering ? 24 : 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _PortfolioMedia(
                  url: widget.media,
                  fit: BoxFit.cover,
                  autoplay: false,
                  muted: true,
                  loop: true,
                  showControls: false,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.92)],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  bottom: 18,
                  right: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.category.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.brandRed,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
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
class _EditorialGridCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final Function(bool, String) onHoverChange;

  const _EditorialGridCard({
    required this.item,
    required this.onTap,
    required this.onHoverChange,
  });

  @override
  State<_EditorialGridCard> createState() => _EditorialGridCardState();
}

class _EditorialGridCardState extends State<_EditorialGridCard> {
  bool hovering = false;

  String _getString(String key) => widget.item[key]?.toString() ?? '';

  @override
  Widget build(BuildContext context) {
    final title = _getString('title').isNotEmpty ? _getString('title') : _getString('name');
    final media = _getMediaUrl(widget.item);
    final category = _getString('category');

    return MouseRegion(
      onEnter: (_) {
        setState(() => hovering = true);
        widget.onHoverChange(true, 'OPEN');
      },
      onExit: (_) {
        setState(() => hovering = false);
        widget.onHoverChange(false, '');
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform: Matrix4.identity()..translate(0.0, hovering ? -6.0 : 0.0),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: hovering ? AppTheme.brandRed : AppTheme.greyBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: hovering
                    ? AppTheme.brandRed.withOpacity(0.15)
                    : Colors.black.withOpacity(0.3),
                blurRadius: hovering ? 24 : 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _PortfolioMedia(
                        url: media,
                        fit: BoxFit.cover,
                        autoplay: false,
                        muted: true,
                        loop: true,
                        showControls: false,
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        color: hovering
                            ? AppTheme.brandRed.withOpacity(0.08)
                            : Colors.transparent,
                      ),
                      Positioned(
                        top: 14,
                        right: 14,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: hovering ? 44 : 38,
                          height: hovering ? 44 : 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hovering ? AppTheme.brandRed : Colors.black.withOpacity(0.55),
                            border: Border.all(
                              color: hovering ? Colors.transparent : Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_outward_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.brandRed,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title.isEmpty ? 'PROJECT' : title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
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
// FULL INTERACTIVE MEDIA & VIDEO CONTROLLER
// ============================================================================
class _PortfolioMedia extends StatefulWidget {
  final String url;
  final BoxFit fit;
  final bool autoplay;
  final bool muted;
  final bool loop;
  final bool showControls;

  const _PortfolioMedia({
    required this.url,
    required this.fit,
    this.autoplay = false,
    this.muted = true,
    this.loop = true,
    this.showControls = false,
  });

  @override
  State<_PortfolioMedia> createState() => _PortfolioMediaState();
}

class _PortfolioMediaState extends State<_PortfolioMedia> {
  VideoPlayerController? _controller;
  bool _isVideo = false;
  bool _initialized = false;
  bool _failed = false;
  bool _isMuted = true;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _isMuted = widget.muted;
    _initialize();
  }

  Future<void> _initialize() async {
    final url = widget.url.trim();
    if (url.isEmpty) return;

    _isVideo = _isVideoUrl(url);
    if (!_isVideo) return;

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _controller = controller;

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      await controller.setLooping(widget.loop);
      await controller.setVolume(_isMuted ? 0 : 1);

      controller.addListener(() {
        if (mounted) setState(() {});
      });

      if (!mounted) return;
      setState(() => _initialized = true);

      if (widget.autoplay) {
        await controller.play();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  bool _isVideoUrl(String url) {
    final clean = url.split('?').first.split('#').first.toLowerCase();
    return clean.endsWith('.mp4') ||
        clean.endsWith('.webm') ||
        clean.endsWith('.mov') ||
        clean.endsWith('.m4v') ||
        clean.endsWith('.ogg') ||
        clean.contains('/video/') ||
        clean.contains('video');
  }

  void _togglePlayPause() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  void _toggleMute() {
    if (_controller == null) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildVideo(BuildContext context) {
    if (_failed) {
      return _placeholder(Icons.video_library_outlined);
    }

    if (!_initialized || _controller == null || !_controller!.value.isInitialized) {
      return const _MediaShimmer();
    }

    final controller = _controller!;
    final isPlaying = controller.value.isPlaying;
    final position = controller.value.position;
    final duration = controller.value.duration;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: _togglePlayPause,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FittedBox(
              fit: widget.fit,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),

            // Subtle Vignette overlay when hovering
            AnimatedOpacity(
              opacity: (widget.showControls && _isHovering) || !isPlaying ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.2),
                      Colors.transparent,
                      Colors.black.withOpacity(0.75),
                    ],
                  ),
                ),
              ),
            ),

            // Large Center Play/Pause Indicator on Pause
            if (!isPlaying)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.brandRed.withOpacity(0.85),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.brandRed.withOpacity(0.4),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                    ),
                  ),
                ),
              ),

            // COMPREHENSIVE INTERACTIVE CONTROLS BAR
            if (widget.showControls)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: AnimatedOpacity(
                  opacity: _isHovering || !isPlaying ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: _togglePlayPause,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${_formatDuration(position)} / ${_formatDuration(duration)}',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: SizedBox(
                                  height: 6,
                                  child: VideoProgressIndicator(
                                    controller,
                                    allowScrubbing: true,
                                    colors: VideoProgressColors(
                                      playedColor: AppTheme.brandRed,
                                      bufferedColor: Colors.white24,
                                      backgroundColor: Colors.white10,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: Icon(
                                _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                color: Colors.white70,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: _toggleMute,
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
    );
  }

  Widget _buildImage(String url) {
    return Image.network(
      url,
      fit: widget.fit,
      cacheWidth: 1400,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const _MediaShimmer();
      },
      errorBuilder: (context, error, stackTrace) => _placeholder(Icons.broken_image_outlined),
    );
  }

  Widget _placeholder(IconData icon) {
    return Container(
      color: AppTheme.darkCard,
      child: Center(
        child: Icon(icon, size: 36, color: Colors.white24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.url.trim();
    if (url.isEmpty) return _placeholder(Icons.image_outlined);
    if (_isVideo) return _buildVideo(context);
    return _buildImage(url);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

// ============================================================================
// MEDIA URL EXTRACTION
// ============================================================================
String _getMediaUrl(Map<String, dynamic> item) {
  final videoUrl = item['videoUrl']?.toString().trim();
  if (videoUrl != null && videoUrl.isNotEmpty) return videoUrl;

  final thumbnail = item['thumbnailUrl']?.toString().trim();
  if (thumbnail != null && thumbnail.isNotEmpty) return thumbnail;

  final image = item['imageUrl']?.toString().trim();
  if (image != null && image.isNotEmpty) return image;

  final fileUrl = item['fileUrl']?.toString().trim();
  if (fileUrl != null && fileUrl.isNotEmpty) return fileUrl;

  final files = item['files'];
  if (files is List) {
    for (final file in files) {
      if (file is String && file.trim().isNotEmpty) return file.trim();
      if (file is Map) {
        final url = file['url']?.toString().trim();
        if (url != null && url.isNotEmpty) return url;
        final fUrl = file['fileUrl']?.toString().trim();
        if (fUrl != null && fUrl.isNotEmpty) return fUrl;
        final path = file['path_display']?.toString().trim();
        if (path != null && path.isNotEmpty) return path;
      }
    }
  }
  return '';
}

bool _isVideoFileUrl(String url) {
  final lower = url.split('?').first.split('#').first.toLowerCase();
  return lower.endsWith('.mp4') ||
      lower.endsWith('.webm') ||
      lower.endsWith('.mov') ||
      lower.endsWith('.m4v') ||
      lower.endsWith('.ogg') ||
      lower.contains('/video/') ||
      lower.contains('video');
}

// ============================================================================
// SKELETON CARD & SHIMMER
// ============================================================================
class _PortfolioSkeletonCard extends StatefulWidget {
  const _PortfolioSkeletonCard();

  @override
  State<_PortfolioSkeletonCard> createState() => _PortfolioSkeletonCardState();
}

class _PortfolioSkeletonCardState extends State<_PortfolioSkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        return ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: ShaderMask(
            shaderCallback: (bounds) {
              final position = -1.0 + value * 3.0;
              return LinearGradient(
                begin: Alignment(position - 1, 0),
                end: Alignment(position + 1, 0),
                colors: const [
                  Colors.transparent,
                  Colors.white10,
                  Colors.transparent,
                ],
              ).createShader(bounds);
            },
            blendMode: BlendMode.srcATop,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                border: Border.all(color: AppTheme.greyBorder),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Container(color: Colors.white.withOpacity(0.03)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 8,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 16,
                          width: 150,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MediaShimmer extends StatefulWidget {
  const _MediaShimmer();

  @override
  State<_MediaShimmer> createState() => _MediaShimmerState();
}

class _MediaShimmerState extends State<_MediaShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final position = -1.0 + (_animationController.value * 2.0);
        return Container(
          color: AppTheme.darkCard,
          child: ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment(position - 1, 0),
                end: Alignment(position + 1, 0),
                colors: const [
                  Colors.transparent,
                  Colors.white10,
                  Colors.transparent,
                ],
              ).createShader(bounds);
            },
            blendMode: BlendMode.srcATop,
            child: Container(color: Colors.white.withOpacity(0.03)),
          ),
        );
      },
    );
  }
}

// ============================================================================
// CLIENT LOGO
// ============================================================================
class _ClientLogo extends StatelessWidget {
  final String name;

  const _ClientLogo({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Text(
        name,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white38,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

// ============================================================================
// FINAL CTA
// ============================================================================
class _PortfolioFinalCta extends StatefulWidget {
  final Function(bool, String) onHoverItem;

  const _PortfolioFinalCta({required this.onHoverItem});

  @override
  State<_PortfolioFinalCta> createState() => _PortfolioFinalCtaState();
}

class _PortfolioFinalCtaState extends State<_PortfolioFinalCta> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.of(context).size.width < 768;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: mobile ? 20 : 64),
      child: MouseRegion(
        onEnter: (_) {
          setState(() => hovering = true);
          widget.onHoverItem(true, 'START');
        },
        onExit: (_) {
          setState(() => hovering = false);
          widget.onHoverItem(false, '');
        },
        child: GestureDetector(
          onTap: () {},
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            padding: EdgeInsets.symmetric(
              horizontal: mobile ? 24 : 64,
              vertical: mobile ? 48 : 80,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              color: hovering ? AppTheme.brandRed : AppTheme.darkCard,
              border: Border.all(
                color: hovering ? AppTheme.brandRed : AppTheme.greyBorder,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: hovering
                      ? AppTheme.brandRed.withOpacity(0.35)
                      : Colors.black.withOpacity(0.4),
                  blurRadius: hovering ? 40 : 20,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HAVE AN IDEA?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: hovering ? Colors.white70 : AppTheme.brandRed,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'LET’S MAKE\nIT REAL.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: mobile ? 44 : 76,
                    height: 0.92,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -3,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Text(
                      'START A PROJECT',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
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
// DETAILS PAGE (WITH FULL INTERACTIVE VIDEO PLAYER)
// ============================================================================
class AppDetailsPage extends StatelessWidget {
  final Map<String, dynamic> item;

  const AppDetailsPage({super.key, required this.item});

  String _value(String key) => item[key]?.toString() ?? '';

  @override
  Widget build(BuildContext context) {
    final title = _value('title').isNotEmpty ? _value('title') : _value('name');
    final description = _value('description');
    final category = _value('category').toUpperCase();
    final media = _getMediaUrl(item);
    final isVideo = _isVideoFileUrl(media);
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    final mediaWidth = isMobile ? width - 40 : width * 0.65;
    final mediaHeight = isMobile ? mediaWidth * 0.75 : mediaWidth * 0.62;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppTheme.darkBackground.withOpacity(0.9),
            elevation: 0,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'THEVAH // PROJECT ARCHIVE',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Colors.white54,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 20 : 64,
                40,
                isMobile ? 20 : 64,
                100,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.brandRed.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.brandRed.withOpacity(0.35)),
                    ),
                    child: Text(
                      category.isEmpty ? 'CASE STUDY' : category,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.brandRed,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title.isEmpty ? 'PROJECT' : title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 42 : 72,
                      height: 0.95,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -2.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (description.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 750),
                      child: Text(
                        description,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          height: 1.8,
                          color: Colors.white60,
                        ),
                      ),
                    ),
                  const SizedBox(height: 48),

                  // INTERACTIVE SHOWCASE (WITH CONTROLS)
                  if (media.isNotEmpty)
                    Center(
                      child: Container(
                        width: mediaWidth,
                        height: mediaHeight,
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.65),
                              blurRadius: 36,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: _PortfolioMedia(
                          url: media,
                          fit: BoxFit.cover,
                          autoplay: isVideo,
                          muted: false,
                          loop: true,
                          showControls: isVideo, // Full interactive controls on Details page
                        ),
                      ),
                    ),

                  const SizedBox(height: 56),

                  _DetailsInfoRow(label: 'CATEGORY', value: category.isEmpty ? '—' : category),
                  _DetailsInfoRow(label: 'PROJECT', value: title.isEmpty ? '—' : title),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailsInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: Colors.white38,
                letterSpacing: 2,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
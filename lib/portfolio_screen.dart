import 'dart:math' as math;
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

class _PortfolioScreenState extends State<PortfolioScreen>
    with TickerProviderStateMixin {
  // ============================================================
  // CONTROLLERS & NOTIFIERS
  // ============================================================
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<Offset> _cursorPosNotifier =
  ValueNotifier<Offset>(Offset.zero);
  final ValueNotifier<bool> _isHoveringNotifier =
  ValueNotifier<bool>(false);
  final ValueNotifier<double> _scrollOffsetNotifier =
  ValueNotifier<double>(0);

  late final AnimationController _marqueeController;
  late final AnimationController _auroraController;

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
  int _visibleProjectCount = 6;
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

    _marqueeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();

    _auroraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

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
        _visibleProjectCount = items.length > 6 ? 6 : items.length;
        _hasMoreProjects = items.length > 6;
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

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    setState(() {
      _visibleProjectCount += 6;
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
    if (_cursorText != text && mounted) {
      setState(() => _cursorText = text);
    }
  }

  void _openDetailsPage(Map<String, dynamic> item) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AppDetailsPage(item: item),
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
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
    _marqueeController.dispose();
    _auroraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;
    final double horizontalPadding = isMobile ? 18 : 64;

    return MouseRegion(
      cursor: isMobile ? MouseCursor.defer : SystemMouseCursors.none,
      onHover: (event) => _cursorPosNotifier.value = event.position,
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Stack(
          children: [
            if (!isMobile)
              Positioned.fill(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _auroraController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _DynamicSpotlightPainter(
                          auroraValue: _auroraController.value,
                        ),
                      );
                    },
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
                    onHoverItem: (hovering) =>
                        _updateCursor(hovering: hovering),
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
                    child: _PortfolioError(
                        error: _error!, onRetry: _loadPortfolio),
                  )
                else if (_allPortfolioItems.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _PortfolioEmpty(),
                    )
                  else ...[
                      // HERO SECTION
                      SliverToBoxAdapter(
                        child: RepaintBoundary(
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
                      ),

                      SliverToBoxAdapter(
                          child: SizedBox(height: isMobile ? 28 : 48)),

                      // CATEGORIES
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding),
                          child: _CategoryFilterBar(
                            categories: _categories,
                            selectedCategory: _selectedCategory,
                            allItems: _allPortfolioItems,
                            onCategorySelected: (category) {
                              setState(() {
                                _selectedCategory = category;
                                _visibleProjectCount = 6;
                                _isLoadingMore = false;
                                _hasMoreProjects = true;
                              });
                            },
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                          child: SizedBox(height: isMobile ? 48 : 72)),

                      // FEATURED SPOTLIGHT CARD (DEEP PARALLAX)
                      if (_selectedCategory == 'ALL' &&
                          _featuredItem != null) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                const _SectionLabel(
                                    text: '01 // FEATURED SPOTLIGHT'),
                                const SizedBox(height: 20),
                                _FeaturedProjectHeroCard(
                                  item: _featuredItem!,
                                  onTap: () =>
                                      _openDetailsPage(_featuredItem!),
                                  onHoverChange: (hovering, text) =>
                                      _updateCursor(
                                          hovering: hovering, text: text),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                            child: SizedBox(height: isMobile ? 64 : 96)),
                      ],

                      // CONTINUOUS RUNNING TICKER
                      SliverToBoxAdapter(
                        child: RepaintBoundary(
                          child: _MarqueeTicker(controller: _marqueeController),
                        ),
                      ),

                      SliverToBoxAdapter(
                          child: SizedBox(height: isMobile ? 64 : 96)),

                      // SELECTED REEL
                      if (_selectedCategory == 'ALL') ...[
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: horizontalPadding),
                                child: const _SectionLabel(
                                    text: '02 // SELECTED REEL'),
                              ),
                              const SizedBox(height: 20),
                              _HorizontalProjectReel(
                                items: _allPortfolioItems,
                                onTapItem: (item) => _openDetailsPage(item),
                                onHoverItem: (hovering, text) =>
                                    _updateCursor(
                                        hovering: hovering, text: text),
                              ),
                            ],
                          ),
                        ),
                        SliverToBoxAdapter(
                            child: SizedBox(height: isMobile ? 64 : 96)),
                      ],

                      // ARCHIVE MATRIX
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding),
                          child: _SectionLabel(
                            text: _selectedCategory == 'ALL'
                                ? '03 // ARCHIVE MATRIX'
                                : 'ARCHIVE // $_selectedCategory',
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 24)),

                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding),
                        sliver: SliverGrid(
                          gridDelegate:
                          SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 640,
                            mainAxisSpacing: isMobile ? 22 : 30,
                            crossAxisSpacing: isMobile ? 18 : 30,
                            childAspectRatio: isMobile ? 1.05 : 1.35,
                          ),
                          delegate: SliverChildBuilderDelegate(
                                (context, index) {
                              final item = _filteredItems[index];
                              return _EditorialGridCard(
                                item: item,
                                onTap: () => _openDetailsPage(item),
                                onHoverChange: (hovering, text) =>
                                    _updateCursor(
                                        hovering: hovering, text: text),
                              );
                            },
                            childCount: _filteredItems.length,
                          ),
                        ),
                      ),

                      // LAZY LOADING SKELETON
                      if (_isLoadingMore)
                        SliverPadding(
                          padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding, vertical: 28),
                          sliver: SliverGrid(
                            gridDelegate:
                            SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 640,
                              mainAxisSpacing: isMobile ? 22 : 30,
                              crossAxisSpacing: isMobile ? 18 : 30,
                              childAspectRatio: isMobile ? 1.05 : 1.35,
                            ),
                            delegate: SliverChildBuilderDelegate(
                                  (context, index) =>
                              const _PortfolioSkeletonCard(),
                              childCount: 2,
                            ),
                          ),
                        ),

                      if (!_hasMoreProjects && _filteredItems.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 40),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.03),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.05)),
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

                      SliverToBoxAdapter(
                          child: SizedBox(height: isMobile ? 70 : 110)),

                      // CLIENT LOGOS
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
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
                              const SizedBox(height: 24),
                              Wrap(
                                spacing: isMobile ? 18 : 36,
                                runSpacing: isMobile ? 16 : 24,
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

                      SliverToBoxAdapter(
                          child: SizedBox(height: isMobile ? 70 : 110)),

                      // CTA
                      SliverToBoxAdapter(
                        child: _PortfolioFinalCta(
                          onHoverItem: (hovering, text) =>
                              _updateCursor(
                                  hovering: hovering, text: text),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 80)),
                      const SliverToBoxAdapter(child: AgencyFooter()),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
              ],
            ),

            const FloatingWhatsAppButton(),

            // DUAL-RING CURSOR
            if (!isMobile)
              ValueListenableBuilder<Offset>(
                valueListenable: _cursorPosNotifier,
                builder: (context, cursorPosition, child) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: _isHoveringNotifier,
                    builder: (context, hovering, child) {
                      final size = hovering ? 80.0 : 20.0;
                      return Positioned(
                        left: cursorPosition.dx - size / 2,
                        top: cursorPosition.dy - size / 2,
                        child: IgnorePointer(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            curve: Curves.easeOut,
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hovering
                                  ? AppTheme.brandRed.withOpacity(0.9)
                                  : Colors.transparent,
                              border: Border.all(
                                color: hovering
                                    ? Colors.transparent
                                    : Colors.white.withOpacity(0.6),
                                width: 1.5,
                              ),
                            ),
                            child: hovering && _cursorText.isNotEmpty
                                ? Center(
                              child: Text(
                                _cursorText,
                                textAlign: TextAlign.center,
                                style:
                                GoogleFonts.plusJakartaSans(
                                  fontWeight:
                                  FontWeight.w800,
                                  fontSize: 10,
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

// ============================================================================
// HIGH-PERFORMANCE EFFECTIVE WINDOW PARALLAX ENGINE
// ============================================================================
class _EffectiveParallaxBox extends StatelessWidget {
  final Widget child;
  final double parallaxIntensity;

  const _EffectiveParallaxBox({
    required this.child,
    this.parallaxIntensity = 0.35,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Flow(
          delegate: _SmoothParallaxFlowDelegate(
            scrollable: Scrollable.of(context),
            itemContext: context,
            intensity: parallaxIntensity,
          ),
          children: [child],
        );
      },
    );
  }
}

class _SmoothParallaxFlowDelegate extends FlowDelegate {
  final ScrollableState? scrollable;
  final BuildContext itemContext;
  final double intensity;

  _SmoothParallaxFlowDelegate({
    required this.scrollable,
    required this.itemContext,
    required this.intensity,
  }) : super(repaint: scrollable?.position);

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) {
    return BoxConstraints.tightFor(
      width: constraints.maxWidth,
      height: constraints.maxHeight * (1.0 + (intensity * 2)),
    );
  }

  @override
  void paintChildren(FlowPaintingContext context) {
    if (scrollable == null) {
      context.paintChild(0);
      return;
    }

    final scrollableBox =
    scrollable!.context.findRenderObject() as RenderBox?;
    final itemBox = itemContext.findRenderObject() as RenderBox?;

    if (scrollableBox == null || itemBox == null || !itemBox.hasSize) {
      context.paintChild(0);
      return;
    }

    final itemOffset = itemBox.localToGlobal(
      Offset.zero,
      ancestor: scrollableBox,
    );

    final viewportHeight = scrollable!.position.viewportDimension;
    final itemCenterY = itemOffset.dy + (itemBox.size.height / 2);
    final relativePosition = ((itemCenterY / viewportHeight) - 0.5).clamp(-0.8, 0.8);

    final maxOffset = context.size.height * intensity;
    final translateY = (-relativePosition * maxOffset) - maxOffset;

    context.paintChild(
      0,
      transform: Matrix4.translationValues(0.0, translateY, 0.0),
    );
  }

  @override
  bool shouldRepaint(_SmoothParallaxFlowDelegate oldDelegate) {
    return scrollable != oldDelegate.scrollable ||
        itemContext != oldDelegate.itemContext ||
        intensity != oldDelegate.intensity;
  }
}

// ============================================================================
// REDESIGNED CATEGORY FILTER BAR
// ============================================================================
class _CategoryFilterBar extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final List<Map<String, dynamic>> allItems;
  final ValueChanged<String> onCategorySelected;

  const _CategoryFilterBar({
    required this.categories,
    required this.selectedCategory,
    required this.allItems,
    required this.onCategorySelected,
  });

  int _getCount(String category) {
    if (category == 'ALL') return allItems.length;
    return allItems.where((item) {
      final cat = item['category']?.toString().toUpperCase() ?? '';
      return cat == category;
    }).length;
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'APP':
        return Icons.phone_iphone_rounded;
      case 'WEBSITE':
        return Icons.language_rounded;
      case 'LOGO':
        return Icons.interests_outlined;
      case 'VIDEO':
        return Icons.play_circle_outline_rounded;
      case 'GRAPHIC DESIGNS':
        return Icons.auto_awesome_outlined;
      case 'ALL':
      default:
        return Icons.grid_view_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF141416),
          borderRadius: BorderRadius.circular(34),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1.2,
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: categories.map((category) {
              final isSelected = selectedCategory == category;
              final count = _getCount(category);
              final icon = _getCategoryIcon(category);

              return _CategoryFilterItem(
                category: category,
                isSelected: isSelected,
                count: count,
                icon: icon,
                isMobile: isMobile,
                onTap: () => onCategorySelected(category),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _CategoryFilterItem extends StatefulWidget {
  final String category;
  final bool isSelected;
  final int count;
  final IconData icon;
  final bool isMobile;
  final VoidCallback onTap;

  const _CategoryFilterItem({
    required this.category,
    required this.isSelected,
    required this.count,
    required this.icon,
    required this.isMobile,
    required this.onTap,
  });

  @override
  State<_CategoryFilterItem> createState() => _CategoryFilterItemState();
}

class _CategoryFilterItemState extends State<_CategoryFilterItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isMobile ? 12 : 16,
            vertical: widget.isMobile ? 7 : 9,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            color: widget.isSelected
                ? AppTheme.brandRed
                : _hovering
                ? Colors.white.withOpacity(0.06)
                : Colors.transparent,
            border: Border.all(
              color: widget.isSelected
                  ? AppTheme.brandRed
                  : _hovering
                  ? Colors.white.withOpacity(0.12)
                  : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: widget.isMobile ? 13 : 15,
                color: widget.isSelected
                    ? Colors.white
                    : _hovering
                    ? Colors.white
                    : Colors.white54,
              ),
              const SizedBox(width: 7),
              Text(
                widget.category,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: widget.isMobile ? 11 : 12,
                  fontWeight:
                  widget.isSelected ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: 0.8,
                  color: widget.isSelected
                      ? Colors.white
                      : _hovering
                      ? Colors.white
                      : Colors.white60,
                ),
              ),
              if (widget.count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? Colors.black.withOpacity(0.25)
                        : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.count}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color:
                      widget.isSelected ? Colors.white : Colors.white38,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// DYNAMIC SPOTLIGHT PAINTER
// ============================================================================
class _DynamicSpotlightPainter extends CustomPainter {
  final double auroraValue;

  _DynamicSpotlightPainter({required this.auroraValue});

  @override
  void paint(Canvas canvas, Size size) {
    final auroraCenter = Offset(
      size.width * 0.85,
      size.height * 0.28 + (math.sin(auroraValue * math.pi * 2) * 20),
    );

    final auroraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.brandRed.withOpacity(0.08),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: auroraCenter, radius: size.width * 0.35),
      );

    canvas.drawCircle(auroraCenter, size.width * 0.35, auroraPaint);
  }

  @override
  bool shouldRepaint(covariant _DynamicSpotlightPainter oldDelegate) =>
      oldDelegate.auroraValue != auroraValue;
}

// ============================================================================
// MARQUEE TICKER
// ============================================================================
class _MarqueeTicker extends StatelessWidget {
  final AnimationController controller;

  const _MarqueeTicker({required this.controller});

  @override
  Widget build(BuildContext context) {
    const items = [
      'UI/UX ARCHITECTURE',
      'HIGH-PERFORMANCE MOBILE',
      'SCALABLE WEB PLATFORMS',
      'BESPOKE BRANDING',
      'CINEMATIC VIDEO EDITING',
    ];

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return ClipRect(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.015),
              border: Border.symmetric(
                horizontal: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                children: List.generate(3, (_) {
                  return Row(
                    children: items.map((text) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.brandRed,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              text,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white30,
                                letterSpacing: 2.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                }),
              ),
            ),
          ),
        );
      },
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
            letterSpacing: 2.5,
          ),
        ),
      ],
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
    final textParallax = (scrollOffset * 0.35).clamp(0, 90);

    return SizedBox(
      height: mobile ? 460 : 540,
      child: Stack(
        children: [
          Positioned(
            top: 60.0 - textParallax.toDouble(),
            left: mobile ? 20 : 64,
            right: mobile ? 20 : 64,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.brandRed.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppTheme.brandRed.withOpacity(0.3)),
                  ),
                  child: Text(
                    'THEVAH // ARCHIVE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.brandRed,
                      letterSpacing: 2.2,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'WE BUILD\nDIGITAL\nEXPERIENCES.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: mobile ? 44 : 78,
                    height: 0.95,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -3.0,
                  ),
                ),
                const SizedBox(height: 20),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: Text(
                    'A curated showcase of high-performance web systems, bespoke mobile architectures, and immersive brand designs.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: mobile ? 14 : 15,
                      height: 1.65,
                      color: Colors.white60,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
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
                      Container(width: 40, height: 1, color: Colors.white24),
                      const SizedBox(width: 12),
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
  State<_FeaturedProjectHeroCard> createState() =>
      _FeaturedProjectHeroCardState();
}

class _FeaturedProjectHeroCardState extends State<_FeaturedProjectHeroCard> {
  bool _hovering = false;

  String _string(String key) => widget.item[key]?.toString() ?? '';

  @override
  Widget build(BuildContext context) {
    final title =
    _string('title').isNotEmpty ? _string('title') : _string('name');
    final mediaUrl = _getMediaUrl(widget.item);
    final category = _string('category').toUpperCase();
    final screenWidth = MediaQuery.of(context).size.width;
    final height = screenWidth < 768 ? 260.0 : 440.0;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovering = true);
        widget.onHoverChange(true, 'EXPLORE');
      },
      onExit: (_) {
        setState(() => _hovering = false);
        widget.onHoverChange(false, '');
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          height: height,
          transform: Matrix4.identity()
            ..translate(0.0, _hovering ? -5.0 : 0.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _hovering
                  ? AppTheme.brandRed.withOpacity(0.8)
                  : Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _EffectiveParallaxBox(
                  parallaxIntensity: 0.35,
                  child: _PortfolioMedia(
                    url: mediaUrl,
                    fit: BoxFit.cover,
                    autoplay: true,
                    muted: true,
                    loop: true,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.88),
                      ],
                      stops: const [0.3, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 24,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: AppTheme.brandRed.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color:
                                    AppTheme.brandRed.withOpacity(0.4)),
                              ),
                              child: Text(
                                category.isEmpty ? 'FEATURED' : category,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.brandRed,
                                  letterSpacing: 1.8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              title.isEmpty ? 'PROJECT' : title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: screenWidth < 768 ? 22 : 30,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _hovering ? 50 : 44,
                        height: _hovering ? 50 : 44,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.brandRed,
                        ),
                        child: const Icon(
                          Icons.arrow_outward_rounded,
                          color: Colors.white,
                          size: 20,
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
      height: mobile ? 220 : 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: mobile ? 18 : 64),
        itemCount: visibleItems.length,
        itemBuilder: (context, index) {
          final item = visibleItems[index];
          final title = item['title']?.toString() ??
              item['name']?.toString() ??
              'PROJECT';
          final media = _getMediaUrl(item);

          return Padding(
            padding: const EdgeInsets.only(right: 16),
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
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth < 768 ? 200.0 : 280.0;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovering = true);
        widget.onHover(true);
      },
      onExit: (_) {
        setState(() => _hovering = false);
        widget.onHover(false);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: cardWidth,
          transform: Matrix4.identity()
            ..translate(0.0, _hovering ? -5.0 : 0.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _hovering
                  ? AppTheme.brandRed
                  : Colors.white.withOpacity(0.08),
              width: 1.2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _EffectiveParallaxBox(
                  parallaxIntensity: 0.25,
                  child: _PortfolioMedia(
                    url: widget.media,
                    fit: BoxFit.cover,
                    autoplay: false,
                    muted: true,
                    loop: true,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.88)
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  bottom: 14,
                  right: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.category.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.brandRed,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
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
  bool _hovering = false;

  String _getString(String key) => widget.item[key]?.toString() ?? '';

  @override
  Widget build(BuildContext context) {
    final title = _getString('title').isNotEmpty
        ? _getString('title')
        : _getString('name');
    final media = _getMediaUrl(widget.item);
    final category = _getString('category');

    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovering = true);
        widget.onHoverChange(true, 'OPEN');
      },
      onExit: (_) {
        setState(() => _hovering = false);
        widget.onHoverChange(false, '');
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()
            ..translate(0.0, _hovering ? -5.0 : 0.0),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _hovering ? AppTheme.brandRed : AppTheme.greyBorder,
              width: 1.2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _EffectiveParallaxBox(
                        parallaxIntensity: 0.32,
                        child: _PortfolioMedia(
                          url: media,
                          fit: BoxFit.cover,
                          autoplay: false,
                          muted: true,
                          loop: true,
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _hovering
                                ? AppTheme.brandRed
                                : Colors.black.withOpacity(0.6),
                          ),
                          child: const Icon(
                            Icons.arrow_outward_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.brandRed,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        title.isEmpty ? 'PROJECT' : title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
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
  }
}

// ============================================================================
// MEDIA PREVIEW COMPONENT
// ============================================================================
class _PortfolioMedia extends StatefulWidget {
  final String url;
  final BoxFit fit;
  final bool autoplay;
  final bool muted;
  final bool loop;

  const _PortfolioMedia({
    required this.url,
    required this.fit,
    this.autoplay = false,
    this.muted = true,
    this.loop = true,
  });

  @override
  State<_PortfolioMedia> createState() => _PortfolioMediaState();
}

class _PortfolioMediaState extends State<_PortfolioMedia> {
  VideoPlayerController? _controller;
  bool _isVideo = false;
  bool _initialized = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final url = widget.url.trim();
    if (url.isEmpty) return;

    _isVideo = _isVideoUrl(url);
    if (!_isVideo) return;

    try {
      final controller =
      VideoPlayerController.networkUrl(Uri.parse(url));
      _controller = controller;

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      await controller.setLooping(widget.loop);
      await controller.setVolume(widget.muted ? 0 : 1);

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
    final clean =
    url.split('?').first.split('#').first.toLowerCase();
    return clean.endsWith('.mp4') ||
        clean.endsWith('.webm') ||
        clean.endsWith('.mov') ||
        clean.endsWith('.m4v') ||
        clean.endsWith('.ogg') ||
        clean.contains('/video/') ||
        clean.contains('video');
  }

  Widget _buildVideo(BuildContext context) {
    if (_failed) {
      return _placeholder(Icons.video_library_outlined);
    }

    if (!_initialized ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return const _MediaShimmer();
    }

    final controller = _controller!;
    return FittedBox(
      fit: widget.fit,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }

  Widget _buildImage(String url) {
    return Image.network(
      url,
      fit: widget.fit,
      cacheWidth: 900,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const _MediaShimmer();
      },
      errorBuilder: (context, error, stackTrace) =>
          _placeholder(Icons.broken_image_outlined),
    );
  }

  Widget _placeholder(IconData icon) {
    return Container(
      color: AppTheme.darkCard,
      child: Center(
        child: Icon(icon, size: 32, color: Colors.white24),
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
// FULL INTERACTIVE VIDEO PLAYER WITH ±10S, TIME BAR & CONTROLS
// ============================================================================
class _InteractiveVideoPlayerView extends StatefulWidget {
  final String videoUrl;

  const _InteractiveVideoPlayerView({required this.videoUrl});

  @override
  State<_InteractiveVideoPlayerView> createState() =>
      _InteractiveVideoPlayerViewState();
}

class _InteractiveVideoPlayerViewState
    extends State<_InteractiveVideoPlayerView> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _showControls = true;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _controller.play();
          _controller.setLooping(true);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _seekRelative(int seconds) {
    if (!_isInitialized) return;
    final currentPos = _controller.value.position;
    final targetPos = currentPos + Duration(seconds: seconds);
    final duration = _controller.value.duration;

    if (targetPos < Duration.zero) {
      _controller.seekTo(Duration.zero);
    } else if (targetPos > duration) {
      _controller.seekTo(duration);
    } else {
      _controller.seekTo(targetPos);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        color: AppTheme.darkCard,
        child: const Center(
          child: CircularProgressIndicator(
            color: AppTheme.brandRed,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _showControls = true),
      onExit: (_) => setState(() => _showControls = false),
      child: GestureDetector(
        onTap: () {
          setState(() => _showControls = !_showControls);
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video Viewport
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            ),

            // Subtle Dimming Overlay for Controls
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.35),
                      Colors.transparent,
                      Colors.black.withOpacity(0.85),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),

            // Center Play/Pause & ±10s Controls
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Rewind 10s
                  _VideoControlButton(
                    icon: Icons.replay_10_rounded,
                    size: 44,
                    iconSize: 24,
                    tooltip: 'Rewind 10s',
                    onTap: () => _seekRelative(-10),
                  ),
                  const SizedBox(width: 24),

                  // Play / Pause Main Button
                  ValueListenableBuilder(
                    valueListenable: _controller,
                    builder: (context, VideoPlayerValue value, child) {
                      final isPlaying = value.isPlaying;
                      return _VideoControlButton(
                        icon: isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 60,
                        iconSize: 34,
                        isPrimary: true,
                        tooltip: isPlaying ? 'Pause' : 'Play',
                        onTap: () {
                          setState(() {
                            isPlaying
                                ? _controller.pause()
                                : _controller.play();
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(width: 24),

                  // Forward 10s
                  _VideoControlButton(
                    icon: Icons.forward_10_rounded,
                    size: 44,
                    iconSize: 24,
                    tooltip: 'Forward 10s',
                    onTap: () => _seekRelative(10),
                  ),
                ],
              ),
            ),

            // Bottom Progress Bar & Timestamps
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: ValueListenableBuilder(
                    valueListenable: _controller,
                    builder: (context, VideoPlayerValue value, child) {
                      final position = value.position;
                      final duration = value.duration;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Scrubber Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: SizedBox(
                              height: 6,
                              child: VideoProgressIndicator(
                                _controller,
                                allowScrubbing: true,
                                padding: EdgeInsets.zero,
                                colors: VideoProgressColors(
                                  playedColor: AppTheme.brandRed,
                                  bufferedColor: Colors.white24,
                                  backgroundColor: Colors.white12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Control Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_formatDuration(position)} / ${_formatDuration(duration)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white70,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(
                                      _isMuted
                                          ? Icons.volume_off_rounded
                                          : Icons.volume_up_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isMuted = !_isMuted;
                                        _controller.setVolume(
                                            _isMuted ? 0.0 : 1.0);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final bool isPrimary;
  final String tooltip;
  final VoidCallback onTap;

  const _VideoControlButton({
    required this.icon,
    required this.size,
    required this.iconSize,
    this.isPrimary = false,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(size),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPrimary
                  ? AppTheme.brandRed
                  : Colors.black.withOpacity(0.65),
              border: Border.all(
                color: isPrimary
                    ? Colors.transparent
                    : Colors.white.withOpacity(0.15),
                width: 1.2,
              ),
              boxShadow: isPrimary
                  ? [
                BoxShadow(
                  color: AppTheme.brandRed.withOpacity(0.4),
                  blurRadius: 16,
                ),
              ]
                  : [],
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
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
  final lower =
  url.split('?').first.split('#').first.toLowerCase();
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
class _PortfolioSkeletonCard extends StatelessWidget {
  const _PortfolioSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        border: Border.all(color: AppTheme.greyBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(color: Colors.white.withOpacity(0.02)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 8,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 14,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
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

class _MediaShimmer extends StatelessWidget {
  const _MediaShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.darkCard,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Text(
        name,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white38,
          letterSpacing: 1.8,
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
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.of(context).size.width < 768;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: mobile ? 18 : 64),
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _hovering = true);
          widget.onHoverItem(true, 'START');
        },
        onExit: (_) {
          setState(() => _hovering = false);
          widget.onHoverItem(false, '');
        },
        child: GestureDetector(
          onTap: () {},
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: EdgeInsets.symmetric(
              horizontal: mobile ? 22 : 56,
              vertical: mobile ? 42 : 68,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: _hovering ? AppTheme.brandRed : AppTheme.darkCard,
              border: Border.all(
                color: _hovering ? AppTheme.brandRed : AppTheme.greyBorder,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HAVE AN IDEA?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _hovering ? Colors.white70 : AppTheme.brandRed,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'LET’S MAKE\nIT REAL.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: mobile ? 40 : 68,
                    height: 0.94,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -2.5,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Text(
                      'START A PROJECT',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 18),
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
// DETAILS PAGE (WITH FULL INTERACTIVE VIDEO PLAYER & DEEP PARALLAX)
// ============================================================================
class AppDetailsPage extends StatefulWidget {
  final Map<String, dynamic> item;

  const AppDetailsPage({super.key, required this.item});

  @override
  State<AppDetailsPage> createState() => _AppDetailsPageState();
}

class _AppDetailsPageState extends State<AppDetailsPage> {
  final ScrollController _pageScrollController = ScrollController();

  @override
  void dispose() {
    _pageScrollController.dispose();
    super.dispose();
  }

  String _value(String key) => widget.item[key]?.toString() ?? '';

  @override
  Widget build(BuildContext context) {
    final title =
    _value('title').isNotEmpty ? _value('title') : _value('name');
    final description = _value('description');
    final category = _value('category').toUpperCase();
    final media = _getMediaUrl(widget.item);
    final isVideo = _isVideoFileUrl(media);
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    final mediaWidth = isMobile ? width - 36 : width * 0.68;
    final mediaHeight =
    isMobile ? mediaWidth * 0.75 : mediaWidth * 0.58;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: CustomScrollView(
        controller: _pageScrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: AppTheme.darkBackground,
            elevation: 0,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'THEVAH // ARCHIVE',
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
                isMobile ? 18 : 64,
                32,
                isMobile ? 18 : 64,
                80,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.brandRed.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppTheme.brandRed.withOpacity(0.35)),
                    ),
                    child: Text(
                      category.isEmpty ? 'CASE STUDY' : category,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.brandRed,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title.isEmpty ? 'PROJECT' : title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 38 : 64,
                      height: 0.95,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -2.0,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (description.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Text(
                        description,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          height: 1.75,
                          color: Colors.white60,
                        ),
                      ),
                    ),
                  const SizedBox(height: 40),

                  // SHOWCASE: VIDEO WITH CONTROLS OR PARALLAX IMAGE
                  if (media.isNotEmpty)
                    Center(
                      child: Container(
                        width: mediaWidth,
                        height: mediaHeight,
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.1)),
                        ),
                        child: isVideo
                            ? _InteractiveVideoPlayerView(videoUrl: media)
                            : _EffectiveParallaxBox(
                          parallaxIntensity: 0.35,
                          child: Image.network(
                            media,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 48),

                  _DetailsInfoRow(
                      label: 'CATEGORY',
                      value: category.isEmpty ? '—' : category),
                  _DetailsInfoRow(
                      label: 'PROJECT',
                      value: title.isEmpty ? '—' : title),
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
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
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
                fontSize: 13.5,
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

// ============================================================================
// LOADING & ERROR & EMPTY
// ============================================================================
class _PortfolioLoading extends StatelessWidget {
  const _PortfolioLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppTheme.brandRed,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'LOADING THEVAH ARCHIVE...',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.5,
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
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 36, color: AppTheme.brandRed),
            const SizedBox(height: 16),
            Text(
              'COULD NOT LOAD PORTFOLIO',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, height: 1.4, color: Colors.white54),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'TRY AGAIN',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  fontSize: 11,
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
          Icon(Icons.inventory_2_outlined,
              size: 42, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 14),
          Text(
            'NO PROJECTS AVAILABLE',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
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
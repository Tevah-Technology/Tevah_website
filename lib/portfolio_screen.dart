import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
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
  // CONTROLLERS
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
  // SERVICE
  // ============================================================

  final PortfolioService _portfolioService = PortfolioService();

  // ============================================================
  // PORTFOLIO STATE
  // ============================================================

  String _selectedCategory = 'ALL';

  String _cursorText = '';

  bool _isLoading = true;

  bool _isLoadingMore = false;

  bool _hasMoreProjects = true;

  String? _error;

  List<Map<String, dynamic>> _allPortfolioItems = [];

  // ============================================================
  // LAZY DISPLAY
  // ============================================================

  static const int _pageSize = 5;

  int _visibleProjectCount = _pageSize;

  // ============================================================
  // CATEGORIES
  // ============================================================

  final List<String> _categories = const [
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

  // ============================================================
  // INITIAL LOAD
  // ============================================================

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

      final validItems = items.where((item) {
        final name = (item['name'] ?? item['title'] ?? '')
            .toString()
            .toLowerCase();

        final media = _getCardMediaUrl(item);

        return media.isNotEmpty &&
            !name.endsWith('.json') &&
            !media.toLowerCase().contains('.json');
      }).toList();

      setState(() {
        _allPortfolioItems = validItems;

        _visibleProjectCount = math.min(
          _pageSize,
          validItems.length,
        );

        _hasMoreProjects = validItems.length > _visibleProjectCount;

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

  // ============================================================
  // SCROLL
  // ============================================================

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final offset = _scrollController.offset;

    _scrollOffsetNotifier.value = offset;

    final maxExtent = _scrollController.position.maxScrollExtent;

    if (offset >= maxExtent - 700) {
      _loadMoreProjects();
    }
  }

  // ============================================================
  // LOAD MORE
  // ============================================================

  Future<void> _loadMoreProjects() async {
    if (_isLoadingMore || !_hasMoreProjects) return;

    final total = _getFilteredAllItems().length;

    if (_visibleProjectCount >= total) {
      if (mounted) {
        setState(() {
          _hasMoreProjects = false;
        });
      }
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    // Small delay gives the browser time to paint the existing cards
    // before adding more widgets.
    await Future.delayed(const Duration(milliseconds: 80));

    if (!mounted) return;

    setState(() {
      _visibleProjectCount = math.min(
        _visibleProjectCount + _pageSize,
        total,
      );

      _hasMoreProjects = _visibleProjectCount < total;

      _isLoadingMore = false;
    });
  }

  // ============================================================
  // FILTERING
  // ============================================================

  List<Map<String, dynamic>> _getFilteredAllItems() {
    if (_selectedCategory == 'ALL') {
      return List<Map<String, dynamic>>.from(_allPortfolioItems);
    }

    return _allPortfolioItems.where((item) {
      final category =
          item['category']?.toString().toUpperCase() ?? '';

      return category == _selectedCategory;
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredItems {
    final items = _getFilteredAllItems();

    final count = math.min(
      _visibleProjectCount,
      items.length,
    );

    return items.take(count).toList();
  }

  // ============================================================
  // FEATURED
  // ============================================================

  Map<String, dynamic>? get _featuredItem {
    if (_allPortfolioItems.isEmpty) return null;

    for (final item in _allPortfolioItems) {
      if (item['isFeatured'] == true ||
          item['isDataFeatured'] == true) {
        return item;
      }
    }

    return _allPortfolioItems.first;
  }

  // ============================================================
  // DISPLAY NAME
  // ============================================================

  String _getSequentialItemName(
      Map<String, dynamic> item,
      ) {
    final category =
        item['category']?.toString().toUpperCase() ?? 'PROJECT';

    final categoryItems = _allPortfolioItems.where((el) {
      return (el['category']?.toString().toUpperCase() ?? '') ==
          category;
    }).toList();

    final index = categoryItems.indexOf(item);

    return '$category ${index >= 0 ? index + 1 : 1}';
  }

  // ============================================================
  // CURSOR
  // ============================================================

  void _updateCursor({
    required bool hovering,
    String text = '',
  }) {
    _isHoveringNotifier.value = hovering;

    if (_cursorText != text && mounted) {
      setState(() {
        _cursorText = text;
      });
    }
  }

  // ============================================================
  // EXTERNAL URL
  // ============================================================

  Future<void> _launchExternalUrl(
      String urlString,
      ) async {
    if (urlString.trim().isEmpty) return;

    String formatted = urlString.trim();

    if (!formatted.startsWith('http://') &&
        !formatted.startsWith('https://')) {
      formatted = 'https://$formatted';
    }

    final uri = Uri.tryParse(formatted);

    if (uri == null) return;

    try {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
    } catch (error) {
      debugPrint('[Portfolio URL Error] $error');
    }
  }

  // ============================================================
  // OPEN PROJECT
  // ============================================================

  void _openDetailsPage(
      Map<String, dynamic> item,
      ) {
    final category =
    (item['category'] ?? '').toString().trim().toUpperCase();

    final liveUrl = (
        item['liveUrl'] ??
            item['link'] ??
            item['url'] ??
            item['websiteUrl'] ??
            item['projectUrl'] ??
            ''
    ).toString().trim();

    final isWebsite =
        category == 'WEBSITE' ||
            category == 'WEBSITES' ||
            category == 'WEB';

    // Keep website behavior.
    if (isWebsite && liveUrl.isNotEmpty) {
      _launchExternalUrl(liveUrl);
      return;
    }

    // Open responsive popup.
    _showProjectDialog(item);
  }

  // ============================================================
  // PROJECT POPUP
  // ============================================================

  void _showProjectDialog(
      Map<String, dynamic> item,
      ) {
    final category =
        item['category']?.toString().toUpperCase() ?? '';

    final categoryItems = _allPortfolioItems.where((project) {
      return (project['category']?.toString().toUpperCase() ?? '') ==
          category;
    }).toList();

    int index = categoryItems.indexOf(item);

    if (index < 0) {
      index = 0;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.88),
      barrierDismissible: true,
      builder: (dialogContext) {
        return _PortfolioProjectDialog(
          items: categoryItems.isEmpty
              ? [item]
              : categoryItems,
          initialIndex: index,
        );
      },
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final screenWidth =
        MediaQuery.of(context).size.width;

    final isMobile = screenWidth < 768;

    final horizontalPadding =
    isMobile ? 18.0 : 64.0;

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
            // ======================================================
            // BACKGROUND
            // ======================================================

            if (!isMobile)
              Positioned.fill(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _auroraController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _DynamicSpotlightPainter(
                          auroraValue:
                          _auroraController.value,
                        ),
                      );
                    },
                  ),
                ),
              ),

            // ======================================================
            // MAIN SCROLL
            // ======================================================

            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // NAVBAR
                SliverToBoxAdapter(
                  child: TevahNavbar(
                    currentRoute:
                    NavRoute.portfolio,
                    onHoverItem: (hovering) {
                      _updateCursor(
                        hovering: hovering,
                      );
                    },
                  ),
                ),

                // ==================================================
                // LOADING
                // ==================================================

                if (_isLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _PortfolioLoading(),
                  )

                // ==================================================
                // ERROR
                // ==================================================

                else if (_error != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _PortfolioError(
                      error: _error!,
                      onRetry: _loadPortfolio,
                    ),
                  )

                // ==================================================
                // EMPTY
                // ==================================================

                else if (_allPortfolioItems.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _PortfolioEmpty(),
                    )

                  // ==================================================
                  // CONTENT
                  // ==================================================

                  else ...[
                      // HERO
                      SliverToBoxAdapter(
                        child: RepaintBoundary(
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
                                scrollOffset:
                                scrollOffset,
                              );
                            },
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: isMobile ? 28 : 48,
                        ),
                      ),

                      // CATEGORIES
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal:
                            horizontalPadding,
                          ),
                          child: _CategoryFilterBar(
                            categories: _categories,
                            selectedCategory:
                            _selectedCategory,
                            allItems:
                            _allPortfolioItems,
                            onCategorySelected:
                                (category) {
                              setState(() {
                                _selectedCategory =
                                    category;

                                _visibleProjectCount =
                                    _pageSize;

                                final total =
                                    _getFilteredAllItems()
                                        .length;

                                _hasMoreProjects =
                                    total >
                                        _visibleProjectCount;
                              });
                            },
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: isMobile ? 48 : 72,
                        ),
                      ),

                      // FEATURED
                      if (_selectedCategory == 'ALL' &&
                          _featuredItem != null) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding:
                            EdgeInsets.symmetric(
                              horizontal:
                              horizontalPadding,
                            ),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                const _SectionLabel(
                                  text:
                                  '01 // FEATURED SPOTLIGHT',
                                ),
                                const SizedBox(height: 20),
                                _FeaturedProjectHeroCard(
                                  item: _featuredItem!,
                                  displayName:
                                  _getSequentialItemName(
                                    _featuredItem!,
                                  ),
                                  onTap: () {
                                    _openDetailsPage(
                                      _featuredItem!,
                                    );
                                  },
                                  onHoverChange:
                                      (hovering, text) {
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
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: isMobile ? 64 : 96,
                          ),
                        ),
                      ],

                      // TICKER
                      SliverToBoxAdapter(
                        child: RepaintBoundary(
                          child: _MarqueeTicker(
                            controller:
                            _marqueeController,
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: isMobile ? 64 : 96,
                        ),
                      ),

                      // SELECTED REEL
                      if (_selectedCategory == 'ALL') ...[
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: [
                              Padding(
                                padding:
                                EdgeInsets.symmetric(
                                  horizontal:
                                  horizontalPadding,
                                ),
                                child:
                                const _SectionLabel(
                                  text:
                                  '02 // SELECTED REEL',
                                ),
                              ),
                              const SizedBox(height: 20),
                              _HorizontalProjectReel(
                                items:
                                _allPortfolioItems,
                                getItemDisplayName:
                                _getSequentialItemName,
                                onTapItem:
                                _openDetailsPage,
                                onHoverItem:
                                    (hovering, text) {
                                  _updateCursor(
                                    hovering: hovering,
                                    text: text,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: isMobile ? 64 : 96,
                          ),
                        ),
                      ],

                      // ARCHIVE LABEL
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                          EdgeInsets.symmetric(
                            horizontal:
                            horizontalPadding,
                          ),
                          child: _SectionLabel(
                            text: _selectedCategory ==
                                'ALL'
                                ? '03 // ARCHIVE MATRIX'
                                : 'ARCHIVE // $_selectedCategory',
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(
                        child: SizedBox(height: 24),
                      ),

                      // =================================================
                      // PROJECT GRID
                      // =================================================

                      SliverPadding(
                        padding:
                        EdgeInsets.symmetric(
                          horizontal:
                          horizontalPadding,
                        ),
                        sliver: SliverGrid(
                          gridDelegate:
                          SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 640,
                            mainAxisSpacing:
                            isMobile ? 22 : 30,
                            crossAxisSpacing:
                            isMobile ? 18 : 30,
                            childAspectRatio:
                            isMobile ? 1.05 : 1.35,
                          ),
                          delegate:
                          SliverChildBuilderDelegate(
                                (context, index) {
                              final item =
                              _filteredItems[index];

                              return _EditorialGridCard(
                                key: ValueKey(
                                  '${item['path_display'] ?? item['name'] ?? index}',
                                ),
                                item: item,
                                displayName:
                                _getSequentialItemName(
                                  item,
                                ),
                                onTap: () {
                                  _openDetailsPage(
                                    item,
                                  );
                                },
                                onHoverChange:
                                    (hovering, text) {
                                  _updateCursor(
                                    hovering:
                                    hovering,
                                    text: text,
                                  );
                                },
                              );
                            },
                            childCount:
                            _filteredItems.length,
                          ),
                        ),
                      ),

                      // =================================================
                      // LOADING MORE
                      // =================================================

                      if (_isLoadingMore)
                        SliverPadding(
                          padding:
                          EdgeInsets.symmetric(
                            horizontal:
                            horizontalPadding,
                            vertical: 28,
                          ),
                          sliver: SliverGrid(
                            gridDelegate:
                            SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 640,
                              mainAxisSpacing:
                              isMobile ? 22 : 30,
                              crossAxisSpacing:
                              isMobile ? 18 : 30,
                              childAspectRatio:
                              isMobile ? 1.05 : 1.35,
                            ),
                            delegate:
                            SliverChildBuilderDelegate(
                                  (context, index) {
                                return const
                                _PortfolioSkeletonCard();
                              },
                              childCount: 2,
                            ),
                          ),
                        ),

                      // ALL LOADED
                      if (!_hasMoreProjects &&
                          _filteredItems.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding:
                            const EdgeInsets.symmetric(
                              vertical: 40,
                            ),
                            child: Center(
                              child: Container(
                                padding:
                                const EdgeInsets
                                    .symmetric(
                                  horizontal: 18,
                                  vertical: 8,
                                ),
                                decoration:
                                BoxDecoration(
                                  color: Colors.white
                                      .withOpacity(
                                      0.03),
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                      20),
                                  border:
                                  Border.all(
                                    color: Colors
                                        .white
                                        .withOpacity(
                                        0.05),
                                  ),
                                ),
                                child: Text(
                                  '✦ ALL PROJECTS LOADED ✦',
                                  style: GoogleFonts
                                      .plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight:
                                    FontWeight.w800,
                                    color:
                                    Colors.white30,
                                    letterSpacing:
                                    2.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: isMobile ? 70 : 110,
                        ),
                      ),

                      // CLIENTS
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                          EdgeInsets.symmetric(
                            horizontal:
                            horizontalPadding,
                          ),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration:
                                    const BoxDecoration(
                                      shape:
                                      BoxShape.circle,
                                      color:
                                      AppTheme.brandRed,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    'TRUSTED BY GLOBAL INNOVATORS',
                                    style: GoogleFonts
                                        .plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight:
                                      FontWeight.bold,
                                      color:
                                      Colors.white38,
                                      letterSpacing:
                                      2.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 24,
                              ),
                              Wrap(
                                spacing:
                                isMobile
                                    ? 18
                                    : 36,
                                runSpacing:
                                isMobile
                                    ? 16
                                    : 24,
                                children:
                                const [
                                  _ClientLogo(
                                    name:
                                    'FINTECH LABS',
                                  ),
                                  _ClientLogo(
                                    name:
                                    'LOGIX GLOBAL',
                                  ),
                                  _ClientLogo(
                                    name:
                                    'NEXUS AI',
                                  ),
                                  _ClientLogo(
                                    name:
                                    'AURA VISUALS',
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
                          height: isMobile ? 70 : 110,
                        ),
                      ),

                      // CTA
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
                        child: SizedBox(height: 80),
                      ),

                      const SliverToBoxAdapter(
                        child: AgencyFooter(),
                      ),

                      const SliverToBoxAdapter(
                        child: SizedBox(height: 24),
                      ),
                    ],
              ],
            ),

            // WHATSAPP
            const FloatingWhatsAppButton(),

            // ======================================================
            // CUSTOM CURSOR
            // ======================================================

            if (!isMobile)
              ValueListenableBuilder<Offset>(
                valueListenable:
                _cursorPosNotifier,
                builder: (
                    context,
                    cursorPosition,
                    child,
                    ) {
                  return ValueListenableBuilder<
                      bool>(
                    valueListenable:
                    _isHoveringNotifier,
                    builder: (
                        context,
                        hovering,
                        child,
                        ) {
                      final size =
                      hovering ? 80.0 : 20.0;

                      return Positioned(
                        left: cursorPosition.dx -
                            size / 2,
                        top: cursorPosition.dy -
                            size / 2,
                        child: IgnorePointer(
                          child:
                          AnimatedContainer(
                            duration:
                            const Duration(
                              milliseconds: 100,
                            ),
                            curve:
                            Curves.easeOut,
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
                                  0.9)
                                  : Colors
                                  .transparent,
                              border:
                              Border.all(
                                color: hovering
                                    ? Colors
                                    .transparent
                                    : Colors
                                    .white
                                    .withOpacity(
                                    0.6),
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
                                      .w800,
                                  fontSize: 10,
                                  color: Colors
                                      .white,
                                  letterSpacing:
                                  1.0,
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
// RESPONSIVE PROJECT POPUP
// ============================================================================

class _PortfolioProjectDialog extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final int initialIndex;

  const _PortfolioProjectDialog({
    required this.items,
    required this.initialIndex,
  });

  @override
  State<_PortfolioProjectDialog> createState() =>
      _PortfolioProjectDialogState();
}

class _PortfolioProjectDialogState
    extends State<_PortfolioProjectDialog> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();

    _currentIndex =
        widget.initialIndex.clamp(
          0,
          math.max(0, widget.items.length - 1),
        );
  }

  void _previous() {
    if (_currentIndex <= 0) return;

    setState(() {
      _currentIndex--;
    });
  }

  void _next() {
    if (_currentIndex >= widget.items.length - 1) {
      return;
    }

    setState(() {
      _currentIndex++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screen =
        MediaQuery.of(context).size;

    final isMobile =
        screen.width < 768;

    final item =
    widget.items[_currentIndex];

    final category =
        item['category']?.toString().toUpperCase() ??
            'PROJECT';

    final media =
    _getFullMediaUrl(item);

    final description =
        item['description']?.toString() ?? '';

    final displayName =
        '$category ${_currentIndex + 1}';

    return Dialog(
      backgroundColor:
      Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 36,
        vertical: isMobile ? 8 : 30,
      ),
      child: Container(
        constraints:
        BoxConstraints(
          maxWidth: 1500,
          maxHeight:
          screen.height * 0.94,
        ),
        decoration: BoxDecoration(
          color: AppTheme.darkBackground,
          borderRadius:
          BorderRadius.circular(
            isMobile ? 18 : 26,
          ),
          border: Border.all(
            color: Colors.white
                .withOpacity(0.10),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withOpacity(0.6),
              blurRadius: 60,
              spreadRadius: 10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius:
          BorderRadius.circular(
            isMobile ? 18 : 26,
          ),
          child: Column(
            children: [
              // ======================================================
              // HEADER
              // ======================================================

              Padding(
                padding:
                EdgeInsets.fromLTRB(
                  isMobile ? 16 : 24,
                  14,
                  14,
                  14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          Text(
                            'THEVAH // $category',
                            style: GoogleFonts
                                .plusJakartaSans(
                              fontSize:
                              9.5,
                              fontWeight:
                              FontWeight
                                  .w800,
                              color: AppTheme
                                  .brandRed,
                              letterSpacing:
                              2.2,
                            ),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            displayName,
                            style: GoogleFonts
                                .plusJakartaSans(
                              fontSize:
                              isMobile
                                  ? 15
                                  : 18,
                              fontWeight:
                              FontWeight
                                  .w800,
                              color: Colors
                                  .white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Text(
                      '${_currentIndex + 1} / ${widget.items.length}',
                      style: GoogleFonts
                          .plusJakartaSans(
                        fontSize: 10,
                        fontWeight:
                        FontWeight.w700,
                        color:
                        Colors.white38,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    _PopupIconButton(
                      icon: Icons.close_rounded,
                      onTap: () {
                        Navigator.of(
                          context,
                        ).pop();
                      },
                    ),
                  ],
                ),
              ),

              Container(
                height: 1,
                color: Colors.white
                    .withOpacity(0.06),
              ),

              // ======================================================
              // MAIN CONTENT
              // ======================================================

              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(
                    isMobile ? 12 : 20,
                  ),
                  child: Column(
                    children: [
                      // MEDIA
                      Expanded(
                        child: Container(
                          width:
                          double.infinity,
                          decoration:
                          BoxDecoration(
                            color:
                            Colors.black,
                            borderRadius:
                            BorderRadius
                                .circular(
                              18,
                            ),
                            border:
                            Border.all(
                              color: Colors
                                  .white
                                  .withOpacity(
                                  0.08),
                            ),
                          ),
                          clipBehavior:
                          Clip.antiAlias,
                          child:
                          _FullMediaViewer(
                            key: ValueKey(
                              media,
                            ),
                            url: media,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // INFO
                      if (description
                          .isNotEmpty)
                        ConstrainedBox(
                          constraints:
                          const BoxConstraints(
                            maxWidth: 1000,
                          ),
                          child: Text(
                            description,
                            maxLines:
                            isMobile
                                ? 3
                                : 4,
                            overflow:
                            TextOverflow
                                .ellipsis,
                            style: GoogleFonts
                                .plusJakartaSans(
                              fontSize:
                              isMobile
                                  ? 11
                                  : 13,
                              height: 1.5,
                              color:
                              Colors.white60,
                            ),
                          ),
                        ),

                      const SizedBox(
                        height: 12,
                      ),

                      // NAVIGATION
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                        children: [
                          _PopupNavigationButton(
                            icon: Icons
                                .arrow_back_rounded,
                            label: 'PREVIOUS',
                            enabled:
                            _currentIndex >
                                0,
                            onTap:
                            _previous,
                          ),
                          _PopupNavigationButton(
                            icon: Icons
                                .arrow_forward_rounded,
                            label: 'NEXT',
                            enabled:
                            _currentIndex <
                                widget.items
                                    .length -
                                    1,
                            isRight: true,
                            onTap: _next,
                          ),
                        ],
                      ),
                    ],
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

// ============================================================================
// FULL MEDIA VIEWER
// ============================================================================

class _FullMediaViewer extends StatefulWidget {
  final String url;

  const _FullMediaViewer({
    super.key,
    required this.url,
  });

  @override
  State<_FullMediaViewer> createState() =>
      _FullMediaViewerState();
}

class _FullMediaViewerState
    extends State<_FullMediaViewer> {
  VideoPlayerController?
  _controller;

  bool _isVideo = false;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final url =
    widget.url.trim();

    if (url.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
      return;
    }

    final video =
    _isVideoUrl(url);

    if (!video) {
      if (mounted) {
        setState(() {
          _isVideo = false;
          _loading = false;
        });
      }

      return;
    }

    try {
      final controller =
      VideoPlayerController.networkUrl(
        Uri.parse(url),
      );

      _controller = controller;

      await controller.initialize();

      await controller.setLooping(true);

      await controller.setVolume(0);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _isVideo = true;
        _loading = false;
      });

      await controller.play();
    } catch (error) {
      debugPrint(
        '[Full Media Video Error] $error',
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child:
        CircularProgressIndicator(
          strokeWidth: 2,
          color: AppTheme.brandRed,
        ),
      );
    }

    if (_failed) {
      return _mediaError();
    }

    if (_isVideo &&
        _controller != null) {
      return Center(
        child: AspectRatio(
          aspectRatio:
          _controller!
              .value
              .aspectRatio,
          child:
          VideoPlayer(
            _controller!,
          ),
        ),
      );
    }

    // IMPORTANT:
    // contain instead of cover.
    //
    // This means the COMPLETE uploaded
    // image is visible.
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4,
      child: SizedBox.expand(
        child: Image.network(
          widget.url,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          filterQuality:
          FilterQuality.high,
          loadingBuilder: (
              context,
              child,
              progress,
              ) {
            if (progress == null) {
              return child;
            }

            return const Center(
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
                color:
                AppTheme.brandRed,
              ),
            );
          },
          errorBuilder:
              (context, error, stack) {
            return _mediaError();
          },
        ),
      ),
    );
  }

  Widget _mediaError() {
    return Center(
      child: Column(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          const Icon(
            Icons.broken_image_outlined,
            size: 40,
            color: Colors.white24,
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            'MEDIA UNAVAILABLE',
            style: GoogleFonts
                .plusJakartaSans(
              fontSize: 10,
              fontWeight:
              FontWeight.w800,
              letterSpacing: 2,
              color:
              Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

// ============================================================================
// POPUP BUTTON
// ============================================================================

class _PopupIconButton
    extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _PopupIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(30),
        child: Container(
          width: 38,
          height: 38,
          decoration:
          BoxDecoration(
            shape:
            BoxShape.circle,
            color: Colors.white
                .withOpacity(0.05),
            border: Border.all(
              color: Colors.white
                  .withOpacity(
                  0.08),
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _PopupNavigationButton
    extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final bool isRight;
  final VoidCallback onTap;

  const _PopupNavigationButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.isRight = false,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Opacity(
      opacity:
      enabled ? 1 : 0.25,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:
          enabled ? onTap : null,
          borderRadius:
          BorderRadius.circular(
              12),
          child: Container(
            padding:
            const EdgeInsets
                .symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration:
            BoxDecoration(
              color: Colors.white
                  .withOpacity(0.04),
              borderRadius:
              BorderRadius.circular(
                  12),
              border: Border.all(
                color: Colors.white
                    .withOpacity(
                    0.08),
              ),
            ),
            child: Row(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                if (!isRight)
                  Icon(
                    icon,
                    size: 15,
                    color:
                    Colors.white,
                  ),
                if (!isRight)
                  const SizedBox(
                    width: 8,
                  ),
                Text(
                  label,
                  style: GoogleFonts
                      .plusJakartaSans(
                    fontSize: 9,
                    fontWeight:
                    FontWeight.w800,
                    letterSpacing:
                    1.5,
                    color:
                    Colors.white,
                  ),
                ),
                if (isRight)
                  const SizedBox(
                    width: 8,
                  ),
                if (isRight)
                  Icon(
                    icon,
                    size: 15,
                    color:
                    Colors.white,
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
// CARD MEDIA
// ============================================================================

class _PortfolioMedia
    extends StatefulWidget {
  final String url;
  final BoxFit fit;
  final bool autoplay;
  final bool muted;
  final bool loop;

  const _PortfolioMedia({
    required this.url,
    this.fit = BoxFit.cover,
    this.autoplay = false,
    this.muted = true,
    this.loop = true,
  });

  @override
  State<_PortfolioMedia> createState() =>
      _PortfolioMediaState();
}

class _PortfolioMediaState
    extends State<_PortfolioMedia> {
  VideoPlayerController?
  _controller;

  bool _isVideo = false;
  bool _initialized = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final url =
    widget.url.trim();

    if (url.isEmpty) return;

    final video =
    _isVideoUrl(url);

    // IMPORTANT:
    // Rebuild after detecting video.
    if (!video) {
      if (mounted) {
        setState(() {
          _isVideo = false;
        });
      }

      return;
    }

    try {
      final controller =
      VideoPlayerController.networkUrl(
        Uri.parse(url),
      );

      _controller = controller;

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      await controller.setLooping(
        widget.loop,
      );

      await controller.setVolume(
        widget.muted ? 0 : 1,
      );

      setState(() {
        _isVideo = true;
        _initialized = true;
      });

      if (widget.autoplay) {
        await controller.play();
      }
    } catch (error) {
      debugPrint(
        '[Portfolio Media Error] $error',
      );

      if (!mounted) return;

      setState(() {
        _failed = true;
        _isVideo = true;
      });
    }
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final url =
    widget.url.trim();

    if (url.isEmpty) {
      return _placeholder(
        Icons.image_outlined,
      );
    }

    if (_isVideo) {
      return _buildVideo();
    }

    return _buildImage(url);
  }

  Widget _buildVideo() {
    if (_failed) {
      return _placeholder(
        Icons.video_library_outlined,
      );
    }

    if (!_initialized ||
        _controller == null ||
        !_controller!
            .value
            .isInitialized) {
      return const _MediaShimmer();
    }

    final controller =
    _controller!;

    return SizedBox.expand(
      child: FittedBox(
        fit: widget.fit,
        clipBehavior:
        Clip.hardEdge,
        child: SizedBox(
          width: controller
              .value
              .size
              .width,
          height: controller
              .value
              .size
              .height,
          child:
          VideoPlayer(
            controller,
          ),
        ),
      ),
    );
  }

  Widget _buildImage(
      String url,
      ) {
    return SizedBox.expand(
      child: Image.network(
        url,
        fit: widget.fit,
        alignment:
        Alignment.center,
        filterQuality:
        FilterQuality.medium,
        loadingBuilder: (
            context,
            child,
            progress,
            ) {
          if (progress == null) {
            return child;
          }

          return const _MediaShimmer();
        },
        errorBuilder:
            (context, error, stack) {
          return _placeholder(
            Icons.broken_image_outlined,
          );
        },
      ),
    );
  }

  Widget _placeholder(
      IconData icon,
      ) {
    return Container(
      color: AppTheme.darkCard,
      child: Center(
        child: Icon(
          icon,
          size: 32,
          color: Colors.white24,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

// ============================================================================
// MEDIA URLS
// ============================================================================

/// Used by cards.
///
/// IMPORTANT:
/// Thumbnail comes BEFORE full video.
/// This prevents portfolio cards from downloading
/// the large original video unnecessarily.
String _getCardMediaUrl(
    Map<String, dynamic> item,
    ) {
  final thumbnail =
  item['thumbnailUrl']
      ?.toString()
      .trim();

  if (thumbnail != null &&
      thumbnail.isNotEmpty) {
    return thumbnail;
  }

  final image =
  item['imageUrl']
      ?.toString()
      .trim();

  if (image != null &&
      image.isNotEmpty) {
    return image;
  }

  final video =
  item['videoUrl']
      ?.toString()
      .trim();

  if (video != null &&
      video.isNotEmpty) {
    return video;
  }

  final file =
  item['fileUrl']
      ?.toString()
      .trim();

  if (file != null &&
      file.isNotEmpty) {
    return file;
  }

  final files =
  item['files'];

  if (files is List) {
    for (final fileItem
    in files) {
      if (fileItem is String &&
          fileItem.trim().isNotEmpty) {
        return fileItem.trim();
      }

      if (fileItem is Map) {
        final thumbnail =
        fileItem['thumbnailUrl']
            ?.toString()
            .trim();

        if (thumbnail != null &&
            thumbnail.isNotEmpty) {
          return thumbnail;
        }

        final url =
        fileItem['url']
            ?.toString()
            .trim();

        if (url != null &&
            url.isNotEmpty) {
          return url;
        }

        final fileUrl =
        fileItem['fileUrl']
            ?.toString()
            .trim();

        if (fileUrl != null &&
            fileUrl.isNotEmpty) {
          return fileUrl;
        }
      }
    }
  }

  return '';
}

/// Used by popup.
///
/// Full original media is preferred here.
String _getFullMediaUrl(
    Map<String, dynamic> item,
    ) {
  final video =
  item['videoUrl']
      ?.toString()
      .trim();

  if (video != null &&
      video.isNotEmpty) {
    return video;
  }

  final file =
  item['fileUrl']
      ?.toString()
      .trim();

  if (file != null &&
      file.isNotEmpty) {
    return file;
  }

  final image =
  item['imageUrl']
      ?.toString()
      .trim();

  if (image != null &&
      image.isNotEmpty) {
    return image;
  }

  final thumbnail =
  item['thumbnailUrl']
      ?.toString()
      .trim();

  if (thumbnail != null &&
      thumbnail.isNotEmpty) {
    return thumbnail;
  }

  return _getCardMediaUrl(item);
}

bool _isVideoUrl(
    String url,
    ) {
  final clean = url
      .split('?')
      .first
      .split('#')
      .first
      .toLowerCase();

  return clean.endsWith('.mp4') ||
      clean.endsWith('.webm') ||
      clean.endsWith('.mov') ||
      clean.endsWith('.m4v') ||
      clean.endsWith('.ogg') ||
      clean.contains('/video/') ||
      clean.contains('video');
}

// ============================================================================
// PARALLAX
// ============================================================================

class _EffectiveParallaxBox
    extends StatelessWidget {
  final Widget child;
  final double parallaxIntensity;

  const _EffectiveParallaxBox({
    required this.child,
    this.parallaxIntensity = 0.35,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return LayoutBuilder(
      builder: (
          context,
          constraints,
          ) {
        return Flow(
          delegate:
          _SmoothParallaxFlowDelegate(
            scrollable:
            Scrollable.of(context),
            itemContext:
            context,
            intensity:
            parallaxIntensity,
          ),
          children: [child],
        );
      },
    );
  }
}

class _SmoothParallaxFlowDelegate
    extends FlowDelegate {
  final ScrollableState? scrollable;
  final BuildContext itemContext;
  final double intensity;

  _SmoothParallaxFlowDelegate({
    required this.scrollable,
    required this.itemContext,
    required this.intensity,
  }) : super(
    repaint:
    scrollable?.position,
  );

  @override
  BoxConstraints
  getConstraintsForChild(
      int i,
      BoxConstraints constraints,
      ) {
    return BoxConstraints.tightFor(
      width: constraints.maxWidth,
      height: constraints.maxHeight *
          (1 + intensity * 2),
    );
  }

  @override
  void paintChildren(
      FlowPaintingContext context,
      ) {
    if (scrollable == null) {
      context.paintChild(0);
      return;
    }

    final scrollableBox =
    scrollable!.context
        .findRenderObject()
    as RenderBox?;

    final itemBox =
    itemContext.findRenderObject()
    as RenderBox?;

    if (scrollableBox == null ||
        itemBox == null ||
        !itemBox.hasSize) {
      context.paintChild(0);
      return;
    }

    final itemOffset =
    itemBox.localToGlobal(
      Offset.zero,
      ancestor: scrollableBox,
    );

    final viewportHeight =
        scrollable!
            .position
            .viewportDimension;

    final itemCenterY =
        itemOffset.dy +
            itemBox.size.height / 2;

    final relativePosition =
    ((itemCenterY /
        viewportHeight) -
        0.5)
        .clamp(-0.8, 0.8);

    final maxOffset =
        context.size.height *
            intensity;

    final translateY =
        (-relativePosition *
            maxOffset) -
            maxOffset;

    context.paintChild(
      0,
      transform:
      Matrix4.translationValues(
        0,
        translateY,
        0,
      ),
    );
  }

  @override
  bool shouldRepaint(
      _SmoothParallaxFlowDelegate
      oldDelegate,
      ) {
    return scrollable !=
        oldDelegate.scrollable ||
        itemContext !=
            oldDelegate.itemContext ||
        intensity !=
            oldDelegate.intensity;
  }
}

// ============================================================================
// CATEGORY FILTER
// ============================================================================

class _CategoryFilterBar
    extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final List<Map<String, dynamic>>
  allItems;
  final ValueChanged<String>
  onCategorySelected;

  const _CategoryFilterBar({
    required this.categories,
    required this.selectedCategory,
    required this.allItems,
    required this.onCategorySelected,
  });

  int _getCount(
      String category,
      ) {
    if (category == 'ALL') {
      return allItems.length;
    }

    return allItems.where((item) {
      final cat =
          item['category']
              ?.toString()
              .toUpperCase() ??
              '';

      return cat == category;
    }).length;
  }

  IconData _getCategoryIcon(
      String category,
      ) {
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

      default:
        return Icons.grid_view_rounded;
    }
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final mobile =
        MediaQuery.of(context)
            .size
            .width <
            768;

    return Center(
      child: Container(
        padding:
        const EdgeInsets.all(6),
        decoration:
        BoxDecoration(
          color:
          const Color(0xFF141416),
          borderRadius:
          BorderRadius.circular(
              34),
          border: Border.all(
            color: Colors.white
                .withOpacity(0.08),
          ),
        ),
        child:
        SingleChildScrollView(
          scrollDirection:
          Axis.horizontal,
          child: Row(
            mainAxisSize:
            MainAxisSize.min,
            children:
            categories.map(
                  (category) {
                return _CategoryFilterItem(
                  category:
                  category,
                  isSelected:
                  selectedCategory ==
                      category,
                  count:
                  _getCount(
                    category,
                  ),
                  icon:
                  _getCategoryIcon(
                    category,
                  ),
                  isMobile:
                  mobile,
                  onTap: () =>
                      onCategorySelected(
                        category,
                      ),
                );
              },
            ).toList(),
          ),
        ),
      ),
    );
  }
}

class _CategoryFilterItem
    extends StatefulWidget {
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
  State<_CategoryFilterItem>
  createState() =>
      _CategoryFilterItemState();
}

class _CategoryFilterItemState
    extends State<
        _CategoryFilterItem> {
  bool _hovering = false;

  @override
  Widget build(
      BuildContext context,
      ) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _hovering = true;
        });
      },
      onExit: (_) {
        setState(() {
          _hovering = false;
        });
      },
      cursor:
      SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child:
        AnimatedContainer(
          duration:
          const Duration(
            milliseconds: 180,
          ),
          margin:
          const EdgeInsets
              .symmetric(
            horizontal: 3,
          ),
          padding:
          EdgeInsets.symmetric(
            horizontal:
            widget.isMobile
                ? 12
                : 16,
            vertical:
            widget.isMobile
                ? 7
                : 9,
          ),
          decoration:
          BoxDecoration(
            borderRadius:
            BorderRadius.circular(
                26),
            color: widget
                .isSelected
                ? AppTheme
                .brandRed
                : _hovering
                ? Colors.white
                .withOpacity(
                0.06)
                : Colors.transparent,
          ),
          child: Row(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size:
                widget.isMobile
                    ? 13
                    : 15,
                color: widget
                    .isSelected
                    ? Colors.white
                    : Colors.white54,
              ),
              const SizedBox(
                width: 7,
              ),
              Text(
                widget.category,
                style: GoogleFonts
                    .plusJakartaSans(
                  fontSize:
                  widget.isMobile
                      ? 11
                      : 12,
                  fontWeight: widget
                      .isSelected
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color: widget
                      .isSelected
                      ? Colors.white
                      : Colors.white60,
                  letterSpacing:
                  0.8,
                ),
              ),
              if (widget.count >
                  0) ...[
                const SizedBox(
                  width: 6,
                ),
                Container(
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 5,
                    vertical: 1.5,
                  ),
                  decoration:
                  BoxDecoration(
                    color: widget
                        .isSelected
                        ? Colors.black
                        .withOpacity(
                        0.25)
                        : Colors.white
                        .withOpacity(
                        0.06),
                    borderRadius:
                    BorderRadius
                        .circular(
                        8),
                  ),
                  child: Text(
                    '${widget.count}',
                    style: GoogleFonts
                        .plusJakartaSans(
                      fontSize: 9.5,
                      fontWeight:
                      FontWeight.w700,
                      color: widget
                          .isSelected
                          ? Colors.white
                          : Colors.white38,
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
// HERO
// ============================================================================

class _CinematicPortfolioHero
    extends StatelessWidget {
  final int totalProjects;
  final double scrollOffset;

  const _CinematicPortfolioHero({
    required this.totalProjects,
    required this.scrollOffset,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final width =
        MediaQuery.of(context)
            .size
            .width;

    final mobile =
        width < 768;

    final textParallax =
    (scrollOffset * 0.35)
        .clamp(0, 90);

    return SizedBox(
      height:
      mobile ? 460 : 540,
      child: Stack(
        children: [
          Positioned(
            top:
            60 -
                textParallax.toDouble(),
            left:
            mobile ? 20 : 64,
            right:
            mobile ? 20 : 64,
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Container(
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration:
                  BoxDecoration(
                    color: AppTheme
                        .brandRed
                        .withOpacity(
                        0.12),
                    borderRadius:
                    BorderRadius
                        .circular(
                        20),
                    border: Border.all(
                      color: AppTheme
                          .brandRed
                          .withOpacity(
                          0.3),
                    ),
                  ),
                  child: Text(
                    'THEVAH // ARCHIVE',
                    style: GoogleFonts
                        .plusJakartaSans(
                      fontSize: 10,
                      fontWeight:
                      FontWeight.w800,
                      color: AppTheme
                          .brandRed,
                      letterSpacing:
                      2.2,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 22,
                ),
                Text(
                  'WE BUILD\nDIGITAL\nEXPERIENCES.',
                  style: GoogleFonts
                      .plusJakartaSans(
                    fontSize:
                    mobile ? 44 : 78,
                    height: 0.95,
                    fontWeight:
                    FontWeight.w900,
                    color:
                    Colors.white,
                    letterSpacing:
                    -3,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                ConstrainedBox(
                  constraints:
                  const BoxConstraints(
                    maxWidth: 580,
                  ),
                  child: Text(
                    'A curated showcase of high-performance web systems, bespoke mobile architectures, and immersive brand designs.',
                    style: GoogleFonts
                        .plusJakartaSans(
                      fontSize:
                      mobile
                          ? 14
                          : 15,
                      height: 1.65,
                      color:
                      Colors.white60,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left:
            mobile ? 20 : 64,
            right:
            mobile ? 20 : 64,
            child: Row(
              mainAxisAlignment:
              MainAxisAlignment
                  .spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration:
                      const BoxDecoration(
                        shape:
                        BoxShape.circle,
                        color: AppTheme
                            .brandRed,
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Text(
                      '$totalProjects WORKS ARCHIVED',
                      style: GoogleFonts
                          .plusJakartaSans(
                        fontSize: 10,
                        fontWeight:
                        FontWeight.bold,
                        color: Colors
                            .white54,
                        letterSpacing:
                        2,
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
// FEATURED CARD
// ============================================================================

class _FeaturedProjectHeroCard
    extends StatefulWidget {
  final Map<String, dynamic> item;
  final String displayName;
  final VoidCallback onTap;
  final Function(bool, String)
  onHoverChange;

  const _FeaturedProjectHeroCard({
    required this.item,
    required this.displayName,
    required this.onTap,
    required this.onHoverChange,
  });

  @override
  State<
      _FeaturedProjectHeroCard>
  createState() =>
      _FeaturedProjectHeroCardState();
}

class _FeaturedProjectHeroCardState
    extends State<
        _FeaturedProjectHeroCard> {
  bool _hovering = false;

  @override
  Widget build(
      BuildContext context,
      ) {
    final category =
        widget.item['category']
            ?.toString()
            .toUpperCase() ??
            'FEATURED';

    final media =
    _getCardMediaUrl(
      widget.item,
    );

    final width =
        MediaQuery.of(context)
            .size
            .width;

    final mobile =
        width < 768;

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _hovering = true;
        });

        widget.onHoverChange(
          true,
          'EXPLORE',
        );
      },
      onExit: (_) {
        setState(() {
          _hovering = false;
        });

        widget.onHoverChange(
          false,
          '',
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child:
        AnimatedContainer(
          duration:
          const Duration(
            milliseconds: 220,
          ),
          height:
          mobile ? 260 : 440,
          transform:
          Matrix4.identity()
            ..translate(
              0,
              _hovering ? -5 : 0,
            ),
          decoration:
          BoxDecoration(
            borderRadius:
            BorderRadius.circular(
                24),
            border: Border.all(
              color: _hovering
                  ? AppTheme
                  .brandRed
                  : Colors.white
                  .withOpacity(
                  0.1),
            ),
          ),
          child: ClipRRect(
            borderRadius:
            BorderRadius.circular(
                24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _PortfolioMedia(
                  url: media,
                  fit: BoxFit.cover,
                  autoplay: false,
                  muted: true,
                ),
                Container(
                  decoration:
                  BoxDecoration(
                    gradient:
                    LinearGradient(
                      begin:
                      Alignment
                          .topCenter,
                      end:
                      Alignment
                          .bottomCenter,
                      colors: [
                        Colors
                            .transparent,
                        Colors.black
                            .withOpacity(
                            0.88),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 24,
                  child: Row(
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
                                fontSize:
                                9,
                                fontWeight:
                                FontWeight
                                    .w800,
                                color: AppTheme
                                    .brandRed,
                                letterSpacing:
                                1.8,
                              ),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            Text(
                              widget
                                  .displayName,
                              maxLines:
                              1,
                              overflow:
                              TextOverflow
                                  .ellipsis,
                              style: GoogleFonts
                                  .plusJakartaSans(
                                fontSize:
                                mobile
                                    ? 22
                                    : 30,
                                fontWeight:
                                FontWeight
                                    .w800,
                                color:
                                Colors
                                    .white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 46,
                        height: 46,
                        decoration:
                        const BoxDecoration(
                          shape:
                          BoxShape
                              .circle,
                          color: AppTheme
                              .brandRed,
                        ),
                        child:
                        const Icon(
                          Icons
                              .arrow_outward_rounded,
                          color:
                          Colors.white,
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
// REEL
// ============================================================================

class _HorizontalProjectReel
    extends StatelessWidget {
  final List<Map<String, dynamic>>
  items;
  final String Function(
      Map<String, dynamic>,
      ) getItemDisplayName;
  final Function(
      Map<String, dynamic>,
      ) onTapItem;
  final Function(bool, String)
  onHoverItem;

  const _HorizontalProjectReel({
    required this.items,
    required this.getItemDisplayName,
    required this.onTapItem,
    required this.onHoverItem,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final mobile =
        MediaQuery.of(context)
            .size
            .width <
            768;

    final visible =
    items.take(8).toList();

    return SizedBox(
      height:
      mobile ? 220 : 280,
      child: ListView.builder(
        scrollDirection:
        Axis.horizontal,
        physics:
        const BouncingScrollPhysics(),
        padding:
        EdgeInsets.symmetric(
          horizontal:
          mobile ? 18 : 64,
        ),
        itemCount:
        visible.length,
        itemBuilder:
            (context, index) {
          final item =
          visible[index];

          return Padding(
            padding:
            const EdgeInsets.only(
              right: 16,
            ),
            child: _ReelCard(
              title:
              getItemDisplayName(
                item,
              ),
              media:
              _getCardMediaUrl(
                item,
              ),
              category:
              item['category']
                  ?.toString() ??
                  '',
              onTap: () =>
                  onTapItem(item),
              onHover:
                  (hovering) {
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
  State<_ReelCard> createState() =>
      _ReelCardState();
}

class _ReelCardState
    extends State<_ReelCard> {
  bool _hovering = false;

  @override
  Widget build(
      BuildContext context,
      ) {
    final mobile =
        MediaQuery.of(context)
            .size
            .width <
            768;

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _hovering = true;
        });

        widget.onHover(true);
      },
      onExit: (_) {
        setState(() {
          _hovering = false;
        });

        widget.onHover(false);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child:
        AnimatedContainer(
          duration:
          const Duration(
            milliseconds: 200,
          ),
          width:
          mobile ? 200 : 280,
          transform:
          Matrix4.identity()
            ..translate(
              0,
              _hovering ? -5 : 0,
            ),
          decoration:
          BoxDecoration(
            borderRadius:
            BorderRadius.circular(
                18),
            border: Border.all(
              color: _hovering
                  ? AppTheme
                  .brandRed
                  : Colors.white
                  .withOpacity(
                  0.08),
            ),
          ),
          child: ClipRRect(
            borderRadius:
            BorderRadius.circular(
                18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _PortfolioMedia(
                  url: widget.media,
                  fit: BoxFit.cover,
                ),
                Container(
                  decoration:
                  BoxDecoration(
                    gradient:
                    LinearGradient(
                      begin:
                      Alignment
                          .topCenter,
                      end:
                      Alignment
                          .bottomCenter,
                      colors: [
                        Colors
                            .transparent,
                        Colors.black
                            .withOpacity(
                            0.9),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  bottom: 14,
                  right: 14,
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
                          fontSize: 8,
                          fontWeight:
                          FontWeight
                              .w800,
                          color: AppTheme
                              .brandRed,
                          letterSpacing:
                          1.8,
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        widget.title,
                        maxLines: 2,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style: GoogleFonts
                            .plusJakartaSans(
                          fontSize: 15,
                          fontWeight:
                          FontWeight
                              .w700,
                          color: Colors
                              .white,
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
  final String displayName;
  final VoidCallback onTap;
  final Function(bool, String)
  onHoverChange;

  const _EditorialGridCard({
    super.key,
    required this.item,
    required this.displayName,
    required this.onTap,
    required this.onHoverChange,
  });

  @override
  State<_EditorialGridCard>
  createState() =>
      _EditorialGridCardState();
}

class _EditorialGridCardState
    extends State<
        _EditorialGridCard> {
  bool _hovering = false;

  @override
  Widget build(
      BuildContext context,
      ) {
    final media =
    _getCardMediaUrl(
      widget.item,
    );

    final category =
        widget.item['category']
            ?.toString() ??
            '';

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _hovering = true;
        });

        widget.onHoverChange(
          true,
          'OPEN',
        );
      },
      onExit: (_) {
        setState(() {
          _hovering = false;
        });

        widget.onHoverChange(
          false,
          '',
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child:
        AnimatedContainer(
          duration:
          const Duration(
            milliseconds: 200,
          ),
          transform:
          Matrix4.identity()
            ..translate(
              0,
              _hovering ? -5 : 0,
            ),
          decoration:
          BoxDecoration(
            color:
            AppTheme.darkCard,
            borderRadius:
            BorderRadius.circular(
                18),
            border: Border.all(
              color: _hovering
                  ? AppTheme
                  .brandRed
                  : AppTheme
                  .greyBorder,
            ),
          ),
          child: ClipRRect(
            borderRadius:
            BorderRadius.circular(
                18),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _PortfolioMedia(
                        url: media,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child:
                        AnimatedContainer(
                          duration:
                          const Duration(
                            milliseconds:
                            180,
                          ),
                          width: 36,
                          height: 36,
                          decoration:
                          BoxDecoration(
                            shape:
                            BoxShape
                                .circle,
                            color: _hovering
                                ? AppTheme
                                .brandRed
                                : Colors.black
                                .withOpacity(
                                0.6),
                          ),
                          child:
                          const Icon(
                            Icons
                                .arrow_outward_rounded,
                            size: 16,
                            color: Colors
                                .white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 16,
                    vertical: 14,
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
                          fontSize: 8,
                          fontWeight:
                          FontWeight
                              .w800,
                          color: AppTheme
                              .brandRed,
                          letterSpacing:
                          1.8,
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        widget.displayName,
                        maxLines: 1,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style: GoogleFonts
                            .plusJakartaSans(
                          fontSize: 15,
                          fontWeight:
                          FontWeight
                              .w700,
                          color: Colors
                              .white,
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
// TICKER
// ============================================================================

class _MarqueeTicker
    extends StatelessWidget {
  final AnimationController
  controller;

  const _MarqueeTicker({
    required this.controller,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    const items = [
      'UI/UX ARCHITECTURE',
      'HIGH-PERFORMANCE MOBILE',
      'SCALABLE WEB PLATFORMS',
      'BESPOKE BRANDING',
      'CINEMATIC VIDEO EDITING',
    ];

    return AnimatedBuilder(
      animation: controller,
      builder: (
          context,
          _,
          ) {
        return Container(
          padding:
          const EdgeInsets
              .symmetric(
            vertical: 18,
          ),
          decoration:
          BoxDecoration(
            color: Colors.white
                .withOpacity(
                0.015),
            border:
            Border.symmetric(
              horizontal:
              BorderSide(
                color: Colors
                    .white
                    .withOpacity(
                    0.05),
              ),
            ),
          ),
          child:
          SingleChildScrollView(
            scrollDirection:
            Axis.horizontal,
            physics:
            const NeverScrollableScrollPhysics(),
            child: Row(
              children:
              List.generate(
                3,
                    (_) {
                  return Row(
                    children:
                    items.map(
                          (text) {
                        return Padding(
                          padding:
                          const EdgeInsets
                              .symmetric(
                            horizontal:
                            20,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration:
                                const BoxDecoration(
                                  shape:
                                  BoxShape.circle,
                                  color:
                                  AppTheme.brandRed,
                                ),
                              ),
                              const SizedBox(
                                width: 12,
                              ),
                              Text(
                                text,
                                style: GoogleFonts
                                    .plusJakartaSans(
                                  fontSize:
                                  11,
                                  fontWeight:
                                  FontWeight
                                      .w800,
                                  color: Colors
                                      .white30,
                                  letterSpacing:
                                  2.5,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ).toList(),
                  );
                },
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

class _SectionLabel
    extends StatelessWidget {
  final String text;

  const _SectionLabel({
    required this.text,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Row(
      mainAxisSize:
      MainAxisSize.min,
      children: [
        Container(
          width: 4,
          height: 14,
          decoration:
          BoxDecoration(
            color:
            AppTheme.brandRed,
            borderRadius:
            BorderRadius.circular(
                2),
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Text(
          text,
          style: GoogleFonts
              .plusJakartaSans(
            fontSize: 11,
            fontWeight:
            FontWeight.w800,
            color:
            AppTheme.brandRed,
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// BACKGROUND
// ============================================================================

class _DynamicSpotlightPainter
    extends CustomPainter {
  final double auroraValue;

  _DynamicSpotlightPainter({
    required this.auroraValue,
  });

  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    final center = Offset(
      size.width * 0.85,
      size.height * 0.28 +
          math.sin(
            auroraValue *
                math.pi *
                2,
          ) *
              20,
    );

    final paint = Paint()
      ..shader =
      RadialGradient(
        colors: [
          AppTheme.brandRed
              .withOpacity(0.08),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: center,
          radius:
          size.width * 0.35,
        ),
      );

    canvas.drawCircle(
      center,
      size.width * 0.35,
      paint,
    );
  }

  @override
  bool shouldRepaint(
      covariant
      _DynamicSpotlightPainter
      oldDelegate,
      ) {
    return oldDelegate
        .auroraValue !=
        auroraValue;
  }
}

// ============================================================================
// SKELETON
// ============================================================================

class _PortfolioSkeletonCard
    extends StatelessWidget {
  const _PortfolioSkeletonCard();

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      decoration:
      BoxDecoration(
        color:
        AppTheme.darkCard,
        border: Border.all(
          color:
          AppTheme.greyBorder,
        ),
        borderRadius:
        BorderRadius.circular(
            18),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.white
                  .withOpacity(
                  0.02),
            ),
          ),
          Padding(
            padding:
            const EdgeInsets.all(
                16),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Container(
                  height: 8,
                  width: 50,
                  decoration:
                  BoxDecoration(
                    color: Colors
                        .white
                        .withOpacity(
                        0.06),
                    borderRadius:
                    BorderRadius
                        .circular(
                        10),
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Container(
                  height: 14,
                  width: 120,
                  decoration:
                  BoxDecoration(
                    color: Colors
                        .white
                        .withOpacity(
                        0.06),
                    borderRadius:
                    BorderRadius
                        .circular(
                        10),
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

class _MediaShimmer
    extends StatelessWidget {
  const _MediaShimmer();

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      color:
      AppTheme.darkCard,
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
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      const EdgeInsets
          .symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white
            .withOpacity(0.02),
        borderRadius:
        BorderRadius.circular(
            10),
        border: Border.all(
          color: Colors.white
              .withOpacity(
              0.04),
        ),
      ),
      child: Text(
        name,
        style: GoogleFonts
            .plusJakartaSans(
          fontSize: 11,
          fontWeight:
          FontWeight.w700,
          color:
          Colors.white38,
          letterSpacing: 1.8,
        ),
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
    extends State<
        _PortfolioFinalCta> {
  bool _hovering = false;

  @override
  Widget build(
      BuildContext context,
      ) {
    final mobile =
        MediaQuery.of(context)
            .size
            .width <
            768;

    return Padding(
      padding:
      EdgeInsets.symmetric(
        horizontal:
        mobile ? 18 : 64,
      ),
      child: MouseRegion(
        onEnter: (_) {
          setState(() {
            _hovering = true;
          });

          widget.onHoverItem(
            true,
            'START',
          );
        },
        onExit: (_) {
          setState(() {
            _hovering = false;
          });

          widget.onHoverItem(
            false,
            '',
          );
        },
        child:
        AnimatedContainer(
          duration:
          const Duration(
            milliseconds: 220,
          ),
          padding:
          EdgeInsets.symmetric(
            horizontal:
            mobile ? 22 : 56,
            vertical:
            mobile ? 42 : 68,
          ),
          decoration:
          BoxDecoration(
            borderRadius:
            BorderRadius.circular(
                28),
            color: _hovering
                ? AppTheme
                .brandRed
                : AppTheme
                .darkCard,
            border: Border.all(
              color: _hovering
                  ? AppTheme
                  .brandRed
                  : AppTheme
                  .greyBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,
            children: [
              Text(
                'HAVE AN IDEA?',
                style: GoogleFonts
                    .plusJakartaSans(
                  fontSize: 11,
                  fontWeight:
                  FontWeight.w800,
                  color: _hovering
                      ? Colors.white70
                      : AppTheme
                      .brandRed,
                  letterSpacing:
                  2.5,
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              Text(
                'LET’S MAKE\nIT REAL.',
                style: GoogleFonts
                    .plusJakartaSans(
                  fontSize:
                  mobile ? 40 : 68,
                  height: 0.94,
                  fontWeight:
                  FontWeight.w900,
                  color:
                  Colors.white,
                  letterSpacing:
                  -2.5,
                ),
              ),
              const SizedBox(
                height: 28,
              ),
              Row(
                children: [
                  Text(
                    'START A PROJECT',
                    style: GoogleFonts
                        .plusJakartaSans(
                      fontSize: 11,
                      fontWeight:
                      FontWeight.w800,
                      color:
                      Colors.white,
                      letterSpacing:
                      1.8,
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  const Icon(
                    Icons
                        .arrow_forward_rounded,
                    color:
                    Colors.white,
                    size: 18,
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
// LOADING / ERROR / EMPTY
// ============================================================================

class _PortfolioLoading
    extends StatelessWidget {
  const _PortfolioLoading();

  @override
  Widget build(
      BuildContext context,
      ) {
    return Center(
      child: Column(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          const SizedBox(
            width: 44,
            height: 44,
            child:
            CircularProgressIndicator(
              strokeWidth: 2.5,
              color:
              AppTheme.brandRed,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Text(
            'LOADING THEVAH ARCHIVE...',
            style: GoogleFonts
                .plusJakartaSans(
              fontSize: 11,
              fontWeight:
              FontWeight.bold,
              letterSpacing:
              2.5,
              color:
              Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
}

class _PortfolioError
    extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _PortfolioError({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Center(
      child: Container(
        constraints:
        const BoxConstraints(
          maxWidth: 440,
        ),
        padding:
        const EdgeInsets.all(
            32),
        decoration:
        BoxDecoration(
          color:
          AppTheme.darkCard,
          borderRadius:
          BorderRadius.circular(
              20),
          border: Border.all(
            color: Colors.white
                .withOpacity(
                0.08),
          ),
        ),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            const Icon(
              Icons
                  .cloud_off_rounded,
              size: 36,
              color:
              AppTheme.brandRed,
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              'COULD NOT LOAD PORTFOLIO',
              style: GoogleFonts
                  .plusJakartaSans(
                fontSize: 15,
                fontWeight:
                FontWeight.w800,
                color:
                Colors.white,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              error,
              textAlign:
              TextAlign.center,
              maxLines: 3,
              overflow:
              TextOverflow.ellipsis,
              style: GoogleFonts
                  .plusJakartaSans(
                fontSize: 12,
                height: 1.4,
                color:
                Colors.white54,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed:
              onRetry,
              style:
              ElevatedButton
                  .styleFrom(
                backgroundColor:
                AppTheme
                    .brandRed,
                foregroundColor:
                Colors.white,
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius
                      .circular(
                      12),
                ),
              ),
              child: Text(
                'TRY AGAIN',
                style: GoogleFonts
                    .plusJakartaSans(
                  fontWeight:
                  FontWeight.w700,
                  letterSpacing:
                  1.2,
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

class _PortfolioEmpty
    extends StatelessWidget {
  const _PortfolioEmpty();

  @override
  Widget build(
      BuildContext context,
      ) {
    return Center(
      child: Column(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            Icons
                .inventory_2_outlined,
            size: 42,
            color: Colors.white
                .withOpacity(0.2),
          ),
          const SizedBox(
            height: 14,
          ),
          Text(
            'NO PROJECTS AVAILABLE',
            style: GoogleFonts
                .plusJakartaSans(
              fontSize: 12,
              fontWeight:
              FontWeight.bold,
              color:
              Colors.white54,
              letterSpacing:
              2,
            ),
          ),
        ],
      ),
    );
  }
}
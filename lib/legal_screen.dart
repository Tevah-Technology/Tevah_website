import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tevahweb/shared_widgets.dart';

// ============================================================================
// LEGAL SECTION ANCHORS ENUM
// ============================================================================

enum LegalSection {
  terms,
  refund,
  privacy,
  contact,
}

// ============================================================================
// PREMIUM ALL-IN-ONE LEGAL SCREEN (WITH SCROLL-SPY HIGHLIGHTING)
// ============================================================================

class LegalScreen extends StatefulWidget {
  final LegalSection initialSection;

  const LegalScreen({
    super.key,
    this.initialSection = LegalSection.terms,
  });

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  final ScrollController _scrollController = ScrollController();

  final GlobalKey _termsKey = GlobalKey();
  final GlobalKey _refundKey = GlobalKey();
  final GlobalKey _privacyKey = GlobalKey();
  final GlobalKey _contactKey = GlobalKey();

  LegalSection _activeSection = LegalSection.terms;
  bool _showFloatingNav = false;
  bool _isAutoScrolling = false;

  @override
  void initState() {
    super.initState();
    _activeSection = widget.initialSection;
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSection(widget.initialSection, animated: false);
    });
  }

  void _onScroll() {
    // 1. Toggle floating nav bar appearance
    if (_scrollController.offset > 280 && !_showFloatingNav) {
      setState(() => _showFloatingNav = true);
    } else if (_scrollController.offset <= 280 && _showFloatingNav) {
      setState(() => _showFloatingNav = false);
    }

    // 2. Real-time ScrollSpy to highlight the active section pill
    if (_isAutoScrolling) return;

    final double triggerLine = MediaQuery.of(context).size.height * 0.35;

    double getY(GlobalKey key) {
      final context = key.currentContext;
      if (context == null) return double.infinity;
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.hasSize) return double.infinity;
      return renderBox.localToGlobal(Offset.zero).dy;
    }

    final termsY = getY(_termsKey);
    final refundY = getY(_refundKey);
    final privacyY = getY(_privacyKey);
    final contactY = getY(_contactKey);

    LegalSection currentSection = _activeSection;

    if (contactY <= triggerLine) {
      currentSection = LegalSection.contact;
    } else if (privacyY <= triggerLine) {
      currentSection = LegalSection.privacy;
    } else if (refundY <= triggerLine) {
      currentSection = LegalSection.refund;
    } else if (termsY <= triggerLine || _scrollController.offset < 400) {
      currentSection = LegalSection.terms;
    }

    if (currentSection != _activeSection) {
      setState(() {
        _activeSection = currentSection;
      });
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _scrollToSection(LegalSection section, {bool animated = true}) async {
    setState(() {
      _activeSection = section;
      _isAutoScrolling = true;
    });

    GlobalKey targetKey;
    switch (section) {
      case LegalSection.terms:
        targetKey = _termsKey;
        break;
      case LegalSection.refund:
        targetKey = _refundKey;
        break;
      case LegalSection.privacy:
        targetKey = _privacyKey;
        break;
      case LegalSection.contact:
        targetKey = _contactKey;
        break;
    }

    final targetContext = targetKey.currentContext;
    if (targetContext != null) {
      if (animated) {
        await Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
          alignment: 0.08,
        );
      } else {
        await Scrollable.ensureVisible(
          targetContext,
          alignment: 0.08,
        );
      }
    }

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _isAutoScrolling = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: const Color(0xFF070709),
      body: Stack(
        children: [
          // Background Atmospheric Mesh
          Positioned(
            top: -120,
            left: screenWidth * 0.15,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.brandRed.withOpacity(0.08),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 140, sigmaY: 140),
                child: const SizedBox.shrink(),
              ),
            ),
          ),
          Positioned(
            top: 600,
            right: -100,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.02),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
                child: const SizedBox.shrink(),
              ),
            ),
          ),

          // Main Scrollable Area
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                const TevahNavbar(currentRoute: NavRoute.legal),

                // Hero Header Banner
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 20.0 : 64.0,
                    isMobile ? 24.0 : 48.0,
                    isMobile ? 20.0 : 64.0,
                    32.0,
                  ),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1040),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.brandRed.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: AppTheme.brandRed.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppTheme.brandRed,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'OFFICIAL COMPLIANCE & LEGAL PORTAL',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.brandRed,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Website Policies\n& Master Terms',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: isMobile ? 36 : 56,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              size: 14,
                              color: Colors.white38,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Effective & Updated: August 20, 2026',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white38,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'These Website Policies & Master Terms govern the digital and engineering services provided by TEVAH TECH SOLUTIONS PRIVATE LIMITED ("TEVAH", "we", "us", or "our"). By visiting our site, accessing deliverables, or approving proposals, you agree to these transparent terms.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            height: 1.7,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Section Anchor Jump Pills (Updated in real-time)
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _HeaderNavPill(
                              title: '1. Terms of Service',
                              icon: Icons.gavel_rounded,
                              isActive: _activeSection == LegalSection.terms,
                              onTap: () => _scrollToSection(LegalSection.terms),
                            ),
                            _HeaderNavPill(
                              title: '2. Cancellation & Refund',
                              icon: Icons.currency_exchange_rounded,
                              isActive: _activeSection == LegalSection.refund,
                              onTap: () => _scrollToSection(LegalSection.refund),
                            ),
                            _HeaderNavPill(
                              title: '3. Privacy Policy',
                              icon: Icons.shield_rounded,
                              isActive: _activeSection == LegalSection.privacy,
                              onTap: () => _scrollToSection(LegalSection.privacy),
                            ),
                            _HeaderNavPill(
                              title: '4. Contact & Office',
                              icon: Icons.business_rounded,
                              isActive: _activeSection == LegalSection.contact,
                              onTap: () => _scrollToSection(LegalSection.contact),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(color: AppTheme.greyBorder),

                // Main Content Block
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16.0 : 64.0,
                    vertical: 48.0,
                  ),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1040),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. TERMS OF SERVICE
                        Container(
                          key: _termsKey,
                          child: _PolicyBentoCard(
                            badgeText: 'CORE CONTRACT TERMS',
                            sectionTitle: 'Terms of Service & Engineering',
                            children: const [
                              _ModernLegalItem(
                                number: '01',
                                title: 'About TEVAH',
                                body:
                                'TEVAH TECH SOLUTIONS PRIVATE LIMITED is an India-based technology and digital solutions enterprise providing scalable technology services to businesses, organizations, churches, nonprofits, and partners globally.',
                                bulletPoints: [
                                  'Website design and development',
                                  'Web application development',
                                  'Custom software development',
                                  'Software integration',
                                  'Artificial intelligence and automation solutions',
                                  'Workflow automation',
                                  'Cloud-based solutions',
                                  'Website hosting and infrastructure management',
                                  'Website maintenance and technical support',
                                  'UI/UX and digital design',
                                  'Digital media and creative services',
                                  'IT consulting and technology implementation',
                                  'Digital marketing-related technology services',
                                  'Training and technical assistance',
                                  'Other technology services agreed upon with clients',
                                ],
                              ),
                              _ModernLegalItem(
                                number: '02',
                                title: 'Contact Information',
                                body:
                                'For queries regarding projects, payments, or terms:\nTEVAH TECH SOLUTIONS PRIVATE LIMITED\nRegistered Office: KCRA 41A Riju House, Chamavila, Karakulam P O, Trivandrum, Kerala 695564\nCustomer Support: +91 91880 75549\nEmail: info@tevah.technology\nWebsite: https://tevah.technology/',
                              ),
                              _ModernLegalItem(
                                number: '03',
                                title: 'Service Terms & Quotations',
                                body:
                                'All services are governed by the agreed statements of work (SOW), estimates, and invoices. Changes in functionality or requirements requested beyond the baseline scope will be estimated as additional billable increments.',
                              ),
                              _ModernLegalItem(
                                number: '04',
                                title: 'Quotations and Proposals',
                                body:
                                'Proposals reflect specifications known at creation. A project is confirmed once the client approves the quotation, signs an agreement, or completes initial milestone deposits.',
                              ),
                              _ModernLegalItem(
                                number: '05',
                                title: 'Payment Milestones & Overdue Invoices',
                                body:
                                'Advance & Milestone Payments: Dedicated resources and third-party tools are provisioned upon deposit settlement. Completed milestones require approval and settlement before following stages begin.\nFinal Deployment: Code releases, credentials, and live production deployment occur upon final payment receipt.\nOverdue Invoices: Unpaid balances may pause active work schedules until settled.',
                              ),
                              _ModernLegalItem(
                                number: '06',
                                title: 'Transaction Currencies',
                                body:
                                'Transactions via Zoho Payments or Indian gateways are charged in INR (Indian Rupees). International clients may be invoiced in USD or custom agreed currencies. Foreign conversion charges are determined by your card provider/bank.',
                              ),
                              _ModernLegalItem(
                                number: '07',
                                title: 'Taxes & Statutory Filings',
                                body:
                                'Statutory Goods & Services Tax (GST) is charged wherever applicable under Indian law and itemized distinctly on formal tax invoices.',
                              ),
                              _ModernLegalItem(
                                number: '08',
                                title: 'Third-Party Costs & Integrations',
                                body:
                                'Third-party software, domain registrations, cloud hosting, APIs, premium plugins, and SaaS subscriptions are subject to respective provider pricing and policy changes outside TEVAH\'s direct control.',
                              ),
                              _ModernLegalItem(
                                number: '09',
                                title: 'Digital Service Delivery',
                                body:
                                'We deliver digital code repositories, website installations, and cloud platforms electronically. Timelines depend upon prompt provision of client assets, credentials, and stage feedback.',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 48),

                        // 2. CANCELLATION & REFUNDS
                        Container(
                          key: _refundKey,
                          child: _PolicyBentoCard(
                            badgeText: 'SETTLEMENTS & GUARANTEES',
                            sectionTitle: 'Cancellation, Refunds & Revisions',
                            children: const [
                              _ModernLegalItem(
                                number: '10',
                                title: 'Cancellation Policy',
                                body:
                                'Prior to Kickoff: Cancellations submitted prior to sprint initiation qualify for refunds minus planning, administrative, and third-party tooling fees.\nAfter Work Commenced: Clients are billed for hours and milestones completed up to the written cancellation notice. Unallocated balances will be refunded.',
                              ),
                              _ModernLegalItem(
                                number: '11',
                                title: 'Refund Policy & Timelines',
                                body:
                                'Non-Refundable: Approved milestones, completed architecture, hours worked, domain registrations, server setup fees, and API licenses cannot be refunded.\nProcessing: Approved refunds are initiated within 7–10 business days directly to the original payment method.',
                              ),
                              _ModernLegalItem(
                                number: '12',
                                title: 'Returns and Digital Replacements',
                                body:
                                'As digital engineers, traditional physical returns do not apply. Any verified defect within the agreed project scope will be audited and resolved promptly.',
                              ),
                              _ModernLegalItem(
                                number: '13',
                                title: 'Revisions and Approvals',
                                body:
                                'Each phase includes defined feedback cycles. Requests submitted after sign-off will be estimated as separate change requests.',
                              ),
                              _ModernLegalItem(
                                number: '14',
                                title: 'Client Responsibilities & Rights',
                                body:
                                'Clients warrant that all supplied text, branding, and images do not violate copyright, trademarks, or confidentiality agreements.',
                              ),
                              _ModernLegalItem(
                                number: '15',
                                title: 'Intellectual Property Rights',
                                body:
                                'Custom project deliverables transfer entirely to the client upon 100% financial settlement. TEVAH retains proprietary ownership of its reusable component libraries and underlying design systems.',
                              ),
                              _ModernLegalItem(
                                number: '16',
                                title: 'Confidentiality & Non-Disclosure',
                                body:
                                'All proprietary source code, credentials, and strategic briefs are protected under commercial confidentiality guidelines.',
                              ),
                              _ModernLegalItem(
                                number: '17',
                                title: 'Third-Party Platforms',
                                body:
                                'TEVAH does not guarantee uninterrupted operational uptime of independent third-party server environments or external SaaS APIs.',
                              ),
                              _ModernLegalItem(
                                number: '18',
                                title: 'Website and Service Availability',
                                body:
                                'Routine scheduled updates and maintenance may cause temporary, brief portal interruptions.',
                              ),
                              _ModernLegalItem(
                                number: '19',
                                title: 'Limitation of Liability',
                                body:
                                'To the fullest extent of the law, TEVAH is not liable for incidental, indirect, or third-party outage damages.',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 48),

                        // 3. PRIVACY POLICY
                        Container(
                          key: _privacyKey,
                          child: _PolicyBentoCard(
                            badgeText: 'SECURITY & DATA GOVERNANCE',
                            sectionTitle: 'Privacy Policy & Data Security',
                            children: const [
                              _ModernLegalItem(
                                number: '20',
                                title: 'Information We Collect',
                                body:
                                'We collect standard business communication information including: Name, Organization, Email, Telephone, Billing Information, Scope Briefs, and IP/Browser telemetry.',
                              ),
                              _ModernLegalItem(
                                number: '21',
                                title: 'How We Utilize Your Data',
                                body:
                                'Information is strictly used to fulfill engineering milestones, process payments, provide ongoing support, and fulfill statutory tax mandates.',
                              ),
                              _ModernLegalItem(
                                number: '22',
                                title: 'Payment Data Privacy',
                                body:
                                'Complete payment card details are encrypted directly via PCI-DSS compliant payment gateways. TEVAH never stores raw credit/debit numbers on its servers.',
                              ),
                              _ModernLegalItem(
                                number: '23',
                                title: 'No Sale of Personal Data',
                                body:
                                'We do not monetize, rent, or sell personal records. We share telemetry only with verified infrastructure providers (e.g. AWS, Zoho, Cloudflare).',
                              ),
                              _ModernLegalItem(
                                number: '24',
                                title: 'Data Security Practices',
                                body:
                                'We use modern cryptographic standards, automated vulnerability monitoring, and segmented internal roles.',
                              ),
                              _ModernLegalItem(
                                number: '25',
                                title: 'Data Retention Guidelines',
                                body:
                                'Files and transaction records are preserved only as long as required for contractual warranty, audits, and statutory tax laws.',
                              ),
                              _ModernLegalItem(
                                number: '26',
                                title: 'Cookies & Analytics',
                                body:
                                'Essential cookies are utilized to deliver user sessions and optimize platform rendering.',
                              ),
                              _ModernLegalItem(
                                number: '27',
                                title: 'Your Privacy Rights',
                                body:
                                'You may request access, correction, or deletion of your personal records at any time by emailing info@tevah.technology.',
                              ),
                              _ModernLegalItem(
                                number: '28',
                                title: 'Children\'s Privacy',
                                body:
                                'Our enterprise services are intended exclusively for commercial organizations and businesses.',
                              ),
                              _ModernLegalItem(
                                number: '29',
                                title: 'External Web Links',
                                body:
                                'We are not responsible for privacy standards on third-party sites linked from our platforms.',
                              ),
                              _ModernLegalItem(
                                number: '30',
                                title: 'Acceptable Network Usage',
                                body:
                                'Users are prohibited from attempting reverse engineering, scraping, or launching malicious intrusions against our infrastructure.',
                              ),
                              _ModernLegalItem(
                                number: '31',
                                title: 'Policy Amendments',
                                body:
                                'Periodic revisions will be published here with an updated Effective Date stamp.',
                              ),
                              _ModernLegalItem(
                                number: '32',
                                title: 'Governing Law & Legal Jurisdiction',
                                body:
                                'These policies are governed by the laws of India. Disputes are subject to the exclusive jurisdiction of the competent courts in Kerala, India.',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 48),

                        // 4. CONTACT & REGISTERED OFFICE
                        Container(
                          key: _contactKey,
                          child: _PolicyBentoCard(
                            badgeText: 'CORPORATE VERIFICATION',
                            sectionTitle: 'Registered Corporate Office & Support',
                            children: const [
                              _ModernLegalItem(
                                number: '33',
                                title: 'Official Inquiries & Grievances',
                                body:
                                'TEVAH TECH SOLUTIONS PRIVATE LIMITED\n\nRegistered Office Address:\nKCRA 41A Riju House, Chamavila, Karakulam P O, Trivandrum, Kerala 695564\n\nDirect Support Line: +91 91880 75549\nOfficial Compliance Email: info@tevah.technology\nCorporate Portal: https://tevah.technology/',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 80),
                const AgencyFooter(),
              ],
            ),
          ),

          // Floating Navigation Quick-Dock (Real-time highlight synced)
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedOpacity(
                opacity: _showFloatingNav ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: IgnorePointer(
                  ignoring: !_showFloatingNav,
                  child: _FloatingLegalQuickDock(
                    activeSection: _activeSection,
                    onScrollToTop: _scrollToTop,
                    onNavigate: _scrollToSection,
                  ),
                ),
              ),
            ),
          ),

          const FloatingWhatsAppButton(),
        ],
      ),
    );
  }
}

// ============================================================================
// FLOATING QUICK-DOCK NAVIGATION PILL
// ============================================================================

class _FloatingLegalQuickDock extends StatelessWidget {
  final LegalSection activeSection;
  final VoidCallback onScrollToTop;
  final ValueChanged<LegalSection> onNavigate;

  const _FloatingLegalQuickDock({
    required this.activeSection,
    required this.onScrollToTop,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;

    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF141416).withOpacity(0.88),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Back To Top Arrow Button
              _DockIconButton(
                icon: Icons.arrow_upward_rounded,
                tooltip: 'Back to Top',
                onTap: onScrollToTop,
              ),

              Container(
                height: 20,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: Colors.white12,
              ),

              // Dynamic Indicator Pills
              _DockItem(
                label: isMobile ? 'Terms' : 'Terms of Service',
                isActive: activeSection == LegalSection.terms,
                onTap: () => onNavigate(LegalSection.terms),
              ),
              _DockItem(
                label: isMobile ? 'Refunds' : 'Cancellation & Refund',
                isActive: activeSection == LegalSection.refund,
                onTap: () => onNavigate(LegalSection.refund),
              ),
              _DockItem(
                label: isMobile ? 'Privacy' : 'Privacy Policy',
                isActive: activeSection == LegalSection.privacy,
                onTap: () => onNavigate(LegalSection.privacy),
              ),
              _DockItem(
                label: isMobile ? 'Office' : 'Office & Contact',
                isActive: activeSection == LegalSection.contact,
                onTap: () => onNavigate(LegalSection.contact),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _DockIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_DockIconButton> createState() => _DockIconButtonState();
}

class _DockIconButtonState extends State<_DockIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _hovered ? AppTheme.brandRed : Colors.white.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.icon,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatefulWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DockItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_DockItem> createState() => _DockItemState();
}

class _DockItemState extends State<_DockItem> {
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
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppTheme.brandRed
                : (_hovered ? Colors.white.withOpacity(0.08) : Colors.transparent),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isActive
                  ? AppTheme.brandRed
                  : (_hovered ? Colors.white24 : Colors.transparent),
            ),
            boxShadow: widget.isActive
                ? [
              BoxShadow(
                color: AppTheme.brandRed.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ]
                : [],
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
              color: widget.isActive
                  ? Colors.white
                  : (_hovered ? Colors.white : Colors.white60),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// HEADER NAVIGATION PILL (WITH SMOOTH REAL-TIME ACTIVE STATE)
// ============================================================================

class _HeaderNavPill extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _HeaderNavPill({
    required this.title,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_HeaderNavPill> createState() => _HeaderNavPillState();
}

class _HeaderNavPillState extends State<_HeaderNavPill> {
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
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppTheme.brandRed
                : (_hovered
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.03)),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: widget.isActive
                  ? AppTheme.brandRed
                  : (_hovered
                  ? AppTheme.brandRed.withOpacity(0.5)
                  : AppTheme.greyBorder),
            ),
            boxShadow: widget.isActive
                ? [
              BoxShadow(
                color: AppTheme.brandRed.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 15,
                color: widget.isActive || _hovered
                    ? Colors.white
                    : Colors.white70,
              ),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: widget.isActive ? FontWeight.w800 : FontWeight.w600,
                  color: widget.isActive || _hovered
                      ? Colors.white
                      : Colors.white70,
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
// BENTO STYLE POLICY CARD CONTAINER
// ============================================================================

class _PolicyBentoCard extends StatelessWidget {
  final String badgeText;
  final String sectionTitle;
  final List<Widget> children;

  const _PolicyBentoCard({
    required this.badgeText,
    required this.sectionTitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF101013),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.brandRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.brandRed,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_outward_rounded,
                size: 16,
                color: Colors.white24,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            sectionTitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: AppTheme.greyBorder),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

// ============================================================================
// INDIVIDUAL LEGAL ITEM (CLEAN TYPOGRAPHY HIERARCHY)
// ============================================================================

class _ModernLegalItem extends StatelessWidget {
  final String number;
  final String title;
  final String body;
  final List<String>? bulletPoints;

  const _ModernLegalItem({
    required this.number,
    required this.title,
    required this.body,
    this.bulletPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              number,
              style: GoogleFonts.firaCode(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.brandRed,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    height: 1.65,
                    color: Colors.white70,
                  ),
                ),
                if (bulletPoints != null && bulletPoints!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: bulletPoints!.map((item) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.025),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Text(
                          '• $item',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
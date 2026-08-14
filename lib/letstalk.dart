import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'environmental.dart';
import 'shared_widgets.dart';

void openLetsTalkModal(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => const LetsTalkModal(),
  );
}

// ============================================================
// COUNTRY DATA
// ============================================================

class CountryData {
  final String name;
  final String code;
  final String flag;

  const CountryData({
    required this.name,
    required this.code,
    required this.flag,
  });
}

// ============================================================
// LET'S TALK MODAL
// ============================================================

class LetsTalkModal extends StatefulWidget {
  const LetsTalkModal({super.key});

  @override
  State<LetsTalkModal> createState() => _LetsTalkModalState();
}

class _LetsTalkModalState extends State<LetsTalkModal> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController =
  TextEditingController();

  final TextEditingController _lastNameController =
  TextEditingController();

  final TextEditingController _phoneController =
  TextEditingController();

  final TextEditingController _emailController =
  TextEditingController();

  final TextEditingController _messageController =
  TextEditingController();

  // ============================================================
  // SELECTED COUNTRY
  // ============================================================

  CountryData _selectedCountry = const CountryData(
    name: 'United States',
    code: '+1',
    flag: '🇺🇸',
  );

  // ============================================================
  // COUNTRIES
  // ============================================================

  static const List<CountryData> _allCountries = [
    CountryData(
      name: 'United States',
      code: '+1',
      flag: '🇺🇸',
    ),
    CountryData(
      name: 'India',
      code: '+91',
      flag: '🇮🇳',
    ),
    CountryData(
      name: 'United Kingdom',
      code: '+44',
      flag: '🇬🇧',
    ),
    CountryData(
      name: 'Australia',
      code: '+61',
      flag: '🇦🇺',
    ),
    CountryData(
      name: 'Canada',
      code: '+1',
      flag: '🇨🇦',
    ),
    CountryData(
      name: 'Germany',
      code: '+49',
      flag: '🇩🇪',
    ),
    CountryData(
      name: 'France',
      code: '+33',
      flag: '🇫🇷',
    ),
    CountryData(
      name: 'United Arab Emirates',
      code: '+971',
      flag: '🇦🇪',
    ),
    CountryData(
      name: 'Singapore',
      code: '+65',
      flag: '🇸🇬',
    ),
    CountryData(
      name: 'Japan',
      code: '+81',
      flag: '🇯🇵',
    ),
    CountryData(
      name: 'Brazil',
      code: '+55',
      flag: '🇧🇷',
    ),
    CountryData(
      name: 'South Africa',
      code: '+27',
      flag: '🇿🇦',
    ),
    CountryData(
      name: 'Saudi Arabia',
      code: '+966',
      flag: '🇸🇦',
    ),
    CountryData(
      name: 'Italy',
      code: '+39',
      flag: '🇮🇹',
    ),
    CountryData(
      name: 'Spain',
      code: '+34',
      flag: '🇪🇸',
    ),
    CountryData(
      name: 'China',
      code: '+86',
      flag: '🇨🇳',
    ),
    CountryData(
      name: 'Mexico',
      code: '+52',
      flag: '🇲🇽',
    ),
  ];

  bool _isSubmitting = false;

  // ============================================================
  // EMAILJS CONFIGURATION
  // ============================================================

  static String _emailJsServiceId = Gmail_Service_ID;
  static String _emailJsTemplateId = Gmail_Template_ID;
  static String _emailJsPublicKey = Gmail_Public_KEY;

  // ============================================================
  // COUNTRY PICKER
  // ============================================================

  void _openCountryPickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return _CountryPickerBottomSheet(
          countries: _allCountries,
          onSelect: (country) {
            setState(() {
              _selectedCountry = country;
            });

            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  // ============================================================
  // SUBMIT FORM
  // ============================================================

  void _submitForm() async {
    debugPrint('');
    debugPrint('==========================================');
    debugPrint('🚀 SUBMIT FORM STARTED');
    debugPrint('==========================================');

    // ----------------------------------------------------------
    // VALIDATION
    // ----------------------------------------------------------

    final bool isValid =
        _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      debugPrint('❌ FORM VALIDATION FAILED');
      debugPrint('==========================================');

      return;
    }

    debugPrint('✅ FORM VALIDATION PASSED');

    setState(() {
      _isSubmitting = true;
    });

    // ----------------------------------------------------------
    // EMAILJS URL
    // ----------------------------------------------------------

    final Uri url = Uri.parse(
      'https://api.emailjs.com/api/v1.0/email/send',
    );

    // ----------------------------------------------------------
    // FORM DATA
    // ----------------------------------------------------------

    final String firstName =
    _firstNameController.text.trim();

    final String lastName =
    _lastNameController.text.trim();

    final String fullName =
    '$firstName $lastName'.trim();

    final String phoneInput =
    _phoneController.text.trim();

    final String fullPhoneNumber = phoneInput.isNotEmpty
        ? '${_selectedCountry.flag} '
        '${_selectedCountry.code} '
        '$phoneInput'
        : 'N/A';

    final String emailInput =
    _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : 'N/A';

    final String message =
    _messageController.text.trim();

    // ----------------------------------------------------------
    // DEBUG LOG
    // ----------------------------------------------------------

    debugPrint('');
    debugPrint('📋 FORM DATA');
    debugPrint('------------------------------------------');
    debugPrint('👤 First Name : $firstName');
    debugPrint('👤 Last Name  : $lastName');
    debugPrint('👤 Full Name  : $fullName');
    debugPrint('📧 Email      : $emailInput');
    debugPrint('📱 Phone      : $fullPhoneNumber');
    debugPrint('📝 Message    : $message');
    debugPrint('🌍 Country    : ${_selectedCountry.name}');
    debugPrint('🌍 Dial Code  : ${_selectedCountry.code}');
    debugPrint('------------------------------------------');

    // ----------------------------------------------------------
    // EMAILJS CONFIG DEBUG
    // ----------------------------------------------------------

    debugPrint('');
    debugPrint('🔧 EMAILJS CONFIGURATION');
    debugPrint('------------------------------------------');
    debugPrint('Service ID : $_emailJsServiceId');
    debugPrint('Template ID: $_emailJsTemplateId');

    // Don't print public key unnecessarily.
    debugPrint(
      'Public Key : ${_emailJsPublicKey.isNotEmpty ? "AVAILABLE" : "EMPTY"}',
    );

    debugPrint('------------------------------------------');

    try {
      // --------------------------------------------------------
      // REQUEST BODY
      // --------------------------------------------------------

      final Map<String, dynamic> requestBody = {
        'service_id': _emailJsServiceId,
        'template_id': _emailJsTemplateId,
        'user_id': _emailJsPublicKey,
        'template_params': {
          'name': fullName,
          'email': emailInput,
          'phone': fullPhoneNumber,
          'message': message,
          'time': DateTime.now()
              .toString()
              .split('.')
              .first,
        },
      };

      debugPrint('');
      debugPrint('📤 SENDING REQUEST TO EMAILJS');
      debugPrint('==========================================');

      debugPrint(
        'URL: $url',
      );

      debugPrint(
        'Method: POST',
      );

      debugPrint(
        'Headers: Content-Type: application/json',
      );

      debugPrint('');
      debugPrint('📦 REQUEST BODY:');
      debugPrint(
        const JsonEncoder.withIndent('  ')
            .convert(requestBody),
      );

      // --------------------------------------------------------
      // HTTP REQUEST
      // --------------------------------------------------------

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost',
        },
        body: jsonEncode(requestBody),
      );

      // --------------------------------------------------------
      // RESPONSE DEBUG
      // --------------------------------------------------------

      debugPrint('');
      debugPrint('📥 EMAILJS RESPONSE');
      debugPrint('==========================================');

      debugPrint(
        'Status Code: ${response.statusCode}',
      );

      debugPrint(
        'Response Body: ${response.body}',
      );

      debugPrint(
        'Response Headers: ${response.headers}',
      );

      debugPrint('==========================================');

      if (!mounted) {
        debugPrint(
          '⚠️ Widget is no longer mounted.',
        );

        return;
      }

      setState(() {
        _isSubmitting = false;
      });

      // --------------------------------------------------------
      // SUCCESS
      // --------------------------------------------------------

      if (response.statusCode == 200) {
        debugPrint('');
        debugPrint('✅ EMAIL SENT SUCCESSFULLY');
        debugPrint('==========================================');

        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.brandRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Text(
              'Inquiry submitted successfully! We will contact you soon.',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }

      // --------------------------------------------------------
      // ERROR RESPONSE
      // --------------------------------------------------------

      else {
        debugPrint('');
        debugPrint('❌ EMAILJS REQUEST FAILED');
        debugPrint('==========================================');
        debugPrint(
          'Status Code: ${response.statusCode}',
        );
        debugPrint(
          'Response Body: ${response.body}',
        );
        debugPrint('==========================================');

        throw Exception(
          'EmailJS Error ${response.statusCode}: ${response.body}',
        );
      }
    }

    // ----------------------------------------------------------
    // CATCH ERROR
    // ----------------------------------------------------------

    catch (e, stackTrace) {
      debugPrint('');
      debugPrint('==========================================');
      debugPrint('❌ EMAILJS SUBMISSION ERROR');
      debugPrint('==========================================');

      debugPrint(
        'Error: $e',
      );

      debugPrint('');
      debugPrint(
        'Stack Trace:',
      );

      debugPrint(
        stackTrace.toString(),
      );

      debugPrint('==========================================');

      if (!mounted) {
        debugPrint(
          '⚠️ Widget is no longer mounted.',
        );

        return;
      }

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text(
            'Failed to send inquiry. Please try again.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _messageController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final double screenWidth =
        MediaQuery.of(context).size.width;

    final bool isMobile = screenWidth < 650;

    return Center(
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context)
            .copyWith(scrollbars: false),
        child: SingleChildScrollView(
          child: Container(
            width: isMobile
                ? screenWidth * 0.92
                : 640,
            margin: const EdgeInsets.symmetric(
              vertical: 24,
            ),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.greyBorder,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.8),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        // ==================================================
                        // HEADER IMAGE
                        // ==================================================

                        SizedBox(
                          height: 340,
                          width: double.infinity,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Image.asset(
                                  'assets/tech.jpg',
                                  fit: BoxFit.cover,
                                ),
                              ),

                              // Wave overlay
                              Positioned.fill(
                                child: ClipPath(
                                  clipper:
                                  WaveHeaderClipper(),
                                  child: Container(
                                    color:
                                    AppTheme.darkCard,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ==================================================
                        // FORM CONTENT
                        // ==================================================

                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            isMobile ? 20 : 40,
                            0,
                            isMobile ? 20 : 40,
                            isMobile ? 28 : 40,
                          ),
                          child: Column(
                            children: [

                              // ------------------------------------------------
                              // TITLE
                              // ------------------------------------------------

                              Text(
                                'PROJECT INQUIRY FORM',
                                textAlign: TextAlign.center,
                                style:
                                GoogleFonts.plusJakartaSans(
                                  fontSize:
                                  isMobile ? 22 : 28,
                                  fontWeight:
                                  FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                ),
                              ),

                              const SizedBox(
                                height: 12,
                              ),

                              Text(
                                'Thanks for choosing TEVAH to build your next digital experience. Please complete this form so we can tailor the perfect solution.',
                                textAlign: TextAlign.center,
                                style:
                                GoogleFonts.plusJakartaSans(
                                  fontSize:
                                  isMobile ? 12 : 14,
                                  color: Colors.white60,
                                  height: 1.5,
                                ),
                              ),

                              const SizedBox(
                                height: 32,
                              ),

                              // ==================================================
                              // NAME
                              // ==================================================

                              Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [

                                  Text(
                                    'Name',
                                    style:
                                    GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight:
                                      FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  if (isMobile) ...[
                                    _StyledFormField(
                                      controller:
                                      _firstNameController,
                                      subLabel:
                                      'First Name',
                                      validator: (v) {
                                        if (v == null ||
                                            v.trim().isEmpty) {
                                          return 'Required';
                                        }

                                        return null;
                                      },
                                    ),

                                    const SizedBox(
                                      height: 12,
                                    ),

                                    _StyledFormField(
                                      controller:
                                      _lastNameController,
                                      subLabel:
                                      'Last Name (Optional)',
                                      validator: (v) =>
                                      null,
                                    ),
                                  ]

                                  else ...[
                                    Row(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [

                                        Expanded(
                                          child:
                                          _StyledFormField(
                                            controller:
                                            _firstNameController,
                                            subLabel:
                                            'First Name',
                                            validator: (v) {
                                              if (v == null ||
                                                  v.trim().isEmpty) {
                                                return 'Required';
                                              }

                                              return null;
                                            },
                                          ),
                                        ),

                                        const SizedBox(
                                          width: 16,
                                        ),

                                        Expanded(
                                          child:
                                          _StyledFormField(
                                            controller:
                                            _lastNameController,
                                            subLabel:
                                            'Last Name (Optional)',
                                            validator: (v) =>
                                            null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),

                              const SizedBox(
                                height: 20,
                              ),

                              // ==================================================
                              // PHONE + EMAIL
                              // ==================================================

                              if (isMobile) ...[
                                _PhoneWithSearchableCountryField(
                                  controller:
                                  _phoneController,
                                  selectedCountry:
                                  _selectedCountry,
                                  onTapSelectCountry:
                                  _openCountryPickerModal,
                                  onChangedText: () =>
                                      setState(() {}),
                                  validator: (v) {
                                    final bool hasPhone =
                                        v != null &&
                                            v.trim().isNotEmpty;

                                    final bool hasEmail =
                                        _emailController
                                            .text
                                            .trim()
                                            .isNotEmpty;

                                    if (!hasPhone &&
                                        !hasEmail) {
                                      return 'Provide Email or Phone';
                                    }

                                    if (hasPhone &&
                                        !RegExp(
                                          r'^[0-9]+$',
                                        ).hasMatch(
                                            v!.trim())) {
                                      return 'Numbers only';
                                    }

                                    return null;
                                  },
                                ),

                                const SizedBox(
                                  height: 16,
                                ),

                                _StyledLabeledFormField(
                                  label: 'Email',
                                  controller:
                                  _emailController,
                                  keyboardType:
                                  TextInputType.emailAddress,
                                  onChangedText: () =>
                                      setState(() {}),
                                  validator: (v) {
                                    final bool hasEmail =
                                        v != null &&
                                            v.trim().isNotEmpty;

                                    final bool hasPhone =
                                        _phoneController
                                            .text
                                            .trim()
                                            .isNotEmpty;

                                    if (!hasEmail &&
                                        !hasPhone) {
                                      return 'Provide Email or Phone';
                                    }

                                    if (hasEmail &&
                                        !RegExp(
                                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                        ).hasMatch(
                                          v!.trim(),
                                        )) {
                                      return 'Invalid Email';
                                    }

                                    return null;
                                  },
                                ),
                              ]

                              else ...[
                                Row(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [

                                    Expanded(
                                      child:
                                      _PhoneWithSearchableCountryField(
                                        controller:
                                        _phoneController,
                                        selectedCountry:
                                        _selectedCountry,
                                        onTapSelectCountry:
                                        _openCountryPickerModal,
                                        onChangedText: () =>
                                            setState(() {}),
                                        validator: (v) {
                                          final bool hasPhone =
                                              v != null &&
                                                  v.trim().isNotEmpty;

                                          final bool hasEmail =
                                              _emailController
                                                  .text
                                                  .trim()
                                                  .isNotEmpty;

                                          if (!hasPhone &&
                                              !hasEmail) {
                                            return 'Provide Email or Phone';
                                          }

                                          if (hasPhone &&
                                              !RegExp(
                                                r'^[0-9]+$',
                                              ).hasMatch(
                                                v!.trim(),
                                              )) {
                                            return 'Numbers only';
                                          }

                                          return null;
                                        },
                                      ),
                                    ),

                                    const SizedBox(
                                      width: 16,
                                    ),

                                    Expanded(
                                      child:
                                      _StyledLabeledFormField(
                                        label: 'Email',
                                        controller:
                                        _emailController,
                                        keyboardType:
                                        TextInputType.emailAddress,
                                        onChangedText: () =>
                                            setState(() {}),
                                        validator: (v) {
                                          final bool hasEmail =
                                              v != null &&
                                                  v.trim().isNotEmpty;

                                          final bool hasPhone =
                                              _phoneController
                                                  .text
                                                  .trim()
                                                  .isNotEmpty;

                                          if (!hasEmail &&
                                              !hasPhone) {
                                            return 'Provide Email or Phone';
                                          }

                                          if (hasEmail &&
                                              !RegExp(
                                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                              ).hasMatch(
                                                v!.trim(),
                                              )) {
                                            return 'Invalid Email';
                                          }

                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              const SizedBox(
                                height: 20,
                              ),

                              // ==================================================
                              // MESSAGE
                              // ==================================================

                              _StyledLabeledFormField(
                                label:
                                'Message / Project Details',
                                controller:
                                _messageController,
                                maxLines: 3,
                                validator: (v) {
                                  if (v == null ||
                                      v.trim().isEmpty) {
                                    return 'Required';
                                  }

                                  return null;
                                },
                              ),

                              const SizedBox(
                                height: 32,
                              ),

                              // ==================================================
                              // SUBMIT BUTTON
                              // ==================================================

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed:
                                  _isSubmitting
                                      ? null
                                      : _submitForm,
                                  style:
                                  ElevatedButton.styleFrom(
                                    backgroundColor:
                                    AppTheme.brandRed,
                                    foregroundColor:
                                    Colors.white,
                                    padding:
                                    const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                    shape:
                                    RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(
                                        12,
                                      ),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isSubmitting
                                      ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child:
                                    CircularProgressIndicator(
                                      color:
                                      Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                      : Text(
                                    'SUBMIT INQUIRY',
                                    style: GoogleFonts
                                        .plusJakartaSans(
                                      fontWeight:
                                      FontWeight.bold,
                                      fontSize: 14,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ==========================================================
                  // CLOSE BUTTON
                  // ==========================================================

                  Positioned(
                    top: 12,
                    right: 12,
                    child: CircleAvatar(
                      backgroundColor:
                      Colors.black.withOpacity(0.5),
                      radius: 18,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: () =>
                            Navigator.of(context).pop(),
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

// ============================================================
// WAVE HEADER CLIPPER
// ============================================================

class WaveHeaderClipper
    extends CustomClipper<Path> {

  @override
  Path getClip(Size size) {
    final Path path = Path();

    path.moveTo(
      0,
      size.height * 0.65,
    );

    final firstControlPoint = Offset(
      size.width * 0.25,
      size.height * 0.85,
    );

    final firstEndPoint = Offset(
      size.width * 0.5,
      size.height * 0.72,
    );

    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    final secondControlPoint = Offset(
      size.width * 0.75,
      size.height * 0.58,
    );

    final secondEndPoint = Offset(
      size.width,
      size.height * 0.78,
    );

    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(
      size.width,
      size.height,
    );

    path.lineTo(
      0,
      size.height,
    );

    path.close();

    return path;
  }

  @override
  bool shouldReclip(
      CustomClipper<Path> oldClipper,
      ) =>
      false;
}

// ============================================================
// PHONE FIELD
// ============================================================

class _PhoneWithSearchableCountryField
    extends StatelessWidget {

  final TextEditingController controller;
  final CountryData selectedCountry;
  final VoidCallback onTapSelectCountry;
  final VoidCallback onChangedText;
  final String? Function(String?)? validator;

  const _PhoneWithSearchableCountryField({
    required this.controller,
    required this.selectedCountry,
    required this.onTapSelectCountry,
    required this.onChangedText,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [

        Text(
          'Phone Number',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: (_) =>
              onChangedText(),

          inputFormatters: [
            FilteringTextInputFormatter
                .digitsOnly,
          ],

          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 14,
          ),

          validator: validator,

          decoration: InputDecoration(
            hintText: '1234567890',

            hintStyle:
            GoogleFonts.plusJakartaSans(
              color: Colors.white24,
              fontSize: 13,
            ),

            prefixIcon: InkWell(
              onTap:
              onTapSelectCountry,
              child: Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 10,
                ),

                margin:
                const EdgeInsets.only(
                  right: 8,
                ),

                decoration:
                const BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: Colors.white24,
                      width: 1.0,
                    ),
                  ),
                ),

                child: Row(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [

                    Text(
                      selectedCountry.flag,
                      style:
                      const TextStyle(
                        fontSize: 18,
                      ),
                    ),

                    const SizedBox(
                      width: 6,
                    ),

                    Text(
                      selectedCountry.code,
                      style:
                      GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),

            filled: true,

            fillColor:
            Colors.white.withOpacity(
              0.04,
            ),

            contentPadding:
            const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),

            border:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppTheme.greyBorder,
              ),
            ),

            enabledBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppTheme.greyBorder,
              ),
            ),

            focusedBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppTheme.brandRed,
                width: 1.5,
              ),
            ),

            errorBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.red.shade400,
              ),
            ),

            focusedErrorBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.red.shade400,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// COUNTRY PICKER
// ============================================================

class _CountryPickerBottomSheet
    extends StatefulWidget {

  final List<CountryData> countries;
  final ValueChanged<CountryData> onSelect;

  const _CountryPickerBottomSheet({
    required this.countries,
    required this.onSelect,
  });

  @override
  State<_CountryPickerBottomSheet>
  createState() =>
      _CountryPickerBottomSheetState();
}

class _CountryPickerBottomSheetState
    extends State<_CountryPickerBottomSheet> {

  late List<CountryData> _filteredCountries;

  final TextEditingController
  _searchController =
  TextEditingController();

  @override
  void initState() {
    super.initState();

    _filteredCountries =
        widget.countries;
  }

  void _filterSearch(String query) {
    setState(() {
      final q = query.toLowerCase();

      _filteredCountries =
          widget.countries.where((c) {
            return c.name
                .toLowerCase()
                .contains(q) ||
                c.code.contains(q);
          }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height:
      MediaQuery.of(context).size.height *
          0.65,

      padding:
      const EdgeInsets.all(20),

      child: Column(
        children: [

          // ========================================================
          // HEADER
          // ========================================================

          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [

              Text(
                'Select Country',
                style:
                GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight:
                  FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.white70,
                ),
                onPressed: () =>
                    Navigator.of(context)
                        .pop(),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          // ========================================================
          // SEARCH
          // ========================================================

          TextField(
            controller:
            _searchController,

            onChanged:
            _filterSearch,

            style:
            GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 14,
            ),

            decoration:
            InputDecoration(
              hintText:
              'Search country name or code...',

              hintStyle:
              GoogleFonts.plusJakartaSans(
                color: Colors.white38,
                fontSize: 13,
              ),

              prefixIcon:
              const Icon(
                Icons.search_rounded,
                color:
                AppTheme.brandRed,
              ),

              filled: true,

              fillColor:
              Colors.white
                  .withOpacity(0.05),

              border:
              OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(
                  12,
                ),
                borderSide: BorderSide(
                  color:
                  AppTheme.greyBorder,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          // ========================================================
          // COUNTRY LIST
          // ========================================================

          Expanded(
            child: ScrollConfiguration(
              behavior:
              ScrollConfiguration.of(
                context,
              ).copyWith(
                scrollbars: false,
              ),

              child:
              ListView.separated(
                itemCount:
                _filteredCountries
                    .length,

                separatorBuilder:
                    (_, __) =>
                    Divider(
                      color:
                      Colors.white
                          .withOpacity(
                        0.08,
                      ),
                    ),

                itemBuilder:
                    (context, index) {

                  final country =
                  _filteredCountries[
                  index];

                  return ListTile(
                    leading: Text(
                      country.flag,
                      style:
                      const TextStyle(
                        fontSize: 22,
                      ),
                    ),

                    title: Text(
                      country.name,
                      style:
                      GoogleFonts
                          .plusJakartaSans(
                        color:
                        Colors.white,
                        fontSize: 14,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),

                    trailing: Text(
                      country.code,
                      style:
                      GoogleFonts
                          .plusJakartaSans(
                        color:
                        AppTheme.brandRed,
                        fontSize: 14,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    onTap: () =>
                        widget.onSelect(
                          country,
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

// ============================================================
// STYLED FORM FIELD
// ============================================================

class _StyledFormField
    extends StatelessWidget {

  final TextEditingController controller;
  final String subLabel;
  final String? Function(String?)?
  validator;

  const _StyledFormField({
    required this.controller,
    required this.subLabel,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [

        TextFormField(
          controller: controller,

          style:
          GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 14,
          ),

          validator: validator,

          decoration:
          InputDecoration(
            filled: true,

            fillColor:
            Colors.white
                .withOpacity(0.04),

            contentPadding:
            const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),

            border:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(8),
              borderSide: BorderSide(
                color:
                AppTheme.greyBorder,
              ),
            ),

            enabledBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(8),
              borderSide: BorderSide(
                color:
                AppTheme.greyBorder,
              ),
            ),

            focusedBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(8),
              borderSide: BorderSide(
                color:
                AppTheme.brandRed,
                width: 1.5,
              ),
            ),

            errorBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(8),
              borderSide: BorderSide(
                color:
                Colors.red.shade400,
              ),
            ),

            focusedErrorBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(8),
              borderSide: BorderSide(
                color:
                Colors.red.shade400,
                width: 1.5,
              ),
            ),
          ),
        ),

        const SizedBox(
          height: 4,
        ),

        Text(
          subLabel,
          style:
          GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: Colors.white38,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// STYLED LABELED FORM FIELD
// ============================================================

class _StyledLabeledFormField
    extends StatelessWidget {

  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final int maxLines;
  final VoidCallback? onChangedText;
  final String? Function(String?)?
  validator;

  const _StyledLabeledFormField({
    required this.label,
    required this.controller,
    this.keyboardType =
        TextInputType.text,
    this.maxLines = 1,
    this.onChangedText,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [

        Text(
          label,
          style:
          GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight:
            FontWeight.bold,
            color: Colors.white,
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        TextFormField(
          controller: controller,

          keyboardType:
          keyboardType,

          maxLines: maxLines,

          onChanged: (_) =>
              onChangedText?.call(),

          style:
          GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 14,
          ),

          validator: validator,

          decoration:
          InputDecoration(
            filled: true,

            fillColor:
            Colors.white
                .withOpacity(0.04),

            contentPadding:
            const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),

            border:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(8),
              borderSide: BorderSide(
                color:
                AppTheme.greyBorder,
              ),
            ),

            enabledBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(8),
              borderSide: BorderSide(
                color:
                AppTheme.greyBorder,
              ),
            ),

            focusedBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(8),
              borderSide: BorderSide(
                color:
                AppTheme.brandRed,
                width: 1.5,
              ),
            ),

            errorBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(8),
              borderSide: BorderSide(
                color:
                Colors.red.shade400,
              ),
            ),

            focusedErrorBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(8),
              borderSide: BorderSide(
                color:
                Colors.red.shade400,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
import 'package:carrier_nest_flutter/helpers/FadeAnimation.dart';
import 'package:carrier_nest_flutter/pages/home.dart';
import 'package:carrier_nest_flutter/rest/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class DriverLoginPage extends StatefulWidget {
  const DriverLoginPage({super.key});

  @override
  _DriverLoginPageState createState() => _DriverLoginPageState();
}

class _DriverLoginPageState extends State<DriverLoginPage> with TickerProviderStateMixin {
  final _phoneNumberController = TextEditingController();
  final _carrierCodeController = TextEditingController();
  final _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  bool _isSecondPhase = false;
  final DriverAuth _driverAuth = DriverAuth();

  // PIN digit controllers and focus nodes
  final List<TextEditingController> _pinDigitControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _pinDigitFocusNodes = List.generate(6, (index) => FocusNode());

  bool _isRequestPinLoading = false;
  bool _isVerifyPinLoading = false;

  // Animation controllers
  late AnimationController _containerAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<double> _containerAnimation;
  late Animation<double> _fadeAnimation;

  // Get platform-specific font family
  String get _fontFamily {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'SF Pro Display';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'Roboto';
    }
    return 'system-ui';
  }

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _containerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Initialize animations
    _containerAnimation = CurvedAnimation(
      parent: _containerAnimationController,
      curve: Curves.easeInOutCubic,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    );

    if (kDebugMode) {
      _phoneNumberController.text = '3172245337';
      _carrierCodeController.text = 'psb625';

      // _phoneNumberController.text = '2065654638';
      // _carrierCodeController.text = 'deepbrosinc';
    }
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _carrierCodeController.dispose();
    _pinController.dispose();
    _pinFocusNode.dispose();

    // Dispose PIN digit controllers and focus nodes
    for (var controller in _pinDigitControllers) {
      controller.dispose();
    }
    for (var focusNode in _pinDigitFocusNodes) {
      focusNode.dispose();
    }

    // Dispose animation controllers
    _containerAnimationController.dispose();
    _fadeAnimationController.dispose();

    super.dispose();
  }

  Future<void> _requestPin() async {
    setState(() {
      _isRequestPinLoading = true;
    });

    try {
      await _driverAuth.fetchCsrfToken();

      final carrierCode = _carrierCodeController.text.toLowerCase();
      if (carrierCode == 'demo') {
        // Skip PIN entry for "demo" carrier code
        _verifyPin(skipPin: true);
        return;
      }

      final response = await _driverAuth.requestPin(
        phoneNumber: _phoneNumberController.text,
        carrierCode: _carrierCodeController.text,
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        // Start the animation to PIN entry phase
        _containerAnimationController.forward();
        await Future.delayed(const Duration(milliseconds: 300));

        setState(() {
          _isSecondPhase = true;
        });

        // Start fade animation and focus first PIN digit
        _fadeAnimationController.forward();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FocusScope.of(context).requestFocus(_pinDigitFocusNodes[0]);
        });
      } else {
        // TODO: Handle error
      }
    } catch (e) {
      // TODO: Handle exception, e.g., display a message
    } finally {
      setState(() {
        _isRequestPinLoading = false;
      });
    }
  }

  Future<void> _verifyPin({bool skipPin = false}) async {
    setState(() {
      _isVerifyPinLoading = true;
    });
    try {
      // Use the hidden PIN controller text, which gets populated by SMS auto-fill or manual entry
      final pinCode = skipPin ? '' : _pinController.text;

      final tokenData = await _driverAuth.verifyPin(
        phoneNumber: _phoneNumberController.text,
        carrierCode: _carrierCodeController.text,
        code: pinCode,
      );

      if (tokenData != null) {
        // Redirect to the home page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyHomePage()), // Assuming HomePage() is the home page widget
        );
      } else {
        // Show snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: skipPin ? const Text('Login failed') : const Text('Incorrect PIN'),
          ),
        );
      }
    } finally {
      setState(() {
        _isVerifyPinLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: CupertinoPageScaffold(
          backgroundColor: const Color(0xFFEFEFEF), // Neumorphic iOS background
          child: DefaultTextStyle(
            style: TextStyle(
              fontFamily: _fontFamily,
              color: const Color(0xFF2D3748),
              fontSize: 16,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: AnimatedBuilder(
                  animation: _containerAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isSecondPhase ? 1.0 : (1.0 - _containerAnimation.value * 0.1),
                      child: Opacity(
                        opacity: _isSecondPhase ? 1.0 : (1.0 - _containerAnimation.value * 0.3),
                        child: _isSecondPhase ? _buildSecondPhaseUI() : _buildFirstPhaseUI(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      return GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: const Color(0xFFE8E8E8), // Neumorphic Android background
          body: DefaultTextStyle(
            style: TextStyle(
              fontFamily: _fontFamily,
              color: const Color(0xFF2D3748),
              fontSize: 16,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: AnimatedBuilder(
                  animation: _containerAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isSecondPhase ? 1.0 : (1.0 - _containerAnimation.value * 0.1),
                      child: Opacity(
                        opacity: _isSecondPhase ? 1.0 : (1.0 - _containerAnimation.value * 0.3),
                        child: _isSecondPhase ? _buildSecondPhaseUI() : _buildFirstPhaseUI(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildTruckIcon() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;
    final bool isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final backgroundColor = isIOS ? const Color(0xFFEFEFEF) : const Color(0xFFE8E8E8);

    return Column(
      children: [
        // App Title above logo
        Text(
          'Carrier Nest',
          style: TextStyle(
            fontSize: isCompact ? 36 : 42,
            fontWeight: FontWeight.w900,
            fontFamily: _fontFamily,
            color: const Color(0xFF2D3748),
            letterSpacing: isIOS ? -1.2 : -0.5,
            shadows: [
              Shadow(
                color: Colors.white.withValues(alpha: 0.8),
                offset: const Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        SizedBox(height: isCompact ? 24 : 32),

        // Enhanced Neumorphic container for truck icon
        Container(
          width: isCompact ? 120 : 140,
          height: isCompact ? 120 : 140,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(isIOS ? 30 : 25),
            boxShadow: [
              // Main neumorphic shadow (dark) - enhanced
              BoxShadow(
                color: isIOS ? const Color(0xFFD1D1D1).withValues(alpha: 0.9) : const Color(0xFFCBCBCB).withValues(alpha: 0.9),
                offset: const Offset(12, 12),
                blurRadius: 24,
                spreadRadius: 0,
              ),
              // Highlight shadow (light) - enhanced
              BoxShadow(
                color: isIOS ? const Color(0xFFFFFFFF).withValues(alpha: 0.95) : const Color(0xFFFFFFFF).withValues(alpha: 0.9),
                offset: const Offset(-12, -12),
                blurRadius: 24,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Center(
            child: Image.asset(
              'assets/images/logo_truck_100.png',
              width: isCompact ? 60 : 70,
              height: isCompact ? 60 : 70,
            ),
          ),
        ),
        SizedBox(height: isCompact ? 40 : 48),
        Text(
          'Driver Login',
          style: TextStyle(
            fontSize: isCompact ? 28 : 32,
            fontWeight: FontWeight.w800,
            fontFamily: _fontFamily,
            color: const Color(0xFF2D3748),
            letterSpacing: isIOS ? -0.8 : -0.2,
            shadows: [
              Shadow(
                color: Colors.white.withValues(alpha: 0.8),
                offset: const Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Enter your credentials to access your assignments',
          style: TextStyle(
            fontSize: isCompact ? 15 : 17,
            fontWeight: FontWeight.w500,
            fontFamily: _fontFamily,
            color: const Color(0xFF718096),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isCompact ? 40 : 48),
      ],
    );
  }

  Widget _buildFirstPhaseUI() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return FadeAnimation(
        1,
        Column(
          children: [
            _buildTruckIcon(),
            _buildCupertinoNumberField(_phoneNumberController, 'Phone Number'),
            const SizedBox(height: 20),
            _buildCupertinoTextField(_carrierCodeController, 'Carrier Code'),
            const SizedBox(height: 32),
            _buildCupertinoButton(
              _requestPin,
              'Continue',
              _isRequestPinLoading,
              _phoneNumberController.text.isEmpty || _carrierCodeController.text.isEmpty,
            ),
          ],
        ),
      );
    } else {
      return FadeAnimation(
        1,
        Column(
          children: [
            _buildTruckIcon(),
            _buildMaterialNumberField(_phoneNumberController, 'Phone Number'),
            const SizedBox(height: 20),
            _buildMaterialTextField(_carrierCodeController, 'Carrier Code'),
            const SizedBox(height: 32),
            _buildMaterialButton(
              _requestPin,
              'Continue',
              _isRequestPinLoading,
              _phoneNumberController.text.isEmpty || _carrierCodeController.text.isEmpty,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSecondPhaseUI() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
            child: defaultTargetPlatform == TargetPlatform.iOS ? _buildIOSSecondPhase() : _buildAndroidSecondPhase(),
          ),
        );
      },
    );
  }

  Widget _buildIOSSecondPhase() {
    return Column(
      children: [
        _buildTruckIcon(),
        _buildPinDigitInput(),
        const SizedBox(height: 32),
        _buildCupertinoButton(_verifyPin, 'Verify PIN', _isVerifyPinLoading, _isPinIncomplete()),
        const SizedBox(height: 24),
        _buildCupertinoBackButton(),
      ],
    );
  }

  Widget _buildAndroidSecondPhase() {
    return Column(
      children: [
        _buildTruckIcon(),
        _buildPinDigitInput(),
        const SizedBox(height: 32),
        _buildMaterialButton(_verifyPin, 'Verify PIN', _isVerifyPinLoading, _isPinIncomplete()),
        const SizedBox(height: 24),
        _buildMaterialBackButton(),
      ],
    );
  }

  // Platform-specific back buttons
  Widget _buildCupertinoBackButton() {
    return GestureDetector(
      onTap: () {
        // Reset animations
        _fadeAnimationController.reset();
        _containerAnimationController.reset();

        setState(() {
          _isSecondPhase = false;
          // Clear PIN controller and digit controllers
          _pinController.clear();
          for (var controller in _pinDigitControllers) {
            controller.clear();
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Back to Login',
          style: TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: CupertinoColors.secondaryLabel,
            decoration: TextDecoration.underline,
            decorationColor: CupertinoColors.secondaryLabel.withValues(alpha: 0.5),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildMaterialBackButton() {
    return GestureDetector(
      onTap: () {
        // Reset animations
        _fadeAnimationController.reset();
        _containerAnimationController.reset();

        setState(() {
          _isSecondPhase = false;
          // Clear PIN controller and digit controllers
          _pinController.clear();
          for (var controller in _pinDigitControllers) {
            controller.clear();
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Back to Login',
          style: TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: Colors.grey[600],
            decoration: TextDecoration.underline,
            decorationColor: Colors.grey[600]?.withValues(alpha: 0.5),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // Platform-specific text fields
  Widget _buildCupertinoTextField(
    TextEditingController controller,
    String label, {
    FocusNode? focusNode,
    bool isPin = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: _fontFamily,
              color: const Color(0xFF4A5568),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEFEFEF),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              // Inset shadow effect for neumorphic text field
              BoxShadow(
                color: const Color(0xFFD1D1D1).withValues(alpha: 0.8),
                offset: const Offset(4, 4),
                blurRadius: 8,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFFFFFFFF).withValues(alpha: 0.9),
                offset: const Offset(-4, -4),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: CupertinoTextField(
            controller: controller,
            focusNode: focusNode,
            placeholder: 'Enter ${label.toLowerCase()}',
            keyboardType: isPin ? TextInputType.number : TextInputType.text,
            obscureText: isPin,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            style: TextStyle(
              fontSize: 16,
              fontFamily: _fontFamily,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF2D3748),
            ),
            placeholderStyle: TextStyle(
              color: const Color(0xFF718096),
              fontFamily: _fontFamily,
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildCupertinoNumberField(
    TextEditingController controller,
    String label, {
    FocusNode? focusNode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: _fontFamily,
              color: const Color(0xFF4A5568),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEFEFEF),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              // Inset shadow effect for neumorphic text field
              BoxShadow(
                color: const Color(0xFFD1D1D1).withValues(alpha: 0.8),
                offset: const Offset(4, 4),
                blurRadius: 8,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFFFFFFFF).withValues(alpha: 0.9),
                offset: const Offset(-4, -4),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: CupertinoTextField(
            controller: controller,
            focusNode: focusNode,
            placeholder: 'Enter ${label.toLowerCase()}',
            keyboardType: TextInputType.number,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            style: TextStyle(
              fontSize: 16,
              fontFamily: _fontFamily,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF2D3748),
            ),
            placeholderStyle: TextStyle(
              color: const Color(0xFF718096),
              fontFamily: _fontFamily,
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialTextField(
    TextEditingController controller,
    String label, {
    FocusNode? focusNode,
    bool isPin = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: _fontFamily,
              color: const Color(0xFF4A5568),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE8E8E8),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              // Inset shadow effect for neumorphic text field
              BoxShadow(
                color: const Color(0xFFCBCBCB).withValues(alpha: 0.8),
                offset: const Offset(4, 4),
                blurRadius: 8,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFFFFFFFF).withValues(alpha: 0.8),
                offset: const Offset(-4, -4),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: CupertinoTextField(
            controller: controller,
            focusNode: focusNode,
            placeholder: 'Enter ${label.toLowerCase()}',
            keyboardType: isPin ? TextInputType.number : TextInputType.text,
            obscureText: isPin,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: const BoxDecoration(
              color: Colors.transparent,
              border: Border(),
            ),
            style: TextStyle(
              fontSize: 16,
              fontFamily: _fontFamily,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF2D3748),
            ),
            placeholderStyle: TextStyle(
              color: const Color(0xFF718096),
              fontFamily: _fontFamily,
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialNumberField(
    TextEditingController controller,
    String label, {
    FocusNode? focusNode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: _fontFamily,
              color: const Color(0xFF4A5568),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE8E8E8),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              // Inset shadow effect for neumorphic text field
              BoxShadow(
                color: const Color(0xFFCBCBCB).withValues(alpha: 0.8),
                offset: const Offset(4, 4),
                blurRadius: 8,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFFFFFFFF).withValues(alpha: 0.8),
                offset: const Offset(-4, -4),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: CupertinoTextField(
            controller: controller,
            focusNode: focusNode,
            placeholder: 'Enter ${label.toLowerCase()}',
            keyboardType: TextInputType.number,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: const BoxDecoration(
              color: Colors.transparent,
              border: Border(),
            ),
            style: TextStyle(
              fontSize: 16,
              fontFamily: _fontFamily,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF2D3748),
            ),
            placeholderStyle: TextStyle(
              color: const Color(0xFF718096),
              fontFamily: _fontFamily,
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),
      ],
    );
  }

  // Helper method to check if PIN is incomplete
  bool _isPinIncomplete() {
    return _pinController.text.length < 6;
  }

  // 6-digit PIN input widget with SMS auto-fill support
  Widget _buildPinDigitInput() {
    final bool isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final backgroundColor = isIOS ? const Color(0xFFEFEFEF) : const Color(0xFFE8E8E8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            'Enter 6-Digit PIN',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: _fontFamily,
              color: const Color(0xFF4A5568),
            ),
          ),
        ),
        Stack(
          children: [
            // Hidden text field for SMS auto-fill - this is the primary input
            Positioned(
              left: 0,
              right: 0,
              child: Container(
                height: 58,
                child: CupertinoTextField(
                  controller: _pinController,
                  focusNode: _pinFocusNode,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: Colors.transparent),
                  ),
                  style: const TextStyle(
                    color: Colors.transparent,
                    fontSize: 24,
                  ),
                  cursorColor: Colors.transparent,
                  onChanged: (value) {
                    // Handle both autofill and manual input
                    if (value.length <= 6) {
                      // Populate individual digit controllers
                      for (int i = 0; i < 6; i++) {
                        if (i < value.length) {
                          _pinDigitControllers[i].text = value[i];
                        } else {
                          _pinDigitControllers[i].clear();
                        }
                      }

                      // If we have 6 digits, verify PIN automatically
                      if (value.length == 6) {
                        Future.delayed(const Duration(milliseconds: 100), () {
                          _verifyPin();
                        });
                      }

                      setState(() {});
                    }
                  },
                ),
              ),
            ),
            // Visual PIN digit display (non-interactive)
            IgnorePointer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return GestureDetector(
                    onTap: () {
                      // Focus the hidden field when any digit is tapped
                      FocusScope.of(context).requestFocus(_pinFocusNode);
                    },
                    child: Container(
                      width: 50,
                      height: 58,
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(isIOS ? 12 : 10),
                        boxShadow: [
                          // Inset shadow effect for neumorphic digit field
                          BoxShadow(
                            color: isIOS ? const Color(0xFFD1D1D1).withValues(alpha: 0.8) : const Color(0xFFCBCBCB).withValues(alpha: 0.8),
                            offset: const Offset(3, 3),
                            blurRadius: 6,
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: isIOS ? const Color(0xFFFFFFFF).withValues(alpha: 0.9) : const Color(0xFFFFFFFF).withValues(alpha: 0.8),
                            offset: const Offset(-3, -3),
                            blurRadius: 6,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          index < _pinController.text.length ? _pinController.text[index] : '',
                          style: TextStyle(
                            fontSize: 24,
                            fontFamily: isIOS ? 'SF Mono' : 'Roboto Mono', // Monospace fonts for numbers
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2D3748),
                            height: 1.0, // Tight line height for better centering
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            // Transparent overlay to capture taps
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  // Focus the hidden field when anywhere in the PIN area is tapped
                  FocusScope.of(context).requestFocus(_pinFocusNode);
                },
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
        // Instruction text for auto-fill
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            'Tap anywhere in the PIN area to enter or use SMS auto-fill',
            style: TextStyle(
              fontSize: 12,
              fontFamily: _fontFamily,
              color: const Color(0xFF718096),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  // Platform-specific buttons
  Widget _buildCupertinoButton(
    VoidCallback onPressed,
    String buttonText,
    bool isLoading,
    bool isFieldEmpty,
  ) {
    bool isButtonEnabled = !isFieldEmpty && !isLoading;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isButtonEnabled
            ? [
                // Elevated neumorphic shadow for enabled button
                BoxShadow(
                  color: const Color(0xFFD1D1D1).withValues(alpha: 0.8),
                  offset: const Offset(6, 6),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: const Color(0xFFFFFFFF).withValues(alpha: 0.9),
                  offset: const Offset(-6, -6),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ]
            : [
                // Pressed/disabled neumorphic shadow
                BoxShadow(
                  color: const Color(0xFFD1D1D1).withValues(alpha: 0.5),
                  offset: const Offset(2, 2),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: const Color(0xFFFFFFFF).withValues(alpha: 0.7),
                  offset: const Offset(-2, -2),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
      ),
      child: CupertinoButton(
        onPressed: isButtonEnabled ? onPressed : null,
        color: Colors.transparent,
        disabledColor: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        padding: EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
            gradient: isButtonEnabled
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF007AFF).withValues(alpha: 0.9),
                      const Color(0xFF0051D5).withValues(alpha: 0.9),
                    ],
                  )
                : null,
            color: isButtonEnabled ? null : const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: isLoading
                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                : Text(
                    buttonText,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      fontFamily: _fontFamily,
                      color: isButtonEnabled ? CupertinoColors.white : const Color(0xFF9CA3AF),
                      letterSpacing: -0.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialButton(
    VoidCallback onPressed,
    String buttonText,
    bool isLoading,
    bool isFieldEmpty,
  ) {
    bool isButtonEnabled = !isFieldEmpty && !isLoading;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(14),
        boxShadow: isButtonEnabled
            ? [
                // Elevated neumorphic shadow for enabled button
                BoxShadow(
                  color: const Color(0xFFCBCBCB).withValues(alpha: 0.8),
                  offset: const Offset(6, 6),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: const Color(0xFFFFFFFF).withValues(alpha: 0.8),
                  offset: const Offset(-6, -6),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ]
            : [
                // Pressed/disabled neumorphic shadow
                BoxShadow(
                  color: const Color(0xFFCBCBCB).withValues(alpha: 0.5),
                  offset: const Offset(2, 2),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: const Color(0xFFFFFFFF).withValues(alpha: 0.7),
                  offset: const Offset(-2, -2),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
      ),
      child: CupertinoButton(
        onPressed: isButtonEnabled ? onPressed : null,
        color: Colors.transparent,
        disabledColor: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        padding: EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
            gradient: isButtonEnabled
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2563EB).withValues(alpha: 0.9),
                      const Color(0xFF1D4ED8).withValues(alpha: 0.9),
                    ],
                  )
                : null,
            color: isButtonEnabled ? null : const Color(0xFFDDDDDD),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: isLoading
                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                : Text(
                    buttonText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: _fontFamily,
                      color: isButtonEnabled ? Colors.white : const Color(0xFF9CA3AF),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

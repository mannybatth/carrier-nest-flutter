import 'package:carrier_nest_flutter/helpers/FadeAnimation.dart';
import 'package:carrier_nest_flutter/pages/home.dart';
import 'package:carrier_nest_flutter/rest/auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class DriverLoginPage extends StatefulWidget {
  const DriverLoginPage({super.key});

  @override
  _DriverLoginPageState createState() => _DriverLoginPageState();
}

class _DriverLoginPageState extends State<DriverLoginPage> {
  final _phoneNumberController = TextEditingController();
  final _carrierCodeController = TextEditingController();
  final _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  bool _isSecondPhase = false;
  final DriverAuth _driverAuth = DriverAuth();

  bool _isRequestPinLoading = false;
  bool _isVerifyPinLoading = false;

  @override
  void initState() {
    super.initState();

    _driverAuth.fetchCsrfToken();
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _carrierCodeController.dispose();
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  Future<void> _requestPin() async {
    setState(() {
      _isRequestPinLoading = true;
    });
    try {
      final response = await _driverAuth.requestPin(
          phoneNumber: _phoneNumberController.text,
          carrierCode: _carrierCodeController.text);

      if (response.statusCode == 200 || response.statusCode == 302) {
        setState(() {
          _isSecondPhase = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            FocusScope.of(context).requestFocus(_pinFocusNode);
          });
        });
      } else {
        // TODO: Handle error
      }
    } finally {
      setState(() {
        _isRequestPinLoading = false;
      });
    }
  }

  Future<void> _verifyPin() async {
    setState(() {
      _isVerifyPinLoading = true;
    });
    try {
      var response = await _driverAuth.verifyPin(
          phoneNumber: _phoneNumberController.text,
          carrierCode: _carrierCodeController.text,
          code: _pinController.text);

      if (response.statusCode == 200 || response.statusCode == 302) {
        // Redirect to the home page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  const MyHomePage()), // Assuming HomePage() is the home page widget
        );
      } else {
        // TODO: Handle error
      }
    } finally {
      setState(() {
        _isVerifyPinLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Call this method here to hide soft keyboard
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text("Carrier Nest")),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isSecondPhase ? _buildSecondPhaseUI() : _buildFirstPhaseUI(),
        ),
      ),
    );
  }

  Widget _buildTruckIcon() {
    return Column(
      children: [
        Image.asset('assets/images/logo_truck_100.png',
            width: 100, height: 100), // Truck image
        const SizedBox(
            height: 32), // Add some space between icon and text fields
      ],
    );
  }

  Widget _buildFirstPhaseUI() {
    return FadeAnimation(
      1,
      ListView(
        children: [
          _buildTruckIcon(),
          _buildTextField(_phoneNumberController, 'Phone Number'),
          const SizedBox(height: 16),
          _buildTextField(_carrierCodeController, 'Carrier Code'),
          const SizedBox(height: 16),
          _buildButton(_requestPin, 'Login', _isRequestPinLoading),
        ],
      ),
    );
  }

  Widget _buildSecondPhaseUI() {
    return ListView(
      children: [
        _buildTruckIcon(),
        _buildTextField(_pinController, 'PIN', focusNode: _pinFocusNode),
        const SizedBox(height: 16),
        _buildButton(_verifyPin, 'Verify PIN', _isVerifyPinLoading),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {FocusNode? focusNode}) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
      ),
    );
  }

  // Modify _buildButton to handle loading state
  Widget _buildButton(
      VoidCallback onPressed, String buttonText, bool isLoading) {
    return InkWell(
      onTap: isLoading ? null : onPressed, // Disable button when loading
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: [
              Colors.blue,
              Colors.blue.withOpacity(0.8),
            ],
          ),
        ),
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white)) // Show spinner when loading
              : Text(
                  buttonText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
        ),
      ),
    );
  }
}

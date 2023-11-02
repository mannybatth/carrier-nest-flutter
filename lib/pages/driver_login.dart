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
  bool _isSecondPhase = false;
  final DriverAuth _driverAuth = DriverAuth();

  @override
  void initState() {
    super.initState();

    _driverAuth.fetchCsrfToken();
    _phoneNumberController.text = '3172245337';
    _carrierCodeController.text = 'psbexpressinc';

    // _phoneNumberController.text = '2065654638';
    // _carrierCodeController.text = 'deepbrosinc';
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _carrierCodeController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _requestPin() async {
    final response = await _driverAuth.requestPin(
        phoneNumber: _phoneNumberController.text,
        carrierCode: _carrierCodeController.text);

    if (response.statusCode == 200 || response.statusCode == 302) {
      setState(() {
        _isSecondPhase = true;
      });
    } else {
      // TODO: Handle error
    }
  }

  Future<void> _verifyPin() async {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isSecondPhase ? _buildSecondPhaseUI() : _buildFirstPhaseUI(),
      ),
    );
  }

  Widget _buildFirstPhaseUI() {
    return Column(
      children: [
        TextField(
          controller: _phoneNumberController,
          decoration: const InputDecoration(labelText: 'Phone Number'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _carrierCodeController,
          decoration: const InputDecoration(labelText: 'Carrier Code'),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _requestPin,
          child: const Text('Submit'),
        ),
      ],
    );
  }

  Widget _buildSecondPhaseUI() {
    return Column(
      children: [
        TextField(
          controller: _pinController,
          decoration: const InputDecoration(labelText: 'PIN'),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _verifyPin,
          child: const Text('Verify PIN'),
        ),
      ],
    );
  }
}

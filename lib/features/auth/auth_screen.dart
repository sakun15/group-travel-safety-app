import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../trip/create_trip_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Controls which UI to show — phone input or OTP input
  bool _codeSent = false;

  // Stores the verification ID Firebase gives us after sending OTP
  String _verificationId = '';

  // Loading spinner flag
  bool _isLoading = false;

  // Text controllers to read what user typed
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // STEP 1 — Send OTP to phone number
  Future<void> _sendOTP() async {
    setState(() => _isLoading = true);

    await _auth.verifyPhoneNumber(
      // +91 is India's country code
      phoneNumber: '+91${_phoneController.text.trim()}',

      // Called when OTP is sent successfully
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _codeSent = true;
          _isLoading = false;
        });
      },

      // Called if verification completes automatically (Android only)
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        _goToHome();
      },

      // Called if something goes wrong
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      },

      // Called if OTP expires
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },

      timeout: const Duration(seconds: 60),
    );
  }

  // STEP 2 — Verify the OTP the user typed
  Future<void> _verifyOTP() async {
    setState(() => _isLoading = true);

    try {
      // Combine verificationId + user's OTP into a credential
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text.trim(),
      );

      // Sign in with that credential
      await _auth.signInWithCredential(credential);
      _goToHome();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP. Please try again.')),
      );
    }
  }

  // Navigate to home screen after successful login
  void _goToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CreateTripScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Group Travel\nSafety',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your phone number to continue',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),

            // Show phone input OR otp input depending on _codeSent
            if (!_codeSent) ...[
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixText: '+91 ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendOTP,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Send OTP'),
                ),
              ),
            ] else ...[
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Enter OTP',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOTP,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Verify OTP'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
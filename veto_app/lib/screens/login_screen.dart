import 'package:flutter/material.dart';
import 'dart:convert';
import '../config/app_config.dart';
import '../services/auth_service.dart';

/// Login screen for OTP-based authentication
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _otpSent = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Set test phone number
    _phoneController.text = '+972525640021';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await AuthService.requestOtp(_phoneController.text);

      if (response.statusCode == 200) {
        // Extract OTP from response for display (for testing)
        final body = response.body;
        String? otp;
        if (body.contains('__debug__')) {
          try {
            final jsonData = jsonDecode(body);
            otp = jsonData['__debug__']?['otp'];
          } catch (e) {
            // Silently handle JSON parse errors
          }
        }

        setState(() {
          _otpSent = true;
          _errorMessage = null;
        });

        if (mounted) {
          String message = 'OTP sent successfully';
          if (otp != null) {
            message = 'OTP: $otp (for testing)';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              duration: const Duration(seconds: 10),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to request OTP: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await AuthService.verifyOtp(
        _phoneController.text,
        _otpController.text,
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final token = jsonData['token'];

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Login successful! You are authenticated.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Wait for snackbar to show, then reset
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            setState(() {
              _otpSent = false;
              _otpController.clear();
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Token: $token'),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      } else {
        final jsonData = jsonDecode(response.body);
        setState(() {
          _errorMessage =
              jsonData['message'] ?? 'Invalid OTP: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VETO Login'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo or app title
            const SizedBox(height: 40),
            Text(
              'Welcome to VETO',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Connecting to: ${AppConfig.baseUrl}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 40),

            // Error message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),
            if (_errorMessage != null) const SizedBox(height: 16),

            // Phone number field
            TextField(
              controller: _phoneController,
              enabled: !_otpSent,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                hintText: '+972525640021',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // OTP field (shown after OTP is sent)
            if (_otpSent)
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'OTP Code',
                  hintText: '000000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            if (_otpSent) const SizedBox(height: 24),

            // Request OTP button
            if (!_otpSent)
              ElevatedButton(
                onPressed: _isLoading ? null : _requestOtp,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Request OTP'),
              ),

            // Verify OTP button
            if (_otpSent)
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Verify OTP'),
              ),

            if (_otpSent)
              TextButton(
                onPressed: () {
                  setState(() {
                    _otpSent = false;
                    _otpController.clear();
                  });
                },
                child: const Text('Use different number'),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:io' show Platform;
import 'dart:async';
import 'generated/l10n.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _storage = FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  final _passwordController = TextEditingController();
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  bool _showPasswordLogin = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    setState(() {
      _isLoading = true;
    });
    await _checkPasswordEnabled();
    if (!_showPasswordLogin) {
      Timer(Duration(seconds: 1), () {
        Navigator.pushReplacementNamed(context, '/home');
      });
      return;
    }
    await _checkBiometricAvailability();
    if (_isBiometricEnabled) {
      _authenticate();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkBiometricAvailability() async {
    if (Platform.isWindows) {
      _isBiometricAvailable = false;
    } else {
      _isBiometricAvailable = await _localAuth.canCheckBiometrics;
    }
  }

  Future<void> _checkPasswordEnabled() async {
    String? passwordEnabled = await _storage.read(key: 'password_enabled');
    if (passwordEnabled == 'true') {
      _showPasswordLogin = true;
      String? biometricEnabled = await _storage.read(key: 'biometric_enabled');
      _isBiometricEnabled = biometricEnabled == 'true';
    }
  }

  Future<void> _authenticate() async {
    try {
      bool authenticated = await _localAuth.authenticate(
        localizedReason: S.of(context).biometricPrompt,
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (authenticated) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          _showPasswordLogin = true;
        });
      }
    } catch (e) {
      setState(() {
        _showPasswordLogin = true;
      });
    }
  }

  Future<void> _login() async {
    String? password = await _storage.read(key: 'app_password');
    if (_passwordController.text == password) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).invalidPasswordMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).authenticationTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_showPasswordLogin)
                    Column(
                      children: [
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: S.of(context).passwordLabel,
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock),
                          ),
                          obscureText: true,
                          autofocus: true,
                          onSubmitted: (value) =>
                              _login(), // Trigger login on Enter
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 50, vertical: 20),
                            textStyle: TextStyle(fontSize: 18),
                          ),
                          child: Text(S.of(context).loginButton),
                        ),
                      ],
                    ),
                  if (_isBiometricAvailable &&
                      _isBiometricEnabled &&
                      !_showPasswordLogin)
                    Column(
                      children: [
                        GestureDetector(
                          onTap: _authenticate,
                          child: Column(
                            children: [
                              Icon(
                                Icons.fingerprint,
                                size: 60,
                                color: Colors.blueAccent,
                              ),
                              SizedBox(height: 10),
                              Text(
                                S.of(context).biometricPrompt,
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:io';
import 'ui_helper.dart';
import 'generated/l10n.dart';

class PasswordSettingsScreen extends StatefulWidget {
  const PasswordSettingsScreen({super.key});

  @override
  _PasswordSettingsScreenState createState() => _PasswordSettingsScreenState();
}

class _PasswordSettingsScreenState extends State<PasswordSettingsScreen> {
  final _storage = FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  bool _isPasswordEnabled = false;
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  String _biometricMessage = '';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _checkBiometricAvailability();
  }

  Future<void> _loadPreferences() async {
    String? passwordEnabled = await _storage.read(key: 'password_enabled');
    String? biometricEnabled = await _storage.read(key: 'biometric_enabled');
    setState(() {
      _isPasswordEnabled = passwordEnabled == 'true';
      _isBiometricEnabled = biometricEnabled == 'true';
    });
  }

  Future<void> _checkBiometricAvailability() async {
    List<BiometricType> availableBiometrics =
        await _localAuth.getAvailableBiometrics();

    setState(() {
      if (availableBiometrics.isEmpty) {
        _isBiometricAvailable = false;
        _biometricMessage = S.of(context).noBiometricsRegistered;
      } else if (!availableBiometrics.contains(BiometricType.strong)) {
        _isBiometricAvailable = false;
        _biometricMessage = S.of(context).biometricsNotStrongEnough;
      } else {
        _isBiometricAvailable = true;
        _biometricMessage = '';
      }
    });
  }

  Future<void> _setPassword(String password) async {
    await _storage.write(key: 'app_password', value: password);
    UIHelper.showSnackBar(S.of(context).passwordSetSuccessfully);
  }

  Future<void> _togglePassword(bool enabled) async {
    if (enabled) {
      String? password = await _showPasswordSetupDialog();
      if (password != null) {
        await _setPassword(password);
        await _storage.write(key: 'password_enabled', value: 'true');
        setState(() {
          _isPasswordEnabled = true;
        });
      } else {
        setState(() {
          _isPasswordEnabled = false;
        });
      }
    } else {
      String? currentPassword =
          await _showPasswordInputDialog(S.of(context).enterPasswordToDisable);
      if (currentPassword != null && await _validatePassword(currentPassword)) {
        await _storage.write(key: 'password_enabled', value: 'false');
        await _storage.delete(key: 'app_password');
        await _storage.delete(key: 'biometric_enabled');
        setState(() {
          _isPasswordEnabled = false;
          _isBiometricEnabled = false;
        });
      } else {
        setState(() {
          _isPasswordEnabled = true;
        });
      }
    }
  }

  Future<void> _toggleBiometric(bool enabled) async {
    bool authenticated = await _authenticate();
    if (!authenticated) {
      UIHelper.showSnackBar(S.of(context).biometricAuthenticationFailed);
      return;
    }
    if (enabled) {
      await _storage.write(key: 'biometric_enabled', value: 'true');
      setState(() {
        _isBiometricEnabled = true;
      });
      UIHelper.showSnackBar(S.of(context).biometricAuthenticationEnabled);
    } else {
      await _storage.write(key: 'biometric_enabled', value: 'false');
      setState(() {
        _isBiometricEnabled = false;
      });
      UIHelper.showSnackBar(S.of(context).biometricAuthenticationDisabled);
    }
  }

  Future<bool> _authenticate() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: S.of(context).authenticateToEnableBiometric,
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  Future<bool> _validatePassword(String password) async {
    String? storedPassword = await _storage.read(key: 'app_password');
    return storedPassword == password;
  }

  Future<String?> _showPasswordSetupDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => _PasswordSetupDialog(),
    );
  }

  Future<String?> _showPasswordInputDialog(String title) async {
    return showDialog<String>(
      context: context,
      builder: (context) => _PasswordInputDialog(title: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).passwordSettingsTitle)),
      body: ListView(
        children: [
          ListTile(
            title: Text(S.of(context).enablePassword),
            trailing: Switch(
              value: _isPasswordEnabled,
              onChanged: (value) async {
                await _togglePassword(value);
              },
            ),
          ),
          if (_isPasswordEnabled)
            ListTile(
              title: Text(S.of(context).changePassword),
              trailing: Icon(Icons.lock),
              onTap: () async {
                String? currentPassword = await _showPasswordInputDialog(
                    S.of(context).enterCurrentPassword);
                if (currentPassword != null &&
                    await _validatePassword(currentPassword)) {
                  String? newPassword = await _showPasswordSetupDialog();
                  if (newPassword != null) {
                    await _setPassword(newPassword);
                  }
                }
              },
            ),
          if (_isPasswordEnabled && !Platform.isWindows)
            ListTile(
              title: Text(S.of(context).enableFingerprintAuthentication),
              trailing: Switch(
                value: _isBiometricEnabled,
                onChanged: _isBiometricAvailable
                    ? (value) async {
                        await _toggleBiometric(value);
                      }
                    : null,
              ),
              subtitle: !_isBiometricAvailable ? Text(_biometricMessage) : null,
            ),
        ],
      ),
    );
  }
}

class _PasswordSetupDialog extends StatefulWidget {
  @override
  __PasswordSetupDialogState createState() => __PasswordSetupDialogState();
}

class __PasswordSetupDialogState extends State<_PasswordSetupDialog> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _errorMessage;

  void _submit() {
    if (_passwordController.text == _confirmPasswordController.text) {
      Navigator.pop(context, _passwordController.text);
    } else {
      setState(() {
        _errorMessage = S.of(context).passwordsDoNotMatch;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context).setPasswordTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(labelText: S.of(context).passwordLabel),
            obscureText: true,
            autofocus: true,
          ),
          TextField(
            controller: _confirmPasswordController,
            decoration:
                InputDecoration(labelText: S.of(context).confirmPasswordLabel),
            obscureText: true,
            onSubmitted: (_) => _submit(),
          ),
          if (_errorMessage != null)
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red),
            ),
          SizedBox(height: 10),
          Text(
            S.of(context).passwordSetupWarning,
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(S.of(context).cancelButton),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(S.of(context).submitButton),
        ),
      ],
    );
  }
}

class _PasswordInputDialog extends StatefulWidget {
  final String title;

  const _PasswordInputDialog({required this.title});

  @override
  __PasswordInputDialogState createState() => __PasswordInputDialogState();
}

class __PasswordInputDialogState extends State<_PasswordInputDialog> {
  final _passwordController = TextEditingController();
  String? _errorMessage;

  void _submit() {
    Navigator.pop(context, _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(labelText: S.of(context).passwordLabel),
            obscureText: true,
            autofocus: true,
            onSubmitted: (_) => _submit(),
          ),
          if (_errorMessage != null)
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(S.of(context).cancelButton),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(S.of(context).submitButton),
        ),
      ],
    );
  }
}

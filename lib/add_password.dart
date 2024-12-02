import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'username_manager.dart';
import 'password_manager.dart';
import 'password_entry.dart';
import 'random_password_generator.dart';
import 'generated/l10n.dart';

class AddPasswordScreen extends StatefulWidget {
  final PasswordEntry? entry;

  const AddPasswordScreen({super.key, this.entry});

  @override
  _AddPasswordScreenState createState() => _AddPasswordScreenState();
}

class _AddPasswordScreenState extends State<AddPasswordScreen> {
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _customSymbolsController =
      TextEditingController(text: '!@#\$%^&*()-_+=<>?');
  String? _selectedUsername;
  static const String defaultCustomSymbols = '!@#\$%^&*()-_+=<>?';

  bool _includeUppercase = true;
  bool _includeLowercase = true;
  bool _includeNumbers = true;
  bool _includeSymbols = true;
  double _passwordLength = 16;
  bool _isStarred = false;
  bool _showPasswordOptions = false;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _keyController.text = widget.entry!.key;
      _userController.text = widget.entry!.user;
      _passwordController.text = widget.entry!.password;
      _selectedUsername = widget.entry!.user;
      _isStarred = widget.entry!.isStarred;
    } else {
      _selectedUsername = S.current.enterNewUsername;
    }
    _keyController.addListener(_forceKeyUppercase);
  }

  @override
  void dispose() {
    _keyController.removeListener(_forceKeyUppercase);
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usernameManager = Provider.of<UsernameManager>(context);
    final passwordManager = Provider.of<PasswordManager>(context);

    // Ensure _selectedUsername is in the list or set to enterNewUserText
    if (_selectedUsername != S.of(context).enterNewUsername &&
        !usernameManager.usernames.contains(_selectedUsername)) {
      _selectedUsername = S.of(context).enterNewUsername;
      _userController.text = widget.entry?.user ?? '';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null
            ? S.of(context).addPasswordTitle
            : S.of(context).editPasswordTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            TextField(
              controller: _keyController,
              decoration: InputDecoration(labelText: S.of(context).keyLabel),
              enabled: widget.entry == null, // Disable key field if editing
            ),
            DropdownButtonFormField<String>(
              value: _selectedUsername,
              hint: Text(S.of(context).selectOrTypeUsername),
              items: [
                S.of(context).enterNewUsername,
                ...usernameManager.usernames
              ].map((username) {
                return DropdownMenuItem<String>(
                  value: username,
                  child: Text(username),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedUsername = value;
                  if (value != S.of(context).enterNewUsername) {
                    _userController.text = value ?? '';
                  } else {
                    _userController.clear();
                  }
                });
              },
            ),
            if (_selectedUsername == S.of(context).enterNewUsername)
              TextField(
                controller: _userController,
                decoration:
                    InputDecoration(labelText: S.of(context).usernameLabel),
              ),
            TextField(
              controller: _passwordController,
              decoration:
                  InputDecoration(labelText: S.of(context).passwordLabel),
              obscureText: false, // Password field is not obscured
            ),
            SizedBox(height: 10), // Add separation
            ElevatedButton(
              onPressed: () {
                _generateRandomPassword();
              },
              child: Text(S.of(context).generateRandomPassword),
            ),
            SizedBox(height: 20),
            ListTile(
              title: Text(S.of(context).advancedPasswordOptions),
              trailing: IconButton(
                icon: Icon(_showPasswordOptions
                    ? Icons.expand_less
                    : Icons.expand_more),
                onPressed: () {
                  setState(() {
                    _showPasswordOptions = !_showPasswordOptions;
                  });
                },
              ),
            ),
            if (_showPasswordOptions)
              Column(
                children: [
                  SwitchListTile(
                    title: Text(S.of(context).includeUppercaseLetters),
                    value: _includeUppercase,
                    onChanged: (value) {
                      setState(() {
                        _includeUppercase = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: Text(S.of(context).includeLowercaseLetters),
                    value: _includeLowercase,
                    onChanged: (value) {
                      setState(() {
                        _includeLowercase = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: Text(S.of(context).includeNumbers),
                    value: _includeNumbers,
                    onChanged: (value) {
                      setState(() {
                        _includeNumbers = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: Text(S.of(context).includeSymbols),
                    value: _includeSymbols,
                    onChanged: (value) {
                      setState(() {
                        _includeSymbols = value;
                      });
                    },
                  ),
                  TextField(
                    controller: _customSymbolsController,
                    decoration: InputDecoration(
                      labelText: S.of(context).customSymbolsLabel,
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.clear),
                            tooltip: S.of(context).clearCustomSymbols,
                            onPressed: _clearCustomSymbols,
                          ),
                          IconButton(
                            icon: Icon(Icons.refresh),
                            tooltip: S.of(context).resetCustomSymbols,
                            onPressed: _resetCustomSymbols,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                      '${S.of(context).passwordLength}: ${_passwordLength.toInt()}'),
                  Slider(
                    value: _passwordLength,
                    min: 6,
                    max: 30,
                    divisions: 24,
                    label: _passwordLength.toInt().toString(),
                    onChanged: (value) {
                      setState(() {
                        _passwordLength = value;
                      });
                    },
                  ),
                ],
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _savePassword(context, passwordManager);
              },
              child: Text(S.of(context).saveButton),
            ),
          ],
        ),
      ),
    );
  }

  void _clearCustomSymbols() {
    _customSymbolsController.clear();
  }

  void _resetCustomSymbols() {
    _customSymbolsController.text = defaultCustomSymbols;
  }

  void _savePassword(BuildContext context, PasswordManager passwordManager) {
    final key = _keyController.text.trim().toUpperCase();
    final user = _userController.text.trim();
    final password = _passwordController.text.trim();

    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).keyRequiredMessage)),
      );
      return;
    }

    final newEntry = PasswordEntry(
      key: key,
      user: user,
      password: password,
      isStarred: _isStarred,
    );

    if (widget.entry == null) {
      // Adding a new entry
      bool keyExists = passwordManager.entries.any((entry) => entry.key == key);

      if (keyExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).keyExistsMessage),
          ),
        );
        return;
      }

      passwordManager.addEntry(newEntry);
    } else {
      // Editing an existing entry
      passwordManager.editEntry(widget.entry!, newEntry);
    }

    Navigator.pop(context);
  }

  void _generateRandomPassword() {
    try {
      String customSymbols = _customSymbolsController.text;
      if (_includeSymbols && customSymbols.isEmpty) {
        throw ArgumentError(S.of(context).customSymbolsCannotBeEmpty);
      }

      final randomPassword = PasswordGenerator.generatePassword(
        length: _passwordLength.toInt(),
        includeUppercase: _includeUppercase,
        includeLowercase: _includeLowercase,
        includeNumbers: _includeNumbers,
        includeSymbols: _includeSymbols,
        customSymbols: customSymbols,
      );
      setState(() {
        _passwordController.text = randomPassword;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _forceKeyUppercase() {
    _keyController.value = _keyController.value.copyWith(
      text: _keyController.text.toUpperCase(),
      selection: _keyController.selection,
    );
  }
}

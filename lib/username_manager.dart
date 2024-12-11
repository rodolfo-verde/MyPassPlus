import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class UsernameManager extends ChangeNotifier {
  List<String> _usernames = [];
  final _storage = const FlutterSecureStorage();

  UsernameManager() {
    _loadUsernames();
  }

  List<String> get usernames => _usernames;

  Future<void> _loadUsernames() async {
    final String? usernamesJson = await _storage.read(key: 'usernames');
    if (usernamesJson != null) {
      _usernames = List<String>.from(jsonDecode(usernamesJson));
      notifyListeners();
    }
  }

  Future<void> _saveUsernames() async {
    await _storage.write(key: 'usernames', value: jsonEncode(_usernames));
  }

  void addUsername(String username) {
    // Check if the username is already in the list and dont add it again
    if (_usernames.contains(username)) {
      return;
    }
    _usernames.add(username);
    _saveUsernames();
    notifyListeners();
  }

  void deleteUsername(String username) {
    _usernames.remove(username);
    _saveUsernames();
    notifyListeners();
  }

  void editUsername(String oldUsername, String newUsername) {
    int index = _usernames.indexOf(oldUsername);
    if (index != -1) {
      _usernames[index] = newUsername;
      _saveUsernames();
      notifyListeners();
    }
  }
}

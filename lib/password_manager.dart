import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import the secure storage package
import 'dart:convert'; // For JSON encoding/decoding
import 'password_entry.dart';

class PasswordManager extends ChangeNotifier {
  List<PasswordEntry> _entries = [];
  final _storage =
      const FlutterSecureStorage(); // Create an instance of FlutterSecureStorage

  PasswordManager() {
    _loadEntries(); // Load entries from secure storage when the manager is created
  }

  List<PasswordEntry> get entries => _entries;

  // Load entries from secure storage
  Future<void> _loadEntries() async {
    final String? entriesJson = await _storage.read(key: 'password_entries');
    if (entriesJson != null) {
      List<dynamic> decodedList = jsonDecode(entriesJson);
      _entries = decodedList.map((e) => PasswordEntry.fromJson(e)).toList();
      notifyListeners();
    }
  }

  // Save entries to secure storage
  Future<void> _saveEntries() async {
    List<Map<String, dynamic>> encodedList =
        _entries.map((e) => e.toJson()).toList();
    await _storage.write(
        key: 'password_entries', value: jsonEncode(encodedList));
  }

  // Filter entries based on search query
  List<PasswordEntry> filteredEntries(String query) {
    List<PasswordEntry> filtered = _entries
        .where((entry) => entry.key.toLowerCase().contains(query.toLowerCase()))
        .toList();
    List<PasswordEntry> started =
        filtered.where((entry) => entry.isStarred).toList();
    List<PasswordEntry> nonStarred =
        filtered.where((entry) => !entry.isStarred).toList();
    return started + nonStarred;
  }

  Future<void> clearEntries() async {
    _entries = [];
    await _storage.delete(key: 'password_entries');
    notifyListeners();
  }

  // Add new entry
  Future<void> addEntry(PasswordEntry entry) async {
    _entries.add(entry);
    await _saveEntries(); // Save to secure storage after adding an entry
    notifyListeners();
  }

  // Edit existing entry
  Future<void> editEntry(PasswordEntry oldEntry, PasswordEntry newEntry) async {
    final index = _entries.indexOf(oldEntry);
    if (index != -1) {
      _entries[index] = newEntry;
      await _saveEntries(); // Save to secure storage after editing an entry
      notifyListeners();
    }
  }

  // Delete an entry
  Future<void> deleteEntry(PasswordEntry entry) async {
    _entries.remove(entry);
    await _saveEntries(); // Save to secure storage after deleting an entry
    notifyListeners();
  }

  // Toggle star status
  Future<void> toggleStar(PasswordEntry entry) async {
    final index = _entries.indexOf(entry);
    if (index != -1) {
      _entries[index].isStarred = !_entries[index].isStarred;
      await _saveEntries(); // Save to secure storage after toggling star status
      notifyListeners();
    }
  }

  // clearAllEntries
  Future<void> clearAllEntries() async {
    _entries = [];
    await _storage.deleteAll();
    notifyListeners();
  }

  // Merge entries (used for syncing and importing)
  Future<void> mergeEntries(List<PasswordEntry> newEntries) async {
    for (var newEntry in newEntries) {
      final index = _entries.indexWhere((entry) => entry.key == newEntry.key);
      if (index != -1) {
        editEntry(_entries[index], newEntry);
      } else {
        _entries.add(newEntry);
      }
    }
    await _saveEntries();
    notifyListeners();
  }

  // Replace entries (used for importing)
  Future<void> replaceEntries(List<PasswordEntry> newEntries) async {
    _entries = newEntries;
    await _saveEntries();
    notifyListeners();
  }
}

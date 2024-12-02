import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'password_manager.dart';
import 'add_password.dart';
import 'password_entry.dart';
import 'settings_screen.dart';
import 'ui_helper.dart';
import 'dart:io';
import 'generated/l10n.dart';

class PasswordListScreen extends StatefulWidget {
  const PasswordListScreen({super.key});

  @override
  _PasswordListScreenState createState() => _PasswordListScreenState();
}

class _PasswordListScreenState extends State<PasswordListScreen> {
  bool showPasswords = false;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final passwordManager = Provider.of<PasswordManager>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).appTitle),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            tooltip: S.of(context).addEntryTooltip,
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => AddPasswordScreen()));
            },
          ),
          IconButton(
            icon: Icon(showPasswords ? Icons.visibility : Icons.visibility_off),
            tooltip: S.of(context).togglePasswordVisibilityTooltip,
            onPressed: () {
              setState(() {
                showPasswords = !showPasswords;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.settings),
            tooltip: S.of(context).settingsTooltip,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              autofocus: Platform.isWindows, // Autofocus on Windows
              decoration: InputDecoration(
                labelText: S.of(context).searchLabel,
                prefixIcon: Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: passwordManager.filteredEntries(searchQuery).length,
              itemBuilder: (context, index) {
                var entry = passwordManager.filteredEntries(searchQuery)[index];
                return PasswordEntryTile(
                  entry: entry,
                  showPasswords: showPasswords,
                  onDelete: () => passwordManager.deleteEntry(entry),
                  onToggleStar: () => passwordManager.toggleStar(entry),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PasswordEntryTile extends StatelessWidget {
  final PasswordEntry entry;
  final bool showPasswords;
  final VoidCallback onDelete;
  final VoidCallback onToggleStar;

  const PasswordEntryTile({
    super.key,
    required this.entry,
    required this.showPasswords,
    required this.onDelete,
    required this.onToggleStar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 4.0,
      child: ListTile(
        leading: IconButton(
          icon: Icon(
            entry.isStarred ? Icons.star : Icons.star_border,
            color: entry.isStarred ? Colors.yellow : null,
          ),
          onPressed: onToggleStar,
        ),
        title: Text(entry.key, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${S.of(context).userLabel}${entry.user}'),
            Text(
              '${S.of(context).passwordLabelMain}${showPasswords ? entry.password : '*******'}',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.vpn_key),
              tooltip: S.of(context).copyPasswordTooltip,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: entry.password));
                UIHelper.showSnackBar(S.of(context).passwordCopiedMessage);
              },
            ),
            IconButton(
              icon: Icon(Icons.person),
              tooltip: S.of(context).copyUsernameTooltip,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: entry.user));
                UIHelper.showSnackBar(S.of(context).usernameCopiedMessage);
              },
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddPasswordScreen(entry: entry),
                    ),
                  );
                } else if (value == 'delete') {
                  bool? confirmDelete =
                      await UIHelper.showConfirmDeleteDialog(context);
                  if (confirmDelete == true) {
                    onDelete();
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Text(S.of(context).edit),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(S.of(context).delete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

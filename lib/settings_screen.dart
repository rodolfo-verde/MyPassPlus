import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:window_manager/window_manager.dart';
import 'package:downloadsfolder/downloadsfolder.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'manage_usernames.dart';
import 'theme_notifier.dart';
import 'password_manager.dart';
import 'ui_helper.dart'; // Import UIHelper
import 'password_entry.dart';
import 'password_settings_screen.dart'; // Import PasswordSettingsScreen
import 'local_connection_screen.dart'; // Import LocalConnectionScreen
import 'generated/l10n.dart'; // Import localization

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _stayOnTop = false;
  String _alignment = 'None';
  bool _isPickingFile = false;
  bool _isModalVisible = false;
  bool _includeStarred = true;
  String _delimiter = ',';
  bool _includeHeader = true;
  String? _selectedDirectoryPath;
  final bool _showDevButton = true; // Toggle this to show/hide the dev button
  String _selectedLanguage = 'en'; // Add this line

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadLanguagePreference(); // Add this line
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _stayOnTop = prefs.getBool('stayOnTop') ?? false;
      _alignment = prefs.getString('alignment') ?? 'None';
      _includeStarred = prefs.getBool('includeStarred') ?? true;
      _delimiter = prefs.getString('delimiter') ?? ',';
      _includeHeader = prefs.getBool('includeHeader') ?? true;
      _selectedLanguage = prefs.getString('language') ?? 'en';
    });
  }

  Future<void> _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('language') ?? 'en';
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('includeStarred', _includeStarred);
    await prefs.setString('delimiter', _delimiter);
    await prefs.setBool('includeHeader', _includeHeader);
    await prefs.setString('language', _selectedLanguage); // Add this line
  }

  Future<void> _setStayOnTop(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _stayOnTop = value;
    });
    await prefs.setBool('stayOnTop', value);
    await windowManager.setAlwaysOnTop(value);
  }

  Future<void> _setAlignment(String value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _alignment = value;
    });
    await prefs.setString('alignment', value);

    if (Platform.isWindows) {
      switch (value) {
        case 'TopLeft':
          windowManager.setAlignment(Alignment.topLeft);
          break;
        case 'TopRight':
          windowManager.setAlignment(Alignment.topRight);
          break;
        case 'Center':
          windowManager.setAlignment(Alignment.center);
          break;
      }
    }
  }

  Future<void> _setLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = language;
    });
    await prefs.setString('language', language);
    S.load(Locale(language));
  }

  Future<void> _temporarilyDisableStayOnTop(
      Future<void> Function() action) async {
    if (Platform.isWindows) {
      bool isAlwaysOnTop = await windowManager.isAlwaysOnTop();
      setState(() {
        _isPickingFile = true;
      });
      await windowManager.setAlwaysOnTop(false);
      await Future.delayed(Duration(milliseconds: 100));
      await action();
      await windowManager.setAlwaysOnTop(isAlwaysOnTop);
      setState(() {
        _isPickingFile = false;
      });
    } else {
      await action();
    }
  }

  Future<void> _showRoleSelectionDialog(BuildContext context) async {
    bool? isSender = await showDialog<bool>(
      context: context,
      barrierDismissible: true, // Allow dismissing by clicking outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).selectRole), // Localized string
          content: Text(
              S.of(context).doYouWantToSendOrReceiveData), // Localized string
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(S.of(context).send), // Localized string
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(S.of(context).receive), // Localized string
            ),
          ],
        );
      },
    );

    if (isSender == null) {
      UIHelper.showSnackBar(
          S.of(context).roleSelectionCancelled); // Localized string
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LocalConnectionScreen(isSender: isSender),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final passwordManager = Provider.of<PasswordManager>(context);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(S.of(context).settingsTitle), // Localized title
          ),
          body: ListView(
            children: [
              ListTile(
                title: Text(S.of(context).darkMode), // Localized string
                trailing: Switch(
                  value: themeNotifier.isDarkMode,
                  onChanged: (value) {
                    themeNotifier.toggleTheme();
                  },
                ),
              ),
              if (Platform.isWindows)
                ListTile(
                  title: Text(S.of(context).stayOnTop), // Localized string
                  trailing: Switch(
                    value: _stayOnTop,
                    onChanged: (value) {
                      _setStayOnTop(value);
                    },
                  ),
                ),
              ListTile(
                title: Text(S.of(context).language), // Localized string
                trailing: DropdownButton<String>(
                  value: _selectedLanguage,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _setLanguage(newValue);
                    }
                  },
                  items: <String>[
                    'en',
                    'es',
                  ] // Add supported languages here
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
              if (Platform.isWindows)
                ListTile(
                  title:
                      Text(S.of(context).windowAlignment), // Localized string
                  trailing: DropdownButton<String>(
                    value: _alignment,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        _setAlignment(newValue);
                      }
                    },
                    items: <Map<String, String>>[
                      {
                        'value': 'None',
                        'display': S.of(context).alignmentValueNone
                      },
                      {
                        'value': 'Center',
                        'display': S.of(context).alignmentValueCenter
                      },
                      {
                        'value': 'TopLeft',
                        'display': S.of(context).alignmentValueTopLeft
                      },
                      {
                        'value': 'TopRight',
                        'display': S.of(context).alignmentValueTopRight
                      },
                    ].map<DropdownMenuItem<String>>((Map<String, String> item) {
                      return DropdownMenuItem<String>(
                        value: item['value'],
                        child: Text(item['display']!),
                      );
                    }).toList(),
                  ),
                ),
              ListTile(
                title: Text(S.of(context).manageUsernames), // Localized string
                trailing: Icon(Icons.arrow_forward),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ManageUsernamesScreen()),
                  );
                },
              ),
              ListTile(
                title: Text(S.of(context).localConnection), // Localized string
                trailing: Icon(Icons.wifi),
                onTap: () async {
                  await _showRoleSelectionDialog(context);
                },
              ),
              ListTile(
                title: Text(S.of(context).exportData), // Localized string
                trailing: Icon(Icons.download),
                onTap: () async {
                  await _exportDataAsCSV(passwordManager, context);
                },
              ),
              ListTile(
                title: Text(S.of(context).importData), // Localized string
                trailing: Icon(Icons.upload),
                onTap: () async {
                  await _temporarilyDisableStayOnTop(() async {
                    await _importData(passwordManager, context);
                  });
                },
              ),
              if (Platform.isAndroid)
                ListTile(
                  title: Text(
                      S.of(context).openDownloadsFolder), // Localized string
                  trailing: Icon(Icons.folder_open),
                  onTap: () async {
                    bool success = await openDownloadFolder();
                    if (!success) {
                      UIHelper.showSnackBar(S
                          .of(context)
                          .failedToOpenDownloadsFolder); // Localized string
                    }
                  },
                ),
              ListTile(
                title: Text(S.of(context).passwordSettings), // Localized string
                trailing: Icon(Icons.lock),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PasswordSettingsScreen()),
                  );
                },
              ),
              Visibility(
                visible: _showDevButton,
                child: ListTile(
                  title: Text(S.of(context).deleteAllData), // Localized string
                  trailing: Icon(Icons.delete),
                  onTap: () async {
                    await _deleteAllData(passwordManager);
                  },
                ),
              ),
            ],
          ),
        ),
        if (_isPickingFile)
          ModalBarrier(
            dismissible: false,
            color: Colors.black.withOpacity(0.5),
          ),
      ],
    );
  }

  Future<void> _deleteAllData(PasswordManager passwordManager) async {
    await passwordManager.clearAllEntries();
    UIHelper.showSnackBar(
        S.current.allDataDeletedSuccessfully); // Localized string
  }

  Future<void> _exportDataAsCSV(
      PasswordManager passwordManager, BuildContext context) async {
    Map<String, dynamic>? exportOptions =
        await _showExportOptionsDialog(context);

    if (exportOptions == null) {
      UIHelper.showSnackBar(S.of(context).exportCancelled); // Localized string
      return;
    }

    // Save preferences
    await _savePreferences();

    // Create the CSV data
    List<List<String>> data = [
      if (_includeHeader)
        _includeStarred
            ? ['Key', 'User', 'Password', 'isStarred']
            : ['Key', 'User', 'Password'],
      ...passwordManager.entries.map((entry) {
        return _includeStarred
            ? [
                entry.key,
                entry.user,
                entry.password,
                entry.isStarred.toString()
              ]
            : [entry.key, entry.user, entry.password];
      }),
    ];

    String csvData =
        const ListToCsvConverter().convert(data, fieldDelimiter: _delimiter);

    // Save the CSV file
    String? directoryPath = exportOptions['directoryPath'];
    if (Platform.isAndroid) {
      final downloadFolder = await getDownloadDirectory();
      directoryPath = downloadFolder.path;
    }
    final filePath = '$directoryPath/exported_passwords.csv';
    final file = File(filePath);

    if (await file.exists()) {
      bool? overwrite = await UIHelper.showOverwriteDialog(context);

      if (overwrite != true) {
        UIHelper.showSnackBar(
            S.of(context).exportCancelled); // Localized string
        return;
      }
    }

    try {
      await file.writeAsString(csvData);
    } catch (e) {
      UIHelper.showSnackBar('$e',
          duration: Duration(seconds: 5)); // Localized string
      return;
    }
    UIHelper.showSnackBar(
        S.of(context).dataExportedSuccessfully); // Localized string
  }

  Future<void> _importData(
      PasswordManager passwordManager, BuildContext context) async {
    // Show file picker
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );
    } on PlatformException catch (e) {
      UIHelper.showSnackBar(
          '${S.of(context).errorPickingFile} ${e.message}'); // Localized string
      return;
    }

    if (result == null) {
      UIHelper.showSnackBar(S.of(context).importCancelled); // Localized string
      return;
    }

    // Read the CSV file
    final file = File(result.files.single.path!);
    final csvData = await file.readAsString();

    // Detect delimiter
    String delimiter = csvData.contains(';') ? ';' : ',';

    // Detect header
    List<dynamic> firstRow = const CsvToListConverter()
        .convert(csvData, fieldDelimiter: delimiter)
        .first;
    bool hasHeader = firstRow.contains('Key') &&
        firstRow.contains('User') &&
        firstRow.contains('Password');

    // print(cleanedCsvData);

    // Parse the cleaned CSV data
    final List<List<dynamic>> data = CsvToListConverter()
        .convert(csvData, fieldDelimiter: delimiter, shouldParseNumbers: false);

    // Process the CSV data
    List<PasswordEntry> entries = [];
    try {
      for (int i = hasHeader ? 1 : 0; i < data.length; i++) {
        final row = data[i];
        if (row.isEmpty) {
          continue;
        }
        entries.add(PasswordEntry(
          key: row[0],
          user: row[1],
          password: row[2],
          isStarred: row.length > 3 ? row[3] == 'true' : false,
        ));
      }
    } catch (e) {
      UIHelper.showSnackBar(
          '${S.of(context).errorParsingCSVData} $e'); // Localized string
      return;
    }

    // Show import options dialog
    bool? replace = await UIHelper.showMergeOrReplaceDialog(context);

    if (replace == null) {
      UIHelper.showSnackBar(S.of(context).importCancelled); // Localized string
      return;
    }

    if (replace == true) {
      await passwordManager.replaceEntries(entries);
      UIHelper.showSnackBar(
          S.of(context).entriesReplacedSuccessfully); // Localized string
    } else {
      await passwordManager.mergeEntries(entries);
      UIHelper.showSnackBar(
          S.of(context).entriesAddedSuccessfully); // Localized string
    }
  }

  Future<Map<String, dynamic>?> _showExportOptionsDialog(
      BuildContext context) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Stack(
              children: [
                AlertDialog(
                  title: Text(
                      S.of(context).exportOptionsTitle), // Localized string
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!Platform.isAndroid)
                          ElevatedButton(
                            onPressed: () async {
                              await _temporarilyDisableStayOnTop(() async {
                                setState(() {
                                  _isModalVisible = true;
                                });
                                await Future.delayed(
                                    Duration(milliseconds: 100));
                                String? directoryPath = await FilePicker
                                    .platform
                                    .getDirectoryPath();
                                if (directoryPath != null) {
                                  setState(() {
                                    _selectedDirectoryPath = directoryPath;
                                  });
                                }
                                setState(() {
                                  _isModalVisible = false;
                                });
                              });
                            },
                            child: Text(S
                                .of(context)
                                .selectDirectory), // Localized string
                          ),
                        if (_selectedDirectoryPath != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              '${S.of(context).selectedDirectory}: $_selectedDirectoryPath',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        CheckboxListTile(
                          title: Text(S.of(context).includeStarred),
                          value: _includeStarred,
                          onChanged: (bool? value) {
                            setState(() {
                              _includeStarred = value ?? true;
                            });
                          },
                        ),
                        CheckboxListTile(
                          title: Text(S.of(context).includeHeader),
                          value: _includeHeader,
                          onChanged: (bool? value) {
                            setState(() {
                              _includeHeader = value ?? true;
                            });
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              Text(
                                S.of(context).delimiter,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: DropdownButton<String>(
                                  value: _delimiter,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _delimiter = newValue ?? ',';
                                    });
                                  },
                                  items: <String>[',', ';']
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child:
                          Text(S.of(context).cancelButton), // Localized string
                    ),
                    TextButton(
                      onPressed:
                          Platform.isAndroid || _selectedDirectoryPath != null
                              ? () {
                                  Navigator.of(context).pop({
                                    'directoryPath': _selectedDirectoryPath,
                                  });
                                }
                              : null,
                      child:
                          Text(S.of(context).exportButton), // Localized string
                    ),
                  ],
                ),
                if (_isModalVisible)
                  ModalBarrier(
                    dismissible: false,
                    color: Colors.black.withOpacity(0.5),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

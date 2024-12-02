import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // Import for Uint8List
import 'package:encrypt/encrypt.dart' as encrypt;
import 'password_manager.dart';
import 'ui_helper.dart';
import 'password_entry.dart';
import 'generated/l10n.dart'; // Import for localization
import 'package:device_info_plus/device_info_plus.dart';

class EncryptedPackage {
  final Uint8List encryptedData;
  final Uint8List iv;

  EncryptedPackage(this.encryptedData, this.iv);

  Map<String, dynamic> toJson() => {
        'encryptedData': base64Encode(encryptedData),
        'iv': base64Encode(iv),
      };

  factory EncryptedPackage.fromJson(Map<String, dynamic> json) {
    return EncryptedPackage(
      base64Decode(json['encryptedData']),
      base64Decode(json['iv']),
    );
  }
}

class Receiver {
  final String name;
  final String ip;

  Receiver(this.name, this.ip);
}

class LocalConnectionScreen extends StatefulWidget {
  final bool isSender;
  const LocalConnectionScreen({super.key, required this.isSender});
  @override
  _LocalConnectionScreenState createState() => _LocalConnectionScreenState();
}

class _LocalConnectionScreenState extends State<LocalConnectionScreen> {
  String _receiverIp = '';
  final String _encryptionKey = 'my32lengthsupersecretnooneknows1'; // 32 chars
  final List<Receiver> _availableReceivers = [];
  ServerSocket? _serverSocket;
  RawDatagramSocket? _discoverySocket;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    if (widget.isSender) {
      setState(() => _isSearching = true);
      _discoverReceivers();
    } else {
      _receiveData();
    }
  }

  @override
  void dispose() {
    _serverSocket?.close();
    _discoverySocket?.close();
    super.dispose();
  }

  Future<void> _discoverReceivers() async {
    setState(() => _isSearching = true);
    _availableReceivers.clear();

    final interfaces = await NetworkInterface.list();
    final validInterfaces = interfaces.where((interface) => interface.addresses
        .any((addr) => addr.type == InternetAddressType.IPv4));

    for (var interface in validInterfaces) {
      if (!mounted) return;

      try {
        final addr = interface.addresses
            .firstWhere((addr) => addr.type == InternetAddressType.IPv4);

        final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
        socket.broadcastEnabled = true;
        _discoverySocket = socket;

        socket.listen((RawSocketEvent event) {
          if (event == RawSocketEvent.read) {
            Datagram? datagram = socket.receive();
            if (datagram != null) {
              String message = String.fromCharCodes(datagram.data);
              if (message.startsWith('RECEIVER_HERE')) {
                List<String> parts = message.split(':');
                String receiverName =
                    parts.length > 1 ? parts[1] : datagram.address.address;
                setState(() {
                  if (!_availableReceivers
                      .any((r) => r.ip == datagram.address.address)) {
                    _availableReceivers
                        .add(Receiver(receiverName, datagram.address.address));
                  }
                });
              }
            }
          }
        });

        // Send discovery message with device name
        final deviceName = await _getDeviceName();
        final discoveryMessage = 'DISCOVER_RECEIVERS:$deviceName';
        socket.send(utf8.encode(discoveryMessage),
            InternetAddress('255.255.255.255'), 4568);
      } catch (e) {
        // Silently handle errors
      }
    }

    await Future.delayed(Duration(seconds: 5));
    if (!mounted) return;

    _discoverySocket?.close();
    setState(() => _isSearching = false);

    if (_availableReceivers.isEmpty) {
      if (mounted) {
        // Check before showing snackbar
        UIHelper.showSnackBar(S.of(context).noReceiversFound);
      }
    } else {
      if (mounted) {
        // Check before showing dialog
        _showReceiverSelectionDialog();
      }
    }
  }

  void _showReceiverSelectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).selectReceiver), // Localized string
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _availableReceivers.map((receiver) {
              return ListTile(
                title: Text(receiver.name),
                subtitle: Text(receiver.ip),
                onTap: () {
                  setState(() {
                    _receiverIp = receiver.ip;
                  });
                  Navigator.of(context).pop();
                  _sendData();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _sendData() async {
    if (!mounted) return; // Check if widget is still mounted

    final passwordManager =
        Provider.of<PasswordManager>(context, listen: false);
    final data = passwordManager.entries.map((entry) {
      return {
        'key': entry.key,
        'user': entry.user,
        'password': entry.password,
        'isStarred': entry.isStarred,
      };
    }).toList();
    final jsonData = jsonEncode(data);
    final encryptedPackage = _encryptData(jsonData);
    final transferPackage = {
      'data': jsonEncode(encryptedPackage.toJson()),
      'deviceName': await _getDeviceName()
    };
    final socket = await Socket.connect(_receiverIp, 4567);
    socket.add(utf8.encode(jsonEncode(transferPackage)));
    await socket.flush();
    await socket.close();
    if (mounted) {
      // Check before showing snackbar
      UIHelper.showSnackBar(S.of(context).dataSentSuccessfully);
    }
  }

  Future<void> _receiveData() async {
    if (!mounted) return;

    try {
      final server =
          await ServerSocket.bind(InternetAddress.anyIPv4, 4567, shared: true);
      _serverSocket = server;
      server.listen((Socket socket) async {
        if (!mounted) {
          socket.close();
          return;
        }

        final receivedData = await socket.fold<Uint8List>(
            Uint8List(0), (buffer, data) => Uint8List.fromList(buffer + data));
        final transferPackage = jsonDecode(utf8.decode(receivedData));
        final packageJson = jsonDecode(transferPackage['data']);
        final senderName = transferPackage['deviceName'];
        final encryptedPackage = EncryptedPackage.fromJson(packageJson);
        final jsonData = _decryptData(encryptedPackage);
        final data = jsonDecode(jsonData) as List<dynamic>;
        final passwordManager =
            Provider.of<PasswordManager>(context, listen: false);
        final newEntries = data.map((entry) {
          return PasswordEntry(
            key: entry['key'],
            user: entry['user'],
            password: entry['password'],
            isStarred: entry['isStarred'],
          );
        }).toList();
        // You may need to implement a way to receive sender's name
        bool? replace = await showDialog<bool>(
          context: context,
          barrierDismissible: true, // Allow dismissing by clicking outside
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(S.of(context).importOptions), // Localized string
              content: Text(S
                  .of(context)
                  .receiverSentMessage(senderName)), // Changed this line
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(S.of(context).merge), // Localized string
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(S.of(context).replace), // Localized string
                ),
              ],
            );
          },
        );

        if (!mounted) return; // Check if widget is still mounted

        if (replace == null) {
          if (mounted) {
            UIHelper.showSnackBar(S.of(context).importCancelled);
          }
          return;
        }
        if (replace == true) {
          await passwordManager.replaceEntries(newEntries);
          UIHelper.showSnackBar(
              S.of(context).entriesReplacedSuccessfully); // Localized string
        } else {
          await passwordManager.mergeEntries(newEntries);
          UIHelper.showSnackBar(
              S.of(context).entriesAddedSuccessfully); // Localized string
        }
        await socket.close();
      });

      // Discovery response setup
      final discoverySocket =
          await RawDatagramSocket.bind(InternetAddress.anyIPv4, 4568);
      _discoverySocket = discoverySocket;
      discoverySocket.listen((RawSocketEvent event) async {
        if (event == RawSocketEvent.read) {
          Datagram? datagram = discoverySocket.receive();
          if (datagram != null) {
            String message = String.fromCharCodes(datagram.data);
            if (message.startsWith('DISCOVER_RECEIVERS')) {
              final deviceName = await _getDeviceName();
              final response = 'RECEIVER_HERE:$deviceName';
              discoverySocket.send(
                  utf8.encode(response), datagram.address, datagram.port);
            }
          }
        }
      });
    } catch (e) {
      // Silently handle errors
    }
  }

  EncryptedPackage _encryptData(String data) {
    final key = encrypt.Key.fromUtf8(_encryptionKey);
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encrypt(data, iv: iv);
    return EncryptedPackage(encrypted.bytes, iv.bytes);
  }

  String _decryptData(EncryptedPackage package) {
    final key = encrypt.Key.fromUtf8(_encryptionKey);
    final iv = encrypt.IV(package.iv);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypt.Encrypted(package.encryptedData);
    return encrypter.decrypt(encrypted, iv: iv);
  }

  Future<String> _getDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.model;
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        return windowsInfo.computerName;
      }
    } catch (e) {
      // Handle any errors
    }
    return "Unknown Device";
  }

  @override
  Widget build(BuildContext context) {
    String statusMessage = widget.isSender
        ? S.of(context).searchingForReceivers
        : S.of(context).waitingForSender;

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).localConnection),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.isSender && !_isSearching) ...[
              ElevatedButton(
                onPressed: _discoverReceivers,
                child: Text(S.of(context).retry),
              ),
            ] else ...[
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(statusMessage),
            ],
          ],
        ),
      ),
    );
  }
}

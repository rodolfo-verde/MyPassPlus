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

class LocalConnectionScreen extends StatefulWidget {
  final bool isSender;
  const LocalConnectionScreen({super.key, required this.isSender});
  @override
  _LocalConnectionScreenState createState() => _LocalConnectionScreenState();
}

class _LocalConnectionScreenState extends State<LocalConnectionScreen> {
  String _receiverIp = '';
  final String _encryptionKey = 'my32lengthsupersecretnooneknows1'; // 32 chars
  final List<String> _availableReceivers = [];
  ServerSocket? _serverSocket;
  RawDatagramSocket? _discoverySocket;
  @override
  void initState() {
    super.initState();
    if (widget.isSender) {
      print("I'm the sender");
      _discoverReceivers();
    } else {
      print("I'm the receiver");
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
    // Get all network interfaces
    final interfaces = await NetworkInterface.list();
    final validInterfaces = interfaces.where((interface) => interface.addresses
        .any((addr) => addr.type == InternetAddressType.IPv4));

    for (var interface in validInterfaces) {
      if (!mounted) return; // Check if widget is still mounted

      try {
        final addr = interface.addresses
            .firstWhere((addr) => addr.type == InternetAddressType.IPv4);

        final socket = await RawDatagramSocket.bind(addr, 0);
        socket.broadcastEnabled = true;
        _discoverySocket = socket;

        print('Binding to interface: ${interface.name} (${addr.address})');

        socket.listen((RawSocketEvent event) {
          if (event == RawSocketEvent.read) {
            Datagram? datagram = socket.receive();
            if (datagram != null) {
              String message = String.fromCharCodes(datagram.data);
              print(
                  'Received message: $message from ${datagram.address.address}');
              if (message == 'RECEIVER_HERE') {
                setState(() {
                  if (!_availableReceivers.contains(datagram.address.address)) {
                    _availableReceivers.add(datagram.address.address);
                  }
                });
              }
            }
          }
        });

        // Send broadcast on this interface
        print('Sending discovery message on ${addr.address}');
        socket.send(utf8.encode('DISCOVER_RECEIVERS'),
            InternetAddress('255.255.255.255'), 4568);
      } catch (e) {
        print('Error on interface ${interface.name}: $e');
      }
    }

    // Wait longer for responses on PC
    await Future.delayed(Duration(seconds: 5));
    if (!mounted) return; // Check if widget is still mounted

    _discoverySocket?.close();

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
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).selectReceiver), // Localized string
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _availableReceivers.map((receiverIp) {
              return ListTile(
                title: Text(receiverIp),
                onTap: () {
                  setState(() {
                    _receiverIp = receiverIp;
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
    final socket = await Socket.connect(_receiverIp, 4567);
    socket.add(utf8.encode(jsonEncode(encryptedPackage.toJson())));
    await socket.flush();
    await socket.close();
    if (mounted) {
      // Check before showing snackbar
      UIHelper.showSnackBar(S.of(context).dataSentSuccessfully);
    }
  }

  Future<void> _receiveData() async {
    if (!mounted) return; // Check if widget is still mounted

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
      final packageJson = jsonDecode(utf8.decode(receivedData));
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
      bool? replace = await showDialog<bool>(
        context: context,
        barrierDismissible: true, // Allow dismissing by clicking outside
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(S.of(context).importOptions), // Localized string
            content:
                Text(S.of(context).replaceOrMergeEntries), // Localized string
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
            S.of(context).mergeFunctionalityWorkInProgress); // Localized string
      }
      await socket.close();
    });
    // Respond to discovery messages
    final RawDatagramSocket discoverySocket =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, 4568);
    _discoverySocket = discoverySocket;
    discoverySocket.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        Datagram? datagram = discoverySocket.receive();
        if (datagram != null) {
          String message = String.fromCharCodes(datagram.data);
          if (message == 'DISCOVER_RECEIVERS') {
            discoverySocket.send(
                utf8.encode('RECEIVER_HERE'), datagram.address, datagram.port);
          }
        }
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).localConnection), // Localized string
      ),
      body: Center(
        child: Text(S.of(context).waitingForRoleSelection), // Localized string
      ),
    );
  }
}

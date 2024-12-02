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
    final RawDatagramSocket socket =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.broadcastEnabled = true;
    _discoverySocket = socket;
    socket.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        Datagram? datagram = socket.receive();
        if (datagram != null) {
          String message = String.fromCharCodes(datagram.data);
          if (message == 'RECEIVER_HERE') {
            setState(() {
              _availableReceivers.add(datagram.address.address);
            });
          }
        }
      }
    });
    // Broadcast message to discover receivers
    socket.send(utf8.encode('DISCOVER_RECEIVERS'),
        InternetAddress('255.255.255.255'), 4568);
    // Wait for a few seconds to gather responses
    await Future.delayed(Duration(seconds: 3));
    socket.close();
    if (_availableReceivers.isEmpty) {
      UIHelper.showSnackBar(S.of(context).noReceiversFound); // Localized string
    } else {
      _showReceiverSelectionDialog();
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
    final encryptedData = _encryptData(jsonData);
    final socket = await Socket.connect(_receiverIp, 4567);
    socket.add(encryptedData);
    await socket.flush();
    await socket.close();
    UIHelper.showSnackBar(
        S.of(context).dataSentSuccessfully); // Localized string
  }

  Future<void> _receiveData() async {
    final server =
        await ServerSocket.bind(InternetAddress.anyIPv4, 4567, shared: true);
    _serverSocket = server;
    server.listen((Socket socket) async {
      final encryptedData = await socket.fold<Uint8List>(
          Uint8List(0), (buffer, data) => Uint8List.fromList(buffer + data));
      final jsonData = _decryptData(encryptedData);
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
      if (replace == null) {
        UIHelper.showSnackBar(
            S.of(context).importCancelled); // Localized string
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

  Uint8List _encryptData(String data) {
    final key = encrypt.Key.fromUtf8(_encryptionKey);
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encrypt(data, iv: iv);
    return Uint8List.fromList(encrypted.bytes);
  }

  String _decryptData(Uint8List encryptedData) {
    final key = encrypt.Key.fromUtf8(_encryptionKey);
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypt.Encrypted(encryptedData);
    final decrypted = encrypter.decrypt(encrypted, iv: iv);
    return decrypted;
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

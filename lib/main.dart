import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/l10n.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:window_manager/window_manager.dart';
import 'auth_screen.dart';
import 'password_manager.dart';
import 'username_manager.dart';
import 'theme_notifier.dart';
import 'dart:io';
import 'dart:ui';
import 'password_list_screen.dart';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
Timer? _inactivityTimer;
final int logoutDelay = 60;
final _storage = FlutterSecureStorage();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows && !(await _ensureSingleInstance())) {
    exit(0);
  }
  final prefs = await SharedPreferences.getInstance();
  final stayOnTop = prefs.getBool('stayOnTop') ?? false;
  final alignment = prefs.getString('alignment') ?? 'None';

  if (prefs.getString('language') == null) {
    final deviceLanguage = PlatformDispatcher.instance.locale.languageCode;
    final supportedLanguages = ['en', 'es'];
    await prefs.setString('language',
        supportedLanguages.contains(deviceLanguage) ? deviceLanguage : 'en');
  }
  final language = prefs.getString('language') ?? 'en';

  runApp(MyApp(stayOnTop: stayOnTop, alignment: alignment, language: language));

  if (Platform.isWindows) {
    doWhenWindowReady(() async {
      final win = appWindow;
      win.minSize = Size(450, 150);
      win.size = Size(550, 470);

      await windowManager.ensureInitialized();
      switch (alignment) {
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
      WindowOptions windowOptions = WindowOptions(alwaysOnTop: stayOnTop);
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        win.show();
      });
    });
  }
}

Future<bool> _ensureSingleInstance() async {
  final result = await Process.run('tasklist', []);
  final matches =
      RegExp(r'MyPass+', caseSensitive: false).allMatches(result.stdout).length;
  return matches < 2;
}

class MyApp extends StatelessWidget {
  final bool stayOnTop;
  final String alignment;
  final String language;

  const MyApp(
      {super.key,
      required this.stayOnTop,
      required this.alignment,
      required this.language});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PasswordManager()),
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => UsernameManager()),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            scaffoldMessengerKey: scaffoldMessengerKey,
            title: 'Password Manager',
            theme:
                themeNotifier.isDarkMode ? ThemeData.dark() : ThemeData.light(),
            localizationsDelegates: [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
            locale: Locale(language),
            initialRoute: '/',
            routes: {
              '/': (context) => AuthScreen(),
              '/home': (context) => PasswordListScreen(),
            },
          );
        },
      ),
    );
  }
}

class LifecycleEventHandler extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (Platform.isAndroid) {
      switch (state) {
        case AppLifecycleState.paused:
          _checkPasswordAndStartTimer();
          break;
        case AppLifecycleState.resumed:
          _cancelLogoutTimer();
          break;
        default:
          break;
      }
    }
  }
}

// Timer management functions
Future<void> _checkPasswordAndStartTimer() async {
  String? passwordEnabled = await _storage.read(key: 'password_enabled');
  if (passwordEnabled == 'true') {
    _startLogoutTimer();
  }
}

void _startLogoutTimer() {
  _cancelLogoutTimer();
  _inactivityTimer = Timer(Duration(seconds: logoutDelay), () {
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushReplacementNamed('/');
    }
  });
}

void _cancelLogoutTimer() {
  if (_inactivityTimer != null && _inactivityTimer!.isActive) {
    _inactivityTimer!.cancel();
  }
}

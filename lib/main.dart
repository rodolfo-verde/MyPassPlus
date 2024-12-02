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

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/akobo_opener_screen.dart';
import 'theme/cyber_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge adaptive system bars
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  runApp(const AkoboApp());
}

class AkoboApp extends StatelessWidget {
  const AkoboApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arc Player',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system, // Automatically adapts to system light & dark mode
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: CyberTheme.lightBg,
        primaryColor: CyberTheme.primaryBlue,
        colorScheme: const ColorScheme.light(
          primary: CyberTheme.primaryBlue,
          secondary: CyberTheme.primaryBlueLight,
          surface: CyberTheme.lightSurface,
        ),
        cardColor: CyberTheme.lightCard,
        dividerColor: CyberTheme.lightBorder,
        splashColor: CyberTheme.primaryBlue.withValues(alpha: 0.1),
        highlightColor: CyberTheme.primaryBlueLight.withValues(alpha: 0.1),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: CyberTheme.darkBg,
        primaryColor: CyberTheme.primaryBlue,
        colorScheme: const ColorScheme.dark(
          primary: CyberTheme.primaryBlue,
          secondary: CyberTheme.primaryBlueLight,
          surface: CyberTheme.darkSurface,
        ),
        cardColor: CyberTheme.darkCard,
        dividerColor: CyberTheme.darkBorder,
        splashColor: CyberTheme.primaryBlue.withValues(alpha: 0.2),
        highlightColor: CyberTheme.primaryBlueLight.withValues(alpha: 0.2),
        useMaterial3: true,
      ),
      home: const AkoboOpenerScreen(),
    );
  }
}

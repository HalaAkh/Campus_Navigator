import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'utils/theme.dart';
import 'utils/app_state.dart';
import 'utils/app_navigator.dart';
import 'firebase_options.dart';
import 'services/beacon_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Initialize Firebase with a timeout to prevent hanging on startup
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 5));
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    // Firebase not configured or timed out — app will still run in demo mode
    debugPrint('Firebase init failed or timed out: $e');
  }

  runApp(const CampusNavigatorApp());
}

class CampusNavigatorApp extends StatelessWidget {
  const CampusNavigatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider (providers: [
      ChangeNotifierProvider(create: (_) => AppState()),
      ChangeNotifierProvider(create: (_) => BeaconService()),
    ],
      child: MaterialApp(
        title: 'Campus Navigator LAU',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const AppNavigator(),
      ),
    );
  }
}


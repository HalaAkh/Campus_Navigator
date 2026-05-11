import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'utils/theme.dart';
import 'utils/app_state.dart';
import 'utils/app_navigator.dart';
import 'firebase_options.dart';
import 'services/beacon_service.dart';
import '/services/rooms_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 5));
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase init failed or timed out: $e');
  }
  await RoomsService().loadRooms();

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


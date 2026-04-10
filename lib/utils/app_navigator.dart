import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../utils/app_state.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/auth_screens.dart';
import '../screens/home/home_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/navigation/room_detail_screen.dart';
import '../screens/navigation/active_navigation_screen.dart';
import '../screens/navigation/navigation_screens.dart';
import '../screens/map/map_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screens.dart';

enum AppRoute {
  splash,
  onboarding,
  login,
  signUp,
  forgotPassword,
  verifyEmail,
  permissions,
  home,
  search,
  roomDetail,
  navigation,
  floorTransition,
  arrived,
  beaconLost,
  map,
  profile,
  settings,
  savedRooms,
  help,
  feedback,
  about,
}

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  AppRoute _currentRoute = AppRoute.splash;
  String? _selectedRoom;
  String _userEmail = '';
  String _userName = '';
  final _authService = AuthService();

  void _goto(AppRoute route) => setState(() => _currentRoute = route);

  void _setUserFromFirebase(User user) {
    final appState = context.read<AppState>();
    appState.setUserFromAuth(user);
    setState(() {
      _userEmail = user.email ?? '';
      _userName = user.displayName ?? '';
    });
  }

  void _clearUser() {
    final appState = context.read<AppState>();
    appState.clearUser();
    setState(() {
      _userEmail = '';
      _userName = '';
    });
  }

  Future<void> _handleInitialRoute() async {
    // Called from splash when app starts or after login/signup flows
    final user = _authService.currentUser;

    if (user != null) {
      // populate provider and local fields
      _setUserFromFirebase(user);

      final isRegistered = await _authService.isUserRegistered(user.uid);

      if (isRegistered) {
        if (_authService.isEmailVerified) {
          _goto(AppRoute.home);
        } else {
          // show verify screen (provider already has name/email)
          setState(() => _currentRoute = AppRoute.verifyEmail);
        }
      } else {
        // Auth exists but Firestore doesn't
        if (_authService.isEmailVerified) {
          // create Firestore profile and go home
          await _authService.createUserProfile(user.displayName ?? '', user.email ?? '');
          _goto(AppRoute.home);
        } else {
          // show verify screen
          setState(() => _currentRoute = AppRoute.verifyEmail);
        }
      }
    } else {
      _goto(AppRoute.onboarding);
    }
  }

  void _onSignUpSuccess() {
    // SignUpScreen expects a VoidCallback; read the signed-up user's info from AuthService
    final user = _authService.currentUser;
    final appState = context.read<AppState>();

    if (user != null) {
      final name = user.displayName ?? '';
      final email = user.email ?? '';
      appState.setUser(name, email);
      setState(() {
        _userName = name;
        _userEmail = email;
        _currentRoute = AppRoute.verifyEmail;
      });
    } else {
      // fallback: clear and go to verify (or show error in real app)
      appState.clearUser();
      setState(() {
        _userName = '';
        _userEmail = '';
        _currentRoute = AppRoute.verifyEmail;
      });
    }
  }

  void _onSignOut() {
    _authService.signOut();
    _clearUser();
    _goto(AppRoute.login);
  }

  void _gotoRoom(String roomNumber) {
    setState(() {
      _selectedRoom = roomNumber;
      _currentRoute = AppRoute.roomDetail;
    });
  }

  void _gotoNavigation(String roomNumber) {
    setState(() {
      _selectedRoom = roomNumber;
      _currentRoute = AppRoute.navigation;
    });
  }

  void _onTabChange(int index) {
    setState(() {
      switch (index) {
        case 0:
          _currentRoute = AppRoute.home;
          break;
        case 1:
          _currentRoute = AppRoute.search;
          break;
        case 2:
          _currentRoute = AppRoute.map;
          break;
        case 3:
          _currentRoute = AppRoute.profile;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: _buildCurrentScreen(),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentRoute) {
      // ─── ENTRY FLOW ───
      case AppRoute.splash:
        return SplashScreen(
          key: const ValueKey('splash'),
          onComplete: _handleInitialRoute,
        );

      case AppRoute.onboarding:
        return OnboardingScreen(
          key: const ValueKey('onboarding'),
          onGetStarted: () => _goto(AppRoute.permissions),
          onLogin: () => _goto(AppRoute.login),
        );

      case AppRoute.login:
        return LoginScreen(
          key: const ValueKey('login'),
          onLoginSuccess: _handleInitialRoute,
          onSignUp: () => _goto(AppRoute.signUp),
          onForgotPassword: () => _goto(AppRoute.forgotPassword),
        );

      case AppRoute.permissions:
        return MandatoryPermissionsScreen(
          key: const ValueKey('mandatory_perms'),
          onPermissionsEnabled: () => _goto(AppRoute.signUp),
        );

      case AppRoute.signUp:
        return SignUpScreen(
          key: const ValueKey('signup'),
          onSignUpSuccess: _onSignUpSuccess,
          onLogin: () => _goto(AppRoute.login),
        );

      case AppRoute.forgotPassword:
        return ForgotPasswordScreen(
          key: const ValueKey('forgotpw'),
          onBack: () => _goto(AppRoute.login),
        );

      case AppRoute.verifyEmail:
        return VerifyEmailScreen(
          key: const ValueKey('verify'),
          email: _userEmail,
          onVerified: () => _goto(AppRoute.home),
          onBack: () {
            _authService.signOut();
            _clearUser();
            _goto(AppRoute.signUp);
          },
        );


      // ─── MAIN SCREENS ───
      case AppRoute.home:
        return HomeScreen(
          key: const ValueKey('home'),
          onTabChange: _onTabChange,
          onRoomTap: _gotoRoom,
          onSearchTap: () => _goto(AppRoute.search),
          onMapTap: () => _goto(AppRoute.map),
        );

      case AppRoute.search:
        return SearchScreen(
          key: const ValueKey('search'),
          onRoomSelected: _gotoRoom,
          onBack: () => _goto(AppRoute.home),
        );

      case AppRoute.map:
        return MapScreen(
          key: const ValueKey('map'),
          onTabChange: _onTabChange,
          onSearchTap: () => _goto(AppRoute.search),
        );

      case AppRoute.profile:
        return ProfileScreen(
          key: const ValueKey('profile'),
          onTabChange: _onTabChange,
          onSettings: () => _goto(AppRoute.settings),
          onSavedRooms: () => _goto(AppRoute.savedRooms),
          onAbout: () => _goto(AppRoute.about),
          onHelp: () => _goto(AppRoute.help),
          onFeedback: () => _goto(AppRoute.feedback),
          onSignOut: _onSignOut,
        );

      // ─── ROOM / NAVIGATION ───
      case AppRoute.roomDetail:
        return RoomDetailScreen(
          key: ValueKey('room_$_selectedRoom'),
          roomNumber: _selectedRoom ?? '408',
          onNavigate: () => _gotoNavigation(_selectedRoom ?? '408'),
          onBack: () => _goto(AppRoute.search),
        );

      case AppRoute.navigation:
        return ActiveNavigationScreen(
          key: ValueKey('nav_$_selectedRoom'),
          roomNumber: _selectedRoom ?? '408',
          onArrived: () => _goto(AppRoute.arrived),
          onEnd: () => _goto(AppRoute.home),
        );

      case AppRoute.arrived:
        return ArrivedScreen(
          key: ValueKey('arrived_$_selectedRoom'),
          roomNumber: _selectedRoom ?? '408',
          onNavigateAgain: () => _goto(AppRoute.search),
          onHome: () => _goto(AppRoute.home),
        );

      case AppRoute.floorTransition:
        return FloorTransitionScreen(
          key: const ValueKey('floortrans'),
          fromFloor: 4,
          toFloor: 5,
          currentBeaconMac: 'C6:2A:90:A1:99:CB',
          onContinueMainStairs: () => _goto(AppRoute.navigation),
          onContinueBackStairs: () => _goto(AppRoute.navigation),
        );

      case AppRoute.beaconLost:
        return BeaconLostScreen(
          key: const ValueKey('beaconlost'),
          onRetry: () => _goto(AppRoute.home),
          onManualSelect: () => _goto(AppRoute.home),
        );

      // ─── SUPPORT SCREENS ───
      case AppRoute.settings:
        return SettingsScreen(
          key: const ValueKey('settings'),
          onBack: () => _goto(AppRoute.profile),
        );

      case AppRoute.savedRooms:
        return SavedRoomsScreen(
          key: const ValueKey('saved'),
          onBack: () => _goto(AppRoute.profile),
          onNavigate: _gotoNavigation,
        );

      case AppRoute.help:
        return HelpScreen(
          key: const ValueKey('help'),
          onBack: () => _goto(AppRoute.profile),
        );

      case AppRoute.feedback:
        return FeedbackScreen(
          key: const ValueKey('feedback'),
          onBack: () => _goto(AppRoute.profile),
          onHome: () => _goto(AppRoute.home),
        );

      case AppRoute.about:
        return AboutScreen(
          key: const ValueKey('about'),
          onBack: () => _goto(AppRoute.profile),
        );
    }
  }
}

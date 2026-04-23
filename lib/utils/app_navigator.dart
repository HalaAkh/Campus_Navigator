import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/services/auth_service.dart';
import '/utils/app_state.dart';
import '/screens/splash/splash_screen.dart';
import '/screens/onboarding/onboarding_screen.dart';
import '/screens/auth/login_screen.dart';
import '/screens/auth/auth_screens.dart';
import '/screens/home/home_screen.dart';
import '/screens/search/search_screen.dart';
import '/screens/navigation/navigate_search_screen.dart';
import '/screens/navigation/navigation_screens.dart';
import '/screens/profile/profile_screen.dart';
import '/screens/settings/settings_screens.dart';
import '/screens/saved_rooms/saved_rooms_screen.dart';

enum AppRoute {
  splash, onboarding, login, signUp, forgotPassword, verifyEmail, permissions,
  home,
  search,          // Google Maps "Search here" — simple search
  navigateSearch,  // Directions search — origin + destination fields
  navigate,
  savedRoomsNav,
  profile, settings, savedRooms, help, feedback, about,
}

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});
  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  AppRoute _route = AppRoute.splash;
  String? _selectedRoom;
  String _userEmail = '';
  String _userName = '';
  final _auth = AuthService();

  void _goto(AppRoute r) => setState(() => _route = r);

  void _setUser(User user) {
    context.read<AppState>().setUserFromAuth(user);
    setState(() { _userEmail = user.email ?? ''; _userName = user.displayName ?? ''; });
  }

  void _clearUser() {
    context.read<AppState>().clearUser();
    setState(() { _userEmail = ''; _userName = ''; });
  }

  Future<void> _handleInitial() async {
    final user = _auth.currentUser;
    if (user != null) {
      _setUser(user);
      context.read<AppState>().loadSavedRoomsFromFirebase();
      context.read<AppState>().loadNavigationHistoryFromFirebase();
      final reg = await _auth.isUserRegistered(user.uid);
      if (reg) {
        if (_auth.isEmailVerified) {
          if (mounted) await PermissionDialogs.showPermissionDialogs(context);
          _goto(AppRoute.home);
        } else { _goto(AppRoute.verifyEmail); }
      } else {
        if (_auth.isEmailVerified) {
          await _auth.createUserProfile(user.displayName ?? '', user.email ?? '');
          if (mounted) await PermissionDialogs.showPermissionDialogs(context);
          _goto(AppRoute.home);
        } else { _goto(AppRoute.verifyEmail); }
      }
    } else { _goto(AppRoute.onboarding); }
  }

  void _onSignUpSuccess() {
    final user = _auth.currentUser;
    if (user != null) {
      context.read<AppState>().setUser(user.displayName ?? '', user.email ?? '');
      setState(() { _userName = user.displayName ?? ''; _userEmail = user.email ?? ''; _route = AppRoute.verifyEmail; });
    } else {
      context.read<AppState>().clearUser();
      setState(() { _route = AppRoute.verifyEmail; });
    }
  }

  void _signOut() { _auth.signOut(); _clearUser(); _goto(AppRoute.login); }

  // Search tap → select room → show on home map (or navigate directly)
  void _onSearchRoomSelected(String num) {
    // Go to navigate search with room pre-filled
    setState(() { _selectedRoom = num; _route = AppRoute.navigateSearch; });
  }

  // Navigate search → start navigation
  void _startNavigation(String num) {
    context.read<AppState>().addToNavigationHistory(num);
    setState(() { _selectedRoom = num; _route = AppRoute.navigate; });
  }

  // Home room tap (from map pin card) → go to navigate
  void _onHomeRoomNavigate(String num) {
    setState(() { _selectedRoom = num; _route = AppRoute.navigate; });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
      child: _build(),
    );
  }

  Widget _build() {
    switch (_route) {
    // Auth
      case AppRoute.splash:
        return SplashScreen(key: const ValueKey('splash'), onComplete: _handleInitial);
      case AppRoute.onboarding:
        return OnboardingScreen(key: const ValueKey('onboarding'),
            onGetStarted: () async { if (mounted) await PermissionDialogs.showPermissionDialogs(context); _goto(AppRoute.signUp); },
            onLogin: () => _goto(AppRoute.login));
      case AppRoute.login:
        return LoginScreen(key: const ValueKey('login'), onLoginSuccess: _handleInitial, onSignUp: () => _goto(AppRoute.signUp), onForgotPassword: () => _goto(AppRoute.forgotPassword));
      case AppRoute.signUp:
        return SignUpScreen(key: const ValueKey('signup'), onSignUpSuccess: _onSignUpSuccess, onLogin: () => _goto(AppRoute.login));
      case AppRoute.forgotPassword:
        return ForgotPasswordScreen(key: const ValueKey('forgotpw'), onBack: () => _goto(AppRoute.login));
      case AppRoute.verifyEmail:
        return VerifyEmailScreen(key: const ValueKey('verify'), email: _userEmail,
            onVerified: () async { if (mounted) await PermissionDialogs.showPermissionDialogs(context); _goto(AppRoute.home); },
            onBack: () { _auth.signOut(); _clearUser(); _goto(AppRoute.signUp); });
      case AppRoute.permissions:
        return PermissionsScreen(key: const ValueKey('perms'), onPermissionsGranted: () => _goto(AppRoute.home), onSkip: () => _goto(AppRoute.home));

    // ─── MAIN ───
      case AppRoute.home:
        return HomeScreen(
          key: const ValueKey('home'),
          onSearchTap: () => _goto(AppRoute.search),
          onNavigateTap: () => _goto(AppRoute.navigateSearch),
          onSavedTap: () => _goto(AppRoute.savedRoomsNav),
          onProfileTap: () => _goto(AppRoute.profile),
          onNavigateToRoom: _onHomeRoomNavigate,
        );

      case AppRoute.search:
        return SearchScreen(
          key: const ValueKey('search'),
          onRoomSelected: _onSearchRoomSelected,
          onBack: () => _goto(AppRoute.home),
          onSavedTap: () => _goto(AppRoute.savedRoomsNav),
          onProfileTap: () => _goto(AppRoute.profile),
        );

      case AppRoute.navigateSearch:
        return NavigateSearchScreen(
          key: const ValueKey('navsearch'),
          prefilledRoom: _selectedRoom,
          onStartNavigation: _startNavigation,
          onBack: () => _goto(AppRoute.home),
        );

      case AppRoute.navigate:
        return NavigationScreen(
          key: ValueKey('nav_$_selectedRoom'),
          roomNumber: _selectedRoom ?? '408',
          onClose: () => _goto(AppRoute.home),
          onNewDestination: () => _goto(AppRoute.navigateSearch),
        );

      case AppRoute.savedRoomsNav:
        return SavedRoomsNavScreen(
          key: const ValueKey('savedNav'),
          onTabChange: (i) {
            if (i == 0) _goto(AppRoute.home);
            if (i == 1) _goto(AppRoute.search);
            if (i == 3) _goto(AppRoute.profile);
          },
          onNavigateToRoom: _startNavigation,
        );

    // Profile
      case AppRoute.profile:
        return ProfileScreen(key: const ValueKey('profile'),
            onTabChange: (i) {
              if (i == 0) _goto(AppRoute.home);
              if (i == 1) _goto(AppRoute.search);
              if (i == 2) _goto(AppRoute.savedRoomsNav);
            },
            onSettings: () => _goto(AppRoute.settings),
            onSavedRooms: () => _goto(AppRoute.savedRooms),
            onAbout: () => _goto(AppRoute.about),
            onHelp: () => _goto(AppRoute.help),
            onFeedback: () => _goto(AppRoute.feedback),
            onSignOut: _signOut,
            onNavigateToRoom: _startNavigation);
      case AppRoute.settings:
        return SettingsScreen(key: const ValueKey('settings'), onBack: () => _goto(AppRoute.profile));
      case AppRoute.savedRooms:
        return SavedRoomsScreen(key: const ValueKey('saved'), onBack: () => _goto(AppRoute.profile), onNavigate: _startNavigation);
      case AppRoute.help:
        return HelpScreen(key: const ValueKey('help'), onBack: () => _goto(AppRoute.profile));
      case AppRoute.feedback:
        return FeedbackScreen(key: const ValueKey('feedback'), onBack: () => _goto(AppRoute.profile), onHome: () => _goto(AppRoute.home));
      case AppRoute.about:
        return AboutScreen(key: const ValueKey('about'), onBack: () => _goto(AppRoute.profile));
    }
  }
}

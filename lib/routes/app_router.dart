import 'package:flutter/material.dart';
import '../auth/splash_screen.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../auth/reset_password_screen.dart';
import '../main_layout.dart';
import '../profile_page.dart';

class AppRoutes {
  // Route names
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String resetPassword = '/reset-password';
  static const String userDashboard = '/user';
  static const String userProfile = '/user/profile';

  static String get initialRoute => splash;

  // Named route table
  static Map<String, WidgetBuilder> get routes => {
    '/': (_) => const SplashScreen(),
    splash: (_) => const SplashScreen(),
    login: (_) => const LoginScreen(),
    register: (_) => const RegisterScreen(),
    resetPassword: (_) => const ResetPasswordScreen(),
    userDashboard: (_) => const MainLayout(),
    userProfile: (_) => const ProfilePage(),
  };

}

// Route navigation helpers
class AppNavigator {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static NavigatorState? get navigator => navigatorKey.currentState;
  static BuildContext? get context => navigator?.context;

  // Authentication navigation
  static Future<void> toSplash() async {
    await navigator?.pushNamedAndRemoveUntil(
      AppRoutes.splash,
      (route) => false,
    );
  }

  static Future<void> toLogin() async {
    await navigator?.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  static Future<void> toRegister() async {
    await navigator?.pushNamed(AppRoutes.register);
  }

  static Future<void> toResetPassword() async {
    await navigator?.pushNamed(AppRoutes.resetPassword);
  }

  // User navigation
  static Future<void> toUserDashboard() async {
    await navigator?.pushNamedAndRemoveUntil(
      AppRoutes.userDashboard,
      (route) => false,
    );
  }

  static Future<void> toUserProfile() async {
    await navigator?.pushNamed(AppRoutes.userProfile);
  }

  // Utility navigation
  static void pop([dynamic result]) {
    navigator?.pop(result);
  }

  static bool canPop() {
    return navigator?.canPop() ?? false;
  }

  static Future<void> popUntil(String routeName) async {
    navigator?.popUntil(ModalRoute.withName(routeName));
  }
}

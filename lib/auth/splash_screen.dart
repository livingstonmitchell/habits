// import 'package:flutter/material.dart';
// import '../routes/app_router.dart';
// import '../services/auth_service.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();
//     _bootstrap();
//   }

//   Future<void> _bootstrap() async {
//     await Future<void>.delayed(const Duration(milliseconds: 600));
//     if (!mounted) return;

//     if (AuthService.instance.isSignedIn) {
//       Navigator.of(
//         context,
//       ).pushNamedAndRemoveUntil(AppRoutes.userDashboard, (route) => false);
//     } else {
//       Navigator.of(
//         context,
//       ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: const [
//             FlutterLogo(size: 96),
//             SizedBox(height: 16),
//             CircularProgressIndicator(),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import '../routes/app_router.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    if (AuthService.instance.isSignedIn) {
      // ✅ User already logged in → go to dashboard
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.userDashboard,
        (route) => false,
      );
    } else {
      // ✅ New / logged-out user → go to onboarding
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.onboarding,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            FlutterLogo(size: 96),
            SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

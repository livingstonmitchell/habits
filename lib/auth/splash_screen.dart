// import 'package:flutter/material.dart';
// import 'package:habits_app/utils/widgets/appbutton.dart';
// import 'package:habits_app/utils/routes/app_router.dart';
// import 'package:habits_app/utils/theme.dart';

// import '../../services/auth_service.dart';

// class OnboardingScreen extends StatefulWidget {
//   const OnboardingScreen({super.key});

//   @override
//   State<OnboardingScreen> createState() => _OnboardingScreenState();
// }

// class _OnboardingScreenState extends State<OnboardingScreen> {
//   final _ctrl = PageController();
//   int _index = 0;

//   final _pages = const [
//     _OnboardPage(
//       title: "Build better days",
//       subtitle: "Create habits that fit your lifestyle in minutes.",
//       icon: Icons.auto_awesome,
//     ),
//     _OnboardPage(
//       title: "One tap check-ins",
//       subtitle: "Track daily progress with quick check-ins and streaks.",
//       icon: Icons.check_circle,
//     ),
//     _OnboardPage(
//       title: "See your growth",
//       subtitle: "Review weekly progress and stay consistent.",
//       icon: Icons.insights,
//     ),
//   ];

//   @override
//   void initState() {
//     super.initState();

//     // ✅ If user already logged in, skip onboarding
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (AuthService.instance.currentUser != null) {
//         Navigator.pushReplacementNamed(context, AppRoutes.userDashboard);
//       }
//     });
//   }

//   void _goLogin() {
//     Navigator.pushReplacementNamed(context, AppRoutes.login);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
//           child: Column(
//             children: [
//               Row(
//                 children: [
//                   const Spacer(),
//                   TextButton(onPressed: _goLogin, child: const Text("Skip")),
//                 ],
//               ),
//               Expanded(
//                 child: PageView(
//                   controller: _ctrl,
//                   onPageChanged: (i) => setState(() => _index = i),
//                   children: _pages,
//                 ),
//               ),
//               Row(
//                 children: List.generate(_pages.length, (i) {
//                   final active = i == _index;
//                   return AnimatedContainer(
//                     duration: const Duration(milliseconds: 250),
//                     margin: const EdgeInsets.only(right: 8),
//                     height: 8,
//                     width: active ? 26 : 8,
//                     decoration: BoxDecoration(
//                       color: active ? AppColors.primary : AppColors.primarySoft,
//                       borderRadius: BorderRadius.circular(999),
//                     ),
//                   );
//                 }),
//               ),
//               const SizedBox(height: 16),
//               AppButton(
//                 text: _index == _pages.length - 1 ? "Get Started" : "Next",
//                 onTap: () {
//                   if (_index == _pages.length - 1) {
//                     _goLogin();
//                   } else {
//                     _ctrl.nextPage(
//                       duration: const Duration(milliseconds: 300),
//                       curve: Curves.easeOut,
//                     );
//                   }
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _OnboardPage extends StatelessWidget {
//   final String title;
//   final String subtitle;
//   final IconData icon;

//   const _OnboardPage({
//     required this.title,
//     required this.subtitle,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const SizedBox(height: 24),
//         Container(
//           height: 220,
//           width: double.infinity,
//           decoration: BoxDecoration(
//             color: AppColors.primarySoft,
//             borderRadius: BorderRadius.circular(24),
//           ),
//           child: Center(
//             child: Icon(icon, size: 88, color: AppColors.primary),
//           ),
//         ),
//         const SizedBox(height: 22),
//         Text(title, style: AppText.h1),
//         const SizedBox(height: 10),
//         Text(subtitle, style: AppText.muted.copyWith(fontSize: 14, height: 1.4)),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:habits_app/utils/routes/app_router.dart';


class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<_OnboardingPageData> _pages = const [
    _OnboardingPageData(
      icon: Icons.explore,
      title: 'Welcome',
      description: 'Discover features designed to make your experience easy.',
    ),
    _OnboardingPageData(
      icon: Icons.lock_outline,
      title: 'Secure',
      description: 'Your data is protected using Firebase authentication.',
    ),
    _OnboardingPageData(
      icon: Icons.check_circle_outline,
      title: 'Get Started',
      description: 'Create an account or login to continue.',
    ),
  ];

  void _nextPage() {
    if (_currentIndex == _pages.length - 1) {
      _goToLogin();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _goToLogin,
                child: const Text('Skip'),
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          page.icon,
                          size: 100,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          page.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentIndex == index ? 20 : 8,
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Next / Get Started button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  child: Text(
                    _currentIndex == _pages.length - 1
                        ? 'Get Started'
                        : 'Next',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple data model for onboarding pages
class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
  });
}


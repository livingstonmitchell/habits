// import 'package:flutter/material.dart';
// import 'package:lottie/lottie.dart';
// import '../../routes/app_router.dart';
// import 'package:audioplayers/audioplayers.dart';

// class OnboardingScreen extends StatefulWidget {
//   const OnboardingScreen({super.key});

//   @override
//   State<OnboardingScreen> createState() => _OnboardingScreenState();
// }

// class _OnboardingScreenState extends State<OnboardingScreen> {
//   final PageController _pageController = PageController();
//   final AudioPlayer _audioPlayer = AudioPlayer();
  
//   int _currentIndex = 0;
//   bool _soundPlayed = false;

  
//   final List<_OnboardingPageData> _pages = const [
//     _OnboardingPageData(
//       lottie: 'assets/lottie/welcome.json',
//       title: 'Welcome',
//       description: 'Discover features designed to make your experience easy.',
//     ),
//     _OnboardingPageData(
//       lottie: 'assets/lottie/secure.json',
//       title: 'Secure',
//       description: 'Your data is protected using Firebase authentication.',
//     ),
//     _OnboardingPageData(
//       lottie: 'assets/lottie/get_started.json',
//       title: 'Get Started',
//       description: 'Create an account or login to continue.',
//     ),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _playWelcomeSound();
//   }

//   Future<void> _playWelcomeSound() async {
//     if (_soundPlayed) return; 

//     _soundPlayed = true;
//       await _audioPlayer.play(
//         AssetSource('audio/welcome.mp3'),
//         volume: 0.5,
//         );
      
//     }
  


//   void _nextPage() {
//     if (_currentIndex == _pages.length - 1) {
//       _goToLogin();
//     } else {
//       _pageController.nextPage(
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeInOut,
//       );
//     }
//   }

//   void _goToLogin() {
//     Navigator.of(context).pushReplacementNamed(AppRoutes.login);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Theme.of(context).colorScheme.primary.withOpacity(0.06),
//               Theme.of(context).colorScheme.surface,
//               Theme.of(context).colorScheme.surface,
//             ],
//           ),
//         ),
//         child: SafeArea(
//           child: Column(
//             children: [
//               // Skip button
//               Align(
//                 alignment: Alignment.topRight,
//                 child: TextButton(
//                   onPressed: _goToLogin,
//                   child: const Text('Skip'),
//                 ),
//               ),

//               // PageView with Card style
//               Expanded(
//                 child: PageView.builder(
//                   controller: _pageController,
//                   itemCount: _pages.length,
//                   onPageChanged: (index) {
//                     setState(() => _currentIndex = index);
//                   },
//                   itemBuilder: (context, index) {
//                     final page = _pages[index];
//                     return Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 20),
//                       child: Card(
//                         elevation: 6,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(24),
//                         ),
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(
//                             vertical: 32,
//                             horizontal: 24,
//                           ),
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               SizedBox(
//                                 height: 240,
//                                 child: Lottie.asset(
//                                   page.lottie,
//                                   repeat: true,
//                                   fit: BoxFit.contain,
//                                 ),
//                               ),
//                               const SizedBox(height: 24),
//                               Text(
//                                 page.title,
//                                 style: Theme.of(context)
//                                     .textTheme
//                                     .headlineSmall
//                                     ?.copyWith(
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                               ),
//                               const SizedBox(height: 12),
//                               Text(
//                                 page.description,
//                                 textAlign: TextAlign.center,
//                                 style: Theme.of(context)
//                                     .textTheme
//                                     .bodyMedium
//                                     ?.copyWith(
//                                       color: Colors.grey.shade700,
//                                       height: 1.4,
//                                     ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),

//               // Page indicators
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: List.generate(
//                   _pages.length,
//                   (index) => AnimatedContainer(
//                     duration: const Duration(milliseconds: 250),
//                     margin: const EdgeInsets.symmetric(horizontal: 4),
//                     height: 8,
//                     width: _currentIndex == index ? 20 : 8,
//                     decoration: BoxDecoration(
//                       color: _currentIndex == index
//                           ? Theme.of(context).colorScheme.primary
//                           : Colors.grey.shade400,
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 24),

//               // Next / Get Started button
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
//                 child: SizedBox(
//                   width: double.infinity,
//                   height: 48,
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(14),
//                       ),
//                       elevation: 0,
//                     ),
//                     onPressed: _nextPage,
//                     child: Text(
//                       _currentIndex == _pages.length - 1
//                           ? 'Get Started'
//                           : 'Next',
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// /// Onboarding page data model
// class _OnboardingPageData {
//   final String lottie;
//   final String title;
//   final String description;

//   const _OnboardingPageData({
//     required this.lottie,
//     required this.title,
//     required this.description,
//   });
// }
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../routes/app_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  int _currentIndex = 0;
  bool _soundPlayed = false;

  final List<_OnboardingPageData> _pages = const [
    _OnboardingPageData(
      lottie: 'assets/lottie/welcome.json',
      title: 'Welcome',
      description: 'Discover features designed to make your experience easy.',
    ),
    _OnboardingPageData(
      lottie: 'assets/lottie/secure.json',
      title: 'Secure',
      description: 'Your data is protected using Firebase authentication.',
    ),
    _OnboardingPageData(
      lottie: 'assets/lottie/get_started.json',
      title: 'Get Started',
      description: 'Create an account or login to continue.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // ❌ NO sound here (web blocks autoplay)
  }

  void _nextPage() async {
    // ✅ Play sound on FIRST user interaction (web-safe)
    if (!_soundPlayed) {
      _soundPlayed = true;
      await _audioPlayer.play(
        AssetSource('audio/welcome.mp3'),
        volume: 0.5,
      );
    }

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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
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

              // PageView with card style
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
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 32,
                            horizontal: 24,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 240,
                                child: Lottie.asset(
                                  page.lottie,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 24),
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
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.grey.shade700,
                                      height: 1.4,
                                    ),
                              ),
                            ],
                          ),
                        ),
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
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
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
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}

/// Onboarding page data model
class _OnboardingPageData {
  final String lottie;
  final String title;
  final String description;

  const _OnboardingPageData({
    required this.lottie,
    required this.title,
    required this.description,
  });
}

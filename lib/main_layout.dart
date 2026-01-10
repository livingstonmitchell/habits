// import 'package:flutter/material.dart';
// import 'profile_page.dart';
// import 'screens/dashboard/home_screen.dart';
// import 'screens/habits/habit_details_screen.dart';

// class MainLayout extends StatefulWidget {
//   const MainLayout({super.key});

//   @override
//   State<MainLayout> createState() => _MainLayoutState();
// }

// class _MainLayoutState extends State<MainLayout> {
//   int _index = 0;
//   late final List<Widget> _pages =  [
//     TodayHomeScreen(),
//     HabitDetailsScreen(),
//     ProfilePage(),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: IndexedStack(index: _index, children: _pages),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _index,
//         onTap: (value) => setState(() => _index = value),
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.local_fire_department),
//             label: 'Habit',
//           ),
//           BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
//         ],
//       ),
//     );
//   }
// }

import 'dart:ui'; // Required for ImageFilter
import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'screens/dashboard/home_screen.dart';
import 'screens/habits/habit_details_screen.dart';
import 'package:habits_app/utils/theme.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _index = 0;

  late final List<Widget> _pages = [
    const TodayHomeScreen(),
    HabitDetailsScreen(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // extendBody allows the body to be drawn under the bottomNavigationBar
      extendBody: true,

      // We add a little padding to the bottom of the stack so
      // content doesn't get completely hidden behind the dock
      body: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: IndexedStack(index: _index, children: _pages),
      ),

      bottomNavigationBar: _buildGlassNavBar(),
    );
  }

  Widget _buildGlassNavBar() {
    return Container(
      height: 82,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Stack(
        children: [
          // 1. THE GLASS BLUR LAYER
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // 2. THE NAVIGATION CONTENT
          Theme(
            // This removes the splash/ripple effect that can look messy on glass
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: BottomNavigationBar(
              currentIndex: _index,
              onTap: (value) => setState(() => _index = value),
              elevation: 0,
              backgroundColor: Colors.transparent, // Crucial for glass effect
              selectedItemColor: AppColors.primary,
              unselectedItemColor: Colors.blueGrey.withOpacity(0.6),
              showSelectedLabels: true,
              showUnselectedLabels: false,
              type: BottomNavigationBarType.fixed,
              items: [
                _buildNavItem(
                  Icons.home_rounded,
                  Icons.home_outlined,
                  'Home',
                  0,
                ),
                _buildNavItem(
                  Icons.local_fire_department_rounded,
                  Icons.local_fire_department_outlined,
                  'Habits',
                  1,
                ),
                _buildNavItem(
                  Icons.person_rounded,
                  Icons.person_outline_rounded,
                  'Profile',
                  2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
    int index,
  ) {
    bool isSelected = _index == index;
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(isSelected ? activeIcon : inactiveIcon, size: 28),
      ),
      label: label,
    );
  }
}

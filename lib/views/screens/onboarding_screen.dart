// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:note_app/views/screens/home_screen.dart';
// import 'package:smooth_page_indicator/smooth_page_indicator.dart';
// import 'package:flutter/services.dart';

// class OnboardingData {
//   final String title;
//   final String subtitle;
//   final Color backgroundColor;
//   final String imagePath;
//   final String buttonLabel;

//   const OnboardingData({
//     required this.title,
//     required this.subtitle,
//     required this.backgroundColor,
//     required this.imagePath,
//     required this.buttonLabel,
//   });
// }

// final List<OnboardingData> onboardingPages = [
//   const OnboardingData(
//     title: 'Capture\nYour Ideas\nInstantly',
//     subtitle:
//         'Jot down your thoughts, notes,\nand to-dos whenever inspiration\nstrikes.',
//     backgroundColor: Color(0xFFFFCC00),
//     imagePath: 'assets/onboarding/capture.png',
//     buttonLabel: 'Next',
//   ),
//   const OnboardingData(
//     title: 'Organize\nYour Notes\nEffortlessly',
//     subtitle:
//         'Categorize, tag, and pin your notes\nfor quick access and better\norganization.',
//     backgroundColor: Color(0xFFC6AEF0),
//     imagePath: 'assets/onboarding/onB2.png',
//     buttonLabel: 'Next',
//   ),
//   const OnboardingData(
//     title: 'Keep Your Notes\nPrivate & Secure',
//     subtitle:
//         'Your notes stay on your device.\nLock sensitive ones with\nfingerprint or face ID.',
//     backgroundColor: Color(0xFF22C55E),
//     imagePath: 'assets/onboarding/onB3.png',
//     buttonLabel: 'Get Started',
//   ),
// ];

// class OnboardingScreen extends StatefulWidget {
//   const OnboardingScreen({super.key});

//   @override
//   State<OnboardingScreen> createState() => _OnboardingScreenState();
// }

// class _OnboardingScreenState extends State<OnboardingScreen> {
//   final PageController _controller = PageController();
//   int _currentPage = 0;

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   Future<void> _onNextPressed() async {
//     if (_currentPage == onboardingPages.length - 1) {
//       // ─── Mark onboarding as seen, then navigate ───
//       await Hive.box('settings').put('hasSeenOnboarding', true);
//       if (!mounted) return;
//       Navigator.of(context).pushReplacement(
//         MaterialPageRoute(builder: (context) => const NoteHomeScreen()),
//       );
//     } else {
//       _controller.nextPage(
//         duration: const Duration(milliseconds: 350),
//         curve: Curves.easeInOut,
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     SystemChrome.setSystemUIOverlayStyle(
//       const SystemUiOverlayStyle(
//         statusBarColor: Colors.transparent,
//         systemNavigationBarColor: Colors.transparent,
//         systemNavigationBarDividerColor: Colors.transparent,
//         statusBarIconBrightness: Brightness.dark,
//         systemNavigationBarIconBrightness: Brightness.dark,
//       ),
//     );
//     final size = MediaQuery.of(context).size;

//     final interTheme = Theme.of(context).copyWith(
//       textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
//       primaryTextTheme: GoogleFonts.interTextTheme(
//         Theme.of(context).primaryTextTheme,
//       ),
//     );

//     return Theme(
//       data: interTheme,
//       child: Scaffold(
//         body: AnimatedContainer(
//           duration: const Duration(milliseconds: 300),
//           color: onboardingPages[_currentPage].backgroundColor,
//           child: SafeArea(
//             child: Column(
//               children: [
//                 Expanded(
//                   child: PageView.builder(
//                     controller: _controller,
//                     itemCount: onboardingPages.length,
//                     onPageChanged: (index) {
//                       setState(() => _currentPage = index);
//                     },
//                     itemBuilder: (context, index) {
//                       final page = onboardingPages[index];
//                       return Padding(
//                         padding: EdgeInsets.symmetric(
//                           horizontal: size.width * 0.064,
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             SizedBox(height: size.height * 0.03),
//                             Text(
//                               page.title,
//                               style: GoogleFonts.inter(
//                                 fontSize: (size.width * 0.105).clamp(
//                                   38.0,
//                                   42.0,
//                                 ),
//                                 fontWeight: FontWeight.w700,
//                                 height: 1.2,
//                                 color: Colors.black,
//                                 letterSpacing: -0.7,
//                               ),
//                             ),
//                             SizedBox(height: size.height * 0.02),
//                             Text(
//                               page.subtitle,
//                               style: GoogleFonts.inter(
//                                 fontSize: size.width * 0.043,
//                                 fontWeight: FontWeight.w500,
//                                 height: 1.35,
//                                 color: Colors.black.withOpacity(0.75),
//                               ),
//                             ),
//                             Expanded(
//                               child: Center(
//                                 child: Image.asset(
//                                   page.imagePath,
//                                   width: size.width * 2,
//                                   fit: BoxFit.contain,
//                                   errorBuilder: (context, error, stack) => Icon(
//                                     Icons.note_alt_outlined,
//                                     size: size.width * 0.5,
//                                     color: Colors.black.withOpacity(0.85),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   ),
//                 ),

//                 // --- Page indicator dots ---
//                 SmoothPageIndicator(
//                   controller: _controller,
//                   count: onboardingPages.length,
//                   effect: ExpandingDotsEffect(
//                     dotHeight: 8,
//                     dotWidth: 8,
//                     expansionFactor: 2.75,
//                     spacing: 8,
//                     activeDotColor: Colors.black,
//                     dotColor: Colors.black.withOpacity(0.25),
//                   ),
//                 ),

//                 SizedBox(height: size.height * 0.025),

//                 // --- Next / Get Started button (smooth, no sparkle) ---
//                 Padding(
//                   padding: EdgeInsets.symmetric(
//                     horizontal: size.width * 0.064,
//                     vertical: size.height * 0.02,
//                   ),
//                   child: _ScaleOnPressButton(
//                     onPressed: _onNextPressed,
//                     child: Container(
//                       width: double.infinity,
//                       height: size.height * 0.066,
//                       decoration: BoxDecoration(
//                         color: Colors.black,
//                         borderRadius: BorderRadius.circular(100),
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           const SizedBox(width: 24),
//                           Text(
//                             onboardingPages[_currentPage].buttonLabel,
//                             style: GoogleFonts.inter(
//                               fontSize: 17,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.white,
//                             ),
//                           ),
//                           const Padding(
//                             padding: EdgeInsets.only(right: 22),
//                             child: Icon(
//                               Icons.keyboard_double_arrow_right,
//                               size: 20,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ─── Premium press-scale button (no ripple, no sparkle) ───────────────
// class _ScaleOnPressButton extends StatefulWidget {
//   final Widget child;
//   final VoidCallback onPressed;

//   const _ScaleOnPressButton({required this.child, required this.onPressed});

//   @override
//   State<_ScaleOnPressButton> createState() => _ScaleOnPressButtonState();
// }

// class _ScaleOnPressButtonState extends State<_ScaleOnPressButton> {
//   bool _pressed = false;

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       behavior: HitTestBehavior.opaque,
//       onTapDown: (_) => setState(() => _pressed = true),
//       onTapUp: (_) {
//         setState(() => _pressed = false);
//         widget.onPressed();
//       },
//       onTapCancel: () => setState(() => _pressed = false),
//       child: AnimatedScale(
//         scale: _pressed ? 0.96 : 1.0,
//         duration: const Duration(milliseconds: 120),
//         curve: Curves.easeOut,
//         child: widget.child,
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:note_app/views/screens/profile_setup_screen.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter/services.dart';

class OnboardingData {
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final String imagePath;
  final String buttonLabel;

  const OnboardingData({
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.imagePath,
    required this.buttonLabel,
  });
}

final List<OnboardingData> onboardingPages = [
  const OnboardingData(
    title: 'Capture\nYour Ideas\nInstantly',
    subtitle:
        'Jot down your thoughts, notes,\nand to-dos whenever inspiration\nstrikes.',
    backgroundColor: Color(0xFFFFCC00),
    imagePath: 'assets/onboarding/capture.png',
    buttonLabel: 'Next',
  ),
  const OnboardingData(
    title: 'Organize\nYour Notes\nEffortlessly',
    subtitle:
        'Categorize, tag, and pin your notes\nfor quick access and better\norganization.',
    backgroundColor: Color(0xFFC6AEF0),
    imagePath: 'assets/onboarding/onB2.png',
    buttonLabel: 'Next',
  ),
  const OnboardingData(
    title: 'Keep Your Notes\nPrivate & Secure',
    subtitle:
        'Your notes stay on your device.\nLock sensitive ones with\nfingerprint or face ID.',
    backgroundColor: Color(0xFF22C55E),
    imagePath: 'assets/onboarding/onB3.png',
    buttonLabel: 'Get Started',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    if (_currentPage == onboardingPages.length - 1) {
      // The hasSeenOnboarding flag is now set in ProfileSetupScreen,
      // once the user has chosen a name and avatar.
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
      );
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    final size = MediaQuery.of(context).size;

    final interTheme = Theme.of(context).copyWith(
      textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      primaryTextTheme: GoogleFonts.interTextTheme(
        Theme.of(context).primaryTextTheme,
      ),
    );

    return Theme(
      data: interTheme,
      child: Scaffold(
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          color: onboardingPages[_currentPage].backgroundColor,
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: onboardingPages.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      final page = onboardingPages[index];
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.064,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: size.height * 0.03),
                            Text(
                              page.title,
                              style: GoogleFonts.inter(
                                fontSize: (size.width * 0.105).clamp(
                                  38.0,
                                  42.0,
                                ),
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                                color: Colors.black,
                                letterSpacing: -0.7,
                              ),
                            ),
                            SizedBox(height: size.height * 0.02),
                            Text(
                              page.subtitle,
                              style: GoogleFonts.inter(
                                fontSize: size.width * 0.043,
                                fontWeight: FontWeight.w500,
                                height: 1.35,
                                color: Colors.black.withOpacity(0.75),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Image.asset(
                                  page.imagePath,
                                  width: size.width * 2,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stack) => Icon(
                                    Icons.note_alt_outlined,
                                    size: size.width * 0.5,
                                    color: Colors.black.withOpacity(0.85),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Page indicator dots
                SmoothPageIndicator(
                  controller: _controller,
                  count: onboardingPages.length,
                  effect: ExpandingDotsEffect(
                    dotHeight: 8,
                    dotWidth: 8,
                    expansionFactor: 2.75,
                    spacing: 8,
                    activeDotColor: Colors.black,
                    dotColor: Colors.black.withOpacity(0.25),
                  ),
                ),

                SizedBox(height: size.height * 0.025),

                // Next / Get Started button (smooth, no sparkle)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.064,
                    vertical: size.height * 0.02,
                  ),
                  child: _ScaleOnPressButton(
                    onPressed: _onNextPressed,
                    child: Container(
                      width: double.infinity,
                      height: size.height * 0.066,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 24),
                          Text(
                            onboardingPages[_currentPage].buttonLabel,
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(right: 22),
                            child: Icon(
                              Icons.keyboard_double_arrow_right,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Premium press-scale button (no ripple, no sparkle) ───────────────
class _ScaleOnPressButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;

  const _ScaleOnPressButton({required this.child, required this.onPressed});

  @override
  State<_ScaleOnPressButton> createState() => _ScaleOnPressButtonState();
}

class _ScaleOnPressButtonState extends State<_ScaleOnPressButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
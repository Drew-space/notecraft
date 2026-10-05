import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:note_app/core/theme/app_colors.dart';
import 'package:note_app/data/models/adapters.dart';
import 'package:note_app/data/models/note.dart';
import 'package:note_app/data/models/user_profile.dart';
import 'package:note_app/viewmodels/theme_provider.dart';
import 'package:note_app/views/screens/home_screen.dart';
import 'package:note_app/views/screens/onboarding_screen.dart';
import 'package:note_app/views/screens/privacy_policy_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Adapters
  Hive.registerAdapter(NoteAdapter());
  Hive.registerAdapter(ChecklistItemAdapter());
  Hive.registerAdapter(UserProfileAdapter());

  await Hive.openBox<Note>('notes');
  await Hive.openBox<UserProfile>('profile');
  await Hive.openBox('settings'); // <── for app-level flags and theme mode

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  ThemeData _buildTheme(Brightness brightness) {
    final colors = brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1A1A1A),
        brightness: brightness,
      ),
      scaffoldBackgroundColor: colors.scaffold,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.scaffold,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: overlayStyleFor(brightness, colors),
      ),
      extensions: <ThemeExtension<dynamic>>[colors],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final settings = Hive.box('settings');
    final hasSeenOnboarding =
        settings.get('hasSeenOnboarding', defaultValue: false) as bool;

    return MaterialApp(
      title: 'NoteCraft',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      // One global status bar and navigation bar style for every screen.
      // This is what keeps the time, battery and network icons visible.
      builder: (context, child) {
        final theme = Theme.of(context);
        final colors = theme.extension<AppColors>() ?? AppColors.light;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyleFor(theme.brightness, colors),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: hasSeenOnboarding
          ? const NoteHomeScreen()
          : const OnboardingScreen(),
      routes: {'/privacy': (_) => const PrivacyPolicyScreen()},
    );
  }
}

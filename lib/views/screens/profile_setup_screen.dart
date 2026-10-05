import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:note_app/core/theme/app_colors.dart';
import 'package:note_app/data/models/user_profile.dart';
import 'package:note_app/viewmodels/providers.dart';
import 'package:note_app/views/screens/home_screen.dart';
import 'package:note_app/views/widgets/user_avatar.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final Random _random = Random();
  late final List<String> _seedHistory;
  int _seedIndex = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _seedHistory = [_generateSeed()];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String get _currentSeed => _seedHistory[_seedIndex];

  bool get _canContinue => _nameController.text.trim().isNotEmpty && !_saving;

  String _generateSeed() {
    return List.generate(
      3,
      (_) => _random.nextInt(0xFFFFFF).toRadixString(36),
    ).join();
  }

  void _next() {
    setState(() {
      if (_seedIndex == _seedHistory.length - 1) {
        _seedHistory.add(_generateSeed());
      }
      _seedIndex++;
    });
  }

  void _previous() {
    if (_seedIndex == 0) return;
    setState(() => _seedIndex--);
  }

  UserProfile get _draft {
    final base = ref.read(profileProvider);
    return UserProfile(
      name: _nameController.text.trim(),
      seed: _currentSeed,
      presetId: base.presetId,
      backgroundColor: base.backgroundColor,
      radius: base.radius,
      scale: base.scale,
    );
  }

  Future<void> _finish() async {
    if (!_canContinue) return;
    setState(() => _saving = true);

    await ref.read(profileProvider.notifier).updateProfile(_draft);
    await Hive.box('settings').put('hasSeenOnboarding', true);

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const NoteHomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              child: Row(
                children: [
                  if (Navigator.of(context).canPop())
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowLeft01,
                        size: 22,
                        color: c.textPrimary,
                      ),
                    )
                  else
                    const SizedBox(height: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set up your profile',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pick an avatar and tell us what to call you. '
                      'Everything stays on your device.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: c.textPrimary.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ArrowButton(
                          icon: HugeIcons.strokeRoundedArrowLeft01,
                          onPressed: _seedIndex == 0 ? null : _previous,
                        ),
                        const SizedBox(width: 22),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: c.border),
                          ),
                          child: UserAvatar(profile: _draft, size: 120),
                        ),
                        const SizedBox(width: 22),
                        _ArrowButton(
                          icon: HugeIcons.strokeRoundedArrowRight01,
                          onPressed: _next,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: Text(
                        'Tap the arrows to browse avatars',
                        style: TextStyle(
                          fontSize: 12,
                          color: c.textPrimary.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'Your name',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      maxLength: 24,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _finish(),
                      cursorColor: c.textPrimary,
                      style: TextStyle(color: c.textPrimary, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Enter your name',
                        hintStyle: TextStyle(color: c.textFaint, fontSize: 14),
                        counterText: '',
                        filled: true,
                        fillColor: c.fieldBg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: c.textPrimary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _canContinue ? _finish : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.accent,
                    disabledBackgroundColor: c.accent.withValues(alpha: 0.35),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: c.onAccent,
                    ),
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

class _ArrowButton extends StatelessWidget {
  final List<List<dynamic>> icon;
  final VoidCallback? onPressed;

  const _ArrowButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null;
    return Material(
      color: enabled ? c.fieldBg : c.fieldBg.withValues(alpha: 0.5),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Center(
            child: HugeIcon(
              icon: icon,
              size: 22,
              color: enabled
                  ? c.textPrimary
                  : c.textFaint.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:note_app/core/theme/app_colors.dart';
import 'package:note_app/data/models/user_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Required for ConsumerStatefulWidget
import 'package:note_app/viewmodels/providers.dart'; // Required for profileProvider
import 'package:note_app/views/widgets/user_avatar.dart';

class EditProfileSheet extends ConsumerStatefulWidget {
  final UserProfile initial;

  const EditProfileSheet({super.key, required this.initial});

  static Future<UserProfile?> show(BuildContext context, UserProfile initial) {
    return showModalBottomSheet<UserProfile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => EditProfileSheet(initial: initial),
    );
  }

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  late final TextEditingController _nameController;
  late final List<String> _seedHistory;
  late int _seedIndex;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _nameController = TextEditingController(text: p.name);
    _seedHistory = [p.seed.isEmpty ? 'default' : p.seed];
    _seedIndex = 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String get _currentSeed => _seedHistory[_seedIndex];

  String _generateSeed() {
    return List.generate(
      3,
      (_) => _random.nextInt(0xFFFFFF).toRadixString(36),
    ).join();
  }

  void _next() {
    setState(() {
      if (_seedIndex < _seedHistory.length - 1) {
        _seedIndex++;
      } else {
        _seedHistory.add(_generateSeed());
        _seedIndex++;
      }
    });
  }

  void _previous() {
    if (_seedIndex == 0) return;
    setState(() => _seedIndex--);
  }

  UserProfile get _draft => UserProfile(
    name: _nameController.text.trim().isEmpty
        ? 'Unnamed'
        : _nameController.text.trim(),
    seed: _currentSeed,
    presetId: widget.initial.presetId,
    backgroundColor: widget.initial.backgroundColor,
    radius: widget.initial.radius,
    scale: widget.initial.scale,
  );

  @override
  Widget build(BuildContext context) {
    // The old SystemChrome call is removed on purpose. It forced white
    // status bar icons every time this sheet opened. The style is now
    // handled globally in main.dart.
    final c = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.68,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Stack(
            children: [
              Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: c.dotInactive,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: HugeIcon(
                            icon: HugeIcons.strokeRoundedArrowLeft01,
                            size: 22,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Edit profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: c.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
                      children: [
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
                              color: c.textPrimary.withOpacity(0.4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          'Display name',
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
                          onChanged: (_) => setState(() {}),
                          cursorColor: c.textPrimary,
                          style: TextStyle(color: c.textPrimary, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Your name',
                            hintStyle: TextStyle(
                              color: c.textFaint,
                              fontSize: 14,
                            ),
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
                ],
              ),
              Positioned(
                right: 20,
                bottom: 20,
                child: FloatingActionButton.extended(
                  onPressed: () {
                    ref.read(profileProvider.notifier).updateProfile(_draft);
                    Navigator.pop(context, _draft);
                  },
                  backgroundColor: c.accent,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                    size: 20,
                    color: c.onAccent,
                  ),
                  label: Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: c.onAccent,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
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
      color: enabled ? c.fieldBg : c.fieldBg.withOpacity(0.5),
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
              color: enabled ? c.textPrimary : c.textFaint.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }
}

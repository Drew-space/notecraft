import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dicebear_core/dicebear_core.dart';

// ⬇️ swap the filename to whatever the ls command printed
import 'package:dicebear_styles/bottts_neutral.dart';

import 'package:note_app/data/models/user_profile.dart';

// Parse once, reuse forever. ⬇️ swap the constant to whatever the peek printed.
final Style kBotttsNeutralStyle = Style.parse(botttsNeutral);

class UserAvatar extends StatelessWidget {
  final UserProfile profile;
  final double size;

  const UserAvatar({super.key, required this.profile, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final avatar = Avatar(kBotttsNeutralStyle, {
      'seed': profile.seed.isEmpty ? 'default' : profile.seed,
      'size': (size * 3).round(),
      'borderRadius': 50,
      'scale': 1.0,
    });

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: SvgPicture.string(avatar.svg, fit: BoxFit.cover),
      ),
    );
  }
}

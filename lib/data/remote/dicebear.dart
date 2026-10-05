// lib/user/data/dicebear.dart
import 'package:note_app/data/models/user_profile.dart';

/// A DiceBear preset = a plain set of render options.
/// Nothing to install — just query params sent to the avatar API.
class DiceBearPreset {
  final String id;
  final String label;
  final String description;

  /// Values may be a `String` or a `List<String>` (joined with ",").
  final Map<String, dynamic> options;

  const DiceBearPreset({
    required this.id,
    required this.label,
    required this.description,
    this.options = const {},
  });
}

/// Bottts Neutral presets (from the DiceBear docs).
///
/// NOTE: option keys/variants differ slightly between DiceBear major
/// versions. Everything here is a normal query param — if a look isn't
/// exactly right, open the DiceBear playground, copy the generated URL
/// and paste the params into the matching preset below.
const kBotttsNeutralPresets = <DiceBearPreset>[
  DiceBearPreset(
    id: 'default',
    label: 'Default',
    description: 'The plain Bottts Neutral robot.',
    options: {},
  ),
  DiceBearPreset(
    id: 'bare',
    label: 'Bare',
    description: 'No surface texture, flat shell.',
    options: {'texture': ''}, // empty variant list = no texture
  ),
  DiceBearPreset(
    id: 'sepia',
    label: 'Sepia',
    description: 'A brass robot on tanned metal.',
    options: {
      'backgroundColor': ['c9b79c'],
      'base': ['01', '02', '03'],
      'top': ['01', '02', '03'],
    },
  ),
  DiceBearPreset(
    id: 'greyscale',
    label: 'Greyscale',
    description: 'Bare metal, four steps of grey.',
    options: {
      'backgroundColor': ['d9d9d9', 'bfbfbf', 'a6a6a6', '8c8c8c'],
    },
  ),
  DiceBearPreset(
    id: 'duotone',
    label: 'Duotone',
    description: 'One indigo for the whole face.',
    options: {
      'backgroundColor': ['4f46e5'],
      'texture': '',
    },
  ),
  DiceBearPreset(
    id: 'muted',
    label: 'Muted',
    description: 'An earthy shell instead of the bright one.',
    options: {
      'backgroundColor': ['e7e0d3', 'd6c7b0', 'b9a88f', '9c8b74', '7d6f5c'],
    },
  ),
  DiceBearPreset(
    id: 'electric',
    label: 'Electric',
    description: 'Acid shells at full saturation.',
    options: {
      'backgroundColor': ['00ff88', '00e5ff', 'ff00e5', 'ffea00', '7c00ff'],
    },
  ),
  DiceBearPreset(
    id: 'pastel-wall',
    label: 'Pastel Wall',
    description: 'Five soft shells.',
    options: {
      'backgroundColor': ['ffd6e0', 'd6f5ff', 'd6ffe0', 'fff5d6', 'e8d6ff'],
    },
  ),
  DiceBearPreset(
    id: 'bold-pop',
    label: 'Bold Pop',
    description: 'Five saturated shells.',
    options: {
      'backgroundColor': ['ff3b30', 'ff9500', 'ffcc00', '34c759', '007aff'],
    },
  ),
  DiceBearPreset(
    id: 'sunrise',
    label: 'Sunrise',
    description: 'A warm gradient across the face plate.',
    options: {
      'backgroundColor': ['ffd8a8', 'ffb37b', 'ff8f5e', 'ff6b4a'],
      'radius': '40',
    },
  ),
  DiceBearPreset(
    id: 'full-cast',
    label: 'Full Cast',
    description: 'Every robot gets the surface texture.',
    options: {'texture': '01,02,03,04,05'},
  ),
  DiceBearPreset(
    id: 'close-up',
    label: 'Close Up',
    description: 'Scaled in on the face plate.',
    options: {'scale': '150'},
  ),
];

DiceBearPreset diceBearPresetById(String id) {
  return kBotttsNeutralPresets.firstWhere(
    (p) => p.id == id,
    orElse: () => kBotttsNeutralPresets.first,
  );
}

Map<String, String> _encodeOptions(Map<String, dynamic> options) {
  final out = <String, String>{};
  options.forEach((key, value) {
    if (value == null) return;
    if (value is List) {
      // Empty list -> keep the param but leave it blank (means "none").
      out[key] = value.join(',');
    } else {
      out[key] = value.toString();
    }
  });
  return out;
}

/// Builds the deterministic DiceBear URL for a profile.
Uri diceBearUri(UserProfile profile, {int size = 256}) {
  final preset = diceBearPresetById(profile.presetId);

  final query = <String, String>{
    'seed': profile.seed.isEmpty ? 'default' : profile.seed,
    'size': '$size',
    'radius': profile.radius.round().toString(),
    'scale': profile.scale.round().toString(),
    ..._encodeOptions(preset.options),
  };

  if (profile.backgroundColor != null && profile.backgroundColor!.isNotEmpty) {
    query['backgroundColor'] = profile.backgroundColor!.replaceFirst('#', '');
  }

  return Uri.https('api.dicebear.com', '/9.x/bottts-neutral/png', query);
}

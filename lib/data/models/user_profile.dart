// lib/user/models/user_profile.dart
import 'dart:convert';

class UserProfile {
  final String name;
  final String seed;
  final String presetId;
  final String? backgroundColor; // '#RRGGBB' or null
  final double radius; // 0..50
  final double scale; // 50..200

  const UserProfile({
    this.name = 'Alex Morgan',
    this.seed = 'alex',
    this.presetId = 'default',
    this.backgroundColor = '#F3F4F6',
    this.radius = 50,
    this.scale = 100,
  });

  UserProfile copyWith({
    String? name,
    String? seed,
    String? presetId,
    String? backgroundColor,
    bool clearBackgroundColor = false,
    double? radius,
    double? scale,
  }) {
    return UserProfile(
      name: name ?? this.name,
      seed: seed ?? this.seed,
      presetId: presetId ?? this.presetId,
      backgroundColor: clearBackgroundColor
          ? null
          : (backgroundColor ?? this.backgroundColor),
      radius: radius ?? this.radius,
      scale: scale ?? this.scale,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'seed': seed,
    'presetId': presetId,
    'backgroundColor': backgroundColor,
    'radius': radius,
    'scale': scale,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] as String? ?? 'Alex Morgan',
    seed: json['seed'] as String? ?? 'alex',
    presetId: json['presetId'] as String? ?? 'default',
    backgroundColor: json['backgroundColor'] as String?,
    radius: (json['radius'] as num?)?.toDouble() ?? 50,
    scale: (json['scale'] as num?)?.toDouble() ?? 100,
  );

  String encode() => jsonEncode(toJson());
  factory UserProfile.decode(String raw) =>
      UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

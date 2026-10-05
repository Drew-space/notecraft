import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════
//  GLOBAL TAGS
// ═══════════════════════════════════════════════════════════════════
const List<String> kGlobalTags = [
  'Personal',
  'Work',
  'School',
  'Finance',
  'Family',
  'Friends',
  'Health',
  'Shopping',
  'Food',
  'Travel',
  'Home',
  'Entertainment',
  'Ideas',
  'Projects',
  'Tasks',
  'Events',
  'Important',
];

// ═══════════════════════════════════════════════════════════════════
//  VIBRANT TAG COLORS  (used for the pill badges)
// ═══════════════════════════════════════════════════════════════════
const List<Color> kTagPalette = [
  Color(0xFFE53935), // Red
  Color(0xFFD81B60), // Pink
  Color(0xFF8E24AA), // Purple
  Color(0xFF5E35B1), // Deep Purple
  Color(0xFF3949AB), // Indigo
  Color(0xFF1E88E5), // Blue
  Color(0xFF039BE5), // Light Blue
  Color(0xFF00ACC1), // Cyan
  Color(0xFF00897B), // Teal
  Color(0xFF43A047), // Green
  Color(0xFF7CB342), // Light Green
  Color(0xFFFDD835), // Yellow
  Color(0xFFFB8C00), // Orange
  Color(0xFFF4511E), // Deep Orange
  Color(0xFF6D4C41), // Brown
  Color(0xFF546E7A), // Blue Grey
  Color(0xFFAD1457), // Dark Pink
];

final Map<String, Color> kTagColorMap = {
  'Personal': kTagPalette[0],
  'Work': kTagPalette[1],
  'School': kTagPalette[2],
  'Finance': kTagPalette[3],
  'Family': kTagPalette[4],
  'Friends': kTagPalette[5],
  'Health': kTagPalette[6],
  'Shopping': kTagPalette[7],
  'Food': kTagPalette[8],
  'Travel': kTagPalette[9],
  'Home': kTagPalette[10],
  'Entertainment': kTagPalette[11],
  'Ideas': kTagPalette[12],
  'Projects': kTagPalette[13],
  'Tasks': kTagPalette[14],
  'Events': kTagPalette[15],
  'Important': kTagPalette[16],
};

Color getTagColor(String tag) {
  if (tag.isEmpty) return kTagPalette.first;
  if (kTagColorMap.containsKey(tag)) return kTagColorMap[tag]!;
  final hash = tag.hashCode;
  return kTagPalette[hash.abs() % kTagPalette.length];
}

// ═══════════════════════════════════════════════════════════════════
//  STRONG PASTEL BACKGROUND PALETTE  (used for note cards)
// ═══════════════════════════════════════════════════════════════════
const Color pastelYellow = Color(0xFFF7D046); // Rich golden yellow
const Color pastelPink = Color(0xFFF28BA8); // Bold blush pink
const Color pastelPurple = Color(0xFFBC9AF5); // Deep lavender purple
const Color pastelRed = Color(0xFFF08B78); // Warm coral red
const Color pastelBlue = Color(0xFF7BB4EE); // Bright sky blue
const Color pastelGreen = Color(0xFF8CC98F); // Fresh garden green
const Color pastelOrange = Color(0xFFF8A24B); // Zesty orange
const Color pastelSlate = Color(0xFF9BA9BE); // Cool steel slate
const Color pastelTeal = Color(0xFF6FC7BA); // Vibrant sea teal
const Color pastelPeach = Color(0xFFF5A17A); // Juicy peach
const Color pastelLavender = Color(0xFFAE9BEA); // Bold lavender
const Color pastelMint = Color(0xFF8ED0AB); // Bright mint

const List<Color> kPastelPalette = [
  pastelYellow,
  pastelPink,
  pastelPurple,
  pastelRed,
  pastelBlue,
  pastelGreen,
  pastelOrange,
  pastelSlate,
  pastelTeal,
  pastelPeach,
  pastelLavender,
  pastelMint,
];

// ═══════════════════════════════════════════════════════════════════
//  NOTE BACKGROUND COLOR PICKER
//  Each tag maps to a specific strong pastel color so the home
//  screen looks intentionally designed and colorful.
// ═══════════════════════════════════════════════════════════════════
Color getNoteBackgroundColor(String tag, String id) {
  if (tag.isNotEmpty) {
    switch (tag) {
      case 'Personal':
        return pastelPink;
      case 'Work':
        return pastelBlue;
      case 'School':
        return pastelYellow;
      case 'Finance':
        return pastelSlate;
      case 'Family':
        return pastelRed;
      case 'Friends':
        return pastelTeal;
      case 'Health':
        return pastelGreen;
      case 'Shopping':
        return pastelPeach;
      case 'Food':
        return pastelMint;
      case 'Travel':
        return pastelBlue;
      case 'Home':
        return pastelOrange;
      case 'Entertainment':
        return pastelPurple;
      case 'Ideas':
        return pastelYellow;
      case 'Projects':
        return pastelLavender;
      case 'Tasks':
        return pastelOrange;
      case 'Events':
        return pastelPink;
      case 'Important':
        return pastelPurple;
      default:
        break;
    }
  }
  // Fallback for custom tags or notes with no tag.
  final hash = (tag.isEmpty ? id : tag).hashCode;
  return kPastelPalette[hash.abs() % kPastelPalette.length];
}

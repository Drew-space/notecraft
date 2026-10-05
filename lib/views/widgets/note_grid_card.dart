// // lib/views/widgets/note_grid_card.dart
// import 'dart:convert';
// import 'dart:io';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:hugeicons/hugeicons.dart';

// import 'package:note_app/core/constants/app_tags.dart';
// import 'package:note_app/core/services/note_lock_service.dart';
// import 'package:note_app/data/models/note.dart';
// import 'package:note_app/views/screens/note_detail_screen.dart';

// // Image box settings
// const double kGridCardImageHeight = 90;
// const double kGridCardImagePadding = 6;

// /// Removes the invisible placeholder characters Quill leaves where an
// /// image sits, so they never show up as a little box in previews.
// String cleanNoteText(String s) => s
//     .replaceAll(RegExp(r'[\uFFFC\uFFFD\u200B-\u200F\u2028\u2029\uFEFF]'), '')
//     .trim();

// // ─── List preview parsing ───────────────────────────────────────────
// enum _ListKind { none, bullet, ordered, checked, unchecked }

// class _PreviewLine {
//   final String text;
//   final _ListKind kind;
//   int number;
//   _PreviewLine(this.text, this.kind, {this.number = 0});
// }

// _ListKind _kindOf(Map? attrs) {
//   switch (attrs?['list']) {
//     case 'bullet':
//       return _ListKind.bullet;
//     case 'ordered':
//       return _ListKind.ordered;
//     case 'checked':
//       return _ListKind.checked;
//     case 'unchecked':
//       return _ListKind.unchecked;
//     default:
//       return _ListKind.none;
//   }
// }

// /// Reads the note's Quill delta and returns one entry per line,
// /// including what kind of list (if any) each line belongs to.
// List<_PreviewLine> _parsePreviewLines(Note note) {
//   final raw = note.deltaJson;
//   if (raw == null || raw.isEmpty) return [];
//   try {
//     final ops = jsonDecode(raw) as List;
//     final lines = <_PreviewLine>[];
//     final buf = StringBuffer();

//     for (final op in ops) {
//       if (op is! Map) continue;
//       final insert = op['insert'];
//       final attrs = op['attributes'] as Map?;
//       if (insert is! String) continue; // images and other embeds are skipped

//       final parts = insert.split('\n');
//       for (var i = 0; i < parts.length; i++) {
//         buf.write(parts[i]);
//         if (i < parts.length - 1) {
//           // A newline ends the line, and its attributes describe the line
//           lines.add(
//             _PreviewLine(cleanNoteText(buf.toString()), _kindOf(attrs)),
//           );
//           buf.clear();
//         }
//       }
//     }
//     if (buf.isNotEmpty) {
//       lines.add(_PreviewLine(cleanNoteText(buf.toString()), _ListKind.none));
//     }

//     // Number the ordered list items (1, 2, 3...)
//     var n = 0;
//     for (final l in lines) {
//       if (l.kind == _ListKind.ordered) {
//         n++;
//         l.number = n;
//       } else {
//         n = 0;
//       }
//     }

//     return lines.where((l) => l.text.trim().isNotEmpty).toList();
//   } catch (_) {
//     return [];
//   }
// }

// /// Shows a note's text. Plain notes show as normal text. Notes with
// /// checklists, bullets or numbered lists show the check marks, bullets
// /// and numbers too.
// class NoteContentPreview extends StatelessWidget {
//   final Note note;
//   final int maxLines;
//   final int? maxListItems; // defaults to maxLines
//   final double fontSize;
//   final Color color;

//   const NoteContentPreview({
//     super.key,
//     required this.note,
//     required this.maxLines,
//     this.maxListItems,
//     this.fontSize = 13,
//     this.color = const Color(0xFF374151),
//   });

//   @override
//   Widget build(BuildContext context) {
//     final style = GoogleFonts.inter(
//       fontSize: fontSize,
//       color: color,
//       height: 1.55,
//     );
//     final lines = _parsePreviewLines(note);
//     final hasList = lines.any((l) => l.kind != _ListKind.none);

//     // Normal note: behave exactly like before
//     if (!hasList) {
//       return Text(
//         cleanNoteText(note.content),
//         style: style,
//         maxLines: maxLines,
//         overflow: TextOverflow.ellipsis,
//       );
//     }

//     final limit = maxListItems ?? maxLines;
//     final shown = lines.take(limit).toList();
//     final truncated = lines.length > limit;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         for (var i = 0; i < shown.length; i++)
//           _row(shown[i], style, truncated && i == shown.length - 1 ? ' …' : ''),
//       ],
//     );
//   }

//   Widget _row(_PreviewLine l, TextStyle style, String suffix) {
//     if (l.kind == _ListKind.none) {
//       return Text(
//         '${l.text}$suffix',
//         style: style,
//         maxLines: 2,
//         overflow: TextOverflow.ellipsis,
//       );
//     }

//     final lineHeight = fontSize * 1.55;
//     final iconSize = fontSize + 3;
//     const iconColor = Color(0xFF1A1A1A);

//     Widget marker;
//     switch (l.kind) {
//       case _ListKind.checked:
//         marker = Icon(Icons.check_circle, size: iconSize, color: iconColor);
//         break;
//       case _ListKind.unchecked:
//         marker = Icon(
//           Icons.radio_button_unchecked,
//           size: iconSize,
//           color: iconColor,
//         );
//         break;
//       case _ListKind.bullet:
//         marker = Text('•', style: style.copyWith(fontWeight: FontWeight.w700));
//         break;
//       case _ListKind.ordered:
//         marker = Text('${l.number}.', style: style);
//         break;
//       case _ListKind.none:
//         marker = const SizedBox.shrink();
//         break;
//     }

//     final textStyle = l.kind == _ListKind.checked
//         ? style.copyWith(
//             decoration: TextDecoration.lineThrough,
//             decorationColor: color,
//           )
//         : style;

//     return Padding(
//       padding: const EdgeInsets.only(bottom: 2),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: fontSize * 1.7,
//             height: lineHeight,
//             child: Align(alignment: Alignment.centerLeft, child: marker),
//           ),
//           Expanded(
//             child: Text(
//               '${l.text}$suffix',
//               style: textStyle,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /// A note card that uses the note's background color, tag color and a small
// /// framed image. Used on the home, pinned and bookmark screens.
// class NoteGridCard extends StatelessWidget {
//   final Note note;
//   const NoteGridCard({super.key, required this.note});

//   Future<void> _open(BuildContext context) async {
//     if (note.isLocked) {
//       final supported = await NoteLockService.isDeviceSupported();
//       if (!supported) {
//         if (!context.mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('No device authentication available'),
//             behavior: SnackBarBehavior.floating,
//           ),
//         );
//         return;
//       }
//       final ok = await NoteLockService.authenticate();
//       if (!ok || !context.mounted) return;
//     }
//     if (!context.mounted) return;
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => NoteDetailScreen(note: note)),
//     );
//   }

//   Widget _image(String url) {
//     final isLocal =
//         url.startsWith('/') ||
//         url.startsWith('file://') ||
//         !url.startsWith('http');
//     if (isLocal) {
//       return Image.file(
//         File(url),
//         fit: BoxFit.cover,
//         width: double.infinity,
//         height: double.infinity,
//         errorBuilder: (_, __, ___) => _imageError(),
//       );
//     }
//     return Image.network(
//       url,
//       fit: BoxFit.cover,
//       width: double.infinity,
//       height: double.infinity,
//       errorBuilder: (_, __, ___) => _imageError(),
//     );
//   }

//   Widget _imageError() => Container(
//     color: Colors.black.withOpacity(0.05),
//     alignment: Alignment.center,
//     child: const HugeIcon(
//       icon: HugeIcons.strokeRoundedImage01,
//       color: Colors.black45,
//       size: 32,
//     ),
//   );

//   Widget _framedImage(String url) => Padding(
//     padding: const EdgeInsets.only(bottom: 12),
//     child: Container(
//       height: kGridCardImageHeight,
//       width: double.infinity,
//       padding: const EdgeInsets.all(kGridCardImagePadding),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.35),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: Colors.black.withOpacity(0.08), width: 1),
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(9),
//         child: _image(url),
//       ),
//     ),
//   );

//   String _formatDate(DateTime date) {
//     const months = [
//       'Jan',
//       'Feb',
//       'Mar',
//       'Apr',
//       'May',
//       'Jun',
//       'Jul',
//       'Aug',
//       'Sep',
//       'Oct',
//       'Nov',
//       'Dec',
//     ];
//     return '${months[date.month - 1]} ${date.day}, ${date.year}';
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bgColor = getNoteBackgroundColor(
//       note.tags.isNotEmpty ? note.tags.first : '',
//       note.id,
//     );
//     final hasImage = note.imageUrl != null && note.imageUrl!.isNotEmpty;

//     return GestureDetector(
//       onTap: () => _open(context),
//       child: Container(
//         decoration: BoxDecoration(
//           color: bgColor,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.06),
//               blurRadius: 10,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(16),
//           child: Stack(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(12),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     if (hasImage) _framedImage(note.imageUrl!),
//                     Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         if (note.isLocked)
//                           const Padding(
//                             padding: EdgeInsets.only(right: 6, top: 2),
//                             child: HugeIcon(
//                               icon: HugeIcons.strokeRoundedLocked,
//                               size: 14,
//                               color: Color(0xFF1A1A1A),
//                             ),
//                           ),
//                         Expanded(
//                           child: Text(
//                             note.title,
//                             style: GoogleFonts.inter(
//                               fontSize: 15,
//                               fontWeight: FontWeight.w700,
//                               color: const Color(0xFF1A1A1A),
//                               height: 1.35,
//                             ),
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                         const SizedBox(width: 4),
//                         if (note.isPinned)
//                           const Padding(
//                             padding: EdgeInsets.only(right: 4),
//                             child: Icon(
//                               Icons.push_pin_outlined,
//                               size: 16,
//                               color: Color(0xFF1A1A1A),
//                             ),
//                           ),
//                         if (note.isBookmarked)
//                           const Icon(
//                             Icons.bookmark,
//                             size: 18,
//                             color: Color(0xFF1A1A1A),
//                           ),
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     NoteContentPreview(
//                       note: note,
//                       maxLines: hasImage ? 3 : 5,
//                       fontSize: 13,
//                     ),
//                     const SizedBox(height: 12),
//                     if (note.tags.isNotEmpty)
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 10,
//                           vertical: 5,
//                         ),
//                         decoration: BoxDecoration(
//                           color: getTagColor(note.tags.first),
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: Text(
//                           note.tags.first,
//                           style: GoogleFonts.inter(
//                             fontSize: 11,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                     const SizedBox(height: 10),
//                     Row(
//                       children: [
//                         const Icon(
//                           Icons.calendar_today_outlined,
//                           size: 11,
//                           color: Color(0xFF4B5563),
//                         ),
//                         const SizedBox(width: 4),
//                         Text(
//                           _formatDate(note.date),
//                           style: GoogleFonts.inter(
//                             fontSize: 11,
//                             color: const Color(0xFF4B5563),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               if (note.isLocked)
//                 Positioned.fill(
//                   child: BackdropFilter(
//                     filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//                     child: Container(
//                       color: Colors.white.withOpacity(0.55),
//                       alignment: Alignment.center,
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           const HugeIcon(
//                             icon: HugeIcons.strokeRoundedLocked,
//                             color: Color(0xFF1A1A1A),
//                             size: 28,
//                           ),
//                           const SizedBox(height: 6),
//                           Text(
//                             'Locked',
//                             style: GoogleFonts.inter(
//                               fontSize: 13,
//                               fontWeight: FontWeight.w700,
//                               color: const Color(0xFF1A1A1A),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// lib/views/widgets/note_grid_card.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:note_app/core/constants/app_tags.dart';
import 'package:note_app/core/services/note_lock_service.dart';
import 'package:note_app/data/models/note.dart';
import 'package:note_app/views/screens/note_detail_screen.dart';

// Image box settings
const double kGridCardImageHeight = 90;
const double kGridCardImagePadding = 6;

/// Removes the invisible placeholder characters Quill leaves where an
/// image sits, so they never show up as a little box in previews.
String cleanNoteText(String s) => s
    .replaceAll(RegExp(r'[\uFFFC\uFFFD\u200B-\u200F\u2028\u2029\uFEFF]'), '')
    .trim();

// ─── List preview parsing ───────────────────────────────────────────
enum _ListKind { none, bullet, ordered, checked, unchecked }

class _PreviewLine {
  final String text;
  final _ListKind kind;
  int number;
  _PreviewLine(this.text, this.kind, {this.number = 0});
}

_ListKind _kindOf(Map? attrs) {
  switch (attrs?['list']) {
    case 'bullet':
      return _ListKind.bullet;
    case 'ordered':
      return _ListKind.ordered;
    case 'checked':
      return _ListKind.checked;
    case 'unchecked':
      return _ListKind.unchecked;
    default:
      return _ListKind.none;
  }
}

/// Reads the note's Quill delta and returns one entry per line,
/// including what kind of list (if any) each line belongs to.
List<_PreviewLine> _parsePreviewLines(Note note) {
  final raw = note.deltaJson;
  if (raw == null || raw.isEmpty) return [];
  try {
    final ops = jsonDecode(raw) as List;
    final lines = <_PreviewLine>[];
    final buf = StringBuffer();

    for (final op in ops) {
      if (op is! Map) continue;
      final insert = op['insert'];
      final attrs = op['attributes'] as Map?;
      if (insert is! String) continue; // images and other embeds are skipped

      final parts = insert.split('\n');
      for (var i = 0; i < parts.length; i++) {
        buf.write(parts[i]);
        if (i < parts.length - 1) {
          // A newline ends the line, and its attributes describe the line
          lines.add(
            _PreviewLine(cleanNoteText(buf.toString()), _kindOf(attrs)),
          );
          buf.clear();
        }
      }
    }
    if (buf.isNotEmpty) {
      lines.add(_PreviewLine(cleanNoteText(buf.toString()), _ListKind.none));
    }

    // Number the ordered list items (1, 2, 3...)
    var n = 0;
    for (final l in lines) {
      if (l.kind == _ListKind.ordered) {
        n++;
        l.number = n;
      } else {
        n = 0;
      }
    }

    return lines.where((l) => l.text.trim().isNotEmpty).toList();
  } catch (_) {
    return [];
  }
}

/// Shows a note's text. Plain notes show as normal text. Notes with
/// checklists, bullets or numbered lists show the check marks, bullets
/// and numbers too.
class NoteContentPreview extends StatelessWidget {
  final Note note;
  final int maxLines;
  final int? maxListItems; // defaults to maxLines
  final double fontSize;
  final Color color;

  const NoteContentPreview({
    super.key,
    required this.note,
    required this.maxLines,
    this.maxListItems,
    this.fontSize = 13,
    this.color = const Color(0xFF374151),
  });

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.inter(
      fontSize: fontSize,
      color: color,
      height: 1.55,
    );
    final lines = _parsePreviewLines(note);
    final hasList = lines.any((l) => l.kind != _ListKind.none);

    // Normal note: behave exactly like before
    if (!hasList) {
      return Text(
        cleanNoteText(note.content),
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    final limit = maxListItems ?? maxLines;
    final shown = lines.take(limit).toList();
    final truncated = lines.length > limit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < shown.length; i++)
          _row(shown[i], style, truncated && i == shown.length - 1 ? ' …' : ''),
      ],
    );
  }

  Widget _row(_PreviewLine l, TextStyle style, String suffix) {
    if (l.kind == _ListKind.none) {
      return Text(
        '${l.text}$suffix',
        style: style,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    final lineHeight = fontSize * 1.55;
    final iconSize = fontSize + 3;
    const iconColor = Color(0xFF1A1A1A);

    Widget marker;
    switch (l.kind) {
      case _ListKind.checked:
        marker = Icon(Icons.check_circle, size: iconSize, color: iconColor);
        break;
      case _ListKind.unchecked:
        marker = Icon(
          Icons.radio_button_unchecked,
          size: iconSize,
          color: iconColor,
        );
        break;
      case _ListKind.bullet:
        marker = Text('•', style: style.copyWith(fontWeight: FontWeight.w700));
        break;
      case _ListKind.ordered:
        marker = Text('${l.number}.', style: style);
        break;
      case _ListKind.none:
        marker = const SizedBox.shrink();
        break;
    }

    final textStyle = l.kind == _ListKind.checked
        ? style.copyWith(
            decoration: TextDecoration.lineThrough,
            decorationColor: color,
          )
        : style;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: fontSize * 1.7,
            height: lineHeight,
            child: Align(alignment: Alignment.centerLeft, child: marker),
          ),
          Expanded(
            child: Text(
              '${l.text}$suffix',
              style: textStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// A note card that uses the note's background color, tag color and a small
/// framed image. Used on the home, pinned and bookmark screens.
///
/// Optional extras (used by the home screen):
///  - [onTap]: overrides the default "open the note" behaviour
///  - [onLongPress]: called on press and hold
///  - [selectionMode] / [selected]: shows the multi-select overlay
class NoteGridCard extends StatelessWidget {
  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selectionMode;
  final bool selected;

  const NoteGridCard({
    super.key,
    required this.note,
    this.onTap,
    this.onLongPress,
    this.selectionMode = false,
    this.selected = false,
  });

  Future<void> _open(BuildContext context) async {
    if (note.isLocked) {
      final supported = await NoteLockService.isDeviceSupported();
      if (!supported) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No device authentication available'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      final ok = await NoteLockService.authenticate();
      if (!ok || !context.mounted) return;
    }
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteDetailScreen(note: note)),
    );
  }

  Widget _image(String url) {
    final isLocal =
        url.startsWith('/') ||
        url.startsWith('file://') ||
        !url.startsWith('http');
    if (isLocal) {
      return Image.file(
        File(url),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _imageError(),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => _imageError(),
    );
  }

  Widget _imageError() => Container(
    color: Colors.black.withOpacity(0.05),
    alignment: Alignment.center,
    child: const HugeIcon(
      icon: HugeIcons.strokeRoundedImage01,
      color: Colors.black45,
      size: 32,
    ),
  );

  Widget _framedImage(String url) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Container(
      height: kGridCardImageHeight,
      width: double.infinity,
      padding: const EdgeInsets.all(kGridCardImagePadding),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.08), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: _image(url),
      ),
    ),
  );

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // Dim overlay + border + check badge shown while selecting notes
  Widget _selectionOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          alignment: Alignment.bottomRight,
          decoration: BoxDecoration(
            color: selected
                ? Colors.black.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? const Color(0xFF1A1A1A) : Colors.transparent,
              width: 2.5,
            ),
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 22,
              color: const Color(0xFF1A1A1A),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = getNoteBackgroundColor(
      note.tags.isNotEmpty ? note.tags.first : '',
      note.id,
    );
    final hasImage = note.imageUrl != null && note.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap ?? () => _open(context),
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasImage) _framedImage(note.imageUrl!),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (note.isLocked)
                          const Padding(
                            padding: EdgeInsets.only(right: 6, top: 2),
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedLocked,
                              size: 14,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            note.title,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (note.isPinned)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.push_pin_outlined,
                              size: 16,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        if (note.isBookmarked)
                          const Icon(
                            Icons.bookmark,
                            size: 18,
                            color: Color(0xFF1A1A1A),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    NoteContentPreview(
                      note: note,
                      maxLines: hasImage ? 3 : 5,
                      fontSize: 13,
                    ),
                    const SizedBox(height: 12),
                    if (note.tags.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: getTagColor(note.tags.first),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          note.tags.first,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 11,
                          color: Color(0xFF4B5563),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(note.date),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (note.isLocked)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: Colors.white.withOpacity(0.55),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedLocked,
                            color: Color(0xFF1A1A1A),
                            size: 28,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Locked',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // Last, so it sits above the lock overlay too
              if (selectionMode) _selectionOverlay(),
            ],
          ),
        ),
      ),
    );
  }
}

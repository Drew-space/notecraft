import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:note_app/data/models/note.dart';
import 'package:note_app/core/constants/app_tags.dart';
import 'package:note_app/core/theme/app_colors.dart';
import 'package:note_app/viewmodels/providers.dart';

// ─── "Huge" toolbar icon size ───────────────────────────────────────
const double kIconSizeHuge = 30;
const double kListItemSpacing =
    2.5; // space added above and below each list item
// ─── Line heights (edit these two values to tune spacing) ───────────
const double kParagraphLineHeight = 1.7;
const double kListLineHeight = 1.15;
const double kCheckboxSize = 24; // increase for a bigger checkbox
// ─── Typography ─────────────────────────────────────────────────────
const String kFontFamily = 'Inter';

// ─── Image snapping ─────────────────────────────────────────────────
// After you drag an image sideways it settles on the nearest of these
// positions: -1 = left, 0 = center, 1 = right.
const List<double> kImageSnapPoints = [-1.0, 0.0, 1.0];

double snapImageAlignment(double value) {
  var best = kImageSnapPoints.first;
  for (final p in kImageSnapPoints) {
    if ((p - value).abs() < (best - value).abs()) best = p;
  }
  return best;
}

// Longest tag text shown in the header chip before it gets "..."
const int kMaxTagChars = 12;

String shortTag(String text, {int max = kMaxTagChars}) {
  final t = text.trim();
  if (t.length <= max) return t;
  return '${t.substring(0, max).trimRight()}...';
}

ThemeData interThemeOf(BuildContext context) {
  final base = Theme.of(context);
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: kFontFamily),
    primaryTextTheme: base.primaryTextTheme.apply(fontFamily: kFontFamily),
  );
}

// ─── Theme constants ────────────────────────────────────────────────
// NOTE: these constants are still used by the three editor toolbars
// (collapsed pill, expanded panel, floating selection toolbar), which
// keep their colors in both light and dark mode. The rest of the screen
// uses context.colors so it follows the theme.
const Color kTextPrimary = Color(0xFF1F1F1F);
const Color kTextSecondary = Colors.grey;
const Color kHintText = Colors.grey;

const Color kPanelBg = Colors.white;
const Color kTileBg = Color(0xFFF6F6F6);
const Color kAccent = Color(0xFF2A2E33);
const Color kImageSelectionBlue = Color(0xFF027AFF);

// ─── Highlight palette ──────────────────────────────────────────────
const Map<String, Color> kHighlightPalette = {
  'Yellow': Color(0xFFF4EF7C),
  'Red': Color(0xFFE0526F),
  'Blue': Color(0xFF027AFF),
  'Green': Color(0xFF8FD9A8),
  'Purple': Color(0xFFAF92F9),
  'Pink': Color(0xFFF29BCB),
};

const Color kDefaultHighlight = Color(0xFFAF92F9);

// Text colors, used for the inline sliding text-color palette
const Map<String, Color> kTextPalette = {
  'White': Color(0xFFFFFFFF),
  'Black': Color(0xFF1F1F1F),
  'Grey': Color(0xFF8A8A8A),
  'Red': Color(0xFFE0526F),
  'Orange': Color(0xFFF2994A),
  'Yellow': Color(0xFFD9B400),
  'Green': Color(0xFF27AE60),
  'Mint': Color(0xFF8FD9A8),
  'Teal': Color(0xFF12B5A5),
  'Blue': Color(0xFF027AFF),
  'Purple': Color(0xFFAF92F9),
  'Pink': Color(0xFFF29BCB),
  'Brown': Color(0xFF8B5E3C),
};

const List<Color> kTextColorPresets = [
  Colors.white,
  Color(0xFF1F1F1F),
  Color(0xFF8A8A8A),
  Color(0xFFE0526F),
  Color(0xFFF2994A),
  Color(0xFFD9B400),
  Color(0xFF27AE60),
  Color(0xFF12B5A5),
  Color(0xFF027AFF),
  Color(0xFFAF92F9),
  Color(0xFFF29BCB),
  Color(0xFF8B5E3C),
];

const List<Color> kTextColorGrid = [
  Color(0xFF1F1F1F),
  Color(0xFF2A2E33),
  Color(0xFF8A8A8A),
  Color(0xFFE0526F),
  Color(0xFFF2994A),
  Color(0xFFD9B400),
  Color(0xFF27AE60),
  Color(0xFF8FD9A8),
  Color(0xFF12B5A5),
  Color(0xFF027AFF),
  Color(0xFFAF92F9),
  Color(0xFFF29BCB),
  Color(0xFF8B5E3C),
  Color(0xFFFFFFFF),
];

// ─── Custom attributes ─────────────────────────────────────────────
class FontSizeAttribute extends quill.Attribute<String?> {
  const FontSizeAttribute(String? size)
    : super('customFontSize', quill.AttributeScope.inline, size);
}

class FontWeightLabelAttribute extends quill.Attribute<String?> {
  const FontWeightLabelAttribute(String? label)
    : super('customFontWeight', quill.AttributeScope.inline, label);
}

FontWeight fontWeightFromLabel(String label) {
  switch (label) {
    case 'Thin':
      return FontWeight.w200;
    case 'Regular':
      return FontWeight.w400;
    case 'Medium':
      return FontWeight.w500;
    case 'Semibold':
      return FontWeight.w600;
    case 'Bold':
      return FontWeight.w700;
    default:
      return FontWeight.w400;
  }
}

// NOTE: no `height` in any inline style below. Line height must come only
// from the block style (paragraph or list) so lists are never overridden.
// The strike-through lines have no fixed decorationColor on purpose, so the
// line always takes the text color and stays visible in dark mode.
TextStyle customStyleBuilder(quill.Attribute attr) {
  if (attr.key == 'customFontSize') {
    final raw = attr.value;
    if (raw is String) {
      final parsed = double.tryParse(raw);
      if (parsed != null) {
        return TextStyle(fontFamily: kFontFamily, fontSize: parsed);
      }
    }
  }
  if (attr.key == 'customFontWeight') {
    final raw = attr.value;
    if (raw is String) {
      return TextStyle(
        fontFamily: kFontFamily,
        fontWeight: fontWeightFromLabel(raw),
      );
    }
  }
  if (attr.key == 'background') {
    return const TextStyle(fontFamily: kFontFamily, letterSpacing: 0.2);
  }
  if (attr.key == 'strikeThrough') {
    return const TextStyle(
      fontFamily: kFontFamily,
      decoration: TextDecoration.lineThrough,
      decorationThickness: 2,
    );
  }
  if (attr.key == 'checked') {
    return const TextStyle(
      fontFamily: kFontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: kListLineHeight,
      decoration: TextDecoration.lineThrough,
      decorationThickness: 2,
    );
  }
  return const TextStyle(fontFamily: kFontFamily);
}

// ─── Color helpers ──────────────────────────────────────────────────
String colorToHex(Color color) =>
    '#${color.value.toRadixString(16).substring(2).toUpperCase()}';

Color? colorFromHex(String? hex) {
  if (hex == null) return null;
  var s = hex.trim().replaceFirst('#', '');
  if (s.length == 3) s = s.split('').map((c) => '$c$c').join();
  if (s.length != 6) return null;
  final parsed = int.tryParse(s, radix: 16);
  if (parsed == null) return null;
  return Color(0xFF000000 | parsed);
}

// ─── Image state ────────────────────────────────────────────────────
// Everything is keyed by a unique image id (stored inside the embed), NOT
// by the position in the note. Positions change every time you type or
// move something, which used to make one image borrow another image's
// size and caused the "ghost" duplicates.
class _ImageStateStore extends ChangeNotifier {
  String? selectedId;
  final Map<String, double> widthFractions = {};
  final Map<String, double> scales = {};
  final Map<String, double> rotations = {};
  final Map<String, double> alignments = {}; // -1 left, 0 center, 1 right

  void select(String? id) {
    if (selectedId == id) return;
    selectedId = id;
    notifyListeners();
  }

  // Loads saved values from the note without triggering a rebuild.
  // Only fills in values that are not already known.
  void seed(String id, {double? w, double? s, double? r, double? a}) {
    if (w != null) widthFractions.putIfAbsent(id, () => w);
    if (s != null) scales.putIfAbsent(id, () => s);
    if (r != null) rotations.putIfAbsent(id, () => r);
    if (a != null) alignments.putIfAbsent(id, () => a);
  }

  void setWidth(String id, double fraction) {
    widthFractions[id] = fraction;
    notifyListeners();
  }

  void setScale(String id, double scale) {
    scales[id] = scale;
    notifyListeners();
  }

  void setRotation(String id, double degrees) {
    rotations[id] = degrees % 360;
    notifyListeners();
  }

  void setAlign(String id, double value) {
    alignments[id] = value.clamp(-1.0, 1.0);
    notifyListeners();
  }

  // Forget one image completely (used after it is deleted).
  void forget(String id) {
    if (selectedId == id) selectedId = null;
    widthFractions.remove(id);
    scales.remove(id);
    rotations.remove(id);
    alignments.remove(id);
    notifyListeners();
  }

  // Forget everything. The builder re-reads the saved values from the
  // note the next time each image is drawn.
  void reset() {
    selectedId = null;
    widthFractions.clear();
    scales.clear();
    rotations.clear();
    alignments.clear();
  }

  // Asks every image to redraw (used after undo and redo).
  void refresh() => notifyListeners();
}

// ─── Quill embed builder ────────────────────────────────────────────
class NoteImageEmbedBuilder extends quill.EmbedBuilder {
  NoteImageEmbedBuilder({
    required this.store,
    required this.onDelete,
    required this.onCommit,
    required this.onMove,
  });

  final _ImageStateStore store;
  final void Function(String id) onDelete;
  // Called when a resize / rotate / drag ends, so it can be saved
  final void Function(String id, String url, bool isLocal) onCommit;
  // Called when the image is dragged up or down by [steps] lines
  final void Function(String id, String url, bool isLocal, int steps) onMove;

  @override
  String get key => 'noteImage';

  @override
  bool get expanded => false;

  @override
  Widget build(BuildContext context, quill.EmbedContext embedContext) {
    final node = embedContext.node;
    Map<String, dynamic> json = {};
    try {
      json = jsonDecode(node.value.data as String) as Map<String, dynamic>;
    } catch (_) {}
    final url = json['url'] as String? ?? '';
    final isLocalFile = json['source'] == 'file';
    // Old notes saved before ids existed fall back to the url as the id
    final id = (json['id'] as String?) ?? 'u:$url';

    // Restore the size, rotation and position that were saved
    store.seed(
      id,
      w: (json['w'] as num?)?.toDouble(),
      s: (json['s'] as num?)?.toDouble(),
      r: (json['r'] as num?)?.toDouble(),
      a: (json['a'] as num?)?.toDouble(),
    );

    return _NoteImage(
      url: url,
      isLocalFile: isLocalFile,
      id: id,
      store: store,
      onDelete: () => onDelete(id),
      onCommit: () => onCommit(id, url, isLocalFile),
      onMove: (steps) => onMove(id, url, isLocalFile, steps),
    );
  }
}

// ─── Image widget ───────────────────────────────────────────────────
class _NoteImage extends StatefulWidget {
  const _NoteImage({
    required this.url,
    required this.id,
    required this.store,
    required this.onDelete,
    required this.onCommit,
    required this.onMove,
    this.isLocalFile = false,
  });

  final String url;
  final bool isLocalFile;
  final String id;
  final _ImageStateStore store;
  final VoidCallback onDelete;
  final VoidCallback onCommit;
  final void Function(int steps) onMove;

  @override
  State<_NoteImage> createState() => _NoteImageState();
}

class _NoteImageState extends State<_NoteImage> {
  // How many pixels of vertical drag equal one line of movement
  static const double _lineStep = 30;

  ImageStream? _stream;
  ImageStreamListener? _listener;
  double? _naturalAspect;
  int _pointers = 0;
  double _baseScale = 1;
  double _dragDy = 0;
  bool _changed = false;
  bool _dragging = false;

  _ImageStateStore get store => widget.store;
  String get id => widget.id;

  @override
  void initState() {
    super.initState();
    _resolveNaturalAspect();
  }

  void _resolveNaturalAspect() {
    final ImageProvider provider = widget.isLocalFile
        ? FileImage(File(widget.url))
        : NetworkImage(widget.url);
    _stream = provider.resolve(const ImageConfiguration());
    _listener = ImageStreamListener((info, _) {
      if (!mounted || info.image.width == 0 || info.image.height == 0) return;
      setState(() => _naturalAspect = info.image.width / info.image.height);
    }, onError: (_, __) {});
    _stream!.addListener(_listener!);
  }

  @override
  void dispose() {
    if (_listener != null) _stream?.removeListener(_listener!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final selected = store.selectedId == id;
        final fraction = (store.widthFractions[id] ?? 0.9).clamp(0.3, 1.0);
        final scale = (store.scales[id] ?? 1.0).clamp(0.4, 4.0);
        final rotation = store.rotations[id] ?? 0.0;
        final align = store.alignments[id] ?? 0.0; // 0 = centered by default
        final aspect = _naturalAspect ?? 4 / 3;

        return LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            final imgW = maxW * fraction * scale;
            final imgH = imgW / aspect;

            final rad = rotation * math.pi / 180;
            final cosA = math.cos(rad).abs();
            final sinA = math.sin(rad).abs();
            final boxW = imgW * cosA + imgH * sinA;
            final boxH = imgW * sinA + imgH * cosA;

            return AnimatedAlign(
              // No animation while the finger is down, a smooth glide
              // into place when it lets go (the snap).
              duration: _dragging
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment(align, 0),
              child: Transform.translate(
                offset: Offset(0, _dragDy),
                child: Listener(
                  onPointerDown: (_) => _pointers++,
                  onPointerUp: (_) => _pointers = math.max(0, _pointers - 1),
                  onPointerCancel: (_) =>
                      _pointers = math.max(0, _pointers - 1),
                  child: GestureDetector(
                    onTap: () => store.select(selected ? null : id),
                    onLongPress: widget.onDelete,
                    onDoubleTap: () {
                      store.setScale(id, 1);
                      store.setRotation(id, 0);
                      store.setAlign(id, 0);
                      widget.onCommit();
                    },
                    onScaleStart: (_) {
                      _baseScale = store.scales[id] ?? 1.0;
                      _dragDy = 0;
                      _changed = false;
                      _dragging = true;
                    },
                    onScaleUpdate: (d) {
                      if (_pointers >= 2) {
                        // Two fingers: pinch to resize
                        _changed = true;
                        store.setScale(
                          id,
                          (_baseScale * d.scale).clamp(0.4, 4.0),
                        );
                      } else if (selected) {
                        // One finger on a selected image: drag it
                        _changed = true;
                        final room = maxW - boxW;
                        if (room > 1) {
                          final current = store.alignments[id] ?? 0.0;
                          store.setAlign(
                            id,
                            current + d.focalPointDelta.dx / (room / 2),
                          );
                        }
                        setState(() => _dragDy += d.focalPointDelta.dy);
                      }
                    },
                    onScaleEnd: (_) {
                      _dragging = false;
                      final steps = (_dragDy / _lineStep).round();
                      if (_dragDy != 0) setState(() => _dragDy = 0);

                      // Snap to the nearest left / center / right spot
                      if (_changed) {
                        final room = maxW - boxW;
                        final current = store.alignments[id] ?? 0.0;
                        store.setAlign(
                          id,
                          room > 1 ? snapImageAlignment(current) : 0.0,
                        );
                      }

                      if (steps != 0) {
                        widget.onMove(steps);
                      } else if (_changed) {
                        widget.onCommit();
                      }
                      _changed = false;
                    },
                    child: SizedBox(
                      width: boxW,
                      height: boxH,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Center(
                            child: Transform.rotate(
                              angle: rad,
                              child: Container(
                                width: imgW,
                                height: imgH,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: selected
                                      ? Border.all(
                                          color: kImageSelectionBlue,
                                          width: 2.5,
                                        )
                                      : null,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: widget.isLocalFile
                                      ? Image.file(
                                          File(widget.url),
                                          fit: BoxFit.contain,
                                          width: double.infinity,
                                          height: double.infinity,
                                        )
                                      : Image.network(
                                          widget.url,
                                          fit: BoxFit.contain,
                                          width: double.infinity,
                                          height: double.infinity,
                                        ),
                                ),
                              ),
                            ),
                          ),
                          if (selected) ...[
                            _cornerHandle(left: true, top: true, maxW: maxW),
                            _cornerHandle(left: false, top: true, maxW: maxW),
                            _cornerHandle(left: true, top: false, maxW: maxW),
                            _cornerHandle(left: false, top: false, maxW: maxW),
                            _rotateHandle(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _cornerHandle({
    required bool left,
    required bool top,
    required double maxW,
  }) {
    double dragStart = store.widthFractions[id] ?? 0.9;
    return Positioned(
      left: left ? -10 : null,
      right: left ? null : -10,
      top: top ? -10 : null,
      bottom: top ? null : -10,
      child: GestureDetector(
        onPanStart: (_) => dragStart = store.widthFractions[id] ?? 0.9,
        onPanUpdate: (d) {
          final dir = left ? -1.0 : 1.0;
          store.setWidth(
            id,
            (dragStart + dir * d.delta.dx / maxW).clamp(0.3, 1.0),
          );
          dragStart = store.widthFractions[id] ?? dragStart;
        },
        onPanEnd: (_) => widget.onCommit(),
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: kImageSelectionBlue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rotateHandle() {
    return Positioned(
      top: -48,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onPanUpdate: (d) {
            final renderObject = context.findRenderObject();
            if (renderObject is! RenderBox) return;
            final center = renderObject.size.center(Offset.zero);
            final local = renderObject.globalToLocal(d.globalPosition);
            final deg =
                math.atan2(local.dy - center.dy, local.dx - center.dx) *
                180 /
                math.pi;
            store.setRotation(id, (deg + 360) % 360);
          },
          onPanEnd: (_) => widget.onCommit(),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6),
              ],
              border: Border.all(color: kImageSelectionBlue, width: 2),
            ),
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedRotateClockwise,
              size: 20,
              color: kImageSelectionBlue,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Main screen ────────────────────────────────────────────────────
class NoteDetailScreen extends ConsumerStatefulWidget {
  final Note? note;

  const NoteDetailScreen({super.key, this.note});

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen> {
  static const int kMaxPinnedNotes = 3;

  late quill.QuillController _controller;
  late TextEditingController _titleController;
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final _ImageStateStore _imageStore = _ImageStateStore();

  // Stable id for this editing session so repeated auto-saves upsert the
  // same note instead of creating duplicates.
  late final String _noteId;
  Timer? _autoSaveTimer;

  bool _isEdited = false;
  late bool _isLocked;
  late bool _isBookmarked;
  late bool _isPinned;

  bool _isToolbarExpanded = false;
  final PageController _toolbarPageController = PageController();
  int _toolbarPage = 0;
  static const int _toolbarPageCount = 2;
  double _dragAccumulator = 0;

  late final List<String> _tags;

  String _weightLabel = 'Medium';
  String _fontSizeLabel = '16';
  String _highlightColorHex = colorToHex(kDefaultHighlight);

  @override
  void initState() {
    super.initState();
    _noteId =
        widget.note?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _tags = List<String>.from(widget.note?.tags ?? const []);
    if (_tags.isEmpty && widget.note?.category != null)
      _tags.add(widget.note!.category!);
    _isLocked = widget.note?.isLocked ?? false;
    _isBookmarked = widget.note?.isBookmarked ?? false;
    _isPinned = widget.note?.isPinned ?? false;

    quill.Document doc;
    try {
      if (widget.note?.deltaJson != null &&
          widget.note!.deltaJson!.isNotEmpty) {
        doc = quill.Document.fromJson(
          jsonDecode(widget.note!.deltaJson!) as List,
        );
      } else {
        doc = quill.Document()..insert(0, widget.note?.content ?? '');
      }
    } catch (_) {
      doc = quill.Document()..insert(0, widget.note?.content ?? '');
    }

    _controller = quill.QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );

    _controller.addListener(() {
      if (!mounted) return;
      final sid = _imageStore.selectedId;
      if (sid != null) {
        final so = _offsetOfImage(sid);
        final sel = _controller.selection;
        if (so == null ||
            !sel.isValid ||
            (sel.start != so && sel.start != so + 1)) {
          _imageStore.select(null);
        }
      }
      if (!_isEdited) setState(() => _isEdited = true);
      _scheduleAutoSave();
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _controller.dispose();
    _titleController.dispose();
    _editorFocusNode.dispose();
    _scrollController.dispose();
    _toolbarPageController.dispose();
    _imageStore.dispose();
    super.dispose();
  }

  void _expandToolbar() {
    _editorFocusNode.canRequestFocus = false;
    _editorFocusNode.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    setState(() => _isToolbarExpanded = true);
  }

  void _collapseToolbar() {
    _editorFocusNode.canRequestFocus = true;
    setState(() => _isToolbarExpanded = false);
  }

  bool _isActive(quill.Attribute attr) =>
      _controller.getSelectionStyle().attributes[attr.key] == attr;
  bool _hasBackground() =>
      _controller.getSelectionStyle().attributes['background'] != null;

  String? _currentColorHex() {
    final v = _controller.getSelectionStyle().attributes['color']?.value;
    return v is String ? v.toUpperCase() : null;
  }

  Color _currentHighlightColor() {
    final v = _controller.getSelectionStyle().attributes['background']?.value;
    if (v is String) {
      final parsed = colorFromHex(v);
      if (parsed != null) return parsed;
    }
    return colorFromHex(_highlightColorHex) ?? kDefaultHighlight;
  }

  Color? _currentTextColor() {
    final hex = _currentColorHex();
    if (hex == null) return null;
    return colorFromHex(hex);
  }

  void _apply(quill.Attribute attr, {bool toggle = true}) {
    final sel = _controller.selection;
    if (!sel.isValid) return;
    final active = toggle && _isActive(attr);
    final toApply = active ? quill.Attribute.clone(attr, null) : attr;
    if (!sel.isCollapsed) {
      int start = sel.start;
      int end = sel.end;
      if (attr.scope == quill.AttributeScope.inline) {
        final plain = _controller.document.toPlainText();
        if (end > start && end <= plain.length && plain[end - 1] == '\n') end--;
      }
      if (end > start) _controller.formatText(start, end - start, toApply);
    } else {
      _controller.formatSelection(toApply);
    }
  }

  void _toggle(quill.Attribute attr) => _apply(attr);

  // ─── Undo / redo ──────────────────────────────────────────────────
  void _undo() {
    if (!_controller.hasUndo) return;
    _controller.undo();
    _afterHistoryChange();
  }

  void _redo() {
    if (!_controller.hasRedo) return;
    _controller.redo();
    _afterHistoryChange();
  }

  // Undo or redo can change an image's saved size under the cache. Clear
  // it so every image reloads its saved size, rotation and position from
  // the note, then redraw them.
  void _afterHistoryChange() {
    _imageStore.reset();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _imageStore.refresh();
    });
    if (!_isEdited) setState(() => _isEdited = true);
    _scheduleAutoSave();
  }

  // Round, grayish button. Light gray in light mode, dark gray in dark mode.
  Widget _historyButton({
    required List<List<dynamic>> icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final c = context.colors;
    final bg = context.isDarkMode
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFE8E8EA);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.35,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: HugeIcon(icon: icon, color: c.textPrimary, size: 20),
        ),
      ),
    );
  }

  void _showTopToast(String message, {List<List<dynamic>>? icon}) {
    final overlayState = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _TopToast(
        message: message,
        icon: icon,
        onDismissed: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    overlayState.insert(entry);
  }

  void _toggleLock() {
    setState(() => _isLocked = !_isLocked);
    _persistNote(); // auto-save immediately
    _showTopToast(
      _isLocked ? 'Note locked' : 'Note unlocked',
      icon: HugeIcons.strokeRoundedLocked,
    );
  }

  void _toggleBookmark() {
    setState(() => _isBookmarked = !_isBookmarked);
    _persistNote(); // auto-save immediately
    _showTopToast(
      _isBookmarked ? 'Added to bookmarks' : 'Removed from bookmarks',
      icon: _isBookmarked
          ? HugeIcons.strokeRoundedBookmark02
          : HugeIcons.strokeRoundedBookmark01,
    );
  }

  void _togglePin() {
    final currentPinCount = ref.read(pinnedNotesProvider).length;

    if (!_isPinned && currentPinCount >= kMaxPinnedNotes) {
      _showTopToast(
        'You can only pin up to $kMaxPinnedNotes notes',
        icon: HugeIcons.strokeRoundedPin,
      );
      return;
    }
    setState(() => _isPinned = !_isPinned);
    _persistNote(); // auto-save immediately
    _showTopToast(
      _isPinned ? 'Pinned successfully' : 'Unpinned',
      icon: HugeIcons.strokeRoundedPin,
    );
  }

  /// True if the note has a title, text, or any embedded block (image).
  bool _hasContent() {
    if (_titleController.text.trim().isNotEmpty) return true;
    if (_controller.document.toPlainText().trim().isNotEmpty) return true;
    try {
      final ops = _controller.document.toDelta().toJson();
      for (final op in ops) {
        if (op is Map && op['insert'] is Map) return true; // embed (image)
      }
    } catch (_) {}
    return false;
  }

  /// Builds a [Note] from the current editor state using the stable id.
  Note _buildNote() {
    final String? firstImageUrl = _extractLeadingImageUrl();
    return Note(
      id: _noteId,
      title: _titleController.text.trim().isEmpty
          ? 'Untitled'
          : _titleController.text.trim(),
      content: _controller.document.toPlainText(),
      deltaJson: jsonEncode(_controller.document.toDelta().toJson()),
      tags: _tags,
      category: _tags.isNotEmpty ? _tags.first : widget.note?.category,
      date: widget.note?.date ?? DateTime.now(),
      color: widget.note?.color ?? const Color(0xFF2D2D2D),
      imageUrl: firstImageUrl,
      isPinned: _isPinned,
      isLocked: _isLocked,
      isBookmarked: _isBookmarked,
      isChecklist: widget.note?.isChecklist ?? false,
      checklistItems: widget.note?.checklistItems,
    );
  }

  /// Persists the note immediately and clears the "Edited" badge.
  Note _persistNote() {
    final note = _buildNote();
    ref.read(notesProvider.notifier).saveNote(note);
    if (mounted && _isEdited) {
      setState(() => _isEdited = false);
    }
    return note;
  }

  /// Debounced auto-save: runs 1.5s after the last change.
  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (_hasContent()) _persistNote();
    });
  }

  // Shared list style so text, numbers, bullets and checkboxes all match.
  TextStyle _listTextStyle(Color color) => TextStyle(
    fontFamily: kFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: color,
    height: kListLineHeight,
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final listStyle = _listTextStyle(c.textPrimary);
    return Theme(
      data: interThemeOf(context),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          // System / hardware back button: run the same save logic as the
          // in-app back arrow.
          _onBack();
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: c.scaffold,
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          _headerIcon(
                            icon: HugeIcons.strokeRoundedArrowLeft02,
                            onTap: _onBack,
                          ),
                          const SizedBox(width: 6),
                          // Undo and redo stay on the LEFT, with a gap
                          // between the two round buttons.
                          ListenableBuilder(
                            listenable: _controller,
                            builder: (context, _) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _historyButton(
                                  icon: HugeIcons.strokeRoundedUndo02,
                                  enabled: _controller.hasUndo,
                                  onTap: _undo,
                                ),
                                const SizedBox(width: 10),
                                _historyButton(
                                  icon: HugeIcons.strokeRoundedRedo02,
                                  enabled: _controller.hasRedo,
                                  onTap: _redo,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Tags on the RIGHT. Long tag names are cut
                          // with "..." so the chip never overflows.
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: _buildTagDropdown(),
                            ),
                          ),
                          const SizedBox(width: 2),
                          if (_isLocked)
                            _headerIcon(
                              icon: HugeIcons.strokeRoundedLocked,
                              onTap: _toggleLock,
                            ),
                          _buildMoreMenuButton(),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: EdgeInsets.only(
                          left: 24,
                          right: 24,
                          bottom: 160 + bottomInset,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            TextField(
                              controller: _titleController,
                              cursorColor: c.textPrimary,
                              style: TextStyle(
                                fontFamily: kFontFamily,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: c.textPrimary,
                                letterSpacing: -0.5,
                                height: 1.28,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Title',
                                hintStyle: TextStyle(
                                  fontFamily: kFontFamily,
                                  color: kHintText,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isCollapsed: true,
                              ),
                              maxLines: null,
                              onChanged: (_) {
                                if (!_isEdited)
                                  setState(() => _isEdited = true);
                                _scheduleAutoSave();
                              },
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const HugeIcon(
                                  icon: HugeIcons.strokeRoundedCalendar01,
                                  size: 12,
                                  color: kTextSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormat(
                                    'EEEE, MMMM d, yyyy',
                                  ).format(widget.note?.date ?? DateTime.now()),
                                  style: const TextStyle(
                                    fontFamily: kFontFamily,
                                    fontSize: 12,
                                    color: kTextSecondary,
                                  ),
                                ),
                                if (_isEdited) ...[
                                  const SizedBox(width: 12),
                                  const Row(
                                    children: [
                                      HugeIcon(
                                        icon: HugeIcons.strokeRoundedEdit02,
                                        size: 12,
                                        color: kTextSecondary,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Edited',
                                        style: TextStyle(
                                          fontFamily: kFontFamily,
                                          fontSize: 12,
                                          color: kTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 24),
                            Theme(
                              data: Theme.of(context).copyWith(
                                primaryColor: c.textPrimary,
                                colorScheme: Theme.of(
                                  context,
                                ).colorScheme.copyWith(primary: c.textPrimary),
                                checkboxTheme: CheckboxThemeData(
                                  shape: const CircleBorder(),
                                  fillColor: WidgetStateProperty.resolveWith((
                                    states,
                                  ) {
                                    if (states.contains(WidgetState.selected))
                                      return c.textPrimary;
                                    return c.surface;
                                  }),
                                  checkColor: WidgetStatePropertyAll(c.surface),
                                  side: BorderSide(
                                    color: c.textPrimary,
                                    width: 2,
                                  ),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.padded,
                                  visualDensity: const VisualDensity(
                                    horizontal: 2,
                                    vertical: 2,
                                  ),
                                ),
                                textTheme: Theme.of(
                                  context,
                                ).textTheme.apply(fontFamily: kFontFamily),
                              ),
                              child: DefaultTextStyle(
                                style: TextStyle(
                                  fontFamily: kFontFamily,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: c.textPrimary,
                                  height: kParagraphLineHeight,
                                ),
                                child: quill.QuillEditor(
                                  controller: _controller,
                                  focusNode: _editorFocusNode,
                                  scrollController: _scrollController,
                                  config: quill.QuillEditorConfig(
                                    scrollable: false,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    autoFocus: false,
                                    expands: false,
                                    placeholder: 'Start typing...',
                                    showCursor: true,
                                    customStyleBuilder: customStyleBuilder,
                                    contextMenuBuilder: _buildSelectionToolbar,
                                    embedBuilders: [
                                      NoteImageEmbedBuilder(
                                        store: _imageStore,
                                        onDelete: _confirmDeleteImage,
                                        onCommit: _commitImageState,
                                        onMove: _moveImage,
                                      ),
                                    ],
                                    customLeadingBlockBuilder:
                                        (
                                          quill.Node node,
                                          quill.LeadingConfig config,
                                        ) {
                                          final listAttr = config
                                              .attrs[quill.Attribute.list.key];
                                          final isCheckbox =
                                              listAttr ==
                                                  quill.Attribute.checked ||
                                              listAttr ==
                                                  quill.Attribute.unchecked;

                                          // Return null so bullets and numbers keep their default look
                                          if (!isCheckbox) return null;

                                          final isChecked =
                                              listAttr ==
                                              quill.Attribute.checked;

                                          return GestureDetector(
                                            onTap: config.enabled == true
                                                ? () => config.onCheckboxTap(
                                                    !isChecked,
                                                  )
                                                : null,
                                            behavior: HitTestBehavior.opaque,
                                            child: Container(
                                              width: kCheckboxSize,
                                              height: kCheckboxSize,
                                              margin: const EdgeInsets.only(
                                                right: 10,
                                              ),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isChecked
                                                    ? c.textPrimary
                                                    : c.surface,
                                                border: Border.all(
                                                  color: c.textPrimary,
                                                  width: 2,
                                                ),
                                              ),
                                              child: isChecked
                                                  ? Icon(
                                                      Icons.check,
                                                      size:
                                                          kCheckboxSize * 0.65,
                                                      color: c.surface,
                                                    )
                                                  : null,
                                            ),
                                          );
                                        },

                                    // ─── SEPARATE LINE HEIGHTS ───
                                    customStyles: quill.DefaultStyles(
                                      // Normal notes
                                      paragraph: quill.DefaultTextBlockStyle(
                                        TextStyle(
                                          fontFamily: kFontFamily,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: c.textPrimary,
                                          height: kParagraphLineHeight,
                                        ),
                                        const quill.HorizontalSpacing(0, 0),
                                        const quill.VerticalSpacing(0, 0),
                                        const quill.VerticalSpacing(0, 0),
                                        null,
                                      ),
                                      // List text (bullets, numbers, checkboxes)
                                      lists: quill.DefaultListBlockStyle(
                                        listStyle,
                                        const quill.HorizontalSpacing(0, 0),
                                        const quill.VerticalSpacing(
                                          kListItemSpacing,
                                          kListItemSpacing,
                                        ), // between blocks
                                        const quill.VerticalSpacing(
                                          kListItemSpacing,
                                          kListItemSpacing,
                                        ), // between items in a block
                                        null,
                                        null,
                                      ),
                                      // The numbers and bullet dots themselves.
                                      // Must match the list height above so
                                      // they line up with the list text.
                                      leading: quill.DefaultTextBlockStyle(
                                        listStyle,
                                        const quill.HorizontalSpacing(0, 0),
                                        const quill.VerticalSpacing(0, 0),
                                        const quill.VerticalSpacing(0, 0),
                                        null,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  left: _isToolbarExpanded ? 8 : 16,
                  right: _isToolbarExpanded ? 8 : 16,
                  bottom: bottomInset + 16,
                  child: _buildToolbar(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerIcon({
    required List<List<dynamic>> icon,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: HugeIcon(icon: icon, color: context.colors.textPrimary, size: 24),
    ),
  );

  Widget _buildMoreMenuButton() {
    final c = context.colors;
    return PopupMenuButton<String>(
      color: c.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      offset: const Offset(0, 46),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) {
        switch (value) {
          case 'save':
            _saveNote();
            break;
          case 'bookmark':
            _toggleBookmark();
            break;
          case 'lock':
            _toggleLock();
            break;
          case 'pin':
            _togglePin();
            break;
          case 'delete':
            _confirmDeleteNote();
            break;
        }
      },
      itemBuilder: (context) => [
        _moreMenuItem(
          value: 'save',
          icon: HugeIcons.strokeRoundedCheckmarkCircle01,
          label: 'Save note',
        ),
        _moreMenuItem(
          value: 'bookmark',
          icon: _isBookmarked
              ? HugeIcons.strokeRoundedBookmark02
              : HugeIcons.strokeRoundedBookmark01,
          label: _isBookmarked ? 'Remove bookmark' : 'Add bookmark',
        ),
        _moreMenuItem(
          value: 'lock',
          icon: HugeIcons.strokeRoundedLocked,
          label: _isLocked ? 'Unlock note' : 'Lock note',
        ),
        _moreMenuItem(
          value: 'pin',
          icon: HugeIcons.strokeRoundedPin,
          label: _isPinned ? 'Unpin note' : 'Pin note',
        ),
        const PopupMenuDivider(height: 1),
        _moreMenuItem(
          value: 'delete',
          icon: HugeIcons.strokeRoundedDelete02,
          label: 'Delete note',
          color: Colors.redAccent,
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedCircleEllipsis,
          color: c.textPrimary,
          size: 24,
        ),
      ),
    );
  }

  PopupMenuItem<String> _moreMenuItem({
    required String value,
    required List<List<dynamic>> icon,
    required String label,
    Color? color,
  }) {
    final itemColor = color ?? context.colors.textPrimary;
    return PopupMenuItem<String>(
      value: value,
      height: 44,
      child: Row(
        children: [
          HugeIcon(icon: icon, size: 18, color: itemColor),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontFamily: kFontFamily,
              fontSize: 14,
              color: itemColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagDropdown() {
    final c = context.colors;
    final hasTag = _tags.isNotEmpty;
    final label = hasTag ? _tags.first : 'Add tag';

    // Same solid badge look as the home screen. "Add tag" (no tag
    // picked yet) uses the same neutral gray as the "All" chip.
    final chipColor = hasTag ? getTagColor(label) : const Color(0xFF8E8E93);

    final allTags = <String>{...kGlobalTags, ..._tags}.toList();

    return PopupMenuButton<String>(
      color: c.surface,
      surfaceTintColor: Colors.transparent,
      offset: const Offset(0, 42),
      constraints: const BoxConstraints(
        minWidth: 180,
        maxWidth: 240,
        maxHeight: 320,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) {
        // Local edit only, persisted on back / save.
        setState(() {
          _tags
            ..clear()
            ..add(value);
          _isEdited = true;
        });
      },
      itemBuilder: (context) {
        return allTags.map((t) {
          final isPrimary = _tags.isNotEmpty && t == _tags.first;
          final color = getTagColor(t);
          return PopupMenuItem<String>(
            value: t,
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    t,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 13,
                      color: c.textPrimary,
                    ),
                  ),
                ),
                if (isPrimary) ...[
                  const Spacer(),
                  Icon(Icons.check_circle, size: 14, color: c.textPrimary),
                ],
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: chipColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: chipColor.withOpacity(0.28),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedTag01,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                // Long tag names are shortened with "..."
                shortTag(label),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: kFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowDown01,
              size: 14,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  /// Back button: auto-saves if there is content, otherwise just closes.
  /// Called both by the in-app back arrow and the system back gesture.
  void _onBack() {
    _autoSaveTimer?.cancel();

    if (_hasContent()) {
      final note = _persistNote();
      Navigator.pop(context, note);
    } else {
      Navigator.pop(context, widget.note);
    }
  }

  String? _extractLeadingImageUrl() {
    try {
      final ops = _controller.document.toDelta().toJson();
      if (ops.isEmpty) return null;
      final insert = ops.first['insert'];
      if (insert is! Map) return null;

      final data = _decodeImageEmbed(insert);
      return data?['url'] as String?;
    } catch (e) {
      debugPrint('Error extracting image: $e');
      return null;
    }
  }

  /// Manual "Save note" menu action. Still works alongside auto-save.
  void _saveNote() {
    _autoSaveTimer?.cancel();

    // Don't create an empty brand-new note from the menu either.
    if (!_hasContent() && widget.note == null) {
      Navigator.pop(context);
      return;
    }

    final note = _persistNote();
    Navigator.pop(context, note);
  }

  void _confirmDeleteNote() {
    // If it's a brand new note that hasn't been saved yet, just pop.
    if (widget.note == null) {
      Navigator.pop(context);
      return;
    }

    final c = context.colors;
    showDialog(
      context: context,
      builder: (dialogCtx) => Theme(
        data: interThemeOf(dialogCtx),
        child: AlertDialog(
          backgroundColor: c.surface,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Delete note?',
            style: TextStyle(
              fontFamily: kFontFamily,
              color: c.textPrimary,
              fontSize: 17,
            ),
          ),
          content: const Text(
            'This note will be permanently removed.',
            style: TextStyle(
              fontFamily: kFontFamily,
              color: kTextSecondary,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: kFontFamily,
                  color: kTextSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                // ─── DELETE FROM HIVE VIA RIVERPOD ───
                ref.read(notesProvider.notifier).deleteNote(widget.note!.id);

                Navigator.pop(dialogCtx);
                Navigator.pop(context);
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontFamily: kFontFamily,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePickerSheet() {
    final c = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Theme(
        data: interThemeOf(sheetCtx),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Image',
                style: TextStyle(
                  fontFamily: kFontFamily,
                  color: c.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _sourceButton(
                      HugeIcons.strokeRoundedCamera01,
                      'Camera',
                      () => _pickImageFromSource(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _sourceButton(
                      HugeIcons.strokeRoundedImage01,
                      'Gallery',
                      () => _pickImageFromSource(ImageSource.gallery),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _sourceButton(
                      HugeIcons.strokeRoundedFolder01,
                      'Files',
                      _pickFileFromDevice,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sourceButton(
    List<List<dynamic>> icon,
    String label,
    VoidCallback onTap,
  ) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: c.fieldBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            HugeIcon(icon: icon, color: c.textPrimary, size: kIconSizeHuge),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: kFontFamily,
                color: c.textPrimary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _persistImage(String path) async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${dir.path}/note_images');
    if (!await imagesDir.exists()) await imagesDir.create(recursive: true);
    final ext = path.contains('.')
        ? path.substring(path.lastIndexOf('.'))
        : '.jpg';
    final newPath =
        '${imagesDir.path}/${DateTime.now().microsecondsSinceEpoch}$ext';
    await File(path).copy(newPath);
    return newPath;
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    Navigator.pop(context);
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: source, imageQuality: 85);
    if (xfile == null || !mounted) return;
    _insertImage(await _persistImage(xfile.path), isLocalFile: true);
  }

  Future<void> _pickFileFromDevice() async {
    Navigator.pop(context);
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path == null || !mounted) return;
    _insertImage(await _persistImage(path), isLocalFile: true);
  }

  int _embedInsertIndex() {
    final text = _controller.document.toPlainText();
    var i = _controller.selection.isValid
        ? _controller.selection.start
        : text.length - 1;
    i = i.clamp(0, text.length - 1);
    while (i > 0 && text[i - 1] != '\n') i--;
    return i;
  }

  // ─── Image helpers ────────────────────────────────────────────────
  // Reads the JSON stored inside an image embed.
  Map<String, dynamic>? _decodeImageEmbed(Map insert) {
    try {
      dynamic data = insert['noteImage'];
      // Some versions wrap custom embeds inside a 'custom' key
      if (data == null && insert['custom'] != null) {
        final inner = jsonDecode(insert['custom'] as String);
        data = inner['noteImage'];
      }
      if (data == null) return null;
      final decoded = data is String ? jsonDecode(data) : data;
      if (decoded is! Map) return null;
      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }

  // Finds where every image currently sits in the note, by image id.
  Map<String, List<int>> _imageOffsets() {
    final out = <String, List<int>>{};
    try {
      final ops = _controller.document.toDelta().toJson();
      var pos = 0;
      for (final op in ops) {
        final ins = (op as Map)['insert'];
        if (ins is String) {
          pos += ins.length;
        } else if (ins is Map) {
          final data = _decodeImageEmbed(ins);
          if (data != null) {
            final id = (data['id'] as String?) ?? 'u:${data['url']}';
            (out[id] ??= <int>[]).add(pos);
          }
          pos += 1;
        }
      }
    } catch (_) {}
    return out;
  }

  int? _offsetOfImage(String id) {
    final list = _imageOffsets()[id];
    if (list == null || list.isEmpty) return null;
    return list.first;
  }

  // Removes the image at [off] together with its own line break, when that
  // is safe (never the final line break of the note).
  void _removeImageAt(int off) {
    final text = _controller.document.toPlainText();
    final len = (off + 2 < text.length && text[off + 1] == '\n') ? 2 : 1;
    _controller.replaceText(off, len, '', null);
  }

  // Safety net: if the same image id ever shows up twice, keep the first
  // and remove the extra copies.
  void _dedupeImages() {
    final map = _imageOffsets();
    final extras = <int>[];
    map.forEach((id, offs) {
      if (!id.startsWith('u:') && offs.length > 1) extras.addAll(offs.skip(1));
    });
    if (extras.isEmpty) return;
    extras.sort((a, b) => b.compareTo(a));
    for (final off in extras) {
      _removeImageAt(off);
    }
  }

  void _insertImage(String url, {bool isLocalFile = false}) {
    final index = _embedInsertIndex();
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final embed = quill.BlockEmbed.custom(
      quill.CustomBlockEmbed(
        'noteImage',
        jsonEncode({
          'id': id,
          'url': url,
          'source': isLocalFile ? 'file' : 'network',
        }),
      ),
    );
    _controller.document.insert(index, embed);
    _controller.updateSelection(
      TextSelection.collapsed(offset: index + 1),
      quill.ChangeSource.local,
    );
    if (!_isEdited) setState(() => _isEdited = true);
    _scheduleAutoSave();
  }

  // Builds the embed JSON for an image, including its saved look
  String _imageJson(String id, String url, bool isLocal) {
    return jsonEncode({
      'id': id,
      'url': url,
      'source': isLocal ? 'file' : 'network',
      'w': _imageStore.widthFractions[id],
      's': _imageStore.scales[id],
      'r': _imageStore.rotations[id],
      'a': _imageStore.alignments[id],
    });
  }

  // Saves the current size, rotation and position into the note
  void _commitImageState(String id, String url, bool isLocal) {
    final off = _offsetOfImage(id);
    if (off == null) return;
    final embed = quill.BlockEmbed.custom(
      quill.CustomBlockEmbed('noteImage', _imageJson(id, url, isLocal)),
    );
    _controller.replaceText(
      off,
      1,
      embed,
      TextSelection.collapsed(offset: off + 1),
    );
    _dedupeImages();
    _scheduleAutoSave();
  }

  List<int> _lineStarts(String text) {
    final starts = <int>[0];
    for (var i = 0; i < text.length - 1; i++) {
      if (text[i] == '\n') starts.add(i + 1);
    }
    return starts;
  }

  // Moves an image up (negative) or down (positive) by [steps] lines.
  // The copy is inserted FIRST and the original removed second, so the
  // image can never be lost, and both steps go through the controller so
  // the editor always stays in sync.
  void _moveImage(String id, String url, bool isLocal, int steps) {
    final origOff = _offsetOfImage(id);
    if (origOff == null) return;

    final json = _imageJson(id, url, isLocal);
    final text = _controller.document.toPlainText();
    final starts = _lineStarts(text);

    var cur = 0;
    for (var i = 0; i < starts.length; i++) {
      if (starts[i] <= origOff) cur = i;
    }
    final target = (cur + steps).clamp(0, starts.length - 1);
    if (target == cur) {
      _commitImageState(id, url, isLocal);
      return;
    }

    final int insertAt;
    if (target < cur) {
      insertAt = starts[target];
    } else {
      insertAt = (target + 1 < starts.length)
          ? starts[target + 1]
          : text.length - 1;
    }

    // 1) Insert the image at its new spot
    _controller.replaceText(
      insertAt,
      0,
      quill.BlockEmbed.custom(quill.CustomBlockEmbed('noteImage', json)),
      null,
    );

    // 2) Remove the original (now one of two copies with the same id)
    final offs = _imageOffsets()[id] ?? <int>[];
    if (offs.length == 2) {
      // The copy inserted above comes first when moving up, second when
      // moving down, so the original is the other one.
      final oldOff = insertAt <= origOff ? offs[1] : offs[0];
      _removeImageAt(oldOff);
    }
    _dedupeImages();

    final newOff = _offsetOfImage(id);
    if (newOff != null) {
      _controller.updateSelection(
        TextSelection.collapsed(offset: newOff + 1),
        quill.ChangeSource.local,
      );
      _imageStore.select(id);
    }
    if (!_isEdited) setState(() => _isEdited = true);
    _scheduleAutoSave();
  }

  void _confirmDeleteImage(String id) {
    final c = context.colors;
    showDialog(
      context: context,
      builder: (dialogCtx) => Theme(
        data: interThemeOf(dialogCtx),
        child: AlertDialog(
          backgroundColor: c.surface,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Delete image?',
            style: TextStyle(
              fontFamily: kFontFamily,
              color: c.textPrimary,
              fontSize: 17,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: kFontFamily,
                  color: kTextSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                // Look the position up now, so it is always up to date
                final off = _offsetOfImage(id);
                if (off == null) return;
                _imageStore.forget(id);
                _removeImageAt(off);
                final maxIndex = math.max(0, _controller.document.length - 1);
                _controller.updateSelection(
                  TextSelection.collapsed(offset: off.clamp(0, maxIndex)),
                  quill.ChangeSource.local,
                );
                if (!_isEdited) setState(() => _isEdited = true);
                _scheduleAutoSave();
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontFamily: kFontFamily,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyContent() {
    Clipboard.setData(ClipboardData(text: _controller.document.toPlainText()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Note copied', style: TextStyle(fontFamily: kFontFamily)),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  EDITOR TOOLBARS: floating selection toolbar, collapsed pill and
  //  expanded panel. Everything from here down to _showWeightSheet is
  //  unchanged on purpose, so the toolbar colors stay exactly as before.
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildSelectionToolbar(
    BuildContext context,
    quill.QuillRawEditorState rawEditorState,
  ) {
    final anchors = rawEditorState.contextMenuAnchors;
    return TextFieldTapRegion(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomSingleChildLayout(
            delegate: TextSelectionToolbarLayoutDelegate(
              anchorAbove: anchors.primaryAnchor,
              anchorBelow: anchors.secondaryAnchor ?? anchors.primaryAnchor,
            ),
            child: _SelectionFormatToolbar(
              textColor: _currentTextColor(),
              highlightColor: _currentHighlightColor(),
              hasHighlight: _hasBackground(),
              isBold: _isActive(quill.Attribute.bold),
              isItalic: _isActive(quill.Attribute.italic),
              isUnderline: _isActive(quill.Attribute.underline),
              onSelectTextColor: (color) =>
                  setState(() => _applyTextColor(colorToHex(color))),
              onSelectHighlight: (color) =>
                  setState(() => _applyHighlight(colorToHex(color))),
              onToggleBold: () => setState(() => _toggle(quill.Attribute.bold)),
              onToggleItalic: () =>
                  setState(() => _toggle(quill.Attribute.italic)),
              onToggleUnderline: () =>
                  setState(() => _toggle(quill.Attribute.underline)),
              onLinkTap: _showLinkDialog,
            ),
          );
        },
      ),
    );
  }

  Widget _buildToolbar() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutBack,
      alignment: Alignment.bottomCenter,
      child: _isToolbarExpanded ? _buildExpandedPanel() : _buildCollapsedPill(),
    );
  }

  Widget _buildCollapsedPill() => Container(
    height: 58,
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    decoration: BoxDecoration(
      color: kTextPrimary,
      borderRadius: BorderRadius.circular(29),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.10),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: _formatPillItem(
            HugeIcons.strokeRoundedBold,
            isActive: _isActive(quill.Attribute.bold),
            onTap: () => setState(() => _toggle(quill.Attribute.bold)),
          ),
        ),
        Expanded(
          child: _formatPillItem(
            HugeIcons.strokeRoundedItalic,
            isActive: _isActive(quill.Attribute.italic),
            onTap: () => setState(() => _toggle(quill.Attribute.italic)),
          ),
        ),
        Expanded(
          child: _formatPillItem(
            HugeIcons.strokeRoundedUnderline,
            isActive: _isActive(quill.Attribute.underline),
            onTap: () => setState(() => _toggle(quill.Attribute.underline)),
          ),
        ),
        Expanded(
          child: _formatPillItem(
            HugeIcons.strokeRoundedAttachment,
            onTap: _showImagePickerSheet,
          ),
        ),
        Expanded(
          child: _formatPillItem(
            HugeIcons.strokeRoundedCopy01,
            onTap: _copyContent,
          ),
        ),
        Container(width: 1, height: 26, color: Colors.white.withOpacity(0.18)),
        Expanded(
          child: _formatPillItem(
            HugeIcons.strokeRoundedArrowUp01,
            onTap: _expandToolbar,
          ),
        ),
      ],
    ),
  );

  Widget _formatPillItem(
    List<List<dynamic>> icon, {
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        height: 50,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        alignment: Alignment.center,
        child: HugeIcon(
          icon: icon,
          size: 22,
          color: isActive ? kTextPrimary : Colors.white,
        ),
      ),
    );
  }

  Widget _buildExpandedPanel() => Container(
    decoration: BoxDecoration(
      color: kTextPrimary,
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.10),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDragHandle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 12, 12),
          child: Row(
            children: [
              Text(
                _toolbarPage == 0 ? 'Text format' : 'More tools',
                style: const TextStyle(
                  fontFamily: kFontFamily,
                  color: kPanelBg,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _collapseToolbar,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: kAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowDown01,
                    color: kTextSecondary,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 320,
          child: PageView(
            controller: _toolbarPageController,
            onPageChanged: (i) => setState(() => _toolbarPage = i),
            children: [_buildTextFormatPage(), _buildMoreToolsPage()],
          ),
        ),
        const SizedBox(height: 10),
        _buildPageIndicator(),
        const SizedBox(height: 12),
      ],
    ),
  );

  Widget _buildDragHandle() => GestureDetector(
    onVerticalDragUpdate: (d) => _dragAccumulator += d.delta.dy,
    onVerticalDragEnd: (d) {
      if (_dragAccumulator > 30) _collapseToolbar();
      _dragAccumulator = 0;
    },
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: kTextSecondary.withOpacity(0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ),
  );

  Widget _buildPageIndicator() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(_toolbarPageCount, (i) {
      final active = i == _toolbarPage;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: active ? 18 : 6,
        height: 6,
        decoration: BoxDecoration(
          color: active ? kPanelBg : kTextSecondary.withOpacity(0.3),
          borderRadius: BorderRadius.circular(3),
        ),
      );
    }),
  );

  Widget _buildTextFormatPage() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildColorRow(),
        _buildQuickIconsBar(),
        _buildWeightSizeRow(),
        _buildAlignRow(),
      ],
    ),
  );

  Widget _buildColorRow() {
    final currentHex = _currentColorHex();
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: kAccent,
        borderRadius: BorderRadius.circular(26),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        children: kTextPalette.values
            .map(
              (c) => _swatchCircle(
                color: c,
                isSelected: currentHex == colorToHex(c),
                onTap: () => _applyTextColor(colorToHex(c)),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _swatchCircle({
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    double size = 40,
  }) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Container(
      width: size,
      height: size,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected
              ? kPanelBg
              : (color == Colors.white
                    ? kTextSecondary.withOpacity(0.4)
                    : Colors.transparent),
          width: isSelected ? 2.5 : 1,
        ),
      ),
    ),
  );

  Widget _buildQuickIconsBar() => Container(
    height: 52,
    decoration: BoxDecoration(
      color: kAccent,
      borderRadius: BorderRadius.circular(26),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _barIcon(
          icon: HugeIcons.strokeRoundedLeftToRightListBullet,
          isActive: _isActive(quill.Attribute.ul),
          onTap: () => _toggle(quill.Attribute.ul),
        ),
        _barIcon(
          icon: HugeIcons.strokeRoundedQuoteUp,
          isActive: _isActive(quill.Attribute.blockQuote),
          onTap: () => _toggle(quill.Attribute.blockQuote),
        ),
        _barIcon(
          icon: HugeIcons.strokeRoundedLink01,
          isActive: false,
          onTap: _showLinkDialog,
        ),
      ],
    ),
  );

  Widget _barIcon({
    required List<List<dynamic>> icon,
    required bool isActive,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Container(
      width: 40,
      height: 40,
      decoration: isActive
          ? const BoxDecoration(color: kPanelBg, shape: BoxShape.circle)
          : null,
      alignment: Alignment.center,
      child: HugeIcon(
        icon: icon,
        color: isActive ? kTextPrimary : kTextSecondary,
        size: kIconSizeHuge - 4,
      ),
    ),
  );

  Widget _buildWeightSizeRow() => Row(
    children: [
      Expanded(
        child: _dropdownPill(label: _weightLabel, onTap: _showWeightSheet),
      ),
      const SizedBox(width: 10),
      Expanded(child: _fontSizeDropdown()),
    ],
  );

  Widget _fontSizeDropdown() {
    const sizes = [12, 14, 16, 18, 20, 24, 28, 32];
    return PopupMenuButton<int>(
      color: kAccent,
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => sizes
          .map(
            (size) => PopupMenuItem<int>(
              value: size,
              height: 38,
              child: Text(
                '$size',
                style: TextStyle(
                  fontFamily: kFontFamily,
                  color: '$size' == _fontSizeLabel
                      ? Colors.white
                      : kTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(),
      onSelected: (size) {
        final label = size.toString();
        _apply(FontSizeAttribute(label), toggle: false);
        setState(() => _fontSizeLabel = label);
      },
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: kAccent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _fontSizeLabel,
              style: const TextStyle(
                fontFamily: kFontFamily,
                color: kTextSecondary,
                fontSize: 14,
              ),
            ),
            const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowDown01,
              color: kTextSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdownPill({required String label, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: kAccent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: kFontFamily,
                  color: kTextSecondary,
                  fontSize: 14,
                ),
              ),
              const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowDown01,
                color: kTextSecondary,
                size: 18,
              ),
            ],
          ),
        ),
      );

  Widget _buildAlignRow() => Row(
    children: [
      Expanded(
        child: _alignBox(
          HugeIcons.strokeRoundedAlignLeft,
          isActive: _isActive(quill.Attribute.leftAlignment),
          onTap: () => _toggle(quill.Attribute.leftAlignment),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _alignBox(
          HugeIcons.strokeRoundedAlignHorizontalCenter,
          isActive: _isActive(quill.Attribute.centerAlignment),
          onTap: () => _toggle(quill.Attribute.centerAlignment),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _alignBox(
          HugeIcons.strokeRoundedAlignRight,
          isActive: _isActive(quill.Attribute.rightAlignment),
          onTap: () => _toggle(quill.Attribute.rightAlignment),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _alignBox(
          HugeIcons.strokeRoundedAlignHorizontalJustifyCenter,
          isActive: _isActive(quill.Attribute.justifyAlignment),
          onTap: () => _toggle(quill.Attribute.justifyAlignment),
        ),
      ),
    ],
  );

  Widget _alignBox(
    List<List<dynamic>> icon, {
    required bool isActive,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Container(
      height: 44,
      decoration: BoxDecoration(
        color: isActive ? kPanelBg : kAccent,
        borderRadius: BorderRadius.circular(22),
      ),
      alignment: Alignment.center,
      child: HugeIcon(
        icon: icon,
        color: isActive ? kTextPrimary : kTextSecondary,
        size: kIconSizeHuge - 4,
      ),
    ),
  );

  Widget _buildMoreToolsPage() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
    child: Column(
      children: [
        _buildHighlightRow(),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _quarterTile(
                label: 'H1',
                isActive: _isActive(quill.Attribute.h1),
                onTap: () => _toggle(quill.Attribute.h1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _quarterTile(
                label: 'H2',
                isActive: _isActive(quill.Attribute.h2),
                onTap: () => _toggle(quill.Attribute.h2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _quarterTile(
                label: 'H3',
                isActive: _isActive(quill.Attribute.h3),
                onTap: () => _toggle(quill.Attribute.h3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _quarterTile(
                icon: HugeIcons.strokeRoundedCheckmarkSquare02,
                isActive: _isActive(quill.Attribute.unchecked),
                onTap: () => _toggle(quill.Attribute.unchecked),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _halfTile(
                HugeIcons.strokeRoundedLeftToRightListBullet,
                label: 'Bullet',
                isActive: _isActive(quill.Attribute.ul),
                onTap: () => _toggle(quill.Attribute.ul),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _halfTile(
                HugeIcons.strokeRoundedLeftToRightListNumber,
                label: 'Numbered',
                isActive: _isActive(quill.Attribute.ol),
                onTap: () => _toggle(quill.Attribute.ol),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _quarterTile(
                icon: HugeIcons.strokeRoundedTextItalic,
                isActive: _isActive(quill.Attribute.italic),
                onTap: () => _toggle(quill.Attribute.italic),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _quarterTile(
                icon: HugeIcons.strokeRoundedTextUnderline,
                isActive: _isActive(quill.Attribute.underline),
                onTap: () => _toggle(quill.Attribute.underline),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _quarterTile(
                icon: HugeIcons.strokeRoundedTextStrikethrough,
                isActive: _isActive(quill.Attribute.strikeThrough),
                onTap: () => _toggle(quill.Attribute.strikeThrough),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _quarterTile(
                icon: HugeIcons.strokeRoundedSourceCode,
                isActive: _isActive(quill.Attribute.codeBlock),
                onTap: () => _toggle(quill.Attribute.codeBlock),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _quarterTile(
                icon: HugeIcons.strokeRoundedLink01,
                isActive: false,
                onTap: _showLinkDialog,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _quarterTile(
                icon: HugeIcons.strokeRoundedImage01,
                onTap: _showImagePickerSheet,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildHighlightRow() {
    final currentHex = _hasBackground()
        ? colorToHex(_currentHighlightColor())
        : null;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: kAccent,
        borderRadius: BorderRadius.circular(26),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        children: kHighlightPalette.values
            .map(
              (c) => _swatchCircle(
                color: c,
                isSelected: currentHex == colorToHex(c),
                onTap: () => setState(() => _applyHighlight(colorToHex(c))),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _halfTile(
    List<List<dynamic>>? icon, {
    String? label,
    required bool isActive,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Container(
      height: 52,
      decoration: BoxDecoration(
        color: isActive ? kPanelBg : kAccent,
        borderRadius: BorderRadius.circular(26),
        border: isActive ? null : Border.all(color: kAccent, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null)
            HugeIcon(
              icon: icon,
              color: isActive ? kTextPrimary : kTextSecondary,
              size: kIconSizeHuge - 4,
            ),
          if (icon != null && label != null) const SizedBox(width: 8),
          if (label != null)
            Text(
              label,
              style: TextStyle(
                fontFamily: kFontFamily,
                color: isActive ? kTextPrimary : kTextSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    ),
  );

  Widget _quarterTile({
    List<List<dynamic>>? icon,
    String? label,
    bool isActive = false,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Container(
      height: 52,
      decoration: BoxDecoration(
        color: isActive ? kPanelBg : kAccent,
        borderRadius: BorderRadius.circular(26),
        border: isActive ? null : Border.all(color: kAccent, width: 1),
      ),
      alignment: Alignment.center,
      child: icon != null
          ? HugeIcon(
              icon: icon,
              color: isActive ? kTextPrimary : kTextSecondary,
              size: kIconSizeHuge - 4,
            )
          : Text(
              label ?? '',
              style: TextStyle(
                fontFamily: kFontFamily,
                color: isActive ? kTextPrimary : kTextSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
    ),
  );

  void _applyHighlight(String colorHex) {
    _apply(quill.Attribute.clone(quill.Attribute.background, colorHex));
    _highlightColorHex = colorHex;
  }

  void _applyTextColor(String colorHex) =>
      _apply(quill.ColorAttribute(colorHex), toggle: false);
  void _clearTextColor() =>
      _apply(quill.Attribute.clone(quill.Attribute.color, null), toggle: false);

  // ═══════════════════════════════════════════════════════════════════
  //  Themed again from here down (weight sheet and link dialog)
  // ═══════════════════════════════════════════════════════════════════
  void _showWeightSheet() {
    const options = ['Thin', 'Regular', 'Medium', 'Semibold', 'Bold'];
    final c = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Theme(
        data: interThemeOf(sheetCtx),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: options.map((label) {
                final selected = label == _weightLabel;
                return ListTile(
                  title: Text(
                    label,
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      color: c.textPrimary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  trailing: selected
                      ? HugeIcon(
                          icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                          color: c.textPrimary,
                          size: 18,
                        )
                      : null,
                  onTap: () {
                    setState(() {
                      final shouldBold = label == 'Semibold' || label == 'Bold';
                      final isBold = _isActive(quill.Attribute.bold);
                      if (shouldBold && !isBold)
                        _apply(quill.Attribute.bold, toggle: false);
                      else if (!shouldBold && isBold)
                        _apply(
                          quill.Attribute.clone(quill.Attribute.bold, null),
                          toggle: false,
                        );
                      _apply(FontWeightLabelAttribute(label), toggle: false);
                      _weightLabel = label;
                    });
                    Navigator.pop(sheetCtx);
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  void _showLinkDialog() {
    final c = context.colors;
    final sel = _controller.selection;
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => Theme(
        data: interThemeOf(dialogCtx),
        child: AlertDialog(
          backgroundColor: c.surface,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Insert Link',
            style: TextStyle(fontFamily: kFontFamily, color: c.textPrimary),
          ),
          content: TextField(
            controller: ctrl,
            cursorColor: c.textPrimary,
            style: TextStyle(fontFamily: kFontFamily, color: c.textPrimary),
            decoration: InputDecoration(
              hintText: 'https://...',
              hintStyle: const TextStyle(
                fontFamily: kFontFamily,
                color: kHintText,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: c.border),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: c.textPrimary),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: kFontFamily,
                  color: kTextSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                if (sel.isValid && !sel.isCollapsed) {
                  _controller.formatText(
                    sel.start,
                    sel.end - sel.start,
                    quill.LinkAttribute(ctrl.text),
                  );
                }
                Navigator.pop(dialogCtx);
              },
              child: Text(
                'Insert',
                style: TextStyle(fontFamily: kFontFamily, color: c.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top toast ──────────────────────────────────────────────────────
// Slides in from the top. Swipe it left or right (or flick it up) to
// dismiss it early. It also closes by itself after a short while.
class _TopToast extends StatefulWidget {
  const _TopToast({
    required this.message,
    required this.onDismissed,
    this.icon,
  });
  final String message;
  final List<List<dynamic>>? icon;
  final VoidCallback onDismissed;

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  Timer? _timer;
  double _dx = 0;
  bool _dragging = false;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slide = Tween(
      begin: const Offset(0, -1.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1800), _closeAnimated);
  }

  // Normal close: slide back up
  Future<void> _closeAnimated() async {
    if (_closed) return;
    _closed = true;
    _timer?.cancel();
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismissed();
  }

  // Swipe close: fly off to the side
  Future<void> _closeBySwipe(double direction) async {
    if (_closed) return;
    _closed = true;
    _timer?.cancel();
    if (!mounted) return;
    setState(() {
      _dragging = false;
      _dx = direction * MediaQuery.of(context).size.width;
    });
    await Future.delayed(const Duration(milliseconds: 220));
    widget.onDismissed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final width = MediaQuery.of(context).size.width;
    final opacity = (1 - (_dx.abs() / (width * 0.6))).clamp(0.0, 1.0);

    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: GestureDetector(
            onHorizontalDragStart: (_) {
              if (_closed) return;
              _timer?.cancel();
              setState(() => _dragging = true);
            },
            onHorizontalDragUpdate: (d) {
              if (_closed) return;
              setState(() => _dx += d.delta.dx);
            },
            onHorizontalDragEnd: (d) {
              if (_closed) return;
              final v = d.primaryVelocity ?? 0;
              if (_dx.abs() > 90 || v.abs() > 700) {
                final dir = _dx != 0 ? _dx.sign : (v != 0 ? v.sign : 1.0);
                _closeBySwipe(dir);
              } else {
                setState(() {
                  _dragging = false;
                  _dx = 0;
                });
                _startTimer();
              }
            },
            onVerticalDragEnd: (d) {
              if ((d.primaryVelocity ?? 0) < -300) _closeAnimated();
            },
            child: AnimatedContainer(
              duration: _dragging
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(_dx, 0, 0),
              child: Opacity(
                opacity: opacity,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: context.isDarkMode
                          ? Border.all(color: c.border)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        if (widget.icon != null) ...[
                          HugeIcon(
                            icon: widget.icon!,
                            color: c.textPrimary,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Text(
                            widget.message,
                            style: TextStyle(
                              fontFamily: kFontFamily,
                              color: c.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Floating selection toolbar ─────────────────────────────────────
// Unchanged: keeps its own colors in light and dark mode.
class _SelectionFormatToolbar extends StatefulWidget {
  final Color? textColor;
  final Color highlightColor;
  final bool hasHighlight;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final ValueChanged<Color> onSelectTextColor;
  final ValueChanged<Color> onSelectHighlight;
  final VoidCallback onToggleBold;
  final VoidCallback onToggleItalic;
  final VoidCallback onToggleUnderline;
  final VoidCallback onLinkTap;

  const _SelectionFormatToolbar({
    required this.textColor,
    required this.highlightColor,
    required this.hasHighlight,
    required this.isBold,
    required this.isItalic,
    required this.isUnderline,
    required this.onSelectTextColor,
    required this.onSelectHighlight,
    required this.onToggleBold,
    required this.onToggleItalic,
    required this.onToggleUnderline,
    required this.onLinkTap,
  });

  @override
  State<_SelectionFormatToolbar> createState() =>
      _SelectionFormatToolbarState();
}

enum _PaletteMode { none, text, highlight }

class _SelectionFormatToolbarState extends State<_SelectionFormatToolbar> {
  _PaletteMode _mode = _PaletteMode.none;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        alignment: Alignment.center,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          constraints: const BoxConstraints(maxWidth: 320),
          decoration: BoxDecoration(
            color: kTextPrimary,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_mode) {
      case _PaletteMode.text:
        return _buildPalette(
          colors: kTextPalette.values.toList(),
          selected: widget.textColor,
          onTap: (c) => widget.onSelectTextColor(c),
          onClose: () => setState(() => _mode = _PaletteMode.none),
        );
      case _PaletteMode.highlight:
        return _buildPalette(
          colors: kHighlightPalette.values.toList(),
          selected: widget.hasHighlight ? widget.highlightColor : null,
          onTap: (c) => widget.onSelectHighlight(c),
          onClose: () => setState(() => _mode = _PaletteMode.none),
        );
      case _PaletteMode.none:
        return _buildDefaultRow();
    }
  }

  Widget _buildDefaultRow() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _formatButton('B', isActive: widget.isBold, onTap: widget.onToggleBold),
      _formatIcon(
        icon: HugeIcons.strokeRoundedTextItalic,
        isActive: widget.isItalic,
        onTap: widget.onToggleItalic,
      ),
      _formatIcon(
        icon: HugeIcons.strokeRoundedTextUnderline,
        isActive: widget.isUnderline,
        onTap: widget.onToggleUnderline,
      ),
      _formatIcon(
        icon: HugeIcons.strokeRoundedLink01,
        isActive: false,
        onTap: widget.onLinkTap,
      ),
      _formatIcon(
        icon: HugeIcons.strokeRoundedTextColor,
        isActive: false,
        onTap: () => setState(() => _mode = _PaletteMode.text),
      ),
      _divider(),
      _formatIcon(
        icon: HugeIcons.strokeRoundedColors,
        isActive: widget.hasHighlight,
        onTap: () => setState(() => _mode = _PaletteMode.highlight),
      ),
    ],
  );

  Widget _buildPalette({
    required List<Color> colors,
    required Color? selected,
    required ValueChanged<Color> onTap,
    required VoidCallback onClose,
  }) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: colors.map((c) {
              final isSel =
                  selected != null && colorToHex(selected) == colorToHex(c);
              return GestureDetector(
                onTap: () => onTap(c),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSel
                          ? kPanelBg
                          : (c == Colors.white
                                ? kTextSecondary.withOpacity(0.5)
                                : Colors.transparent),
                      width: isSel ? 2.5 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      _divider(),
      _formatIcon(
        icon: HugeIcons.strokeRoundedArrowDown01,
        isActive: false,
        onTap: onClose,
      ),
    ],
  );

  Widget _formatButton(
    String label, {
    required bool isActive,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: isActive
          ? const BoxDecoration(color: kPanelBg, shape: BoxShape.circle)
          : null,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: kFontFamily,
          color: isActive ? kTextPrimary : kPanelBg,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );

  Widget _formatIcon({
    required List<List<dynamic>> icon,
    required bool isActive,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: isActive
          ? const BoxDecoration(color: kPanelBg, shape: BoxShape.circle)
          : null,
      child: HugeIcon(
        icon: icon,
        color: isActive ? kTextPrimary : kPanelBg,
        size: 19,
      ),
    ),
  );

  Widget _divider() => Container(
    width: 1,
    height: 22,
    margin: const EdgeInsets.symmetric(horizontal: 2),
    color: kPanelBg.withOpacity(0.25),
  );
}

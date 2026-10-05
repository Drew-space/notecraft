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

import 'package:note_app/data/models/note.dart';
import 'package:note_app/core/constants/app_tags.dart';
import 'package:note_app/viewmodels/providers.dart';

// ─── "Huge" toolbar icon size ───────────────────────────────────────
const double kIconSizeHuge = 30;

// ─── Line heights (edit these two values to tune spacing) ───────────
const double kParagraphLineHeight = 1.7;
const double kListLineHeight = 1.15;

// ─── Typography ─────────────────────────────────────────────────────
const String kFontFamily = 'Inter';

ThemeData interThemeOf(BuildContext context) {
  final base = Theme.of(context);
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: kFontFamily),
    primaryTextTheme: base.primaryTextTheme.apply(fontFamily: kFontFamily),
  );
}

// ─── Theme constants ────────────────────────────────────────────────
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
  if (attr.key == 'strikeThrough' || attr.key == 'checked') {
    return const TextStyle(
      fontFamily: kFontFamily,
      decoration: TextDecoration.lineThrough,
      decorationColor: kTextPrimary,
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
class _ImageStateStore extends ChangeNotifier {
  int? selectedOffset;
  final Map<int, double> widthFractions = {};
  final Map<int, double> scales = {};
  final Map<int, double> rotations = {};

  void select(int? offset) {
    if (selectedOffset == offset) return;
    selectedOffset = offset;
    notifyListeners();
  }

  void setWidth(int offset, double fraction) {
    widthFractions[offset] = fraction;
    notifyListeners();
  }

  void setScale(int offset, double scale) {
    scales[offset] = scale;
    notifyListeners();
  }

  void setRotation(int offset, double degrees) {
    rotations[offset] = degrees % 360;
    notifyListeners();
  }

  void rotateQuarter(int offset) {
    final current = rotations[offset] ?? 0;
    rotations[offset] = (current + 90) % 360;
    notifyListeners();
  }

  void _remap(int Function(int) shift) {
    final wf = <int, double>{};
    final sc = <int, double>{};
    final rt = <int, double>{};
    widthFractions.forEach((k, v) => wf[shift(k)] = v);
    scales.forEach((k, v) => sc[shift(k)] = v);
    rotations.forEach((k, v) => rt[shift(k)] = v);
    widthFractions
      ..clear()
      ..addAll(wf);
    scales
      ..clear()
      ..addAll(sc);
    rotations
      ..clear()
      ..addAll(rt);
    notifyListeners();
  }

  void remapAfterInsert(int offset) => _remap((k) => k >= offset ? k + 1 : k);

  void remapAfterDelete(int offset) {
    selectedOffset = null;
    widthFractions.remove(offset);
    scales.remove(offset);
    rotations.remove(offset);
    _remap((k) => k > offset ? k - 1 : k);
  }
}

// ─── Quill embed builder ────────────────────────────────────────────
class NoteImageEmbedBuilder extends quill.EmbedBuilder {
  NoteImageEmbedBuilder({required this.store, required this.onDelete});

  final _ImageStateStore store;
  final void Function(int offset) onDelete;

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
    final offset = node.offset;
    return _NoteImage(
      url: url,
      isLocalFile: isLocalFile,
      offset: offset,
      store: store,
      onDelete: () => onDelete(offset),
    );
  }
}

// ─── Image widget ───────────────────────────────────────────────────
class _NoteImage extends StatefulWidget {
  const _NoteImage({
    required this.url,
    required this.offset,
    required this.store,
    required this.onDelete,
    this.isLocalFile = false,
  });

  final String url;
  final bool isLocalFile;
  final int offset;
  final _ImageStateStore store;
  final VoidCallback onDelete;

  @override
  State<_NoteImage> createState() => _NoteImageState();
}

class _NoteImageState extends State<_NoteImage> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  double? _naturalAspect;
  int _pointers = 0;
  double _baseScale = 1;

  _ImageStateStore get store => widget.store;
  int get offset => widget.offset;

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
        final selected = store.selectedOffset == offset;
        final fraction = (store.widthFractions[offset] ?? 0.9).clamp(0.3, 1.0);
        final scale = (store.scales[offset] ?? 1.0).clamp(0.4, 4.0);
        final rotation = store.rotations[offset] ?? 0.0;
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

            return Align(
              alignment: Alignment.center,
              child: Listener(
                onPointerDown: (_) => _pointers++,
                onPointerUp: (_) => _pointers = math.max(0, _pointers - 1),
                onPointerCancel: (_) => _pointers = math.max(0, _pointers - 1),
                child: GestureDetector(
                  onTap: () => store.select(selected ? null : offset),
                  onLongPress: widget.onDelete,
                  onDoubleTap: () {
                    store.setScale(offset, 1);
                    store.setRotation(offset, 0);
                  },
                  onScaleStart: (_) => _baseScale = store.scales[offset] ?? 1.0,
                  onScaleUpdate: (d) {
                    if (_pointers >= 2) {
                      store.setScale(
                        offset,
                        (_baseScale * d.scale).clamp(0.4, 4.0),
                      );
                    }
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
    double dragStart = store.widthFractions[offset] ?? 0.9;
    return Positioned(
      left: left ? -10 : null,
      right: left ? null : -10,
      top: top ? -10 : null,
      bottom: top ? null : -10,
      child: GestureDetector(
        onPanStart: (_) => dragStart = store.widthFractions[offset] ?? 0.9,
        onPanUpdate: (d) {
          final dir = left ? -1.0 : 1.0;
          store.setWidth(
            offset,
            (dragStart + dir * d.delta.dx / maxW).clamp(0.3, 1.0),
          );
        },
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
            store.setRotation(offset, (deg + 360) % 360);
          },
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
      final so = _imageStore.selectedOffset;
      final sel = _controller.selection;
      if (so != null &&
          (!sel.isValid || (sel.start != so && sel.start != so + 1))) {
        _imageStore.select(null);
      }
      setState(() => _isEdited = true);
    });
  }

  @override
  void dispose() {
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
    setState(() {
      _isLocked = !_isLocked;
      _isEdited = true;
    });
    _showTopToast(
      _isLocked ? 'Note locked, save to apply' : 'Note unlocked, save to apply',
      icon: HugeIcons.strokeRoundedLocked,
    );
  }

  void _toggleBookmark() {
    setState(() {
      _isBookmarked = !_isBookmarked;
      _isEdited = true;
    });
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
    setState(() {
      _isPinned = !_isPinned;
      _isEdited = true;
    });
    _showTopToast(
      _isPinned ? 'Pinned successfully' : 'Unpinned',
      icon: HugeIcons.strokeRoundedPin,
    );
  }

  // Shared list style so text, numbers, bullets and checkboxes all match.
  static const TextStyle _listTextStyle = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: kTextPrimary,
    height: kListLineHeight,
  );

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Theme(
      data: interThemeOf(context),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFFF6F6F6),
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
                        const SizedBox(width: 4),
                        Flexible(child: _buildTagDropdown()),
                        const Spacer(),
                        if (_isLocked)
                          _headerIcon(
                            icon: HugeIcons.strokeRoundedLocked,
                            onTap: _toggleLock,
                          ),
                        GestureDetector(
                          onTap: _toggleBookmark,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              _isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: kTextPrimary,
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
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
                            style: const TextStyle(
                              fontFamily: kFontFamily,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: kTextPrimary,
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
                              primaryColor: kTextPrimary,
                              colorScheme: Theme.of(
                                context,
                              ).colorScheme.copyWith(primary: kTextPrimary),
                              checkboxTheme: CheckboxThemeData(
                                shape: const CircleBorder(),
                                fillColor: WidgetStateProperty.resolveWith((
                                  states,
                                ) {
                                  if (states.contains(WidgetState.selected))
                                    return kTextPrimary;
                                  return Colors.white;
                                }),
                                checkColor: const WidgetStatePropertyAll(
                                  Colors.white,
                                ),
                                side: const BorderSide(
                                  color: kTextPrimary,
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
                              style: const TextStyle(
                                fontFamily: kFontFamily,
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                                color: kTextPrimary,
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
                                    ),
                                  ],
                                  // ─── SEPARATE LINE HEIGHTS ───
                                  customStyles: quill.DefaultStyles(
                                    // Normal notes
                                    paragraph: quill.DefaultTextBlockStyle(
                                      const TextStyle(
                                        fontFamily: kFontFamily,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: kTextPrimary,
                                        height: kParagraphLineHeight,
                                      ),
                                      const quill.HorizontalSpacing(0, 0),
                                      const quill.VerticalSpacing(0, 0),
                                      const quill.VerticalSpacing(0, 0),
                                      null,
                                    ),
                                    // List text (bullets, numbers, checkboxes)
                                    lists: quill.DefaultListBlockStyle(
                                      _listTextStyle,
                                      const quill.HorizontalSpacing(0, 0),
                                      const quill.VerticalSpacing(0, 0),
                                      const quill.VerticalSpacing(0, 0),
                                      null,
                                      null,
                                    ),
                                    // The numbers and bullet dots themselves.
                                    // Must match the list height above so
                                    // they line up with the list text.
                                    leading: quill.DefaultTextBlockStyle(
                                      _listTextStyle,
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
      child: HugeIcon(icon: icon, color: kTextPrimary, size: 24),
    ),
  );

  Widget _buildMoreMenuButton() {
    return PopupMenuButton<String>(
      color: Colors.white,
      elevation: 8,
      offset: const Offset(0, 46),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) {
        switch (value) {
          case 'save':
            _saveNote();
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
          color: kTextPrimary,
          size: 24,
        ),
      ),
    );
  }

  PopupMenuItem<String> _moreMenuItem({
    required String value,
    required List<List<dynamic>> icon,
    required String label,
    Color color = kTextPrimary,
  }) => PopupMenuItem<String>(
    value: value,
    height: 44,
    child: Row(
      children: [
        HugeIcon(icon: icon, size: 18, color: color),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(fontFamily: kFontFamily, fontSize: 14, color: color),
        ),
      ],
    ),
  );

  Widget _buildTagDropdown() {
    final hasTag = _tags.isNotEmpty;
    final label = hasTag ? _tags.first : 'Add tag';
    final tagColor = hasTag ? getTagColor(label) : const Color(0xFFF1F1F4);
    final textColor = hasTag ? tagColor : kTextPrimary;

    final allTags = <String>{...kGlobalTags, ..._tags}.toList();

    return PopupMenuButton<String>(
      color: Colors.white,
      offset: const Offset(0, 42),
      constraints: const BoxConstraints(
        minWidth: 180,
        maxWidth: 240,
        maxHeight: 320,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) {
        setState(() {
          _tags.remove(value);
          _tags.insert(0, value);
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
                    style: const TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 13,
                      color: kTextPrimary,
                    ),
                  ),
                ),
                if (isPrimary) ...[
                  const Spacer(),
                  const Icon(Icons.check_circle, size: 14, color: kTextPrimary),
                ],
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: tagColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedTag01,
              size: 16,
              color: textColor,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: kFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(width: 4),
            HugeIcon(
              icon: HugeIcons.strokeRoundedArrowDown01,
              size: 14,
              color: textColor,
            ),
          ],
        ),
      ),
    );
  }

  void _onBack() {
    if (!_isEdited) {
      Navigator.pop(context);
      return;
    }
    showDialog(
      context: context,
      builder: (dialogCtx) => Theme(
        data: interThemeOf(dialogCtx),
        child: AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Discard changes?',
            style: TextStyle(
              fontFamily: kFontFamily,
              color: kTextPrimary,
              fontSize: 17,
            ),
          ),
          content: const Text(
            'Going back will undo everything you just did.',
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
                'Keep editing',
                style: TextStyle(
                  fontFamily: kFontFamily,
                  color: kTextSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                Navigator.pop(context);
              },
              child: const Text(
                'Discard',
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

  void _saveNote() {
    // ─── EXTRACT FIRST IMAGE URL FROM THE EDITOR ───────────────────
    String? firstImageUrl = widget.note?.imageUrl;
    try {
      final deltaJson = _controller.document.toDelta().toJson();
      for (final op in deltaJson) {
        if (op['insert'] is Map &&
            (op['insert'] as Map).containsKey('noteImage')) {
          final imageData = jsonDecode(
            (op['insert'] as Map)['noteImage'] as String,
          );
          firstImageUrl = imageData['url'] as String?;
          break; // stop at the first image
        }
      }
    } catch (e) {
      debugPrint('Error extracting image: $e');
    }

    final note = Note(
      id: widget.note?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim().isEmpty
          ? 'Untitled'
          : _titleController.text.trim(),
      content: _controller.document.toPlainText(),
      deltaJson: jsonEncode(_controller.document.toDelta().toJson()),
      tags: _tags,
      category: _tags.isNotEmpty ? _tags.first : widget.note?.category,
      date: widget.note?.date ?? DateTime.now(),
      color: widget.note?.color ?? const Color(0xFF2D2D2D),
      imageUrl: firstImageUrl, // extracted image is saved here
      isPinned: _isPinned,
      isLocked: _isLocked,
      isBookmarked: _isBookmarked,
      isChecklist: widget.note?.isChecklist ?? false,
      checklistItems: widget.note?.checklistItems,
    );

    ref.read(notesProvider.notifier).saveNote(note);
    debugPrint('Saving: ${note.title} | image: ${note.imageUrl}');
    Navigator.pop(context, note);
  }

  void _confirmDeleteNote() {
    // If it's a brand new note that hasn't been saved yet, just pop.
    if (widget.note == null) {
      Navigator.pop(context);
      return;
    }

    showDialog(
      context: context,
      builder: (dialogCtx) => Theme(
        data: interThemeOf(dialogCtx),
        child: AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Delete note?',
            style: TextStyle(
              fontFamily: kFontFamily,
              color: kTextPrimary,
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
              const Text(
                'Add Image',
                style: TextStyle(
                  fontFamily: kFontFamily,
                  color: kTextPrimary,
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
  ) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: kTileBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          HugeIcon(icon: icon, color: kTextPrimary, size: kIconSizeHuge),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: kFontFamily,
              color: kTextPrimary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _pickImageFromSource(ImageSource source) async {
    Navigator.pop(context);
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: source, imageQuality: 85);
    if (xfile != null) _insertImage(xfile.path, isLocalFile: true);
  }

  Future<void> _pickFileFromDevice() async {
    Navigator.pop(context);
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path != null) _insertImage(path, isLocalFile: true);
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

  void _insertImage(String url, {bool isLocalFile = false}) {
    final index = _embedInsertIndex();
    _imageStore.remapAfterInsert(index);
    final embed = quill.BlockEmbed.custom(
      quill.CustomBlockEmbed(
        'noteImage',
        jsonEncode({'url': url, 'source': isLocalFile ? 'file' : 'network'}),
      ),
    );
    _controller.document.insert(index, embed);
    _controller.updateSelection(
      TextSelection.collapsed(offset: index + 1),
      quill.ChangeSource.local,
    );
    setState(() => _isEdited = true);
  }

  void _confirmDeleteImage(int offset) {
    showDialog(
      context: context,
      builder: (dialogCtx) => Theme(
        data: interThemeOf(dialogCtx),
        child: AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Delete image?',
            style: TextStyle(
              fontFamily: kFontFamily,
              color: kTextPrimary,
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
                _imageStore.remapAfterDelete(offset);
                _controller.document.delete(offset, 1);
                _controller.updateSelection(
                  TextSelection.collapsed(offset: offset),
                  quill.ChangeSource.local,
                );
                setState(() => _isEdited = true);
                Navigator.pop(dialogCtx);
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

  void _showWeightSheet() {
    const options = ['Thin', 'Regular', 'Medium', 'Semibold', 'Bold'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
                      color: selected ? kAccent : kTextPrimary,
                    ),
                  ),
                  trailing: selected
                      ? const HugeIcon(
                          icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                          color: kAccent,
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
    final sel = _controller.selection;
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => Theme(
        data: interThemeOf(dialogCtx),
        child: AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Insert Link',
            style: TextStyle(fontFamily: kFontFamily, color: kTextPrimary),
          ),
          content: TextField(
            controller: ctrl,
            style: const TextStyle(
              fontFamily: kFontFamily,
              color: kTextPrimary,
            ),
            decoration: const InputDecoration(
              hintText: 'https://...',
              hintStyle: TextStyle(fontFamily: kFontFamily, color: kHintText),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: kTileBg),
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
              child: const Text(
                'Insert',
                style: TextStyle(fontFamily: kFontFamily, color: kAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top toast ──────────────────────────────────────────────────────
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

    Future.delayed(const Duration(milliseconds: 1800), () async {
      if (!mounted) return;
      await _controller.reverse();
      widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
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
                    HugeIcon(icon: widget.icon!, color: Colors.black, size: 18),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        fontFamily: kFontFamily,
                        color: Colors.black,
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
    );
  }
}

// ─── Floating selection toolbar ─────────────────────────────────────
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

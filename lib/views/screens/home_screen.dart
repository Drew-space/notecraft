import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:note_app/core/constants/app_tags.dart';
import 'package:note_app/core/theme/app_colors.dart';
import 'package:note_app/data/models/note.dart';
import 'package:note_app/data/models/user_profile.dart';
import 'package:note_app/viewmodels/providers.dart';
import 'package:note_app/viewmodels/theme_provider.dart';
import 'package:note_app/views/screens/note_detail_screen.dart';
import 'package:note_app/views/screens/bookmarks_screen.dart';
import 'package:note_app/views/screens/pinned_screen.dart';
import 'package:note_app/core/services/note_lock_service.dart';
import 'package:note_app/views/widgets/note_grid_card.dart';
import 'package:note_app/views/widgets/profile_drawer.dart';
import 'package:note_app/views/widgets/user_avatar.dart';
import 'package:note_app/views/sheets/edit_profile_sheet.dart';

// Pinned card image box width (edit to make the image wider or narrower)
const double kPinnedImageWidth = 112;

class NoteHomeScreen extends ConsumerStatefulWidget {
  const NoteHomeScreen({super.key});

  @override
  ConsumerState<NoteHomeScreen> createState() => _NoteHomeScreenState();
}

class _NoteHomeScreenState extends ConsumerState<NoteHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PageController _pageController = PageController(viewportFraction: 0.84);
  int _currentPage = 0;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  // Category filter ('All' means no filter)
  String _selectedFilter = 'All';

  // Multi-select state
  final Set<String> _selectedIds = {};

  bool get _isSearching => _query.trim().isNotEmpty;
  bool get _selecting => _selectedIds.isNotEmpty;

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onCreateNote() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NoteDetailScreen()),
    );
  }

  // Used by the pinned carousel cards
  Future<void> _openNote(Note note) async {
    if (note.isLocked) {
      final ok = await _authenticate();
      if (!ok || !mounted) return;
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteDetailScreen(note: note)),
    );
  }

  // Shows a snackbar if the device has no lock screen, otherwise asks
  // the user to authenticate. Returns true if it is safe to continue.
  Future<bool> _authenticate() async {
    final supported = await NoteLockService.isDeviceSupported();
    if (!supported) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No device authentication available'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
    final ok = await NoteLockService.authenticate();
    return ok && mounted;
  }

  // ─── Theme toggle ──────────────────────────────────────────────
  void _toggleTheme() {
    final isDark = context.isDarkMode;
    ref
        .read(themeModeProvider.notifier)
        .setMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  // ─── Search ────────────────────────────────────────────────────
  // Matches the title, the text (including list items) and the tags.
  bool _matchesQuery(Note note) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (note.title.toLowerCase().contains(q)) return true;
    if (cleanNoteText(note.content).toLowerCase().contains(q)) return true;
    if (note.tags.any((t) => t.toLowerCase().contains(q))) return true;
    if ((note.category ?? '').toLowerCase().contains(q)) return true;
    return false;
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
    FocusScope.of(context).unfocus();
  }

  // ─── Category filter ───────────────────────────────────────────
  bool _matchesTag(Note n, String tag) =>
      n.tags.contains(tag) || n.category == tag;

  // If the selected tag no longer has any notes (for example after
  // deleting them), fall back to 'All'.
  String _activeFilter(List<Note> notes) {
    if (_selectedFilter == 'All') return 'All';
    return notes.any((n) => _matchesTag(n, _selectedFilter))
        ? _selectedFilter
        : 'All';
  }

  // ─── Selection helpers ─────────────────────────────────────────
  void _toggleSelect(String id) {
    setState(() {
      if (!_selectedIds.remove(id)) _selectedIds.add(id);
    });
  }

  void _exitSelection() => setState(_selectedIds.clear);

  // ─── Long press actions ────────────────────────────────────────
  Future<void> _showNoteActions(Note note) async {
    final c = context.colors;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.isLocked ? 'Locked note' : note.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              if (note.isPinned)
                _actionTile(
                  sheetCtx,
                  HugeIcons.strokeRoundedPin,
                  'Unpin note',
                  'unpin',
                ),
              if (note.isLocked)
                _actionTile(
                  sheetCtx,
                  HugeIcons.strokeRoundedLocked,
                  'Unlock note',
                  'unlock',
                ),
              if (note.isBookmarked)
                _actionTile(
                  sheetCtx,
                  HugeIcons.strokeRoundedBookmark02,
                  'Remove bookmark',
                  'unbookmark',
                ),
              _actionTile(
                sheetCtx,
                HugeIcons.strokeRoundedCheckmarkCircle01,
                'Select multiple',
                'select',
              ),
              _actionTile(
                sheetCtx,
                HugeIcons.strokeRoundedDelete02,
                'Delete note',
                'delete',
                color: Colors.redAccent,
              ),
            ],
          ),
        ),
      ),
    );

    if (action == null || !mounted) return;
    final notifier = ref.read(notesProvider.notifier);

    switch (action) {
      case 'unpin':
        await notifier.setPinned(note.id, false);
        break;
      case 'unlock':
        if (await _authenticate()) {
          await notifier.setLocked(note.id, false);
        }
      case 'unbookmark':
        await notifier.setBookmarked(note.id, false);

        break;
      case 'select':
        setState(() => _selectedIds.add(note.id));
        break;
      case 'delete':
        await _deleteNotes([note]);
        break;
    }
  }

  Widget _actionTile(
    BuildContext sheetCtx,
    List<List<dynamic>> icon,
    String label,
    String value, {
    Color? color,
  }) {
    final c = context.colors;
    final itemColor = color ?? c.textPrimary;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: HugeIcon(icon: icon, color: itemColor, size: 22),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: itemColor,
        ),
      ),
      onTap: () => Navigator.pop(sheetCtx, value),
    );
  }

  // ─── Delete (single or many) ───────────────────────────────────
  Future<void> _deleteNotes(List<Note> targets) async {
    if (targets.isEmpty) return;
    final c = context.colors;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          targets.length == 1
              ? 'Delete note?'
              : 'Delete ${targets.length} notes?',
          style: GoogleFonts.inter(color: c.textPrimary, fontSize: 17),
        ),
        content: Text(
          targets.length == 1
              ? 'This note will be permanently removed.'
              : 'These notes will be permanently removed.',
          style: GoogleFonts.inter(color: c.textMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: c.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Locked notes need the user to prove it is them first
    if (targets.any((n) => n.isLocked)) {
      if (!await _authenticate()) return;
    }

    await ref
        .read(notesProvider.notifier)
        .deleteNotes(targets.map((n) => n.id).toSet());
    if (!mounted) return;
    _exitSelection();
  }

  // ─── Safely render a local file OR a network image ─────────────
  Widget _buildImageWidget(String imageUrl, {BoxFit fit = BoxFit.cover}) {
    final isLocal =
        imageUrl.startsWith('/') ||
        imageUrl.startsWith('file://') ||
        !imageUrl.startsWith('http');
    if (isLocal) {
      return Image.file(
        File(imageUrl),
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _imageErrorPlaceholder(),
      );
    }
    return Image.network(
      imageUrl,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => _imageErrorPlaceholder(),
    );
  }

  Widget _imageErrorPlaceholder() => Container(
    color: Colors.black.withOpacity(0.05),
    alignment: Alignment.center,
    child: const HugeIcon(
      icon: HugeIcons.strokeRoundedImage01,
      color: Colors.black45,
      size: 32,
    ),
  );

  // ─── Pinned card image ─────────────────────────────────────────
  // The whole image is shown (not cropped) inside a rounded, bordered
  // frame. A blurred copy of the same image fills any empty space, so
  // it looks good for tall, wide or square pictures.
  Widget _buildPinnedImage(String url) {
    return Container(
      width: kPinnedImageWidth,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: _buildImageWidget(url, fit: BoxFit.cover),
            ),
            Container(color: Colors.white.withOpacity(0.2)),
            _buildImageWidget(url, fit: BoxFit.contain),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The status bar style is handled globally in main.dart.
    final c = context.colors;
    final notes = ref.watch(notesProvider);
    final pinnedNotes = ref.watch(pinnedNotesProvider);
    final profile = ref.watch(profileProvider);

    final sortedNotes = [...notes]..sort((a, b) => b.date.compareTo(a.date));
    final regularNotes = sortedNotes.where((n) => !n.isPinned).toList();
    final searchResults = sortedNotes.where(_matchesQuery).toList();

    final activeFilter = _activeFilter(notes);
    final isFiltering = activeFilter != 'All';
    final filteredNotes = sortedNotes
        .where((n) => _matchesTag(n, activeFilter))
        .toList();

    // Search shows every match, a filter shows every note in that
    // category (pinned ones too), otherwise pinned notes live in the
    // carousel and the grid only shows the rest.
    final List<Note> gridNotes = _isSearching
        ? searchResults
        : isFiltering
        ? filteredNotes
        : regularNotes;

    // Everything the user can currently see (used by "select all")
    final List<Note> visibleNotes = _isSearching
        ? searchResults
        : isFiltering
        ? filteredNotes
        : sortedNotes;

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      ),
      child: PopScope(
        // Back button leaves selection mode first, then the screen
        canPop: !_selecting,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _exitSelection();
        },
        child: Scaffold(
          key: _scaffoldKey,
          drawerEnableOpenDragGesture: !_selecting,
          drawer: ProfileDrawer(
            profile: profile,
            totalNotes: notes.length,
            pinnedNotes: pinnedNotes.length,
            bookmarkNotes: ref.watch(bookmarkedNotesProvider).length,
            selectedItem: 'All notes',
            onEditProfile: () => EditProfileSheet.show(context, profile),
            onMenuItemTap: (label) {
              if (label == 'Pinned') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PinnedScreen()),
                );
              }
              if (label == 'Bookmark') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BookmarksScreen()),
                );
              }
            },
          ),
          backgroundColor: c.scaffold,
          body: SafeArea(
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  child: _selecting
                      ? _buildSelectionHeader(visibleNotes, notes)
                      : _buildHeader(profile),
                ),
                SliverToBoxAdapter(
                  child: _buildSearchBar(showFilter: notes.isNotEmpty),
                ),
                if (notes.isEmpty)
                  SliverToBoxAdapter(child: _buildEmptyState(context))
                else ...[
                  if (_isSearching)
                    SliverToBoxAdapter(
                      child: _buildSearchSummary(searchResults.length),
                    )
                  else ...[
                    if (pinnedNotes.isNotEmpty && !isFiltering)
                      SliverToBoxAdapter(
                        child: _buildPinnedSection(pinnedNotes),
                      ),
                    SliverToBoxAdapter(
                      child: _buildCategoryFilters(notes, activeFilter),
                    ),
                  ],
                  if (_isSearching && searchResults.isEmpty)
                    SliverToBoxAdapter(child: _buildNoResults())
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 12,
                      ),
                      sliver: SliverMasonryGrid.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childCount: gridNotes.length,
                        itemBuilder: (context, index) {
                          final note = gridNotes[index];
                          return NoteGridCard(
                            note: note,
                            selectionMode: _selecting,
                            selected: _selectedIds.contains(note.id),
                            // null means "use the card's default open"
                            onTap: _selecting
                                ? () => _toggleSelect(note.id)
                                : null,
                            onLongPress: _selecting
                                ? () => _toggleSelect(note.id)
                                : () => _showNoteActions(note),
                          );
                        },
                      ),
                    ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
          floatingActionButton: _selecting
              ? null
              : FloatingActionButton(
                  onPressed: _onCreateNote,
                  backgroundColor: c.accent,
                  shape: const CircleBorder(),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedAdd01,
                    color: c.onAccent,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSearchSummary(int count) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
      child: Text(
        count == 1 ? '1 result' : '$count results',
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: c.textMuted,
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 60, left: 40, right: 40),
      child: Column(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedSearch01,
            size: 44,
            color: c.textFaint,
          ),
          const SizedBox(height: 14),
          Text(
            'No notes found',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different word, or check the spelling.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: c.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 80, left: 40, right: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: c.searchBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedNote01,
                color: c.textPrimary,
                size: 44,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No notes yet',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tap the + button to create your first note. Capture your thoughts, ideas, and to-do lists in one place.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: c.textMuted,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _onCreateNote,
            style: ElevatedButton.styleFrom(
              backgroundColor: c.accent,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedAdd01,
                  color: c.onAccent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Create Note',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: c.onAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(UserProfile profile) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            behavior: HitTestBehavior.opaque,
            child: UserAvatar(profile: profile, size: 44),
          ),
          Text(
            'My Notes',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          _buildThemeToggle(),
        ],
      ),
    );
  }

  // Header shown while selecting notes: close, count, select all, delete
  Widget _buildSelectionHeader(List<Note> visible, List<Note> all) {
    final c = context.colors;
    final allSelected =
        visible.isNotEmpty && visible.every((n) => _selectedIds.contains(n.id));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            _circleButton(
              onTap: _exitSelection,
              child: Icon(Icons.close, size: 22, color: c.textPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                '${_selectedIds.length} selected',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
            ),
            _circleButton(
              onTap: () => setState(() {
                if (allSelected) {
                  _selectedIds.clear();
                } else {
                  _selectedIds.addAll(visible.map((n) => n.id));
                }
              }),
              child: Icon(
                allSelected ? Icons.deselect : Icons.select_all,
                size: 22,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            _circleButton(
              onTap: () => _deleteNotes(
                all.where((n) => _selectedIds.contains(n.id)).toList(),
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedDelete02,
                color: Colors.redAccent,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({required VoidCallback onTap, required Widget child}) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: c.chipBg,
          shape: BoxShape.circle,
          border: Border.all(color: c.border),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  // Round button that switches between light and dark mode.
  // Shows a moon in light mode and a sun in dark mode.
  Widget _buildThemeToggle() {
    final c = context.colors;
    final isDark = context.isDarkMode;
    return GestureDetector(
      onTap: _toggleTheme,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: c.chipBg,
          shape: BoxShape.circle,
          border: Border.all(color: c.border),
        ),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          ),
          child: KeyedSubtree(
            key: ValueKey<bool>(isDark),
            child: HugeIcon(
              icon: isDark
                  ? HugeIcons.strokeRoundedSun01
                  : HugeIcons.strokeRoundedMoon02,
              color: c.textPrimary,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar({bool showFilter = true}) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: c.searchBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            HugeIcon(
              icon: HugeIcons.strokeRoundedSearch01,
              color: c.textMuted,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
                cursorColor: c.textPrimary,
                style: GoogleFonts.inter(color: c.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  hintStyle: GoogleFonts.inter(
                    color: c.textMuted,
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_query.isNotEmpty)
              GestureDetector(
                onTap: _clearSearch,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.cancel, size: 20, color: c.textFaint),
                ),
              ),
            if (showFilter && _query.isEmpty) const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildPinnedSection(List<Note> pinnedNotes) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: c.chipBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.border),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedPin,
                    color: c.textPrimary,
                    size: 17,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pinned notes',
                    style: GoogleFonts.inter(
                      color: c.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Keep your important thoughts close',
                    style: GoogleFonts.inter(
                      color: c.textMuted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: c.chipBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c.border),
                ),
                child: Text(
                  '${pinnedNotes.length}',
                  style: GoogleFonts.inter(
                    color: c.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: SizedBox(
            height: 180,
            child: PageView.builder(
              controller: _pageController,
              padEnds: false,
              itemCount: pinnedNotes.length,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                final note = pinnedNotes[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: AnimatedScale(
                    scale: _currentPage == index ? 1.0 : 0.97,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: _buildPinnedCard(note),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pinnedNotes.length, (index) {
            final isActive = _currentPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 22 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? c.textPrimary : c.dotInactive,
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // Selection overlay for the pinned card (same idea as the grid card)
  Widget _buildPinnedSelectionOverlay(bool selected) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(10),
          alignment: Alignment.bottomRight,
          decoration: BoxDecoration(
            color: selected
                ? Colors.black.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
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
              size: 24,
              color: const Color(0xFF1A1A1A),
            ),
          ),
        ),
      ),
    );
  }

  // The pinned card keeps its pastel color and dark text in both modes,
  // so it stays readable and matches the grid cards.
  Widget _buildPinnedCard(Note note) {
    final bgColor = getNoteBackgroundColor(
      note.tags.isNotEmpty ? note.tags.first : '',
      note.id,
    );
    final hasImage = note.imageUrl != null && note.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: _selecting ? () => _toggleSelect(note.id) : () => _openNote(note),
      onLongPress: _selecting
          ? () => _toggleSelect(note.id)
          : () => _showNoteActions(note),
      child: Container(
        width: double.infinity,
        height: 180,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              // A little breathing room around the image frame
              padding: EdgeInsets.all(hasImage ? 10 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (hasImage) _buildPinnedImage(note.imageUrl!),
                  Expanded(
                    child: Padding(
                      padding: hasImage
                          ? const EdgeInsets.fromLTRB(12, 6, 6, 4)
                          : const EdgeInsets.fromLTRB(15, 16, 15, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1A1A1A),
                                    height: 1.35,
                                  ),
                                ),
                              ),
                              if (note.isBookmarked)
                                const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Icon(
                                    Icons.bookmark,
                                    size: 18,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ClipRect(
                              child: NoteContentPreview(
                                note: note,
                                maxLines: 4,
                                maxListItems: 3,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
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
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              const Spacer(),
                              if (hasImage)
                                const SizedBox(width: 6)
                              else ...[
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 11,
                                  color: Color(0xFF4B5563),
                                ),
                                const SizedBox(width: 4),
                              ],
                              // With an image there is less room, so the
                              // date is shorter and can never overflow
                              Flexible(
                                child: Text(
                                  hasImage
                                      ? _shortDate(note.date)
                                      : _formatDate(note.date),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: const Color(0xFF4B5563),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (note.isLocked) _buildLockOverlay(),
            if (_selecting)
              _buildPinnedSelectionOverlay(_selectedIds.contains(note.id)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilters(List<Note> notes, String activeFilter) {
    final visibleTags = kGlobalTags
        .where((tag) => notes.any((n) => _matchesTag(n, tag)))
        .toList();
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildFilterChip(
            'All',
            notes.length,
            isSelected: activeFilter == 'All',
          ),
          ...visibleTags.map((tag) {
            final count = notes.where((n) => _matchesTag(n, tag)).length;
            return _buildFilterChip(
              tag,
              count,
              isSelected: activeFilter == tag,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count, {bool isSelected = false}) {
    // Solid, badge-style chip: flat colored background, white text,
    // small rounded rectangle. Same look in light and dark mode.
    // "All" uses a neutral gray. Tapping a chip filters the notes, and
    // the chips that are not selected are dimmed a little.
    final isAll = label == 'All';
    final chipColor = isAll ? const Color(0xFF8E8E93) : getTagColor(label);

    final shadow = isSelected
        ? [
            BoxShadow(
              color: chipColor.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ]
        : [
            BoxShadow(
              color: chipColor.withOpacity(0.20),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ];

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = label),
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isSelected ? 1.0 : 0.55,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: chipColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: shadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    count.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockOverlay() {
    return BackdropFilter(
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
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              'Locked',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Tap to unlock',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF4B5563),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Short date without the year, e.g. "Sep 29"
  String _shortDate(DateTime date) {
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
    return '${months[date.month - 1]} ${date.day}';
  }

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

  void _showFilterBottomSheet() {
    final c = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        final sheetTheme = Theme.of(sheetCtx).copyWith(
          textTheme: GoogleFonts.interTextTheme(Theme.of(sheetCtx).textTheme),
          primaryTextTheme: GoogleFonts.interTextTheme(
            Theme.of(sheetCtx).primaryTextTheme,
          ),
        );
        return Theme(
          data: sheetTheme,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter & Sort',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFilterOption(
                  HugeIcons.strokeRoundedCalendar01,
                  'Sort by Date',
                ),
                _buildFilterOption(
                  HugeIcons.strokeRoundedTag01,
                  'Filter by Tag',
                ),
                _buildFilterOption(
                  HugeIcons.strokeRoundedColors,
                  'Filter by Color',
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(List<List<dynamic>> icon, String label) {
    final c = context.colors;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: HugeIcon(icon: icon, color: c.textSecondary, size: 22),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: c.textPrimary,
        ),
      ),
      trailing: HugeIcon(
        icon: HugeIcons.strokeRoundedArrowRight01,
        size: 18,
        color: c.textFaint,
      ),
      onTap: () => Navigator.pop(context),
    );
  }
}

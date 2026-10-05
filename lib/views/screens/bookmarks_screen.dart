import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'package:note_app/core/theme/app_colors.dart';
import 'package:note_app/viewmodels/providers.dart';
import 'package:note_app/views/widgets/note_grid_card.dart';
import 'package:note_app/views/widgets/profile_drawer.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final bookmarkedNotes = ref.watch(bookmarkedNotesProvider);
    final allNotes = ref.watch(notesProvider);
    final profile = ref.watch(profileProvider);

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: c.scaffold,
        drawer: ProfileDrawer(
          profile: profile,
          totalNotes: allNotes.length,
          pinnedNotes: ref.watch(pinnedNotesProvider).length,
          bookmarkNotes: bookmarkedNotes.length,
          selectedItem: 'Bookmark',
          onEditProfile: () {},
          onMenuItemTap: (label) {
            Navigator.of(context).pop();
            if (label == 'All notes' || label == 'Pinned') {
              Navigator.of(context).pop();
            }
          },
        ),
        appBar: AppBar(
          backgroundColor: c.scaffold,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: Builder(
            builder: (ctx) => IconButton(
              onPressed: () => Scaffold.of(ctx).openDrawer(),
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedMenu01,
                color: c.textPrimary,
                size: 24,
              ),
            ),
          ),
          title: Text(
            'Bookmark',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
        ),
        body: SafeArea(
          child: bookmarkedNotes.isEmpty
              ? _buildEmpty(c)
              : MasonryGridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  itemCount: bookmarkedNotes.length,
                  itemBuilder: (context, i) =>
                      NoteGridCard(note: bookmarkedNotes[i]),
                ),
        ),
      ),
    );
  }

  Widget _buildEmpty(AppColors c) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        HugeIcon(
          icon: HugeIcons.strokeRoundedBookmark02,
          size: 48,
          color: c.textFaint,
        ),
        const SizedBox(height: 12),
        Text(
          'No bookmarks yet',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tap the bookmark icon on a note to save it here.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 13, color: c.textMuted),
        ),
      ],
    ),
  );
}
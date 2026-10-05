import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:note_app/data/models/note.dart';
import 'package:note_app/data/models/user_profile.dart';

// ─── Notes State ────────────────────────────────────────────────────
class NotesNotifier extends Notifier<List<Note>> {
  @override
  List<Note> build() {
    // Read initial data from Hive
    final box = Hive.box<Note>('notes');
    return box.values.toList();
  }

  Future<void> saveNote(Note note) async {
    final box = Hive.box<Note>('notes');
    final index = state.indexWhere((n) => n.id == note.id);

    if (index != -1) {
      await box.putAt(index, note);
      state = [...state]..[index] = note;
    } else {
      await box.add(note);
      state = [...state, note];
    }
  }

  Future<void> deleteNote(String id) async {
    final box = Hive.box<Note>('notes');
    final index = state.indexWhere((n) => n.id == id);
    if (index != -1) {
      await box.deleteAt(index);
      state = state.where((n) => n.id != id).toList();
    }
  }

  /// Deletes many notes at once. Uses Hive keys (not indexes) so removing
  /// one note can never shift the position of the next one to delete.
  Future<void> deleteNotes(Set<String> ids) async {
    if (ids.isEmpty) return;
    final box = Hive.box<Note>('notes');
    final keys = box.keys.where((k) {
      final n = box.get(k);
      return n != null && ids.contains(n.id);
    }).toList();
    await box.deleteAll(keys);
    state = state.where((n) => !ids.contains(n.id)).toList();
  }

  Future<void> setPinned(String id, bool value) async {
    final index = state.indexWhere((n) => n.id == id);
    if (index == -1) return;
    await saveNote(state[index].copyWith(isPinned: value));
  }

  Future<void> setLocked(String id, bool value) async {
    final index = state.indexWhere((n) => n.id == id);
    if (index == -1) return;
    await saveNote(state[index].copyWith(isLocked: value));
  }

  Future<void> setBookmarked(String id, bool value) async {
    final index = state.indexWhere((n) => n.id == id);
    if (index == -1) return;
    await saveNote(state[index].copyWith(isBookmarked: value));
  }
}

final notesProvider = NotifierProvider<NotesNotifier, List<Note>>(
  NotesNotifier.new,
);

// Derived providers for Pinned and Bookmarked
final pinnedNotesProvider = Provider<List<Note>>((ref) {
  final notes = ref.watch(notesProvider);
  return notes.where((n) => n.isPinned).toList();
});

final bookmarkedNotesProvider = Provider<List<Note>>((ref) {
  final notes = ref.watch(notesProvider);
  return notes.where((n) => n.isBookmarked).toList();
});

// ─── Profile State ──────────────────────────────────────────────────
class ProfileNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() {
    final box = Hive.box<UserProfile>('profile');
    return box.get('current') ?? const UserProfile();
  }

  Future<void> updateProfile(UserProfile profile) async {
    final box = Hive.box<UserProfile>('profile');
    await box.put('current', profile);
    state = profile;
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, UserProfile>(
  ProfileNotifier.new,
);

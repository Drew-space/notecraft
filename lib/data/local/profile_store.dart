// lib/user/data/profile_store.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:note_app/data/models/user_profile.dart';

class ProfileStore {
  static const _key = 'user_profile_v1';

  Future<UserProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const UserProfile();
    try {
      return UserProfile.decode(raw);
    } catch (_) {
      return const UserProfile();
    }
  }

  Future<void> save(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, profile.encode());
  }
}

/// Single source of truth for the user profile, shared by header + drawer.
class ProfileController extends ChangeNotifier {
  ProfileController._();
  static final ProfileController instance = ProfileController._();

  final ProfileStore _store = ProfileStore();

  UserProfile _profile = const UserProfile();
  UserProfile get profile => _profile;

  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    _profile = await _store.load();
    _loaded = true;
    notifyListeners();
  }

  Future<void> update(UserProfile profile) async {
    _profile = profile;
    notifyListeners();
    await _store.save(profile);
  }
}

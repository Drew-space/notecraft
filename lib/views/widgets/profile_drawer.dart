// lib/views/widgets/profile_drawer.dart
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:note_app/core/theme/app_colors.dart';
import 'package:note_app/data/models/user_profile.dart';
import 'package:note_app/views/widgets/user_avatar.dart';
import 'package:note_app/views/screens/privacy_policy_screen.dart';

class ProfileDrawer extends StatelessWidget {
  final UserProfile profile;
  final int totalNotes;
  final int pinnedNotes;
  final int bookmarkNotes;
  final VoidCallback onEditProfile;
  final void Function(String label) onMenuItemTap;

  /// Which drawer row is currently active (e.g. 'All notes', 'Pinned', 'Bookmark').
  final String selectedItem;

  const ProfileDrawer({
    super.key,
    required this.profile,
    required this.totalNotes,
    required this.pinnedNotes,
    required this.bookmarkNotes,
    required this.onEditProfile,
    required this.onMenuItemTap,
    this.selectedItem = 'All notes',
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Drawer(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- Profile header (tap to edit) ----------
            InkWell(
              onTap: onEditProfile,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 16, 20),
                child: Row(
                  children: [
                    UserAvatar(profile: profile, size: 56),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Tap to edit profile',
                            style: TextStyle(fontSize: 12, color: c.textMuted),
                          ),
                        ],
                      ),
                    ),
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedEdit02,
                      size: 18,
                      color: c.textFaint,
                    ),
                  ],
                ),
              ),
            ),

            Divider(height: 1, color: c.divider),
            const SizedBox(height: 12),

            _DrawerItem(
              icon: HugeIcons.strokeRoundedNote01,
              label: 'All notes',
              count: totalNotes,
              isSelected: selectedItem == 'All notes',
              onTap: () => onMenuItemTap('All notes'),
            ),
            _DrawerItem(
              icon: HugeIcons.strokeRoundedPin,
              label: 'Pinned',
              count: pinnedNotes,
              isSelected: selectedItem == 'Pinned',
              onTap: () => onMenuItemTap('Pinned'),
            ),
            _DrawerItem(
              icon: HugeIcons.strokeRoundedBookmark02,
              label: 'Bookmark',
              count: bookmarkNotes,
              isSelected: selectedItem == 'Bookmark',
              onTap: () => onMenuItemTap('Bookmark'),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Divider(height: 1, color: c.divider),
            ),

            _DrawerItem(
              icon: HugeIcons.strokeRoundedShield01,
              label: 'Privacy Policy',
              isSelected: selectedItem == 'Privacy Policy',
              onTap: () {
                // 1. Notify the parent (if it needs to update selected state)
                onMenuItemTap('Privacy Policy');

                // 2. Close the drawer
                Navigator.pop(context);

                // 3. Navigate to the Privacy Policy screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyScreen(),
                  ),
                );
              },
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text(
                'NoteCraft',
                style: TextStyle(
                  fontSize: 11.5,
                  color: c.textPrimary.withOpacity(0.35),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final int? count;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    this.count,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected ? c.chipBg : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            child: Row(
              children: [
                HugeIcon(
                  icon: icon,
                  size: 21,
                  color: isSelected ? c.textPrimary : c.textMuted,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: c.textPrimary,
                    ),
                  ),
                ),
                if (count != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: c.chipBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: c.textMuted,
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
}

// lib/views/screens/privacy_policy_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  /// Bump this when you change the policy text.
  static const String _lastUpdated = 'September 2026';

  /// The public policy page. Change these two lines if the address changes.
  /// If your site needs the full file name, use
  /// 'https://ix-drew.vercel.app/Note-Craft/index.html' instead.
  static const String _portfolioUrl = 'https://ix-drew.vercel.app/Note-Craft/';

  /// Shown on screen (no https://).
  static const String _portfolioLabel = 'ix-drew.vercel.app/Note-Craft';

  Future<void> _openPortfolio(BuildContext context) async {
    final ok = await launchUrl(
      Uri.parse(_portfolioUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the link'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final interTheme = Theme.of(context).copyWith(
      textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      primaryTextTheme: GoogleFonts.interTextTheme(
        Theme.of(context).primaryTextTheme,
      ),
    );

    return Theme(
      data: interTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F6F6),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF6F6F6),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft02,
              color: Color(0xFF1A1A1A),
              size: 24,
            ),
          ),
          centerTitle: true,
          title: Text(
            'Privacy Policy',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const HugeIcon(
                          icon: HugeIcons.strokeRoundedShield01,
                          size: 20,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your privacy matters',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'This app is fully offline. We do not collect, '
                              'store, or share any of your personal data.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                height: 1.55,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Center(
                  child: Text(
                    'Last updated: $_lastUpdated',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF8C8B8E),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Sections ──────────────────────────────────────────
                const _Section(
                  title: '1. Information We Collect',
                  body:
                      'We do not collect any personal information. The app '
                      'does not require you to create an account, sign in, '
                      'or provide any personal details such as your name, '
                      'email, or phone number.',
                ),
                const _Section(
                  title: '2. Data Storage',
                  body:
                      'All notes, images, and preferences you create inside '
                      'the app are stored locally on your device only. '
                      'Nothing is uploaded to any server. If you uninstall '
                      'the app, that data is permanently removed from your '
                      'device.',
                ),
                const _Section(
                  title: '3. Internet Access',
                  body:
                      'The app works fully offline and your notes and images '
                      'never leave your device. When you are online, two '
                      'small features may connect to third-party services: '
                      'generated profile avatars may be requested from '
                      'DiceBear, and the app font may be downloaded from '
                      'Google Fonts. These requests go directly from your '
                      'device and may expose your IP address to those '
                      'services. They never include your notes or images.',
                ),
                const _Section(
                  title: '4. Permissions',
                  body:
                      'The app may request access to your camera or photo '
                      'library only when you choose to attach an image to a '
                      'note. These permissions are optional and used solely '
                      'for that purpose.',
                ),
                const _Section(
                  title: '5. Biometric / Device Lock',
                  body:
                      'If you enable the optional note lock feature, the app '
                      'uses your device\'s built-in authentication (fingerprint, '
                      'face, or PIN). Biometric data never leaves your device '
                      'and is handled entirely by your operating system.',
                ),
                const _Section(
                  title: '6. Third-Party Services',
                  body:
                      'The app does not use analytics, advertising, or '
                      'tracking services, and we never sell or share your '
                      'notes. The only third-party services involved are the '
                      'two described in section 3.',
                ),
                const _Section(
                  title: '7. Children\'s Privacy',
                  body:
                      'This app is not directed at children under the age of '
                      '13. We do not knowingly collect any information from '
                      'children.',
                ),
                const _Section(
                  title: '8. Changes to This Policy',
                  body:
                      'We may update this Privacy Policy from time to time. '
                      'Any changes will be reflected on this screen with an '
                      'updated "Last updated" date.',
                ),
                const _Section(
                  title: '9. Contact',
                  body:
                      'The full Privacy Policy and Terms of Use are available '
                      'online at the link below, along with the developer\'s '
                      'contact details.',
                ),

                // ── Portfolio link ────────────────────────────────────
                GestureDetector(
                  onTap: () => _openPortfolio(context),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.language,
                            size: 20,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Full policy and terms online',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _portfolioLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF2563EB),
                                  decoration: TextDecoration.underline,
                                  decorationColor: const Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.open_in_new,
                          size: 18,
                          color: Color(0xFF9CA3AF),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                Center(
                  child: Text(
                    'NoteCraft · offline',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: const Color(0xFF1A1A1A).withOpacity(0.35),
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

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              height: 1.7,
              color: const Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }
}

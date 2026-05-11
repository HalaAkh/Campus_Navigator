import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/rooms_service.dart';
import '../../utils/theme.dart';
import '../../utils/app_state.dart';
import '../../widgets/common/widgets.dart';
import '/services/beacon_service.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  final ValueChanged<int> onTabChange;
  final VoidCallback onSettings;
  final VoidCallback onSavedRooms;
  final VoidCallback onAbout;
  final VoidCallback onHelp;
  final VoidCallback onFeedback;
  final VoidCallback onSignOut;
  final ValueChanged<String> onNavigateToRoom;

  const ProfileScreen({
    super.key,
    required this.onTabChange,
    required this.onSettings,
    required this.onSavedRooms,
    required this.onAbout,
    required this.onHelp,
    required this.onFeedback,
    required this.onSignOut,
    required this.onNavigateToRoom,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showAllRecent = false;

  static const _primary = Color(0xFF007A6E);
  static const _text = Color(0xFF1C2B2A);
  static const _muted = Color(0xFF6B7B7A);
  static const _border = Color(0xFFE5EBEB);
  static const _bg = Color(0xFFF7FAFA);
  static const _contactEmail = 'hala.elakhrass@lau.edu';

  // EDIT PROFILE DIALOG
  void _showEditProfile(BuildContext context, AppState state) {
    final nameCtrl = TextEditingController(text: state.userName);
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool saving = false;
    String? inlineError;

    bool isPasswordComplex(String p) {
      return RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$')
          .hasMatch(p);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(9999)))),
                const SizedBox(height: 20),
                Text('Edit Profile', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: _text)),
                const SizedBox(height: 4),
                Text('Update your display name or change your password.',
                    style: GoogleFonts.poppins(fontSize: 12, color: _muted)),
                const SizedBox(height: 16),

                // inline error banner
                if (inlineError != null) ...[
                  _InlineErrorBanner(message: inlineError!),
                  const SizedBox(height: 14),
                ] else
                  const SizedBox(height: 8),

                // Display name
                Text('Display Name', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _text)),
                const SizedBox(height: 6),
                _buildTextField(nameCtrl, 'Your name', Icons.person_outline),
                const SizedBox(height: 24),

                Divider(color: _border),
                const SizedBox(height: 16),

                Text('Change Password', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _text)),
                const SizedBox(height: 4),
                Text('Leave blank to keep your current password.',
                    style: GoogleFonts.poppins(fontSize: 11, color: _muted)),
                const SizedBox(height: 14),

                Text('Current Password', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _text)),
                const SizedBox(height: 6),
                _buildPasswordField(ctx, currentPassCtrl, 'Current password',
                    obscureCurrent, () => setModal(() => obscureCurrent = !obscureCurrent)),
                const SizedBox(height: 12),

                Text('New Password', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _text)),
                const SizedBox(height: 6),
                _buildPasswordField(ctx, newPassCtrl, 'New password',
                    obscureNew, () => setModal(() => obscureNew = !obscureNew)),
                const SizedBox(height: 12),

                Text('Confirm New Password', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _text)),
                const SizedBox(height: 6),
                _buildPasswordField(ctx, confirmPassCtrl, 'Confirm new password',
                    obscureConfirm, () => setModal(() => obscureConfirm = !obscureConfirm)),
                const SizedBox(height: 28),

                Row(children: [
                  Expanded(child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _border, width: 1.5)),
                      child: Center(child: Text('Cancel',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _muted))),
                    ),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: GestureDetector(
                    onTap: () async {
                      // clear previous error
                      setModal(() => inlineError = null);

                      final newName = nameCtrl.text.trim();
                      final currentPass = currentPassCtrl.text;
                      final newPass = newPassCtrl.text;
                      final confirmPass = confirmPassCtrl.text;

                      final hasNameChange =
                          newName.isNotEmpty && newName != state.userName;
                      final typedNew = newPass.isNotEmpty;
                      final typedCurrent = currentPass.isNotEmpty;
                      final typedConfirm = confirmPass.isNotEmpty;

                      // Nothing changed
                      if (!hasNameChange && !typedNew && !typedCurrent && !typedConfirm) {
                        setModal(() => inlineError = 'No changes to save.');
                        return;
                      }

                      //  Password field cross-checks
                      // Entered new password but forgot current
                      if (typedNew && !typedCurrent) {
                        setModal(() => inlineError =
                        'Please enter your current password first.');
                        return;
                      }

                      // Entered current password but forgot new
                      if (typedCurrent && !typedNew) {
                        setModal(() => inlineError =
                        'Please enter a new password.');
                        return;
                      }

                      // Entered new but forgot confirmation
                      if (typedNew && !typedConfirm) {
                        setModal(() => inlineError =
                        'Please confirm your new password.');
                        return;
                      }

                      if (typedNew) {
                        // Same as current
                        if (newPass == currentPass) {
                          setModal(() => inlineError =
                          'New password must be different from your current password.');
                          return;
                        }

                        if (!isPasswordComplex(newPass)) {
                          setModal(() => inlineError =
                          'Password must be at least 8 characters and include an uppercase letter, a lowercase letter, a number, and a special character (!@#\$&*~).');
                          return;
                        }

                        // Confirmation mismatch
                        if (newPass != confirmPass) {
                          setModal(() => inlineError =
                          'New passwords do not match. Please re-enter.');
                          return;
                        }
                      }

                      //  Save
                      setModal(() { saving = true; inlineError = null; });
                      try {
                        if (hasNameChange) {
                          await state.updateUserName(newName);
                        }
                        if (typedNew) {
                          await state.updatePassword(currentPass, newPass);
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Profile updated successfully.',
                              style: GoogleFonts.poppins(fontSize: 13)),
                          backgroundColor: _primary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ));
                      } catch (e) {
                        setModal(() {
                          saving = false;
                          inlineError = e.toString().replaceFirst('Exception: ', '');
                        });
                      }
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                          color: _primary, borderRadius: BorderRadius.circular(12)),
                      child: Center(
                        child: saving
                            ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                            : Text('Save Changes',
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ),
                  )),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon) {
    return Container(
      decoration: BoxDecoration(
          color: const Color(0xFFF7FAFA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5EBEB))),
      child: TextField(
        controller: ctrl,
        style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1C2B2A)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF6B7B7A)),
          prefixIcon: Icon(icon, size: 18, color: const Color(0xFF007A6E)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  static Widget _buildPasswordField(BuildContext context,
      TextEditingController ctrl, String hint, bool obscure, VoidCallback toggle) {
    return Container(
      decoration: BoxDecoration(
          color: const Color(0xFFF7FAFA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5EBEB))),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1C2B2A)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF6B7B7A)),
          prefixIcon: const Icon(Icons.lock_outline, size: 18, color: Color(0xFF007A6E)),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18, color: const Color(0xFF6B7B7A)),
            onPressed: toggle,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ABOUT SHEET
  void _showAbout(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.78,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          Center(child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(9999)))),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Logo row
              Row(children: [
                Container(
                  width: 52, height: 52,
                  child: Center(child: Image.asset('assets/images/pin1.png',
                      width: 28, height: 35,
                      errorBuilder: (_, __, ___) =>
                      const Icon(Icons.explore, color: Colors.white, size: 35))),
                ),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Campus Navigator',
                      style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: _text)),
                  Text('Version 1  ·  LAU Beirut',
                      style: GoogleFonts.poppins(fontSize: 12, color: _muted)),
                ]),
              ]),
              const SizedBox(height: 24),

              _aboutSection('What is Campus Navigator?',
                  'Campus Navigator is a real-time indoor navigation app built for LAU campus. It helps anyone with a valid LAU email locate and navigate to any room, office, or facility within campus buildings, quickly and effortlessly.'),

              _aboutSection('How does it work?',
                  'The app uses MOKO SMART Bluetooth Low Energy (BLE) beacons installed throughout the building to determine your live position indoors. Once your location is detected, an AI-powered engine generates accurate, step-by-step walking directions directly to your destination.'),

              _aboutSection('Key Features',
                  '• Live indoor positioning via BLE beacons\n• AI-generated turn-by-turn directions\n• Voice guidance (text-to-speech)\n• Floor-by-floor map with room labels\n• Save and share favorite rooms\n• Navigation history\n• Cross-floor routing via stairs or elevator'),

              _aboutSection('Coverage',
                  'Currently covering Floors 4 and 5 of the Nicol Hall, LAU Beirut, with 57 rooms and 6 BLE beacons. Expansion to additional buildings and floors is planned for future versions.'),

              _aboutSection('Technology',
                  'Built with Flutter for cross-platform support. Powered by Firebase for real-time data, OpenAI GPT-4o-mini for intelligent routing, and the flutter_blue_plus package for Bluetooth beacon scanning.'),

              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFFF0FAF7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border)),
                child: Row(children: [
                  const Icon(Icons.school_outlined, color: _primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Developed at LAU Beirut',
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _text)),
                    Text('Nicol Hall, Beirut, Lebanon',
                        style: GoogleFonts.poppins(fontSize: 11, color: _muted)),
                  ])),
                ]),
              ),
            ]),
          )),
        ]),
      ),
    );
  }

  static Widget _aboutSection(String title, String body) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _primary)),
      const SizedBox(height: 6),
      Text(body, style: GoogleFonts.poppins(fontSize: 13, color: _text, height: 1.6)),
    ]),
  );

  //  HELP & FAQ SHEET
  void _showHelp(BuildContext context) {
    final sections = [
    _FAQSection('Getting Started', [
      _FAQ('What is Campus Navigator?',
          'Campus Navigator v1 is a free indoor navigation app for LAU campus. It guides you step-by-step to any room, office, lab, or facility inside Nicol Hall, Floors 4 and 5, using MOKO SMART Bluetooth Low Energy beacons and OpenAI.'),
      _FAQ('Who can use the app?',
          'Anyone with a valid LAU email address can use the app. Simply create an account with your LAU email and you are ready to go.'),
      _FAQ('Which buildings and floors are covered?',
          'Currently Floors 4 and 5 of Nicol Hall, LAU Beirut campus, with a total of 57 rooms. More buildings and floors are planned for future updates.'),
      _FAQ('Do I need internet to navigate?',
          'Yes, a connection is required when you first start navigation; the app contacts OpenAI engine to generate your route. Once the route is loaded, you can follow it offline.'),
    ]),
    _FAQSection('Navigation', [
    _FAQ('How do I navigate to a room?',
    'Tap the Navigate tab at the bottom, search for your destination by room number or name, then tap Start Navigation. The app will detect your position and guide you with turn-by-turn directions and voice guidance.'),
    _FAQ('Can the app guide me between floors?',
    'Yes. If your destination is on a different floor, Campus Navigator automatically routes you to the nearest stairs or elevator, tells you to change floors, then continues guiding you on the new floor.'),
    _FAQ('What does the dotted line on the map mean?',
    'The solid line shows the path you have already walked. The dotted line shows the remaining route ahead of you.'),
    _FAQ('What happens if I take a wrong turn?',
    'After a short period without matching any expected beacon, the app shows an Off Route alert and offers to recalculate your route from your current position.'),
    _FAQ('How do I know when I have arrived?',
    'The app shows a green "You\'ve Arrived" screen with your final instruction and plays a voice confirmation. Tap Done to finish, or New Destination to navigate somewhere else.'),
    ]),
    _FAQSection('Location & Bluetooth', [
    _FAQ('Why does the app need Bluetooth?',
    'Campus Navigator uses MOKO SMART Bluetooth Low Energy beacons installed in the building to determine your indoor position. Without Bluetooth, the app cannot detect where you are and cannot guide you.'),
    _FAQ('Why does the app need location permission?',
    'On both Android and iOS, the operating system requires location permission to scan for Bluetooth devices, even though the app does not use GPS or track your location outside the building. The permission is needed purely to detect which beacon is closest to you so the app can guide you to your destination. Your location data never leaves your device and is not stored or shared.'),
    ]),
    _FAQSection('Saved Rooms & History', [
    _FAQ('How do I save a room?',
    'On the Home map, tap any category chip (Labs, Offices, Toilets, etc.) to open the room list, then tap the bookmark icon on any room card. Saved rooms appear in the Saved tab and on your Profile.'),
    _FAQ('How do I remove a saved room?',
    'Go to the Saved tab and tap Remove on the room you want to delete. Changes sync to your account automatically.'),
    _FAQ('Where can I see my navigation history?',
    'Your last navigations appear in the Recent section on your Profile screen. Tap any item to navigate there again directly.'),
    ]),
    _FAQSection('Account', [
    _FAQ('How do I change my display name?',
    'Go to Profile → Edit Profile, update the Display Name field, and tap Save Changes.'),
    _FAQ('How do I change my password?',
    'Go to Profile → Edit Profile, fill in your current password and your new password (at least 8 characters with uppercase, lowercase, number, and special character), then tap Save Changes.'),
    _FAQ('I forgot my password. What do I do?',
    'On the Sign In screen, tap "Forgot Password?" and enter your LAU email. A reset link will be sent to your inbox. Check your spam folder if you do not see it within a few minutes.'),
    ]),
    ];

    showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
    height: MediaQuery.of(context).size.height * 0.90,
    decoration: const BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    child: Column(children: [
    const SizedBox(height: 12),
    Center(child: Container(
    width: 36, height: 4,
    decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(9999)))),
    Padding(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Help & FAQ',
    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: _text)),
    Text('Everything you need to know about Campus Navigator.',
    style: GoogleFonts.poppins(fontSize: 12, color: _muted)),
    ]),
    ),
    Divider(height: 1, color: _border),
    Expanded(child: ListView.builder(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
    itemCount: sections.length,
    itemBuilder: (_, si) {
    final section = sections[si];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    if (si > 0) const SizedBox(height: 24),
    Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
    color: const Color(0xFFF0FAF7),
    borderRadius: BorderRadius.circular(9999),
    border: Border.all(color: _border),
    ),
    child: Text(section.title,
    style: GoogleFonts.poppins(
    fontSize: 12, fontWeight: FontWeight.w700, color: _primary)),
    ),
    ...section.faqs.asMap().entries.map((e) => Padding(
    padding: EdgeInsets.only(bottom: e.key < section.faqs.length - 1 ? 8 : 0),
    child: _FAQTile(faq: e.value),
    )),
    ]);
    },
    )),
    ]),
    ),
    );
  }
  //  FEEDBACK SHEET
  void _showFeedback(BuildContext context) {
    String? selectedType;
    final msgCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String? inlineError;

    final types = [
      _FeedbackType('Bug Report', 'Something isn\'t working correctly'),
      _FeedbackType('Feature Request', 'I have an idea for improvement'),
      _FeedbackType( 'Map / Route Issue', 'Directions or map are inaccurate'),
      _FeedbackType('General Feedback', 'Share your overall experience'),
      _FeedbackType( 'Compliment', 'Something I really loved'),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.88,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(children: [
              const SizedBox(height: 12),
              Center(child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(9999)))),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Send Feedback', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: _text)),
                    Text('Your input helps us improve Campus Navigator.',
                        style: GoogleFonts.poppins(fontSize: 12, color: _muted)),
                  ]),
                ]),
              ),
              Divider(height: 24, color: _border),
              Expanded(child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  if (inlineError != null) ...[
                    _InlineErrorBanner(message: inlineError!),
                    const SizedBox(height: 20),
                  ],

                  Text('Feedback Type',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _text)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: types.map((t) {
                      final selected = selectedType == t.label;
                      return GestureDetector(
                        onTap: () => setModal(() => { selectedType = t.label, inlineError = null }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? _primary : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: selected ? _primary : _border,
                                width: selected ? 1.5 : 1),
                            boxShadow: selected ? [BoxShadow(
                                color: _primary.withValues(alpha: 0.2),
                                blurRadius: 6, offset: const Offset(0, 2))] : [],
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const SizedBox(width: 6),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(t.label, style: GoogleFonts.poppins(
                                  fontSize: 12, fontWeight: FontWeight.w600,
                                  color: selected ? Colors.white : _text)),
                              Text(t.subtitle, style: GoogleFonts.poppins(
                                  fontSize: 9, color: selected
                                  ? Colors.white.withValues(alpha: 0.8) : _muted)),
                            ]),
                          ]),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  Text('Message',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _text)),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                        color: const Color(0xFFF7FAFA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border)),
                    child: TextField(
                      controller: msgCtrl,
                      maxLines: 5,
                      onChanged: (_) { if (inlineError != null) setModal(() => inlineError = null); },
                      style: GoogleFonts.poppins(fontSize: 13, color: _text),
                      decoration: InputDecoration(
                        hintText: 'Describe your feedback in detail...',
                        hintStyle: GoogleFonts.poppins(fontSize: 13, color: _muted),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.send_outlined, size: 12, color: _muted),
                    const SizedBox(width: 4),
                    Text('Will be sent to $_contactEmail',
                        style: GoogleFonts.poppins(fontSize: 10, color: _muted)),
                  ]),
                  const SizedBox(height: 28),

                  GestureDetector(
                    onTap: () {
                      if (selectedType == null) {
                        setModal(() => inlineError = 'Please select a feedback type.');
                        return;
                      }
                      if (msgCtrl.text.trim().isEmpty) {
                        setModal(() => inlineError = 'Please write a message.');
                        return;
                      }
                      _launchEmail(
                        to: _contactEmail,
                        subject: 'Campus Navigator Feedback | $selectedType',
                        body: '\n'
                            '${msgCtrl.text.trim()}\n\n'
                            '---\nSent from Campus Navigator App v1',
                      );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Opening email to send your feedback...',
                            style: GoogleFonts.poppins(fontSize: 13)),
                        backgroundColor: _primary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ));
                    },
                    child: Container(
                      width: double.infinity, height: 52,
                      decoration: BoxDecoration(
                          color: _primary, borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(
                              color: _primary.withValues(alpha: 0.3),
                              blurRadius: 10, offset: const Offset(0, 4))]),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text('Send Feedback',
                            style: GoogleFonts.poppins(
                                fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                      ]),
                    ),
                  ),
                ]),
              )),
            ]),
          ),
        ),
      ),
    );
  }

  // CONTACT US SHEET
  void _showContact(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(9999)))),
          const SizedBox(height: 20),
          Text('Contact Us', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: _text)),
          const SizedBox(height: 4),
          Text('We\'d love to hear from you!',
              style: GoogleFonts.poppins(fontSize: 12, color: _muted)),
          const SizedBox(height: 24),

          _contactTile(
            context,
            icon: Icons.mail_outline_rounded,
            label: 'Email Us',
            subtitle: _contactEmail,
            color: _primary,
            onTap: () => _launchEmail(
                to: _contactEmail,
                subject: 'Campus Navigator | Inquiry',
                body: 'Hello,\n\n'),
          ),

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A))),
            child: Row(children: [
              const Icon(Icons.schedule_outlined, size: 16, color: Color(0xFFF59E0B)),
              const SizedBox(width: 10),
              Expanded(child: Text(
                  'Response time is typically within 1–2 business days.',
                  style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF92400E)))),
            ]),
          ),
        ]),
      ),
    );
  }

  static Widget _contactTile(BuildContext context, {
    required IconData icon, required String label, required String subtitle,
    required Color color, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5EBEB)),
            boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6)]),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1C2B2A))),
            Text(subtitle, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF6B7B7A))),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
        ]),
      ),
    );
  }

  // EMAIL LAUNCHER
  static Future<void> _launchEmail({
    required String to,
    required String subject,
    required String body,
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: to,
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final beacon = context.watch<BeaconService>().currentBeacon;
    final initials = state.userName.isNotEmpty
        ? state.userName.split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : 'U';
    final isProf = state.userEmail.endsWith('@lau.edu.lb');
    final isStudent = state.userEmail.endsWith('@lau.edu');
    final badgeLabel = isProf ? 'LAU Professor' : isStudent ? 'LAU Student' : 'LAU Member';
    final badgeColor = isProf ? const Color(0xFF1A56A0) : _primary;

    final menuItems = [
      _MenuItem(
        icon: Icons.person_outline_rounded,
        label: 'Edit Profile',
        onTap: () => _showEditProfile(context, state),
      ),
      _MenuItem(
        icon: Icons.info_outline_rounded,
        label: 'About',
        onTap: () => _showAbout(context),
      ),
      _MenuItem(
        icon: Icons.help_outline_rounded,
        label: 'Help & FAQ',
        onTap: () => _showHelp(context),
      ),
      _MenuItem(
        icon: Icons.mail_outline_rounded,
        label: 'Contact Us',
        onTap: () => _showContact(context),
      ),
      _MenuItem(
        icon: Icons.chat_bubble_outline_rounded,
        label: 'Send Feedback',
        onTap: () => _showFeedback(context),
      ),
    ];

    return Scaffold(
      backgroundColor: _bg,
      body: Column(children: [
        Expanded(child: SingleChildScrollView(child: Column(children: [

          // HEADER BANNER
          Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
            Container(
              height: 150,
              width: double.infinity,
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient2),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 20, right: 20,
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Image.asset('assets/images/pin1.png', width: 28, height: 28,
                    errorBuilder: (_, __, ___) =>
                    const Icon(Icons.explore, color: Colors.white, size: 28)),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(state.userName,
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text(state.userEmail,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.white.withValues(alpha: 0.75))),
                ]),
              ]),
            ),
            Positioned(bottom: -36, child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: Colors.white, shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10), blurRadius: 12)],
              ),
              child: Center(child: Text(initials,
                  style: GoogleFonts.poppins(
                      fontSize: 22, fontWeight: FontWeight.w800, color: _primary))),
            )),
          ]),

          const SizedBox(height: 50),

          // LAU badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
                color: badgeColor, borderRadius: BorderRadius.circular(9999)),
            child: Text(badgeLabel,
                style: GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
          const SizedBox(height: 20),

          // STATS ROW
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              _StatTile(value: '${state.navigationCount}', label: 'Navigations'),
              const SizedBox(width: 10),
              _StatTile(value: '${state.savedRooms.length}', label: 'Saved'),
              const SizedBox(width: 10),
              _StatTile(
                value: beacon != null ? 'F${beacon.floor}' : '--',
                label: 'Position',
                isLive: beacon != null,
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // SAVED ROOMS PREVIEW
          if (state.savedRooms.isNotEmpty) ...[
            _SectionHeader(title: 'Saved Rooms', actionLabel: 'See all', onAction: () => widget.onTabChange(2)),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: state.savedRooms.take(5).length,
                itemBuilder: (context, i) {
                  final room = state.savedRooms[i];
                  return GestureDetector(
                    onTap: () => widget.onNavigateToRoom(room.number),
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _border),
                        boxShadow: [BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                              color: _primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.bookmark_rounded, color: _primary, size: 18),
                        ),
                        const SizedBox(height: 6),
                        Text(room.number, style: GoogleFonts.poppins(
                            fontSize: 11, fontWeight: FontWeight.w700, color: _text)),
                      ]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],

          // RECENT NAVIGATIONS
          if (state.navigationHistory.isNotEmpty) ...[
            _SectionHeader(
              title: 'Recent',
              actionLabel: _showAllRecent ? 'Show less' : 'See all',
              onAction: () => setState(() => _showAllRecent = !_showAllRecent),
            ),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: state.navigationHistory
                    .take(_showAllRecent ? state.navigationHistory.length : 3)
                    .map((roomNum) {
                  final room = RoomsService().getRoomByNumber(roomNum);
                  return GestureDetector(
                    onTap: () => widget.onNavigateToRoom(roomNum),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: Row(children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                              color: _primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.history_rounded, color: _primary, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(room?.name ?? 'Room $roomNum',
                              style: GoogleFonts.poppins(
                                  fontSize: 13, fontWeight: FontWeight.w500, color: _text)),
                          Text('Room $roomNum · Floor ${room?.floor ?? (roomNum.startsWith("5") ? 5 : 4)}',
                              style: GoogleFonts.poppins(fontSize: 11, color: _muted)),
                        ])),
                        const Icon(Icons.navigation_rounded, color: _primary, size: 16),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // MENU
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: menuItems.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  return Column(children: [
                    GestureDetector(
                      onTap: item.onTap,
                      child: Container(
                        color: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(children: [
                          Icon(item.icon, size: 18, color: _primary),
                          const SizedBox(width: 12),
                          Expanded(child: Text(item.label, style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w500, color: _text))),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: _muted),
                        ]),
                      ),
                    ),
                    if (i < menuItems.length - 1)
                      Divider(height: 1, color: _border, indent: 46),
                  ]);
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sign out
          TextButton.icon(
            onPressed: widget.onSignOut,
            icon: const Icon(Icons.logout_rounded, size: 16, color: Colors.redAccent),
            label: Text('Sign Out', style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w500, color: Colors.redAccent)),
          ),
          const SizedBox(height: 6),
          Text('Campus Navigator · v1',
              style: GoogleFonts.poppins(
                  fontSize: 10, color: _muted.withValues(alpha: 0.6))),
          const SizedBox(height: 80),
        ]))),
      ]),

      bottomNavigationBar: AppBottomTabBar(currentIndex: 3, onTap: (i) {
        if (i == 0) widget.onTabChange(0);
        if (i == 1) widget.onTabChange(1);
        if (i == 2) widget.onTabChange(2);
      }),
    );
  }
}

// SECTION HEADER
class _SectionHeader extends StatelessWidget {
  final String title, actionLabel;
  final VoidCallback onAction;
  const _SectionHeader(
      {required this.title, required this.actionLabel, required this.onAction});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
    child: Row(children: [
      Text(title, style: GoogleFonts.poppins(
          fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1C2B2A))),
      const Spacer(),
      if (actionLabel.isNotEmpty)
        GestureDetector(
          onTap: onAction,
          child: Text(actionLabel, style: GoogleFonts.poppins(
              fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF007A6E))),
        ),
    ]),
  );
}

// STAT TILE
class _StatTile extends StatelessWidget {
  final String value, label;
  final bool isLive;
  const _StatTile({required this.value, required this.label, this.isLive = false});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5EBEB)),
      ),
      child: Column(children: [
        if (isLive)
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 6, height: 6,
                decoration: const BoxDecoration(
                    color: Color(0xFF10B981), shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(value, style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF007A6E))),
          ])
        else
          Text(value, style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1C2B2A))),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.poppins(
            fontSize: 9, color: const Color(0xFF6B7B7A)), textAlign: TextAlign.center),
      ]),
    ),
  );
}

// INLINE ERROR BANNER
class _InlineErrorBanner extends StatelessWidget {
  final String message;
  const _InlineErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(message,
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFFB91C1C)))),
      ]),
    );
  }
}

// DATA MODELS
class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.label, required this.onTap});
}

class _FAQ {
  final String question, answer;
  const _FAQ(this.question, this.answer);
}

class _FAQSection {
  final String title;
  final List<_FAQ> faqs;
  const _FAQSection(this.title, this.faqs);
}

class _FeedbackType {
  final String  label, subtitle;
  const _FeedbackType(this.label, this.subtitle);
}

// FAQ TILE
class _FAQTile extends StatefulWidget {
  final _FAQ faq;
  const _FAQTile({required this.faq});

  @override
  State<_FAQTile> createState() => _FAQTileState();
}

class _FAQTileState extends State<_FAQTile> {
  bool _open = false;

  static const _primary = Color(0xFF007A6E);
  static const _text = Color(0xFF1C2B2A);
  static const _muted = Color(0xFF6B7B7A);
  static const _border = Color(0xFFE5EBEB);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => _open = !_open),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _open ? const Color(0xFFF0FAF7) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _open ? _primary.withValues(alpha: 0.3) : _border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
                color: _open ? _primary : _border.withValues(alpha: 0.5),
                shape: BoxShape.circle),
            child: Icon(
                _open ? Icons.remove_rounded : Icons.add_rounded,
                color: _open ? Colors.white : _muted, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(widget.faq.question,
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _text))),
        ]),
        if (_open) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 38),
            child: Text(widget.faq.answer,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: _muted, height: 1.6)),
          ),
        ],
      ]),
    ),
  );
}
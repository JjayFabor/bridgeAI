import 'package:bridgeai/features/frontend/pages/settings_page/change_password.dart';
import 'package:bridgeai/features/frontend/pages/settings_page/contact_support.dart';
import 'package:bridgeai/features/frontend/pages/settings_page/deactivate_account.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'delete_account.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  bool _pushNotificationsEnabled = true;
  bool _emailNotificationsEnabled = true;
  bool _smsNotificationsEnabled = true;
  final String _textSize = 'Medium';
  final String _colorContrast = 'Normal';
  final String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          ListTile(
            title: Text(
              'Profile Settings',
              style: GoogleFonts.cormorant(
                textStyle: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Profile'),
            onTap: () {
              // Navigate to Edit Profile Page
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Change Password'),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ChangePasswordPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Account Privacy'),
            onTap: () {
              // Navigate to Account Privacy Settings Page
            },
          ),
          const Divider(),
          ListTile(
            title: Text(
              'Notification Settings',
              style: GoogleFonts.cormorant(
                textStyle: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Push Notifications'),
            value: _pushNotificationsEnabled,
            onChanged: (bool value) {
              setState(() {
                _pushNotificationsEnabled = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Email Notifications'),
            value: _emailNotificationsEnabled,
            onChanged: (bool value) {
              setState(() {
                _emailNotificationsEnabled = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('SMS Notifications'),
            value: _smsNotificationsEnabled,
            onChanged: (bool value) {
              setState(() {
                _smsNotificationsEnabled = value;
              });
            },
          ),
          const Divider(),
          ListTile(
            title: Text(
              'Accessibility Settings',
              style: GoogleFonts.cormorant(
                textStyle: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ListTile(
            title: const Text('Text Size'),
            subtitle: Text(_textSize),
            onTap: () {
              // Navigate to Text Size Selection Page
            },
          ),
          ListTile(
            title: const Text('Color Contrast'),
            subtitle: Text(_colorContrast),
            onTap: () {
              // Navigate to Color Contrast Selection Page
            },
          ),
          SwitchListTile(
            title: const Text('Text-to-Speech'),
            value: false, // Set initial value
            onChanged: (bool value) {
              setState(() {
                // Handle Text-to-Speech toggle
              });
            },
          ),
          const Divider(),
          ListTile(
            title: Text(
              'Account Management',
              style: GoogleFonts.cormorant(
                textStyle: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Deactivate Account'),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DeactivateAccountPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('Delete Account'),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DeleteAccountPage()));
            },
          ),
          const Divider(),
          ListTile(
            title: Text(
              'Support and Feedback',
              style: GoogleFonts.cormorant(
                textStyle: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.support),
            title: const Text('Contact Support'),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ContactSupportPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.report),
            title: const Text('Report a Problem'),
            onTap: () {
              // Navigate to Report a Problem Page
            },
          ),
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('Submit Feedback'),
            onTap: () {
              // Navigate to Submit Feedback Page
            },
          ),
          const Divider(),
          ListTile(
            title: Text(
              'App Preferences',
              style: GoogleFonts.cormorant(
                textStyle: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ListTile(
            title: const Text('Language'),
            subtitle: Text(_language),
            onTap: () {
              // Navigate to App Language Selection Page
            },
          ),
        ],
      ),
    );
  }
}

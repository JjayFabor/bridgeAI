import 'package:bridgeai/features/frontend/pages/dashboard_page/homepage_dashboard.dart';
import 'package:bridgeai/features/frontend/pages/login_page/login_screen.dart';
import 'package:bridgeai/features/frontend/pages/profile_page/profile_page.dart';
import 'package:bridgeai/features/frontend/pages/profile_page/progress_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../global/provider_implementation/user_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late User? _user;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? profileData =
        Provider.of<UserProvider>(context).profileData;
    String? userId = _user?.uid; // Assuming you can retrieve userId from _user

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: Text(
          getTitle(),
          style: GoogleFonts.cormorant(
            textStyle: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.grey[900], // Dark background color
          child: Column(
            children: <Widget>[
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.blueAccent,
                ),
                accountName: Text(
                  profileData?['username'] ?? 'User Name',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                accountEmail: Text(
                  profileData?['email'] ?? 'user@example.com',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: profileData?['profile_picture'] != null
                      ? NetworkImage(profileData!['profile_picture'])
                      : null,
                  child: profileData?['profile_picture'] == null
                      ? const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home, color: Colors.white),
                title:
                    const Text('Home', style: TextStyle(color: Colors.white)),
                onTap: () {
                  setState(() {
                    _page = 0;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.white),
                title: const Text('Profile',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  setState(() {
                    _page = 2;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.assessment, color: Colors.white),
                title: const Text('Progress',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProgressPage(userId: userId ?? ''),
                    ),
                  );
                },
              ),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.white),
                title: const Text('Settings',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  // Add the desired functionality here
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.white),
                title:
                    const Text('Logout', style: TextStyle(color: Colors.white)),
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
      body: Container(child: getSelectedWidget(index: _page)),
    );
  }

  String getTitle() {
    switch (_page) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Search';
      case 2:
        return 'Profile';
      default:
        return 'Dashboard';
    }
  }

  Widget getSelectedWidget({required int index}) {
    Widget widget;
    switch (index) {
      case 0:
        widget = const HomepageDashboard();
        break;
      case 1:
        widget = const Text("Search");
        break;
      case 2:
        widget = const ProfilePage();
        break;
      default:
        widget = const HomepageDashboard();
        break;
    }
    return widget;
  }
}

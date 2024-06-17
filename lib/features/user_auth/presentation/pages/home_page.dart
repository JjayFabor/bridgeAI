import 'package:bridgeai/features/user_auth/presentation/pages/homepage_dashboard.dart';
import 'package:bridgeai/features/user_auth/presentation/pages/profile_page.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.blueAccent,
        bottomNavigationBar: CurvedNavigationBar(
          backgroundColor: Colors.blueAccent,
          animationDuration: const Duration(milliseconds: 300),
          items: const <Widget>[
            Icon(Icons.home, size: 35),
            Icon(Icons.search, size: 35),
            Icon(Icons.person, size: 35),
          ],
          index: _page,
          onTap: (selectedindex) {
            // Handle buttons tap
            setState(() {
              _page = selectedindex;
            });
          },
        ),
        body: Container(child: getSelectedWidget(index: _page)));
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

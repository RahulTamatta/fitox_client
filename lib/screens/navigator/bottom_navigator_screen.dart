import 'package:fit_talk/screens/home/home_screen.dart';
import 'package:fit_talk/screens/tools/tools_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../themes/app_theme.dart';
import '../chat/chats_list_screen.dart';
import '../community /community_screen.dart';

class BottomNavigatorScreen extends StatefulWidget {
  const BottomNavigatorScreen({super.key});

  @override
  State<BottomNavigatorScreen> createState() => _BottomNavigatorScreenState();
}

class _BottomNavigatorScreenState extends State<BottomNavigatorScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;
  late final List<BottomNavigationBarItem> _bottomItems;

  @override
  void initState() {
    super.initState();
    _initializeScreens();
    _initializeBottomItems();
  }

  void _initializeScreens() {
    _screens = [
      const HomeScreen(),
      const ChatListScreen(),
      const ToolsScreen(),
      const CommunityScreen(),
    ];
  }

  void _initializeBottomItems() {
    _bottomItems = [
      BottomNavigationBarItem(
        icon: _buildAnimatedIcon(Icons.dashboard_rounded, 0),
        activeIcon: _buildActiveIcon(Icons.dashboard_rounded, 0),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: _buildAnimatedIcon(Icons.message_rounded, 1),
        activeIcon: _buildActiveIcon(Icons.message_rounded, 1),
        label: 'Chat',
      ),
      BottomNavigationBarItem(
        icon: _buildAnimatedIcon(Icons.extension_rounded, 2),
        activeIcon: _buildActiveIcon(Icons.extension_rounded, 2),
        label: 'Tools',
      ),
      BottomNavigationBarItem(
        icon: _buildAnimatedIcon(Icons.people_alt_rounded, 3),
        activeIcon: _buildActiveIcon(Icons.people_alt_rounded, 3),
        label: 'Community',
      ),
    ];
  }

  Widget _buildAnimatedIcon(IconData icon, int index) {
    return Icon(icon, size: _selectedIndex == index ? 24 : 22);
  }

  Widget _buildActiveIcon(IconData icon, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, size: 24, color: AppTheme.primaryColor),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: BottomNavigationBar(
          items: _bottomItems,
          currentIndex: _selectedIndex,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.grey.shade500,
          selectedLabelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),
    );
  }
}

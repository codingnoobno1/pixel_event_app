import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../events/event_list_screen.dart';
import '../profile/profile_screen.dart';
import 'tabs/event_mode_tab.dart';
import '../../widgets/widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    EventListScreen(),
    EventModeTab(), // 4th tab added here
    Scaffold(backgroundColor: Colors.transparent, body: Center(child: Text("Passes Area", style: TextStyle(color: Colors.white)))),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    const cyan = Color(0xFF00FFFF);
    const pink = Color(0xFFFF2E88);
    const bg = Color(0xFF0B0B0F);

    return Scaffold(
      backgroundColor: bg,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: cyan.withOpacity(0.3), width: 1),
                boxShadow: [
                  BoxShadow(color: cyan.withOpacity(0.2), blurRadius: 10),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset("assets/images/app_icon.jpg", height: 32, width: 32),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "PIXEL_VAULT",
              style: GoogleFonts.jetBrainsMono(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: cyan),
            onPressed: () {},
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Stack(
        children: [
          // Background Depth Glows
          Positioned(
            top: -100,
            right: -50,
            child: _buildGlowCircle(pink.withOpacity(0.05), 300),
          ),
          _screens[_selectedIndex],
        ],
      ),
      bottomNavigationBar: _buildFloatingNavBar(),
    );
  }

  Widget _buildGlowCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 50)],
      ),
    );
  }

  Widget _buildFloatingNavBar() {
    const cyan = Color(0xFF00FFFF);
    return Container(
      height: 70,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 30),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cyan.withOpacity(0.1), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.grid_view_rounded, "EXPLORE"),
                _navItem(1, Icons.sensors_rounded, "LIVE"),
                _navItem(2, Icons.confirmation_number_rounded, "PASSES"),
                _navItem(3, Icons.person_rounded, "PROFILE"),
              ],
            ),
          ),
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 800.ms, curve: Curves.easeOutQuint);
  }

  Widget _navItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    const cyan = Color(0xFF00FFFF);
    
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? cyan.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isSelected ? cyan : Colors.white38,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              color: isSelected ? cyan : Colors.white38,
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

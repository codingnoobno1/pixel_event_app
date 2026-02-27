import 'package:flutter/material.dart';
import '../events/event_list_screen.dart';
import '../profile/my_passes_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    EventListScreen(),
    MyPassesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    const pink = Color(0xFFFF2E88);
    const bg = Color(0xFF0B0B0F);
    const card = Color(0xFF15151F);

    return Scaffold(
      backgroundColor: bg,

      // 🔥 APP BAR CYBER STYLE
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 12),

            // pixel logo
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                "assets/images/app_icon.jpg",
                height: 36,
                width: 36,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(width: 12),

            const Text(
              "PIXEL EVENTS",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontSize: 18,
              ),
            )
          ],
        ),
      ),

      // 🔥 BODY
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0B0B0F),
              Color(0xFF090912),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _screens[_selectedIndex],
      ),

      // 🔥 CYBER BOTTOM NAV
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: pink.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 1,
            )
          ],
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
          },
          indicatorColor: pink.withOpacity(0.2),
          labelBehavior:
              NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.event_outlined),
              selectedIcon: Icon(Icons.event),
              label: "Events",
            ),
            NavigationDestination(
              icon: Icon(Icons.qr_code_outlined),
              selectedIcon: Icon(Icons.qr_code),
              label: "Passes",
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}
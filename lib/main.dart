import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/events/event_list_screen.dart';
import 'screens/events/event_detail_screen.dart';
import 'screens/registration/event_pass_screen.dart';
import 'screens/events/event_lobby_screen.dart';
import 'screens/events/modes/quiz_mode_screen.dart';
import 'screens/events/modes/voting_mode_screen.dart';
import 'screens/events/modes/treasure_hunt_screen.dart';
import 'providers/providers.dart';
import 'models/models.dart';
import 'widgets/widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: PixelEventsApp(),
    ),
  );
}

class PixelEventsApp extends StatelessWidget {
  const PixelEventsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pixel Events',
      debugShowCheckedModeBanner: false,
      theme: FlexThemeData.dark(
        colors: const FlexSchemeColor(
          primary: Color(0xFF00FFFF), // Cyan
          primaryContainer: Color(0xFF003737),
          secondary: Color(0xFFFF2E88), // Cyber Pink
          secondaryContainer: Color(0xFF3F0020),
          tertiary: Color(0xFFFFD700), // Gold
          tertiaryContainer: Color(0xFF3B3200),
          appBarColor: Color(0xFF0B0B0F),
          error: Color(0xFFCF6679),
        ),
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 13,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 20,
          useTextTheme: true,
          useM2StyleDividerInM3: true,
          inputDecoratorBorderType: FlexInputBorderType.outline,
          inputDecoratorRadius: 12.0,
          inputDecoratorUnfocusedHasBorder: true,
          chipRadius: 20.0,
          cardRadius: 16.0,
          dialogRadius: 20.0,
          elevatedButtonRadius: 12.0,
          filledButtonRadius: 12.0,
          outlinedButtonRadius: 12.0,
          fabRadius: 16.0,
          navigationBarIndicatorRadius: 12.0,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
        fontFamily: GoogleFonts.outfit().fontFamily,
        scaffoldBackground: const Color(0xFF0B0B0F),
      ),
      themeMode: ThemeMode.dark,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/event-detail') {
          final event = settings.arguments as Event;
          return MaterialPageRoute(
            builder: (context) => EventDetailScreen(event: event),
          );
        }
        if (settings.name == '/event-pass') {
          if (settings.arguments is EventPass) {
            return MaterialPageRoute(
              builder: (context) => EventPassScreen(eventPass: settings.arguments as EventPass),
            );
          }
        }
        if (settings.name == '/event-lobby') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => EventLobbyScreen(
              event: args['event'] as Event,
              pass: args['pass'] as EventPass,
            ),
          );
        }
        if (settings.name == '/quiz-mode') {
          final event = settings.arguments as Event;
          return MaterialPageRoute(
            builder: (context) => QuizModeScreen(event: event),
          );
        }
        if (settings.name == '/voting-mode') {
          final event = settings.arguments as Event;
          return MaterialPageRoute(
            builder: (context) => VotingModeScreen(event: event),
          );
        }
        if (settings.name == '/treasure-hunt') {
          final event = settings.arguments as Event;
          return MaterialPageRoute(
            builder: (context) => TreasureHuntScreen(event: event),
          );
        }
        return null;
      },
      routes: {
        '/': (context) => const UnifiedSplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/events': (context) => const EventListScreen(),
      },
    );
  }
}

class UnifiedSplashScreen extends ConsumerStatefulWidget {
  const UnifiedSplashScreen({super.key});

  @override
  ConsumerState<UnifiedSplashScreen> createState() => _UnifiedSplashScreenState();
}

class _UnifiedSplashScreenState extends ConsumerState<UnifiedSplashScreen> {
  String _loadingMessage = "Initializing Systems";
  bool _startTear = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _startTear = true);
    });
  }

  Future<void> _initializeApp() async {
    try {
      setState(() => _loadingMessage = "Syncing Database");
      await ref.read(cacheServiceProvider).database;
      
      setState(() => _loadingMessage = "Verifying Identity");
      final authService = ref.read(authServiceProvider);
      final isAuthenticated = await authService.isAuthenticated();
      
      setState(() => _loadingMessage = "Welcome to the Future");
      await Future.delayed(const Duration(milliseconds: 1500)); 
      
      if (mounted) {
        if (isAuthenticated) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0B0B0F);
    const pink = Color(0xFFFF2E88);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Gradient Glow
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: pink.withOpacity(0.05),
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.5, 1.5), duration: 3.seconds),

          Center(
            child: SingleChildScrollView( // Added to prevent overflow on smaller screens
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 🔥 PIXEL LOGO with "Tear" entrance
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: pink.withOpacity(0.5), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: pink.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Image.asset(
                        "assets/images/app_icon.jpg",
                        height: 120,
                        width: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ).animate()
                   .scale(begin: const Offset(0.0, 0.0), end: const Offset(1, 1), duration: 800.ms, curve: Curves.elasticOut)
                   .shimmer(delay: 1.seconds, duration: 2.seconds)
                   .shake(hz: 4, curve: Curves.easeInOutCubic, duration: 500.ms, delay: 100.ms),
  
                  const SizedBox(height: 32),
  
                  // App Title with "Tear" entrance
                  const Text(
                    "PIXEL EVENTS",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.5, end: 0)
                   .shimmer(delay: 1200.ms, duration: 1500.ms),
  
                  const SizedBox(height: 20), // Reduced height to save space
  
                  // Integrated Loading Component
                  CyberLoading(message: _loadingMessage)
                      .animate().fadeIn(delay: 800.ms),
                ],
              ),
            ),
          ),

          // Tear Overlay (Two halves sliding away)
          if (_startTear) ...[
            // Top Half
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height / 2,
              child: Container(color: bg),
            ).animate().slideY(begin: 0, end: -1, duration: 1200.ms, curve: Curves.easeInOutQuart),
            
            // Bottom Half
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height / 2,
              child: Container(color: bg),
            ).animate().slideY(begin: 0, end: 1, duration: 1200.ms, curve: Curves.easeInOutQuart),
          ],

          // Version Tag at bottom
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "POWERED BY PIXEL",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 1500.ms),
        ],
      ),
    );
  }
}

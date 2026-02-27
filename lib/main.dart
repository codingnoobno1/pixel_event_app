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
import 'providers/providers.dart';
import 'models/models.dart';

void main() {
  print("🔥 MAIN STARTED");
  WidgetsFlutterBinding.ensureInitialized();
  print("✅ WIDGETS BINDING INITIALIZED");
  
  runApp(
    const ProviderScope(
      child: PixelEventsApp(),
    ),
  );
  
  print("✅ RUN APP CALLED");
}

class PixelEventsApp extends StatelessWidget {
  const PixelEventsApp({super.key});

  @override
  Widget build(BuildContext context) {
    print("🎨 BUILDING APP");
    return MaterialApp(
      title: 'Pixel Events',
      debugShowCheckedModeBanner: false,
      // Premium Light Theme
      theme: FlexThemeData.light(
        scheme: FlexScheme.deepPurple,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 7,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 10,
          blendOnColors: false,
          useTextTheme: true,
          inputDecoratorBorderType: FlexInputBorderType.outline,
          inputDecoratorRadius: 12.0,
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
      ),
      // Premium Dark Theme
      darkTheme: FlexThemeData.dark(
        scheme: FlexScheme.deepPurple,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 13,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 20,
          useTextTheme: true,
          useM2StyleDividerInM3: true,
          inputDecoratorBorderType: FlexInputBorderType.outline,
          inputDecoratorRadius: 12.0,
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
      ),
      themeMode: ThemeMode.system,
      // Define named routes
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/events': (context) => const EventListScreen(),
        '/event-detail': (context) {
          final event = ModalRoute.of(context)!.settings.arguments as Event;
          return EventDetailScreen(event: event);
        },
        '/event-pass': (context) {
          final pass = ModalRoute.of(context)!.settings.arguments as EventPass;
          return EventPassScreen(eventPass: pass);
        },
      },
    );
  }
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    print("🚀 SPLASH SCREEN INIT");
    _initialize();
  }

  Future<void> _initialize() async {
    print("⏳ STARTING INITIALIZATION");
    
    try {
      // Initialize cache service
      print("📦 Initializing cache service...");
      await ref.read(cacheServiceProvider).database;
      print("✅ Cache service initialized");
      
      // Check authentication status
      print("🔐 Checking authentication status...");
      final authService = ref.read(authServiceProvider);
      final isAuthenticated = await authService.isAuthenticated();
      print("🔐 Authentication status: $isAuthenticated");
      
      print("✅ INITIALIZATION COMPLETE");
      
      // Navigate based on auth status
      if (mounted) {
        if (isAuthenticated) {
          print("✅ USER AUTHENTICATED - NAVIGATING TO HOME");
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          print("✅ USER NOT AUTHENTICATED - NAVIGATING TO LOGIN");
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      print("❌ INITIALIZATION ERROR: $e");
      // Navigate to login on error
      if (mounted) {
        print("⚠️ ERROR OCCURRED - NAVIGATING TO LOGIN");
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print("🎨 BUILDING SPLASH SCREEN");
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Using Icon instead of Image.asset to avoid asset loading issues
            Icon(
              Icons.event,
              size: 120,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            const Text(
              'Pixel Events',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            const Text(
              'Loading...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

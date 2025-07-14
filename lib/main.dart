// main.dart - Updated untuk SmartKuliner
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'providers/cart_provider.dart';
import 'screens/navbar/home_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/deeplink_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseAuth.instance.setLanguageCode('id');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => MyAuthProvider()..initialize(),
        ),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'SmartKuliner',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.orange,
          primaryColor: const Color(0xFF4DA8DA),
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'Poppins', // Optional: add custom font
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final DeeplinkService _deeplinkService = DeeplinkService();
  bool _isDeeplinkInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeDeeplink();
  }

  Future<void> _initializeDeeplink() async {
    // Wait for first frame to ensure widget tree is ready
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Wait a bit for auth state to settle
      await Future.delayed(const Duration(milliseconds: 1500));

      // Initialize deeplink service
      _deeplinkService.initialize(context);

      // Handle initial deeplink
      await _deeplinkService.handleInitialLink(context);

      setState(() {
        _isDeeplinkInitialized = true;
      });
    });
  }

  @override
  void dispose() {
    _deeplinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading while checking auth state atau deeplink belum ready
        if (authProvider.isLoading || !_isDeeplinkInitialized) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4DA8DA)),
              ),
            ),
          );
        }

        // Show appropriate screen based on auth state
        if (authProvider.isAuthenticated) {
          return const HomeScreen(); // Your main app screen
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

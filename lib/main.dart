import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'providers/cart_provider.dart';
import 'screens/cart_screen.dart';
import 'screens/navbar/home_screen.dart'; // You'll create this later
import 'package:firebase_auth/firebase_auth.dart';

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

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading while checking auth state
        if (authProvider.isLoading) {
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

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class SplashScreen extends StatefulWidget {
  final Widget child;
  
  const SplashScreen({super.key, required this.child});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeSplash();
  }

  Future<void> _initializeSplash() async {
    // Warte 3 Sekunden bevor der Splash Screen entfernt wird
    await Future.delayed(const Duration(seconds: 3));
    
    // Entferne den nativen Splash Screen
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
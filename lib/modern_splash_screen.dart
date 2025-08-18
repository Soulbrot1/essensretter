import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'dart:async';

class ModernSplashScreen extends StatefulWidget {
  final Widget child;
  
  const ModernSplashScreen({super.key, required this.child});

  @override
  State<ModernSplashScreen> createState() => _ModernSplashScreenState();
}

class _ModernSplashScreenState extends State<ModernSplashScreen> 
    with TickerProviderStateMixin {
  bool _showSplash = true;
  
  // Animation Controllers
  late AnimationController _titleController;
  late AnimationController _subtitle1Controller;
  late AnimationController _subtitle2Controller;
  late AnimationController _pulseController;
  
  // Animations
  late Animation<double> _titleFade;
  late Animation<double> _titleScale;
  late Animation<double> _subtitle1Fade;
  late Animation<double> _subtitle2Fade;
  late Animation<Offset> _subtitle1Slide;
  late Animation<Offset> _subtitle2Slide;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Entferne den nativen Splash sofort
    FlutterNativeSplash.remove();
    
    // Setup Title Animation (Food Rescue)
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _titleFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _titleController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _titleScale = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _titleController,
      curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
    ));
    
    // Setup Subtitle 1 Animation (Stop the waste)
    _subtitle1Controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _subtitle1Fade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _subtitle1Controller,
      curve: Curves.easeInOut,
    ));
    
    _subtitle1Slide = Tween<Offset>(
      begin: const Offset(-0.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _subtitle1Controller,
      curve: Curves.easeOutCubic,
    ));
    
    // Setup Subtitle 2 Animation (Start good taste)
    _subtitle2Controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _subtitle2Fade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _subtitle2Controller,
      curve: Curves.easeInOut,
    ));
    
    _subtitle2Slide = Tween<Offset>(
      begin: const Offset(0.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _subtitle2Controller,
      curve: Curves.easeOutCubic,
    ));
    
    // Pulse Animation für den Titel
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Starte die Animationen
    _startAnimations();
  }

  Future<void> _startAnimations() async {
    // Kleine Verzögerung
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Starte Title Animation
    _titleController.forward();
    
    // Warte und starte erste Subtitle
    await Future.delayed(const Duration(milliseconds: 800));
    _subtitle1Controller.forward();
    
    // Warte und starte zweite Subtitle
    await Future.delayed(const Duration(milliseconds: 400));
    _subtitle2Controller.forward();
    
    // Starte Pulse Animation nach allen anderen
    await Future.delayed(const Duration(milliseconds: 600));
    _pulseController.repeat(reverse: true);
    
    // Warte 7 Sekunden insgesamt
    await Future.delayed(const Duration(seconds: 5));
    
    if (mounted) {
      // Fade out Animation
      await _titleController.reverse();
      setState(() {
        _showSplash = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitle1Controller.dispose();
    _subtitle2Controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showSplash) {
      return widget.child;
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final topTextPosition = screenHeight * 0.25 - 140; // 140px nach oben (30 + 60 + 50)
    final bottomTextPosition = screenHeight * 0.65 + 50; // 50px nach unten (30 + 20)

    return Scaffold(
      backgroundColor: const Color(0xFF2E7D32),
      body: Stack(
        children: [
          // Hintergrundbild
          Positioned.fill(
            child: Image.asset(
              'assets/images/splashscreen.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFF2E7D32),
                );
              },
            ),
          ),
          
          // Food Rescue - Über dem Logo mit Scale und Pulse
          Positioned(
            top: topTextPosition,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: child,
                  );
                },
                child: FadeTransition(
                  opacity: _titleFade,
                  child: ScaleTransition(
                    scale: _titleScale,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.0),
                            Colors.white.withValues(alpha: 0.1),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        'Food Rescue',
                        style: TextStyle(
                          fontSize: 45,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              blurRadius: 20,
                              color: Colors.green.shade900.withValues(alpha: 0.8),
                              offset: const Offset(0, 4),
                            ),
                            const Shadow(
                              blurRadius: 30,
                              color: Colors.black54,
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Subtitles unter dem Logo
          Positioned(
            top: bottomTextPosition,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Stop the waste - von links eingleiten
                FadeTransition(
                  opacity: _subtitle1Fade,
                  child: SlideTransition(
                    position: _subtitle1Slide,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        'Stop the waste',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          letterSpacing: 3,
                          shadows: [
                            Shadow(
                              blurRadius: 15,
                              color: Colors.black.withValues(alpha: 0.8),
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 15),
                
                // Start good taste - von rechts eingleiten
                FadeTransition(
                  opacity: _subtitle2Fade,
                  child: SlideTransition(
                    position: _subtitle2Slide,
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.green.shade200,
                          Colors.white,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        'Start good taste',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 3,
                          shadows: [
                            Shadow(
                              blurRadius: 15,
                              color: Colors.black.withValues(alpha: 0.8),
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
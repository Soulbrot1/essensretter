import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  final Widget child;

  const OnboardingScreen({super.key, required this.child});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _shouldShowOnboarding = false;
  bool _isLoading = true;

  // Liste der Screenshot-Pfade mit deinen Onboarding-Bildern
  final List<OnboardingPage> _onboardingPages = [
    OnboardingPage(
      imagePath: 'assets/images/onboarding/Onboarding 1 .png',
      title: 'Willkommen bei EssensRetter',
      description: 'Reduziere Lebensmittelverschwendung und spare Geld',
    ),
    OnboardingPage(
      imagePath: 'assets/images/onboarding/Onboarding 2.png',
      title: 'Lebensmittel hinzufügen',
      description: 'Füge ganz einfach deine Lebensmittel mit Ablaufdatum hinzu',
    ),
    OnboardingPage(
      imagePath: 'assets/images/onboarding/Onboarding 3.png',
      title: 'Rechtzeitig erinnert werden',
      description:
          'Erhalte Benachrichtigungen bevor deine Lebensmittel ablaufen',
    ),
    OnboardingPage(
      imagePath: 'assets/images/onboarding/Onboarding 4.png',
      title: 'Statistiken einsehen',
      description: 'Verfolge deinen Fortschritt und reduziere Verschwendung',
    ),
    OnboardingPage(
      imagePath: 'assets/images/onboarding/Onboarding 5.png',
      title: 'Rezepte generieren',
      description:
          'Lass dir passende Rezepte für deine Lebensmittel vorschlagen',
    ),
    OnboardingPage(
      imagePath: 'assets/images/onboarding/Onboarding 6.png',
      title: 'Intelligente Features',
      description: 'Nutze KI für automatisches Erfassen und clevere Vorschläge',
    ),
    OnboardingPage(
      imagePath: 'assets/images/onboarding/Onboarding 7.png',
      title: 'Bereit loszulegen!',
      description: 'Starte jetzt und rette Lebensmittel vor der Verschwendung',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    setState(() {
      _shouldShowOnboarding = !hasSeenOnboarding;
      _isLoading = false;
    });
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (mounted) {
      setState(() {
        _shouldShowOnboarding = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_shouldShowOnboarding) {
      return widget.child;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Images that fill the screen except navigation bar
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingPages.length,
                itemBuilder: (context, index) {
                  final page = _onboardingPages[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Image.asset(
                      page.imagePath,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback wenn Screenshot noch nicht vorhanden
                        return Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Bild ${index + 1}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            // Fixed Navigation Bar
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Skip Button
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(
                        'Überspringen',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ),

                    // Page Indicators
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _onboardingPages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 6),
                            height: 6,
                            width: _currentPage == index ? 20 : 6,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Next/Finish Button
                    ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _onboardingPages.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _completeOnboarding();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        _currentPage < _onboardingPages.length - 1
                            ? 'Weiter'
                            : 'Los geht\'s',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String imagePath;
  final String title;
  final String description;

  OnboardingPage({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}

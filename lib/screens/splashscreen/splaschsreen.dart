import 'package:animated_gradient_background/animated_gradient_background.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../config_App/colorsApp.dart';
import '../../config_App/image.dart';
import '../../sevice/controlleur/splashcontrolleur/splashscreen_controlleur.dart';
import '../../shared/widgets/premium_particles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _shineController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shineAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.elasticOut),
    );
    _fadeController.forward();

    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _shineAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shineController, curve: Curves.easeInOutSine),
    );
    Future.delayed(const Duration(milliseconds: 800), () {
      _shineController.repeat(reverse: false);
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PremiumParticleBackground(
        config: ParticleThemes.goldIntense,
        showGradient: true,
        child: AnimatedGradientBackground(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [
          Color(0xFF0A0A0A),
          Color(0xFF1A0A00),
          Color(0xFF2A1500),
          Color(0xFF1A0A00),
          Color(0xFF0A0A0A),
        ],
        child: GetBuilder<SplashController>(
          builder: (controller) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),
                  // Logo animé premium avec effet shine
                  AnimatedBuilder(
                    animation: _fadeController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Column(
                            children: [
                              // Logo avec effet shine
                              Stack(
                                children: [
                                  ShaderMask(
                                    shaderCallback: (bounds) => LinearGradient(
                                      colors: [
                                        const Color(0xFFD4AF37),
                                        const Color(0xFFF0D060),
                                        const Color(0xFFFFE44D),
                                        const Color(0xFFD4AF37),
                                      ],
                                      stops: const [0.0, 0.3, 0.6, 1.0],
                                    ).createShader(bounds),
                                    child: Image.asset(
                                      Consticon.logo,
                                      width: 60.w,
                                      height: 20.h,
                                    ),
                                  ),
                                  // Effet shine qui traverse le logo
                                  AnimatedBuilder(
                                    animation: _shineController,
                                    builder: (context, child) {
                                      return ShaderMask(
                                        shaderCallback: (bounds) => LinearGradient(
                                          colors: [
                                            Colors.white.withValues(alpha: 0),
                                            Colors.white.withValues(alpha: 0.6),
                                            Colors.white.withValues(alpha: 0),
                                          ],
                                          stops: [
                                            _shineAnimation.value - 0.3,
                                            _shineAnimation.value,
                                            _shineAnimation.value + 0.3,
                                          ],
                                        ).createShader(bounds),
                                        child: Image.asset(
                                          Consticon.logo,
                                          width: 60.w,
                                          height: 20.h,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: 3.h),
                              // Titre premium avec effet scintillant
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: const [
                                    Color(0xFFD4AF37),
                                    Color(0xFFFFF8DC),
                                    Color(0xFFD4AF37),
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ).createShader(bounds),
                                child: const Text(
                                  'KONGOSSA',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 10,
                                  ),
                                ),
                              ),
                              SizedBox(height: 1.5.h),
                              Text(
                                'splash.tagline'.tr,
                                style: TextStyle(
                                  color: ColorApp.premiumGoldLight.withValues(alpha: 0.7),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 3,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              // Ligne décorative dorée
                              Container(
                                width: 30.w,
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Color(0xFFD4AF37),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                '⭐ ${'app.premium'.tr} ⭐',
                                style: TextStyle(
                                  color: ColorApp.premiumGold.withValues(alpha: 0.5),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const Spacer(flex: 2),
                  // Indicateur de chargement premium
                  if (controller.isLoading.value)
                    Column(
                      children: [
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ColorApp.premiumGold,
                            ),
                          ),
                        ),
                        SizedBox(height: 1.5.h),
                        Text(
                          'splash.preparing'.tr,
                          style: TextStyle(
                            color: ColorApp.premiumGold.withValues(alpha: 0.5),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  const Spacer(flex: 1),
                  // Message d'erreur premium
                  if (controller.errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.red.withValues(alpha: 0.15),
                                  Colors.red.withValues(alpha: 0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  color: Theme.of(context).colorScheme.error,
                                  size: 36,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  controller.errorMessage.value,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => controller.initializeApp(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ColorApp.premiumGold,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 8,
                                    shadowColor: ColorApp.premiumGold.withValues(alpha: 0.4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 14,
                                    ),
                                  ),
                                  child: const Text(
                                    'Réessayer',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Footer premium
                  Padding(
                    padding: EdgeInsets.only(bottom: 3.h),
                    child: Text(
                      '✨ ${'app.elite'.tr.toLowerCase().tr} ✨',
                      style: TextStyle(
                        color: ColorApp.premiumGold.withValues(alpha: 0.3),
                        fontSize: 10,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../config_App/colorsApp.dart';
import '../../../sevice/controlleur/authentification/auth_controlleur.dart';
import '../../../sevice/i18n/translation_service.dart';
import '../../../shared/widgets/premium_particles.dart';
import 'sign_in_form.dart';

void showCustomDialog(BuildContext context, {required ValueChanged onValue}) {
  showGeneralDialog(
    context: context,
    barrierLabel: "Barrier",
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.8),
    transitionDuration: const Duration(milliseconds: 600),
    pageBuilder: (_, __, ___) {
      return Center(
        child: Container(
          height: 670,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: ColorApp.premiumGold.withValues(alpha: 0.15),
                offset: const Offset(0, 30),
                blurRadius: 60,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                offset: const Offset(0, 30),
                blurRadius: 60,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: Stack(
              children: [
                // Particules premium animées en arrière-plan
                Positioned.fill(
                  child: PremiumParticleBackground(
                    config: ParticleThemes.gold,
                    showGradient: false,
                  ),
                ),
                // Contenu glass-morphism existant
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 32,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.12),
                          Colors.white.withValues(alpha: 0.06),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Scaffold(
                      backgroundColor: Colors.transparent,
                      body: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          SingleChildScrollView(
                            child: Column(
                              children: [
                                // Badge premium
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFD4AF37),
                                        Color(0xFFF0D060),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),                                      child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.black,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'app.premium'.tr,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Titre avec dégradé doré
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: const [
                                      Color(0xFFD4AF37),
                                      Color(0xFFFFF8DC),
                                      Color(0xFFD4AF37),
                                    ],
                                  ).createShader(bounds),
                                  child: Text(
                                    "auth.sign_in".tr,
                                    style: const TextStyle(
                                      fontSize: 34,
                                      fontFamily: "Poppins",
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "auth.sign_in_desc".tr,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const SignInForm(),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              ColorApp.premiumGold.withValues(
                                                alpha: 0.5,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Text(
                                        "app.or".tr,
                                        style: TextStyle(
                                          color: ColorApp.premiumGold
                                              .withValues(alpha: 0.7),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              ColorApp.premiumGold.withValues(
                                                alpha: 0.5,
                                              ),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  "auth.signup_options".tr,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildPremiumSocialButton(
                                      asset: "assets/icons/email_box.svg",
                                      onPressed: () {},
                                    ),
                                    _buildPremiumSocialButton(
                                      asset: "assets/icons/apple_box.svg",
                                      onPressed: () {},
                                    ),
                                    Obx(() {
                                      if (authController
                                          .isGoogleSignInAvailable
                                          .value) {
                                        return _buildPremiumSocialButton(
                                          asset: "assets/icons/google_box.svg",
                                          onPressed:
                                              authController.isLoading.value
                                              ? null
                                              : () => authController
                                                    .signInWithGoogle(),
                                        );
                                      } else {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withValues(
                                              alpha: 0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.red.withValues(
                                                alpha: 0.3,
                                              ),
                                            ),
                                          ),                                            child: Text(
                                            'auth.google_unavailable'.tr,
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.error,
                                              fontSize: 11,
                                            ),
                                          ),
                                        );
                                      }
                                    }),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: -48,
                            child: InkWell(
                              onTap: () => Get.back(),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFD4AF37),
                                      Color(0xFFF0D060),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: ColorApp.premiumGold.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 20,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
    transitionBuilder: (_, anim, __, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
        child: FadeTransition(opacity: anim, child: child),
      );
    },
  ).then(onValue);
}

Widget _buildPremiumSocialButton({
  required String asset,
  required VoidCallback? onPressed,
}) {
  return Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: ColorApp.premiumGold.withValues(alpha: 0.2),
          blurRadius: 12,
          spreadRadius: 1,
        ),
      ],
    ),
    child: Material(
      color: Colors.white.withValues(alpha: 0.1),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: SvgPicture.asset(asset, height: 40, width: 40),
        ),
      ),
    ),
  );
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:rive/rive.dart' hide RadialGradient, LinearGradient;
import '../../config_App/colorsApp.dart';
import '../../config_App/image.dart';
import 'package:kongossa/shared/widgets/widgets.dart';
import 'components/animated_btn.dart';
import 'components/sign_in_dialog.dart';

class OnbodingScreen extends StatefulWidget {
  const OnbodingScreen({super.key});

  @override
  State<OnbodingScreen> createState() => _OnbodingScreenState();
}

class _OnbodingScreenState extends State<OnbodingScreen> {
  late RiveAnimationController _btnAnimationController;
  bool isShowSignInDialog = false;

  @override
  void initState() {
    _btnAnimationController = OneShotAnimation(
      "active",
      autoplay: false,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Arrière-plan premium avec dégradé doré/noir
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    ColorApp.premiumGold.withValues(alpha: 0.08),
                    const Color(0xFF0A0A0A),
                    const Color(0xFF000000),
                  ],
                  radius: 1.2,
                  center: const Alignment(0.3, -0.2),
                ),
              ),
            ),
          ),

          // Effet de lumière dorée
          Positioned(
            top: -100,
            left: -50,
            width: 300,
            height: 300,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    ColorApp.premiumGold.withValues(alpha: 0.15),
                    ColorApp.premiumGold.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Animation Rive
          const RiveAnimation.asset(
            "assets/RiveAssets/shapes.riv",
          ),

          // Effet flou premium
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: const SizedBox(),
            ),
          ),

          // Contenu principal
          AnimatedPositioned(
            top: isShowSignInDialog ? -50 : 0,
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            duration: const Duration(milliseconds: 260),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SizedBox(height: 5.h),

                    // Logo premium avec dégradé doré
                    Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              ColorApp.premiumGold,
                              ColorApp.premiumGoldLight,
                              ColorApp.premiumGold,
                            ],
                            stops: [0.0, 0.5, 1.0],
                          ).createShader(bounds),
                          child: CustomImage(
                            source: Consticon.logo,
                            type: ImageType.asset,
                            width: 180,
                            height: 130,
                          ),
                        ),
                        SizedBox(height: 1.h),

                        // Badge premium
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [ColorApp.premiumGold, ColorApp.premiumGoldLight],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: ColorApp.premiumGold.withValues(alpha: 0.3),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, size: 14.sp, color: Colors.black),
                              SizedBox(width: 1.w),
                              Text(
                                'app.elite'.tr,
                                style: TextStyle(
                                  fontSize: 9.sp,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 3.h),

                    // Texte de description premium
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: ColorApp.premiumGold.withValues(alpha: 0.15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: ColorApp.premiumGold.withValues(alpha: 0.03),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.format_quote,
                            size: 20.sp,
                            color: ColorApp.premiumGold.withValues(alpha: 0.5),
                          ),
                          SizedBox(height: 1.h),
                          CustomText(
                            'onboarding.description'.tr,
                            type: TextType.quote,
                            align: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 2),

                    // Bouton d'animation premium
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: ColorApp.premiumGold.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: AnimatedBtn(
                        btnAnimationController: _btnAnimationController,
                        press: () {
                          _btnAnimationController.isActive = true;

                          Future.delayed(
                            const Duration(milliseconds: 800),
                            () {
                              setState(() {
                                isShowSignInDialog = true;
                              });
                              if (!context.mounted) return;
                              showCustomDialog(
                                context,
                                onValue: (_) {
                                  setState(() {
                                    isShowSignInDialog = false;
                                  });
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 3.h),

                    // Fonctionnalités premium
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: ColorApp.premiumGold.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _buildPremiumFeature(
                                icon: Icons.share,
                                label: 'onboarding.feature.share'.tr,
                              ),
                              _buildPremiumFeature(
                                icon: Icons.sports_esports,
                                label: 'onboarding.feature.games'.tr,
                              ),
                            ],
                          ),
                          SizedBox(height: 1.h),
                          Row(
                            children: [
                              _buildPremiumFeature(
                                icon: Icons.work,
                                label: 'onboarding.feature.jobs'.tr,
                              ),
                              _buildPremiumFeature(
                                icon: Icons.event,
                                label: 'onboarding.feature.events'.tr,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 3.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFeature({
    required IconData icon,
    required String label,
  }) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 1.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(1.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ColorApp.premiumGold, ColorApp.premiumGoldLight],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 12.sp, color: Colors.black),
            ),
            SizedBox(width: 1.w),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 11.sp,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:rive/rive.dart' hide Image;
import 'package:shimmer/shimmer.dart';
import '../../config_App/image.dart';
import '../../presentation/component/image_component/image.dart';
import '../../presentation/component/style/custum_text.dart';
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
          // Arrière-plan avec effet flou
          Positioned(
            width: MediaQuery.of(context).size.width * 1.7,
            left: 100,
            bottom: 100,
            child: Image.asset(
              "assets/Backgrounds/Spline.png",
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: const SizedBox(),
            ),
          ),

          // Animation Rive
          const RiveAnimation.asset(
            "assets/RiveAssets/shapes.riv",
          ),

          // Effet flou supplémentaire
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
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
                padding:  EdgeInsets.symmetric(horizontal: 4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // const Spacer(),
                    // Image.asset(Consticon.logo),
                    // Titre et description
                     SizedBox(
                      // width: 260,
                      child: Column(
                        children: [
                          CustomImage(
                              source: Consticon.logo,
                              type: ImageType.asset,
                              width: 200,
                              height: 150
                          ),
                          // Image.asset(Consticon.logo),
                          // SizedBox(height: 16),
                          CustomText(
                            "Le réseau social 100% Africain qui réunit les Africains du monde entier. "
                                "Un espace de partage, de discussion et de valorisation de nos cultures et valeurs africaines.",
                            // style: TextStyle(
                            //   fontSize: 16,
                            //   color: Colors.black87,
                            // ),
                              type: TextType.quote
                          ),
                        ],
                      ),
                    ),


                     const Spacer(flex: 2),

                    // Bouton d'animation
                    AnimatedBtn(
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


                    // Texte descriptif supplémentaire
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: CustomText(

                        "Rejoignez notre communauté pour :\n"
                            "• Partager des contenus avec des filtres africains\n"
                            "• Jouer à des jeux inspirés de nos cultures\n"
                            "• Trouver des opportunités d'emploi\n"
                            "• Participer à des événements panafricains",
                          type: TextType.caption
                        // style: TextStyle(
                        //   fontSize: 14,
                        //   color: Colors.black54,
                        // ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
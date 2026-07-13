import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kongossa/model/datamodel/user_model.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:rive/rive.dart' hide RadialGradient, LinearGradient;

// import 'package:rive_animation/constants.dart';
// import 'package:rive_animation/screens/home/home_screen.dart';
// import 'package:rive_animation/utils/rive_utils.dart';

import '../../config_App/colorsApp.dart';
import '../../model/menu.dart';
import '../../shared/widgets/bottom_navigation.dart';
import '../../shared/widgets/component_for_post/create_post_widget.dart';
import '../../sevice/connection/connectionchecker.dart';
import '../../sevice/controlleur/authentification/auth_controlleur.dart';
import '../../utils/rive_utils.dart';
import '../../shared/widgets/premium_particles.dart';
import '../collaboration/friend.dart';
import '../home/home_screen.dart';
import '../live/live_feed_screen.dart';
import '../mymember/memberpage.dart';
import '../profil_screen.dart';
import 'components/btm_nav_item.dart';
import 'components/menu_btn.dart';
import 'components/side_bar.dart';

class EntryPoint extends StatefulWidget {
  const EntryPoint({super.key});

  @override
  State<EntryPoint> createState() => _EntryPointState();
}

class _EntryPointState extends State<EntryPoint>
    with SingleTickerProviderStateMixin {
  bool isSideBarOpen = false;

  Menu selectedBottonNav = bottomNavItems.first;
  Menu selectedSideMenu = sidebarMenus.first;

  late SMIBool isMenuOpenInput;

  void updateSelectedBtmNav(Menu menu) {
    if (selectedBottonNav != menu) {
      setState(() {
        selectedBottonNav = menu;
      });
    }
  }

  late AnimationController _animationController;
  late Animation<double> scalAnimation;
  late Animation<double> animation;

  @override
  void initState() {
    Connexioncheck.getConnectivity(Get.context);
    _animationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 200),
        )..addListener(() {
          setState(() {});
        });
    scalAnimation = Tween<double>(begin: 1, end: 0.8).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.fastOutSlowIn,
      ),
    );
    animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.fastOutSlowIn,
      ),
    );
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF0A0A0A),
      body: PremiumParticleBackground(
        config: ParticleThemes.goldPurple,
        showGradient: true,
        child: Container(
        height: Get.height,
        child: Stack(
          children: [
            AnimatedPositioned(
              width: 288,
              height:Get.height,
              duration: const Duration(milliseconds: 200),
              curve: Curves.fastOutSlowIn,
              left: isSideBarOpen ? 0 : -288,
              top: 0,
              child: const SideBar(),
            ),
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(
                  1 * animation.value - 30 * (animation.value) * pi / 180,
                ),
              child: Transform.translate(
                offset: Offset(animation.value * 265, 0),
                child: Transform.scale(
                  scale: scalAnimation.value,
                  child:  ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                    // child: FriendFeedScreen(),
                    child: Obx(() {
                      if (authController.indexpage.value == 0) {
                        return HomePage();
                      }
                      if (authController.indexpage.value == 1) {
                        return FriendFeedScreen();
                      }
                      if (authController.indexpage.value == 2) {
                        return  CreatePostPremiumScreen();
                      }
                      if (authController.indexpage.value == 3) {
                        return  MembersPageTikTok (

                        );
                      }                      if (authController.indexpage.value == 4) {
                        return  PremiumProfileScreen (
                          userId: AppUser.info?.googleId??"0",
                          avatarUrl: AppUser.info?.photoUrl??"",
                          displayName: AppUser.info?.displayName??"",
                          username: AppUser.info?.displayName??"pas dispo",
                          mail: "${AppUser.info?.email??""}",
                          bio: "${AppUser.info?.bio??'tiktok.bio'.tr}  📩 ${AppUser.info?.email??""}",

                        );
                      }
                      if (authController.indexpage.value == 5) {
                        return const LiveFeedScreen();
                      }
                      return HomePage(); // ou un autre widget par défaut
                    }),
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.fastOutSlowIn,
              left: isSideBarOpen ? 220 : 0,
              top: 16,
              child: MenuBtn(
                press: () {
                  isMenuOpenInput.value = !isMenuOpenInput.value;

                  if (_animationController.value == 0) {
                    _animationController.forward();
                  } else {
                    _animationController.reverse();
                  }

                  setState(() {
                    isSideBarOpen = !isSideBarOpen;
                  });
                },
                riveOnInit: (artboard) {
                  final controller = StateMachineController.fromArtboard(
                    artboard,
                    "State Machine",
                  );

                  artboard.addController(controller!);

                  isMenuOpenInput =
                      controller.findInput<bool>("isOpen") as SMIBool;
                  isMenuOpenInput.value = true;
                },
              ),
            ),
          ],
        ),
      ),
    ),
      bottomNavigationBar: KongossaTikTokNavBar(),
    );
  }

  Widget _buildNeonNavItem({
    required Menu navBar,
    required int index,
    required bool isSelected,
  }) {
    return Expanded(
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: isSelected ? 1 : 0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        builder: (context, double value, child) {
          return GestureDetector(
            onTap: () {
              debugPrint("object");
              RiveUtils.chnageSMIBoolState(navBar.rive.status!);
              updateSelectedBtmNav(navBar);
              HapticFeedback.selectionClick();
            },
            child: Container(
              // padding: EdgeInsets.symmetric(vertical: 0.8.h),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          ColorApp.primary1.withValues(alpha: 0.2 + value * 0.3),
                          ColorApp.primary2.withValues(alpha: 0.1 + value * 0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icône avec effet 3D
                  Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(isSelected ? 0.2 : 0)
                      ..rotateX(isSelected ? 0.1 : 0),
                    alignment: Alignment.center,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: EdgeInsets.all(isSelected ? 2.w : 1.5.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: ColorApp.primary1.withValues(alpha: 0.6),
                                  blurRadius: 15,
                                  spreadRadius: 5 * value,
                                ),
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  spreadRadius: -2,
                                ),
                              ]
                            : null,
                      ),
                      child: ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            colors: isSelected
                                ? [Colors.red, const Color(0xFFE0E0E0)]
                                : [ColorApp.primary3, ColorApp.primary3],
                          ).createShader(bounds);
                        },
                        child: SizedBox(
                          // height: 20.h,
                          // width: 20.w,
                          child: BtmNavItem(
                            navBar: navBar,
                            press: () {},
                            riveOnInit: (artboard) {
                              navBar.rive.status = RiveUtils.getRiveInput(
                                artboard,
                                stateMachineName: navBar.rive.stateMachineName,
                              );
                            },
                            selectedNav: selectedBottonNav,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 0.8.h),

                  // Label avec animation
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      fontSize: isSelected ? 11.sp : 10.sp,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : ColorApp.primary3.withValues(alpha: 0.8),
                      letterSpacing: 0.5,
                      shadows: isSelected
                          ? [
                              Shadow(
                                color: ColorApp.primary1.withValues(alpha: 0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(navBar.title.tr, textAlign: TextAlign.center),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

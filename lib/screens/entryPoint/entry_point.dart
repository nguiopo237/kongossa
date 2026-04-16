import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:rive/rive.dart' hide RadialGradient, LinearGradient;

import '../../config_App/colorsApp.dart';
import '../../config_App/image.dart';
import '../../constants.dart';
import '../../model/datamodel/user_model.dart';
import '../../model/menu.dart';
import '../../presentation/component/widget/bottom_navigation.dart';
import '../../presentation/component/widget/component_for_post/create_post_widget.dart';
import '../../presentation/component/widget/component_for_post/createpost.dart';
import '../../presentation/component/widget/widget_component.dart';
import '../../sevice/connection/connectionchecker.dart';
import '../../sevice/controlleur/authentification/auth_controlleur.dart';
import '../../utils/rive_utils.dart';
import '../collaboration/friend.dart';
import '../home/home_screen.dart' hide ColorApp;
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
  // ==================== CONSTANTES ====================
  static const int _sidebarWidth = 288;
  static const int _sidebarClosedOffset = -288;
  static const double _menuButtonOffset = 220;
  static const double _scaleEndValue = 0.8;
  static const double _rotationAngle = 30;
  static const Duration _animationDuration = Duration(milliseconds: 200);

  // ==================== VARIABLES D'ÉTAT ====================
  bool isSideBarOpen = false;
  Menu selectedBottonNav = bottomNavItems.first;
  Menu selectedSideMenu = sidebarMenus.first;
  late SMIBool isMenuOpenInput;

  // ==================== CONTROLEURS D'ANIMATION ====================
  late AnimationController _animationController;
  late Animation<double> scaleAnimation;
  late Animation<double> animation;

  // ==================== GETTERS ====================
  num get _sidebarLeftPosition => isSideBarOpen ? 0 : _sidebarClosedOffset;
  double get _menuButtonLeftPosition => isSideBarOpen ? _menuButtonOffset : 0;
  double get _transformOffset => animation.value ;
 // double get _transformOffset => animation.value * _sidebarWidth - _sidebarClosedOffset;
  bool get _isAnimationStarted => _animationController.value == 0;

  // ==================== CYCLE DE VIE ====================
  @override
  void initState() {
    super.initState();
    _initializeConnectivity();
    _initializeAnimationController();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ==================== MÉTHODES PRIVÉES ====================
  void _initializeConnectivity() {
    Connexioncheck.getConnectivity(Get.context);
  }

  void _initializeAnimationController() {
    _animationController = AnimationController(
      vsync: this,
      duration: _animationDuration,
    )..addListener(() {
      setState(() {});
    });
  }

  void _initializeAnimations() {
    scaleAnimation = Tween<double>(begin: 1, end: _scaleEndValue).animate(
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
  }

  void _toggleSideMenu() {
    isMenuOpenInput.value = !isMenuOpenInput.value;

    if (_isAnimationStarted) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }

    setState(() {
      isSideBarOpen = !isSideBarOpen;
    });
  }

  Widget _buildMainContent() {
    return Obx(() {
      final currentIndex = authController.indexpage.value;

      switch (currentIndex) {
        case 0:
          return const ModernHomePage();
        case 1:
          return  FriendFeedScreen();
        case 2:
          return const CreatePostPremiumView();
        case 3:
          return const MembersPageTikTok();
        case 4:
          return PremiumProfileScreen(
            userId: AppUser.info!.googleId,
            avatarUrl: AppUser.info!.photoUrl,
            displayName: AppUser.info!.displayName,
            username: AppUser.info!.displayName,
            mail: "${AppUser.info!.email}",
            bio: "${AppUser.info?.bio ?? "Créateur de contenu | Digital Creator ✨\nCollaborations"}  📩 ${AppUser.info!.email}",
          );
        default:
          return const ModernHomePage();
      }
    });
  }

  Matrix4 _buildTransformMatrix() {
    return Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..rotateY(1 * animation.value - _rotationAngle * animation.value * pi / 180);
  }

  void _onMenuButtonPressed() {
    _toggleSideMenu();
  }

  void _onRiveInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      "State Machine",
    );
    artboard.addController(controller!);
    isMenuOpenInput = controller.findInput<bool>("isOpen") as SMIBool;
    isMenuOpenInput.value = true;
  }

  // ==================== BUILD WIDGETS ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: _buildBody(),
      bottomNavigationBar:  KongossaTikTokNavBar(),
    );
  }

  Widget _buildBody() {
    return Container(
      height: Get.height,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(Consticon.background),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [

          _buildMainContainer(),
          _buildSidebar(),
          _buildMenuButton(),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return AnimatedPositioned(
      width: Get.width/1.5 ,
      height: Get.height,
      duration: _animationDuration,
      curve: Curves.fastOutSlowIn,
      left: _sidebarLeftPosition.toDouble(),
      top: 0,
      child: const SideBar(),
    );
  }

  Widget _buildMainContainer() {
    return Transform(
      alignment: Alignment.center,
      transform: _buildTransformMatrix(),
      child: Transform.translate(
        offset: Offset(0, 0),
        child: Transform.scale(
          scale: scaleAnimation.value,
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            child: _buildMainContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton() {
    return AnimatedPositioned(
      duration: _animationDuration,
      curve: Curves.fastOutSlowIn,
      left: _menuButtonLeftPosition,
      top: 16,
      child: MenuBtn(
        press: _onMenuButtonPressed,
        riveOnInit: _onRiveInit,
      ),
    );
  }
}
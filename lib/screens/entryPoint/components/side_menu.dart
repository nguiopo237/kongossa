import 'package:flutter/material.dart';
import 'package:rive/rive.dart' hide LinearGradient, RadialGradient;
import 'dart:math';

import '../../../model/menu.dart';
import 'package:kongossa/shared/widgets/widgets.dart';
import 'package:kongossa/config_App/colorsApp.dart';

class PremiumSideMenu extends StatefulWidget {
  const PremiumSideMenu({
    super.key,
    required this.menu,
    required this.press,
    required this.riveOnInit,
    required this.selectedMenu,
    required this.index,
    this.isExpanded = true,
  });

  final Menu menu;
  final VoidCallback press;
  final ValueChanged<Artboard> riveOnInit;
  final Menu selectedMenu;
  final int index;
  final bool isExpanded;

  @override
  State<PremiumSideMenu> createState() => _PremiumSideMenuState();
}

class _PremiumSideMenuState extends State<PremiumSideMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Animation en cascade basée sur l'index
    final delay = widget.index * 100;

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(delay / 1000, 1.0, curve: Curves.elasticOut),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(delay / 1000, 1.0, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.5, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(delay / 1000, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: ColorApp.primary1.withValues(alpha: 0.1),
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    if (widget.selectedMenu != widget.menu) {
      if (isHovered) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSelected = widget.selectedMenu == widget.menu;

    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                    colors: [
                      ColorApp.primary1.withValues(alpha: 0.9),
                      ColorApp.primary2.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                      : LinearGradient(
                    colors: [
                      Colors.transparent,
                      _colorAnimation.value ?? Colors.transparent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: ColorApp.primary1.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Effet de brillance
                    if (isSelected)
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Transform.rotate(
                          angle: pi / 4,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.2),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Fond animé
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: isSelected ? 1.0 : 0.0,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment.centerLeft,
                                radius: 2.0,
                                colors: [
                                  ColorApp.primary1.withValues(alpha: 0.3),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Contenu
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: widget.press,
                        borderRadius: BorderRadius.circular(16),
                        splashColor: ColorApp.primary1.withValues(alpha: 0.3),
                        highlightColor: Colors.transparent,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          child: Row(
                            children: [
                              // Icône avec effet de halo
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (isSelected)
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            ColorApp.primary1.withValues(alpha: 0.4),
                                            Colors.transparent,
                                          ],
                                          radius: 0.8,
                                        ),
                                      ),
                                    ),

                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.1)
                                          : ColorApp.primary3.withValues(alpha: 0.1),
                                      boxShadow: [
                                        if (isSelected)
                                          BoxShadow(
                                            color: ColorApp.primary1
                                                .withValues(alpha: 0.3),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          ),
                                      ],
                                    ),
                                    child: Center(
                                      child: ColorFiltered(
                                        colorFilter: ColorFilter.mode(
                                          isSelected
                                              ? Colors.white
                                              : ColorApp.primary3,
                                          BlendMode.srcIn,
                                        ),
                                        child: RiveAnimation.asset(
                                          widget.menu.rive.src,
                                          artboard: widget.menu.rive.artboard,
                                          onInit: widget.riveOnInit,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(width: 16),

                              // Texte avec animation
                              Expanded(
                                child: AnimatedCrossFade(
                                  duration: const Duration(milliseconds: 300),
                                  crossFadeState: widget.isExpanded
                                      ? CrossFadeState.showFirst
                                      : CrossFadeState.showSecond,
                                  firstChild: CustomText(
                                    widget.menu.title,
                                    type: TextType.titleLarge,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : ColorApp.primary3,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      fontSize: 14,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  secondChild: Container(),
                                ),
                              ),

                              // Indicateur de sélection
                              if (isSelected && widget.isExpanded)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(left: 8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
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
          ),
        ),
      ),
    );
  }
}

// Widget parent pour gérer toute la sidebar
class PremiumSidebar extends StatefulWidget {
  final List<Menu> menuItems;
  final Menu selectedMenu;
  final ValueChanged<Menu> onMenuSelected;
  final bool isExpanded;

  const PremiumSidebar({
    super.key,
    required this.menuItems,
    required this.selectedMenu,
    required this.onMenuSelected,
    this.isExpanded = true,
  });

  @override
  State<PremiumSidebar> createState() => _PremiumSidebarState();
}

class _PremiumSidebarState extends State<PremiumSidebar> {
  final Map<String, RiveAnimationController> _riveControllers = {};

  void _onRiveInit(String artboardId, Artboard artboard) {
    // _riveControllers[artboardId] = RiveAnimationController();
    artboard.addController(_riveControllers[artboardId]!);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.isExpanded ? 280 : 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ColorApp.background.withValues(alpha: 0.95),
            ColorApp.background.withValues(alpha: 0.98),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête premium
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        ColorApp.primary1,
                        ColorApp.primary2,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ColorApp.primary1.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.diamond_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                if (widget.isExpanded) ...[
                  const SizedBox(width: 12),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: widget.isExpanded ? 1.0 : 0.0,
                    child:                      CustomText(
                      'sidebar.premium',
                      type: TextType.headlineSmall,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        background: null,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Menu items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 20),
              itemCount: widget.menuItems.length,
              itemBuilder: (context, index) {
                final menu = widget.menuItems[index];
                return PremiumSideMenu(
                  menu: menu,
                  press: () => widget.onMenuSelected(menu),
                  riveOnInit: (artboard) => _onRiveInit(menu.rive.artboard, artboard),
                  selectedMenu: widget.selectedMenu,
                  index: index,
                  isExpanded: widget.isExpanded,
                );
              },
            ),
          ),

          // Section utilisateur
          Container(
            padding:  EdgeInsets.all(16),
            margin:  EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.05),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        ColorApp.primary3.withValues(alpha: 0.3),
                        ColorApp.primary3.withValues(alpha: 0.1),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                if (widget.isExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          'sidebar.admin_user',
                          type: TextType.labelMedium,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        CustomText(
                          'sidebar.premium_account',
                          type: TextType.labelSmall,
                          style: TextStyle(
                            color: ColorApp.primary1,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
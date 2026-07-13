import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart' hide LinearGradient, RadialGradient;
import 'dart:math';

import '../../../model/menu.dart';
import 'package:kongossa/shared/widgets/widgets.dart';
import 'package:kongossa/config_App/colorsApp.dart';

/// Type of image to display.
enum ImageType {
  network,
  circle,
  asset,
  file,
}

/// A custom image widget supporting different image sources and shapes.
class CustomImage extends StatelessWidget {
  final String? source;
  final String? imageUrl;
  final ImageType type;
  final double? height;
  final double? width;
  final BoxFit fit;

  const CustomImage({
    super.key,
    this.source,
    this.imageUrl,
    this.type = ImageType.network,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final url = source ?? imageUrl ?? '';
    if (url.isEmpty) {
      return const Icon(Icons.person, size: 40, color: Colors.grey);
    }

    final image = CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
    );

    if (type == ImageType.circle) {
      return ClipOval(
        child: SizedBox(
          width: height ?? 40,
          height: height ?? 40,
          child: image,
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: image,
    );
  }
}

/// Widget for a premium sidebar menu item (duplicated from side_menu.dart
/// to resolve the ambiguous import).
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
  bool _isHovered = false;

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
      end: ColorApp.primary1.withAlpha(25), // 0.1 * 255 ≈ 25
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
    _isHovered = isHovered;
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
    final bool shouldAnimate = isSelected || _isHovered;

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
                      ColorApp.primary1.withAlpha(230), // 0.9 * 255 ≈ 230
                      ColorApp.primary2.withAlpha(179), // 0.7 * 255 ≈ 179
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
                        color: ColorApp.primary1.withAlpha(102), // 0.4 * 255 ≈ 102
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    BoxShadow(
                      color: Colors.black.withAlpha(13), // 0.05 * 255 ≈ 13
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
                                  Colors.white.withAlpha(51), // 0.2 * 255 ≈ 51
                                  Colors.white.withAlpha(0),
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
                                  ColorApp.primary1.withAlpha(77), // 0.3 * 255 ≈ 77
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
                        splashColor: ColorApp.primary1.withAlpha(77), // 0.3 * 255 ≈ 77
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
                                            ColorApp.primary1.withAlpha(102), // 0.4 * 255 ≈ 102
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
                                          ? Colors.white.withAlpha(26) // 0.1 * 255 ≈ 26
                                          : ColorApp.primary3.withAlpha(26),
                                      boxShadow: [
                                        if (isSelected)
                                          BoxShadow(
                                            color: ColorApp.primary1
                                                .withAlpha(77), // 0.3 * 255 ≈ 77
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
                                  secondChild: const SizedBox.shrink(),
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
                                        color: Colors.white.withAlpha(204), // 0.8 * 255 ≈ 204
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
    // Créer un nouveau contrôleur si nécessaire
    if (!_riveControllers.containsKey(artboardId)) {
      _riveControllers[artboardId] = SimpleAnimation('idle');
    }
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
            ColorApp.background.withAlpha(242), // 0.95 * 255 ≈ 242
            ColorApp.background.withAlpha(250), // 0.98 * 255 ≈ 250
          ],
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26), // 0.1 * 255 ≈ 26
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
                        color: ColorApp.primary1.withAlpha(77), // 0.3 * 255 ≈ 77
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
                    child: const CustomText(
                      'sidebar.premium',
                      type: TextType.headlineSmall,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
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
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withAlpha(13), // 0.05 * 255 ≈ 13
                  Colors.white.withAlpha(5), // 0.02 * 255 ≈ 5
                ],
              ),
              border: Border.all(
                color: Colors.white.withAlpha(26), // 0.1 * 255 ≈ 26
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
                        ColorApp.primary3.withAlpha(77), // 0.3 * 255 ≈ 77
                        ColorApp.primary3.withAlpha(26), // 0.1 * 255 ≈ 26
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withAlpha(51), // 0.2 * 255 ≈ 51
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
                        const CustomText(
                          'sidebar.admin_user',
                          type: TextType.labelMedium,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const CustomText(
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
                          color: Colors.green.withAlpha(128), // 0.5 * 255 ≈ 128
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
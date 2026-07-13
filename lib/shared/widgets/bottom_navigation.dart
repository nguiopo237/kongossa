import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

import '../../config_App/colorsApp.dart';
import '../../sevice/controlleur/authentification/auth_controlleur.dart';
import 'package:get/get.dart';

class KongossaTikTokNavBar extends StatefulWidget {
  @override
  _KongossaTikTokNavBarState createState() => _KongossaTikTokNavBarState();
}

class _KongossaTikTokNavBarState extends State<KongossaTikTokNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> animation;

  final List<Map<String, dynamic>> _navItems = [
    {
      'icon': Icons.home_outlined,
      'activeIcon': Icons.home,
      'label': 'nav.home',
      'index': '0',
      'gradient': [ColorApp.premiumGold, ColorApp.premiumGoldLight, ColorApp.premiumGold],
    },
    {
      'icon': Icons.people_outline,
      'activeIcon': Icons.people,
      'label': 'nav.kongoss',
      'index': '1',
      'gradient': [ColorApp.premiumGold, ColorApp.premiumAmber, ColorApp.premiumGold],
    },
    {
      'icon': Icons.add_box_outlined,
      'activeIcon': Icons.add_box,
      'label': 'nav.post',
      'index': '2',
      'gradient': [ColorApp.premiumGoldLight, ColorApp.premiumGold, ColorApp.premiumGoldLight],
    },
    {
      'icon': Icons.chat_bubble_outline,
      'activeIcon': Icons.chat_bubble,
      'label': 'nav.chats',
      'index': '3',
      'gradient': [ColorApp.premiumGold, ColorApp.premiumRose, ColorApp.premiumGold],
    },
    {
      'icon': Icons.person_outline,
      'activeIcon': Icons.person,
      'label': 'nav.profile',
      'index': '4',
      'gradient': [ColorApp.premiumAmber, ColorApp.premiumGoldLight, ColorApp.premiumAmber],
    },
    {
      'icon': Icons.live_tv_outlined,
      'activeIcon': Icons.live_tv,
      'label': 'nav.live',
      'index': '5',
      'gradient': [ColorApp.premiumGold, ColorApp.premiumRose, ColorApp.premiumGold],
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  int get _selectedIndex => authController.indexpage.value;

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 100 * (1 - animation.value)),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0A0A0A),
                  const Color(0xFF1A1A1A).withValues(alpha: 0.95),
                  const Color(0xFF2A2A2A).withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.1, 0.8, 1.0],
              ),
              border: Border(
                top: BorderSide(
                  color: ColorApp.premiumGold.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: ColorApp.premiumGold.withValues(alpha: 0.1),
                  offset: const Offset(0, -4),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  color: Colors.transparent,
                  child: Obx(() => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      _navItems.length,
                          (index) => _buildPremiumNavItem(
                        item: _navItems[index],
                        isSelected: authController.indexpage.value == index,
                        index: index,
                      ),
                    ),
                  )),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumNavItem({
    required Map<String, dynamic> item,
    required bool isSelected,
    required int index,
  }) {
    return GestureDetector(
      onTap: () {
        authController.indexpage.value = index;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 18 : 8,
          vertical: 6,
        ),
        decoration: isSelected
            ? BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    item['gradient'][0],
                    item['gradient'][1],
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: item['gradient'][0].withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: item['gradient'][0].withValues(alpha: 0.15),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 0),
                  ),
                ],
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item['activeIcon'] : item['icon'],
              color: isSelected
                  ? Colors.black
                  : const Color(0xFF666666),
              size: isSelected ? 24 : 20,
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Text(
                item['label'].toString().tr,
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'dart:ui';

import '../../../main.dart';
import '../../../model/datamodel/user_model.dart';
import '../../../sevice/controlleur/authentification/auth_controlleur.dart';
import '../style/custum_text.dart'; // pour ImageFilter

class KongossaTikTokNavBar extends StatefulWidget {
  @override
  _KongossaTikTokNavBarState createState() => _KongossaTikTokNavBarState();
}

class _KongossaTikTokNavBarState extends State<KongossaTikTokNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> animation;
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _navItems = [
    {
      'icon': Icons.home_outlined,
      'activeIcon': Icons.home,
      'label': 'Accueil',
      'index': '0',
      'gradient': [Color(0xFFFF6B6B), Color(0xFFFF8E53), Color(0xFFFF6B6B)],
    },
    {
      'icon': Icons.people_outline,
      'activeIcon': Icons.people,
      'label': 'Kongoss',
      'index': '1',
      'gradient': [Color(0xFF6C5CE7), Color(0xFFFF6B6B), Color(0xFF6C5CE7)],
    },
    {
      'icon': Icons.add_box_outlined,
      'activeIcon': Icons.add_box,
      'label': 'Poster',
      'index': '2',
      'gradient': [Color(0xFFFFD93D), Color(0xFFFF8E53), Color(0xFFFFD93D)],
    },
    {
      'icon': Icons.chat_bubble_outline,
      'activeIcon': Icons.chat_bubble,
      'label': 'Messages',
      'index': '3',
      'gradient': [Color(0xFFFF6B6B), Color(0xFF6C5CE7), Color(0xFFFF6B6B)],
    },
    {
      'icon': Icons.person_outline,
      'activeIcon': Icons.person,
      'label': 'Profil',
      'index': '4',
      'gradient': [Color(0xFFFF8E53), Color(0xFFFFD93D), Color(0xFFFF8E53)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }




  @override
  Widget build(BuildContext context) {


    return Container(height: 7.7.h,
      child: Column( mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: animation,

              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 100 * (1 - animation.value)),
                  child: Container(
                    padding: EdgeInsets.symmetric( vertical: 0.5.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF0A0A0A),
                          Color(0xFF1A1A1A).withOpacity(0.95),
                          Color(0xFF2A2A2A).withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: const [0.1, 0.8, 1.0],
                      ),
                      // border: Border.all(
                      //   color: Colors.white.withOpacity(0.15),
                      //   width: 1.2,
                      // ),
                      border: Border(top: BorderSide(color: Colors.white.withOpacity(0.15))),

                      // borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFFF6B6B).withOpacity(0.15),
                          offset: const Offset(0, 8),
                          blurRadius: 24,
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          offset: const Offset(0, 2),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(0),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                           padding: EdgeInsets.only(bottom: 2.h),
                          color: Colors.black,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(
                              _navItems.length,
                                  (index) => Expanded(child: _buildKongossaNavItem(
                                    item: _navItems[index],
                                    isSelected: _selectedIndex == index,
                                    index: index,
                                  )),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKongossaNavItem({
    required Map<String, dynamic> item,
    required bool isSelected,
    required int index,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
          authController.indexpage.value = index;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 250),
        curve: Curves.easeOutQuint,
        padding: EdgeInsets.symmetric(
          // horizontal: isSelected ? 20 : 10,
          vertical: 0.5,
        ),
        // decoration: isSelected
        //     ? BoxDecoration(
        //   gradient: LinearGradient(
        //     colors: [
        //       item['gradient'][0],
        //       item['gradient'][1],
        //     ],
        //     begin: Alignment.topLeft,
        //     end: Alignment.bottomRight,
        //   ),
        //   borderRadius: BorderRadius.circular(25),
        //   boxShadow: [
        //     BoxShadow(
        //       color: item['gradient'][0].withOpacity(0.4),
        //       blurRadius: 12,
        //       spreadRadius: 1,
        //       offset: Offset(0, 2),
        //     ),
        //   ],
        // )
        //     : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(
                  isSelected ? item['activeIcon'] : item['icon'],
                  color: isSelected
                      ? Colors.white
                      : Color(0xFF4A4A4A).withOpacity(0.8),
                  size: isSelected ? 2.5.h  : 2.h,
                ),

                StreamBuilder(
                  stream: Sms

                      .where('receiveId', isEqualTo: AppUser.info!.googleId)
                      .where('isRead', isEqualTo: false)
                      .snapshots(),
                  builder: (context, asyncSnapshot) {
                  final  totalUnreadMessages = asyncSnapshot.data?.docs.length ?? 0;
                  print( asyncSnapshot.data?.docs.length);
                  // asyncSnapshot.data?.docs.map((e) => print(e["content"]),).toList();
                    return Positioned(
                      right: 0,
                      child: Visibility(
                        visible: totalUnreadMessages!=0&&index==3,
                        child: CircleAvatar(
                          backgroundColor: Colors.red,
                          radius: 11.sp,
                          child: CustomText(
                            totalUnreadMessages.toString(),
                            type: TextType.button,

                            style: TextStyle(color: Colors.white,fontSize: 12.sp,fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  }
                ),
              ],
            ),
            if (isSelected) ...[
              // SizedBox(width: 8),
              Text(
                item['label'],
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import '../../../model/menu.dart';
import 'animated_bar.dart';

class BtmNavItem extends StatelessWidget {
  const BtmNavItem(
      {super.key,
      required this.navBar,
      required this.press,
      required this.riveOnInit,
      required this.selectedNav});

  final Menu navBar;
  final VoidCallback press;
  final ValueChanged<Artboard> riveOnInit;
  final Menu selectedNav;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: press,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBar(isActive: selectedNav == navBar),
          SizedBox(
            height: 30,
            width: 30,
            child: Opacity(
              opacity: selectedNav == navBar ? 1 : 0.8,
              child: RiveAnimation.asset(
                navBar.rive.src,
                artboard: navBar.rive.artboard,
                onInit: riveOnInit,
                fit: BoxFit.cover,
                useArtboardSize: true,

              ),
            ),
          ),
        ],
      ),
    );
  }
}

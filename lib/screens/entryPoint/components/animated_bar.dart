import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class AnimatedBar extends StatelessWidget {
  const AnimatedBar({
    super.key,
    required this.isActive,
  });

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      margin: const EdgeInsets.only(bottom: 2),
      duration: const Duration(milliseconds: 200),
      height: 4,
      width: isActive ? 10.w : 0,
      decoration: const BoxDecoration(
          color: Color(0xFF81B4FF),
          borderRadius: BorderRadius.all(
            Radius.circular(12),
          )),
    );
  }
}

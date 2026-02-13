import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kongossa/config_App/colorsApp.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:rive/rive.dart';
import 'package:shimmer/shimmer.dart';

import '../../../presentation/component/style/custum_text.dart';

class AnimatedBtn extends StatelessWidget {
  const AnimatedBtn({
    super.key,
    required RiveAnimationController btnAnimationController,
    required this.press,
  }) : _btnAnimationController = btnAnimationController;

  final RiveAnimationController _btnAnimationController;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: press,
      child: SizedBox(
        height: 64,
        width: 236,
        child: Stack(
          children: [
            RiveAnimation.asset(
              "assets/RiveAssets/button.riv",
              controllers: [_btnAnimationController],
            ),
            Positioned.fill(
              top: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.right_chevron,color: ColorApp.primary2,),
                   SizedBox(width: 2.w),
                  Shimmer.fromColors(
                    baseColor: ColorApp.primary1,
                    highlightColor: ColorApp.BlackColor2,
                    child: CustomText(
                      "Commencer",
                    //  style: Theme.of(context).textTheme.labelLarge,
                        type: TextType.button
                    ),
                  )
                ],
              ),
            ),
        // SizedBox(
        //   width: 200.0,
        //   height: 100.0,
        //   child: Shimmer.fromColors(
        //     baseColor: Colors.red,
        //     highlightColor: Colors.yellow,
        //     child: Text(
        //       'Shimmer',
        //       textAlign: TextAlign.center,
        //       style: TextStyle(
        //         fontSize: 40.0,
        //         fontWeight:
        //         FontWeight.bold,
        //       ),
        //     ),
        //   ),
        // ),
          ],
        ),
      ),
    );
  }
}

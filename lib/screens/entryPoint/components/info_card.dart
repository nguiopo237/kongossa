import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kongossa/config_App/colorsApp.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../presentation/component/image_component/image.dart';
import '../../../presentation/component/style/custum_text.dart';

class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.name,
    required this.bio,
    this.image = null,
  });

  final String? name, bio, image;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: image == ""
          ? CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(CupertinoIcons.person, color: ColorApp.primary1.withOpacity(0.5)),
            )
          : CustomImage(
              source: image!,
              type: ImageType.avatar,
              width: 12.w,
              height: 16.h,
            ),
      title: CustomText(
        "${name}".toUpperCase(),
        type: TextType.headlineSmall,
        style: TextStyle(
          color: ColorApp.primary3,
          fontWeight: FontWeight.w600,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
      ),

      subtitle: CustomText(
        "${bio}".toUpperCase(),
        type: TextType.headlineSmall,
        style: TextStyle(
          color: ColorApp.primary3,
          fontWeight: FontWeight.w600,
          fontSize: 12.sp,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

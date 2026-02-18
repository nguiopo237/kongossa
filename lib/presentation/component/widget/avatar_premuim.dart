// lib/presentation/widgets/premium_avatar.dart

import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../config_App/image.dart';
import '../../../model/datamodel/user_model.dart';
import '../../../sevice/controlleur/splashcontrolleur/splashscreen_controlleur.dart';
import '../../../sevice/theme/theme_profil.dart';

class PremiumAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? userId;
  final double size;
  final bool hasStory;
  final bool isLive;
  final bool isVerified;
  final VoidCallback? onTap;

  const PremiumAvatar({
    Key? key,
    this.imageUrl,
    this.userId,
    this.size = 60,
    this.hasStory = false,
    this.isLive = false,
    this.isVerified = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            padding: EdgeInsets.all(hasStory ? 3 : 0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasStory
                  ? const LinearGradient(
                      colors: [
                        Color(0xFFFCE38A),
                        Color(0xFFFF6B6B),
                        Color(0xFFA8E6CF),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: hasStory ? Colors.black : Colors.transparent,
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: size / 2,
                backgroundImage: imageUrl != null
                    ? NetworkImage(imageUrl!)
                    : const AssetImage(Consticon.profils)
                as ImageProvider,
                backgroundColor: Colors.grey[800],
                child: Visibility(
                  visible:  imageUrl == null,
                  child: s.buildUserProfile(
                  width: 40.w,
                  height: 40.h,
                  uid: AppUser.info!.googleId == userId ? null : userId,
                ),),
              ),
            ),
          ),
          if (isLive)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (isVerified)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 12),
              ),
            ),
        ],
      ),
    );
  }
}

// lib/presentation/widgets/premium_avatar.dart

import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../sevice/theme/theme_profil.dart';

class PremiumAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final bool hasStory;
  final bool isLive;
  final bool isVerified;
  final VoidCallback? onTap;

  const PremiumAvatar({
    Key? key,
    this.imageUrl,
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
                    : const AssetImage('assets/default_avatar.png')
                as ImageProvider,
                backgroundColor: Colors.grey[800],
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
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
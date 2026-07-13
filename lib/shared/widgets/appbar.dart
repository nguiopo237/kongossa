import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'select_media.dart';
import 'package:kongossa/shared/widgets/widgets.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:get/get.dart';

import '../../config_App/colorsApp.dart';
import '../../config_App/image.dart';
import '../../sevice/controlleur/firestore_collections_service.dart';
import '../../model/datamodel/user_model.dart';
import 'component_for_post/create_post_widget.dart';
import 'notification_button.dart';

class ProfessionalAppBar extends StatelessWidget {
  final VoidCallback? onCreatePost;
  final VoidCallback? onProfileTap;
  final ValueChanged<String>? onSearch;

  const ProfessionalAppBar({
    super.key,
    this.onCreatePost,
    this.onProfileTap,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      width: double.infinity,
      height: 7.h,
      padding: EdgeInsets.symmetric(horizontal: 2.w),
      child: Row(
        children: [
          _buildPremiumLogo(),
          SizedBox(width: 3.w),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildPremiumSearchBar()),
                SizedBox(width: 2.w),
                NotificationPopupButton(bellColor: ColorApp.premiumGoldLight),
                SizedBox(width: 2.w),
                _buildPremiumUserProfile(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Logo premium avec effet shimmer doré
  Widget _buildPremiumLogo() {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        colors: const [
          Color(0xFFD4AF37),
          Color(0xFFF0D060),
          Color(0xFFFFE44D),
          Color(0xFFD4AF37),
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Container(
        height: 5.h,
        width: 22.w,
        child: CustomImage(
          source: Consticon.logo,
          type: ImageType.asset,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  /// Barre de recherche premium glassmorphism avec bordures dorées
  Widget _buildPremiumSearchBar() {
    return Container(
      height: 5.5.h,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ColorApp.premiumGold.withValues(alpha: 0.15),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorApp.premiumGold.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextFormField(
        onChanged: onSearch,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 13.sp),
        decoration: InputDecoration(
          hintText: 'search.hint'.tr,
          hintStyle: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 12.sp,
            fontWeight: FontWeight.w300,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: ColorApp.premiumGold.withValues(alpha: 0.5),
            size: 16.sp,
          ),
          suffixIcon: Container(
            margin: EdgeInsets.all(0.8.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColorApp.premiumGold.withValues(alpha: 0.3),
                  ColorApp.premiumGoldLight.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.tune_rounded,
              color: ColorApp.premiumGold,
              size: 16.sp,
            ),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        ),
      ),
    );
  }

  /// Profil utilisateur premium avec halo doré
  Widget _buildPremiumUserProfile() {
    return StreamBuilder(
      stream: FirestoreCollectionsService.users.where(
        'googleId',
        isEqualTo: AppUser.info?.googleId,
      ).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildProfileShimmer();
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _buildDefaultProfile();
        }
        try {
          final document = snapshot.data!.docs.first;
          return _buildPremiumProfileContent(document, context);
        } catch (e) {
          return _buildDefaultProfile();
        }
      },
    );
  }

  /// Contenu du profil premium avec halo doré animé
  Widget _buildPremiumProfileContent(DocumentSnapshot document, BuildContext context) {
    return Container(
      padding: EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        gradient: const SweepGradient(
          colors: [
            Color(0xFFD4AF37),
            Color(0xFFF0D060),
            Color(0xFFFFF8DC),
            Color(0xFFD4AF37),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: ColorApp.premiumGold.withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.all(1.5),
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A0A),
          shape: BoxShape.circle,
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: document["photoUrl"] == null || document["photoUrl"] == ""
                  ? Container(
                      width: 9.w,
                      height: 9.w,
                      color: const Color(0xFF1A1A1A),
                      child: Icon(
                        CupertinoIcons.person_fill,
                        size: 5.w,
                        color: Theme.of(Get.context!).colorScheme.outline,
                      ),
                    )
                  : CustomImage(
                      source: document["photoUrl"]!,
                      type: ImageType.network,
                      width: 8.w,
                      height: 8.w,
                      fit: BoxFit.cover,
                    ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 2.5.w,
                height: 2.5.w,
                decoration: BoxDecoration(
                  color: ColorApp.premiumGoldLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0A0A0A), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: ColorApp.premiumGold.withValues(alpha: 0.6),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Effet de chargement premium
  Widget _buildProfileShimmer() {
    return Container(
      width: 11.w,
      height: 11.w,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        shape: BoxShape.circle,
        border: Border.all(
          color: ColorApp.premiumGold.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: SizedBox(
          width: 4.w,
          height: 4.w,
          child: CircularProgressIndicator(
            strokeWidth: 0.3.w,
            valueColor: AlwaysStoppedAnimation<Color>(ColorApp.premiumGold),
          ),
        ),
      ),
    );
  }

  /// Profil par défaut premium
  Widget _buildDefaultProfile() {
    return Container(
      width: 11.w,
      height: 11.w,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        shape: BoxShape.circle,
        border: Border.all(
          color: ColorApp.premiumGold.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorApp.premiumGold.withValues(alpha: 0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Icon(
        CupertinoIcons.person_crop_circle,
        color: ColorApp.premiumGold,
        size: 6.w,
      ),
    );
  }
}

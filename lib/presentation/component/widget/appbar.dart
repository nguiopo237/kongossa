import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kongossa/presentation/component/widget/select_media.dart';
import 'package:kongossa/presentation/component/widget/widget_component.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:get/get.dart';

import '../../../config_App/colorsApp.dart';
import '../../../config_App/image.dart';
import '../../../main.dart';
import '../../../model/datamodel/user_model.dart';
import '../image_component/image.dart';
import 'component_for_post/create_post_widget.dart';

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
      color: Colors.white,
      width: double.infinity,
      height: 10.h,
      padding: EdgeInsets.symmetric(horizontal: 2.w),
      child: Row(
        children: [
          // Logo avec effet de gradient
          _buildLogo(),
          SizedBox(width: 3.w),

          // Section recherche et actions
          Expanded(
            child: Row(
              children: [
                // Barre de recherche améliorée
                Expanded(
                  child: _buildSearchBar(),
                ),
                SizedBox(width: 2.w),

                // Bouton création de post
                // _buildCreatePostButton(),
                SizedBox(width: 2.w),

                // Profil utilisateur avec menu
                _buildUserProfile(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Logo avec effet moderne
  Widget _buildLogo() {
    return Container(
      height: 8.h,
      width: 20.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            ColorApp.primary1.withOpacity(0.1),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CustomImage(
        source: Consticon.logo,
        type: ImageType.asset,
        height: 7.h,
        width: 18.w,
        fit: BoxFit.contain,
      ),
    );
  }

  // Barre de recherche moderne
  Widget _buildSearchBar() {
    return Container(
      height: 6.h,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        onChanged: onSearch,
        decoration: InputDecoration(
          hintText: "Rechercher...",
          hintStyle: GoogleFonts.inter(
            color: Colors.grey[400],
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey[400],
            size: 20.sp,
          ),
          suffixIcon: Container(
            margin: EdgeInsets.all(1.w),
            decoration: BoxDecoration(
              color: ColorApp.primary1.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.tune_rounded,
              color: ColorApp.primary1,
              size: 18.sp,
            ),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 3.w,
            vertical: 1.h,
          ),
        ),
      ),
    );
  }

  // Bouton de création avec animation
  Widget _buildCreatePostButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 6.h,
      width: 6.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorApp.primary1,
            ColorApp.primary2,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: ColorApp.primary1.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onCreatePost ?? () {
            WidgetComponent.getmodal(
              sectionview: Container(
                height: Get.height,
                child: CreatePostPremiumScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(15),
          child: Center(
            child: Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 22.sp,
            ),
          ),
        ),
      ),
    );
  }

  // Profil utilisateur premium
  Widget _buildUserProfile() {
    return StreamBuilder(
      stream: Users.where('googleId', isEqualTo: AppUser.info?.googleId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildProfileShimmer();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildDefaultProfile();
        }

        try {
          final document = snapshot.data!.docs.first;
          return _buildProfileContent(document);
        } catch (e) {
          return _buildDefaultProfile();
        }
      },
    );
  }

  // Contenu du profil
  Widget _buildProfileContent(DocumentSnapshot document) {
    return Container(
      padding: EdgeInsets.all(0.5.w),
      decoration: BoxDecoration(
        gradient: SweepGradient(
          colors: [
            ColorApp.primary1,
            ColorApp.primary2,
            ColorApp.primary3,
            ColorApp.primary1,
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Container(
        padding: EdgeInsets.all(0.3.w),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Stack(
          children: [
            // Avatar
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: document["photoUrl"] == null || document["photoUrl"] == ""
                  ? Container(
                width: 12.w,
                height: 12.w,
                color: Colors.grey[100],
                child: Icon(
                  CupertinoIcons.person_fill,
                  size: 6.w,
                  color: Colors.grey[400],
                ),
              )
                  : CustomImage(
                source: document["photoUrl"]!,
                type: ImageType.network,
                width: 12.w,
                height: 12.w,
                fit: BoxFit.cover,
              ),
            ),

            // Badge de statut en ligne
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 2.5.w,
                height: 2.5.w,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 0.2.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.4),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),

            // Bouton d'upload
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  WidgetComponent.getmodal(
                    sectionview: Container(
                      height: 60.h,
                      child: PremiumMediaSelector(
                        onSourceSelected: (p1) {},
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 4.w,
                  height: 4.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ColorApp.primary1,
                        ColorApp.primary2,
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 0.2.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ColorApp.primary1.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.add_a_photo_rounded,
                    color: Colors.white,
                    size: 2.w,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Effet de chargement
  Widget _buildProfileShimmer() {
    return Container(
      width: 12.w,
      height: 12.w,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SizedBox(
          width: 4.w,
          height: 4.w,
          child: CircularProgressIndicator(
            strokeWidth: 0.3.w,
            valueColor: AlwaysStoppedAnimation<Color>(ColorApp.primary1),
          ),
        ),
      ),
    );
  }

  // Profil par défaut
  Widget _buildDefaultProfile() {
    return Container(
      width: 12.w,
      height: 12.w,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorApp.primary1.withOpacity(0.1),
            ColorApp.primary2.withOpacity(0.1),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        CupertinoIcons.person_crop_circle,
        color: ColorApp.primary1,
        size: 8.w,
      ),
    );
  }
}

// Extension pour les couleurs (à ajouter dans votre ColorApp)
extension ProfessionalColors on ColorApp {
  static Color get primary2 => const Color(0xFF6C63FF);
  static Color get primary3 => const Color(0xFFFF6B6B);
  static Color get primary4 => const Color(0xFF4ECDC4);
  static Color get primary5 => const Color(0xFFA8E6CF);
}
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';

import '../../../config_App/colorsApp.dart';
import '../../../model/datamodel/user_model.dart';
import '../../../utils/transitions.dart';
import 'package:kongossa/sevice/upload/upload.dart';
import '../../../presentation/component/video_component/comment_video.dart';
import '../../../presentation/component/video_component/tiktok_player_video.dart';
import 'package:kongossa/shared/widgets/widgets.dart';

class PremiumPostcard extends StatefulWidget {
  final String? image;
  final String? name;
  final List<dynamic>? alllike;
  final String? bio;
  final String id;
  final String? content;
  final String? postImage;
  final String? postVideo;
  final int likes;
  final int comments;
  final int shares;
  final bool isVerified;
  final bool isLike;
  final bool isBookmarked;
  final DateTime? timestamp;
  final String? location;
  final String? privacy;
  final List<String>? carouselImages; 
  final VoidCallback? onBookmark;
  final VoidCallback? onShare;
  final VoidCallback? onComment;
  final VoidCallback? onMore;
  final VoidCallback? onProfileTap;
  final VoidCallback? onLikeCountTap;

  const PremiumPostcard({
    super.key,
    this.image = "",
    this.name = "",
    this.bio = "",
    this.isLike = false,
    this.content,
    required this.id,
    this.postImage,
    this.alllike,
    this.postVideo,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.isVerified = false,
    this.isBookmarked = false,
    this.timestamp,
    this.location,
    this.privacy,
    this.carouselImages, 
    this.onBookmark,
    this.onShare,
    this.onComment,
    this.onMore,
    this.onProfileTap,
    this.onLikeCountTap,
  });

  @override
  State<PremiumPostcard> createState() => _PremiumPostcardState();
}

class _PremiumPostcardState extends State<PremiumPostcard> with TickerProviderStateMixin {
  bool _isLiked = false;
  bool _isBookmarked = false;
  String? _mediaType;
  int _currentCarouselIndex = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late PageController _pageController;

  WidgetComponent item = WidgetComponent();

  verifie() async {
    if (widget.postImage != null && widget.postImage!.isNotEmpty) {
      final type = await UniversalCloudinaryUploader.detectResourceType(widget.postImage!);
      if (mounted) {
        setState(() {
          _mediaType = UniversalCloudinaryUploader.resourceTypeToString(type);
        });
      }
    }
  }

  PostUpdateService service = PostUpdateService();

  @override
  void initState() {
    super.initState();
    _isBookmarked = widget.isBookmarked;
    if (widget.postImage != null) {
      verifie();
    }

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.elasticOut),
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _pageController = PageController();
    _slideController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<bool> _onLikeButtonTapped(bool isLiked) async {
    setState(() {
      _isLiked = !isLiked;
      if (_isLiked) {
        _pulseController.forward().then((_) => _pulseController.reset());
      }
    });
    service.toggleLike(postId: widget.id, isLiked: _isLiked, like: widget.likes);
    return _isLiked;
  }

  Future<bool> _onBookmarkTapped(bool isBookmarked) async {
    setState(() {
      _isBookmarked = !isBookmarked;
    });
    widget.onBookmark?.call();
    return _isBookmarked;
  }

  String _getTimeAgo() {
    if (widget.timestamp != null) {
      return timeago.format(widget.timestamp!, locale: Get.locale?.languageCode ?? 'en');
    }
    return 'post.just_now'.tr;
  }

  Widget _buildMediaContent() {
    if (widget.postVideo != null && widget.postVideo!.isNotEmpty) {
      return Container(
        height: 60.h,
        child: Stack(
          children: [
            ClipRRect(
              child: TikTokVideoPlayer(
                id: widget.id,
                videoUrl: widget.postVideo!,
                username: '',
                description: '',
                music: '',
                profileImage: '',
              ),
            ),
            Positioned(
              bottom: 2.w,
              right: 2.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.8.h),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ColorApp.premiumGold.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.volume_up_rounded, color: ColorApp.premiumGold, size: 14.sp),
                    SizedBox(width: 1.w),
                    CustomText(
                      "HD",
                      style: GoogleFonts.poppins(
                        color: ColorApp.premiumGold,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (widget.carouselImages != null && widget.carouselImages!.isNotEmpty) {
      return _buildCarousel();
    }

    if (widget.postImage != null && widget.postImage!.isNotEmpty) {
      if (_mediaType != null && _mediaType!.toLowerCase().contains('video')) {
        return const SizedBox.shrink();
      }
      return _buildPremiumPostImage();
    }

    return const SizedBox.shrink();
  }

  Widget _buildCarousel() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 1.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorApp.premiumGold.withValues(alpha: 0.15),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: ColorApp.premiumGold.withValues(alpha: 0.05),
            blurRadius: 30,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 45.h,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.carouselImages!.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentCarouselIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return CachedNetworkImage(
                    imageUrl: widget.carouselImages![index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: const Color(0xFF2A2A2A),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            ColorApp.premiumGold.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: const Color(0xFF2A2A2A),
                      child: Icon(
                        Icons.broken_image,
                        size: 40.sp,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            bottom: 2.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: ColorApp.premiumGold.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: List.generate(
                  widget.carouselImages!.length,
                      (index) => Container(
                    width: 2.w,
                    height: 2.w,
                    margin: EdgeInsets.symmetric(horizontal: 0.5.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentCarouselIndex
                          ? ColorApp.premiumGold
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 2.w,
            right: 2.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.8.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ColorApp.premiumGold.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.photo_library_rounded,
                    color: ColorApp.premiumGold,
                    size: 14.sp,
                  ),
                  SizedBox(width: 1.w),
                  CustomText(
                    "${_currentCarouselIndex + 1}/${widget.carouselImages!.length}",
                    style: GoogleFonts.poppins(
                      color: ColorApp.premiumGold,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 0.5.h, horizontal: 1.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1A1A1A),
              const Color(0xFF222222),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: ColorApp.premiumGold.withValues(alpha: 0.08),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: ColorApp.premiumGold.withValues(alpha: 0.03),
              blurRadius: 40,
              spreadRadius: -10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildContentSection(),
            _buildMediaContent(),
            _buildEngagementBar(),
            _buildActionRow(),
            if (widget.comments > 0) _buildCommentsPreview(),
            SizedBox(height: 1.h),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(3.w),
      child: Row(
        children: [
          InkWell(
            onTap: widget.onProfileTap,
            borderRadius: BorderRadius.circular(100),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(
                  colors: [
                    ColorApp.premiumGold,
                    ColorApp.premiumGoldLight,
                    ColorApp.premiumChampagne,
                    ColorApp.premiumGold,
                  ],
                ),
              ),
              padding: EdgeInsets.all(1.5),
              child: AppTransitions.heroAvatar(
                userId: widget.id,
                child: CircleAvatar(
                  radius: 19.sp,
                  backgroundColor: const Color(0xFF1A1A1A),
                  backgroundImage: widget.image != null && widget.image!.isNotEmpty
                      ? CachedNetworkImageProvider(widget.image!)
                      : null,
                  child: widget.image == null || widget.image!.isEmpty
                      ? Icon(CupertinoIcons.person_fill, size: 20.sp, color: Theme.of(context).colorScheme.onSurfaceVariant)
                      : null,
                ),
              ),
            ),
          ),
          SizedBox(width: 2.5.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: InkWell(
                        onTap: widget.onProfileTap,
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [ColorApp.premiumGold, ColorApp.premiumGoldLight],
                          ).createShader(bounds),
                          child: Text(
                            widget.name ?? 'post.unknown_user'.tr,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 15.sp,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    if (widget.isVerified) ...[
                      SizedBox(width: 0.8.w),
                      Container(
                        padding: EdgeInsets.all(0.5.w),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [ColorApp.premiumGold, ColorApp.premiumGoldLight],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.verified,
                          color: Colors.black,
                          size: 12.sp,
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 0.3.h),
                Row(
                  children: [
                    if (widget.bio != null && widget.bio!.isNotEmpty) ...[
                      Text(
                        widget.bio!,
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w400,
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(width: 1.w),
                      Container(width: 0.3.w, height: 1.5.h, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      SizedBox(width: 1.w),
                    ],
                    Icon(
                      widget.privacy == "public" ? Icons.public : Icons.lock,
                      size: 12.sp,
                      color: ColorApp.premiumGold.withValues(alpha: 0.5),
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      "•",
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12.sp),
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      _getTimeAgo(),
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              if (widget.location != null)
                Container(
                  margin: EdgeInsets.only(right: 2.w),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.location, size: 14.sp, color: ColorApp.premiumGold.withValues(alpha: 0.5)),
                      SizedBox(width: 0.5.w),
                      Text(
                        widget.location!,
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ColorApp.premiumGold.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                  color: const Color(0xFF2A2A2A),
                ),
                child: IconButton(
                  onPressed: widget.onMore,
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    color: ColorApp.premiumGold.withValues(alpha: 0.6),
                    size: 18.sp,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints.tightFor(width: 7.w, height: 7.w),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    if (widget.content == null || widget.content!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      child: ExpandableText(
        widget.content!,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 14.5.sp,
          height: 1.5,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          letterSpacing: -0.2,
        ),
        expandText: 'post.see_more'.tr,
        collapseText: 'post.see_less'.tr,
        maxLines: 3,
        linkColor: ColorApp.premiumGold,
        linkStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 13.5.sp,
          color: ColorApp.premiumGold,
        ),
        hashtagStyle: GoogleFonts.poppins(
          color: ColorApp.premiumGold,
          fontWeight: FontWeight.w600,
        ),
        mentionStyle: GoogleFonts.poppins(
          color: ColorApp.premiumGoldLight,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPremiumPostImage() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorApp.premiumGold.withValues(alpha: 0.1),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: widget.postImage!,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 40.h,
                color: const Color(0xFF2A2A2A),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ColorApp.premiumGold.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 40.h,
                color: const Color(0xFF2A2A2A),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 40.sp, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    SizedBox(height: 1.h),
                    Text(
                      'post.image_unavailable'.tr,
                      style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 2.w,
              right: 2.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.8.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ColorApp.premiumGold.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.photo_rounded, color: ColorApp.premiumGold, size: 14.sp),
                    SizedBox(width: 1.w),
                    Text(
                      "1/1 • HD",
                      style: GoogleFonts.poppins(
                        color: ColorApp.premiumGold,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildEngagementBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () {
              _onLikeButtonTapped(widget.isLike);
            },
            borderRadius: BorderRadius.circular(20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(0.8.w),
                  decoration: BoxDecoration(
                    gradient: widget.alllike!.contains(AppUser.info?.googleId??0)
                        ? const LinearGradient(
                            colors: [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    shape: BoxShape.circle,
                    color: widget.alllike!.contains(AppUser.info!.googleId)
                        ? null
                        : Colors.white.withValues(alpha: 0.05),
                  ),
                  child: Icon(
                    Icons.favorite,
                    color: widget.alllike!.contains(AppUser.info!.googleId)
                        ? Colors.white
                        : Colors.grey[600],
                    size: 12.sp,
                  ),
                ),
                SizedBox(width: 1.w),
                Text(
                  _formatCount(widget.likes),
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(width: 1.w),
                Text(
                  'post.like'.tr,
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Icon(Icons.mode_comment_outlined, size: 14.sp, color: Theme.of(context).colorScheme.onSurfaceVariant),
              SizedBox(width: 1.w),
              Text(
                '${_formatCount(widget.comments)}',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 2.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.share_outlined, size: 12.sp, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    SizedBox(width: 1.w),
                    Text(
                      '${_formatCount(widget.shares)}',
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 2.w),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: ColorApp.premiumGold.withValues(alpha: 0.08)),
          bottom: BorderSide(color: ColorApp.premiumGold.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: widget.alllike!.contains(AppUser.info!.googleId)
                ? Icons.favorite_rounded
                : Icons.favorite_outline_rounded,
            label: 'post.like'.tr,
            color: widget.alllike!.contains(AppUser.info!.googleId)
                ? const Color(0xFFFF6B6B)
                : Colors.grey[500]!,
            backgroundColor: widget.alllike!.contains(AppUser.info!.googleId)
                ? const Color(0xFFFF6B6B).withValues(alpha: 0.1)
                : null,
            onTap: () => _onLikeButtonTapped(_isLiked),
          ),
          _buildActionButton(
            icon: Icons.mode_comment_outlined,
            label: 'post.comment'.tr,
            color: Theme.of(context).colorScheme.onSurfaceVariant!,
            onTap: () {
              Future.microtask(() {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  builder: (context) => ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    child: SizedBox(
                      height: Get.height / 1.3,
                      // child: CommentModal(videoId: widget.id, videoTitle: ''),
                    ),
                  ),
                );
              });
            },
          ),
          _buildActionButton(
            icon: Icons.share_outlined,
            label: 'post.share'.tr,
            color: Theme.of(context).colorScheme.onSurfaceVariant!,
            onTap: () {},
          ),
          _buildActionButton(
            icon: _isBookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_outline_rounded,
            label: 'post.save'.tr,
            color: _isBookmarked ? ColorApp.premiumGold : Colors.grey[600]!,
            backgroundColor: _isBookmarked
                ? ColorApp.premiumGold.withValues(alpha: 0.1)
                : null,
            onTap: () => _onBookmarkTapped(_isBookmarked),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    Color? backgroundColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 1.2.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: backgroundColor,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16.sp, color: color),
                SizedBox(width: 1.w),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: color,
                    fontWeight: FontWeight.w500,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommentsPreview() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: ColorApp.premiumGold.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 10.sp,
            backgroundColor: const Color(0xFF2A2A2A),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: InkWell(
              onTap: widget.onComment,
              child: Row(
                children: [
                  Icon(
                    Icons.mode_comment_outlined,
                    size: 12.sp,
                    color: ColorApp.premiumGold.withValues(alpha: 0.6),
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    'post.see_comments'.tr + '${widget.comments}' + 'post.comments'.tr,
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 10.sp,
            color: ColorApp.premiumGold.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}

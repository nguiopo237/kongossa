import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class PostOptionsMenu extends StatefulWidget {
  final String? postId;
  final String? postOwnerId;
  final String? postOwnerName;
  final bool isCurrentUser;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;
  final VoidCallback? onHide;
  final VoidCallback? onCopyLink;
  final VoidCallback? onPinPost;
  final VoidCallback? onMuteUser;
  final VoidCallback? onBlockUser;
  final VoidCallback? onSaveToCollection;
  final VoidCallback? onShareToStory;
  final VoidCallback? onSendInMessage;
  final VoidCallback? onAddToFavorites;
  final VoidCallback? onViewDetails;
  final VoidCallback? onShare;

  const PostOptionsMenu({
    Key? key,
    this.postId,
    this.postOwnerId,
    this.postOwnerName,
    required this.isCurrentUser,
    this.onEdit,
    this.onDelete,
    this.onReport,
    this.onHide,
    this.onCopyLink,
    this.onPinPost,
    this.onMuteUser,
    this.onBlockUser,
    this.onSaveToCollection,
    this.onShareToStory,
    this.onSendInMessage,
    this.onAddToFavorites,
    this.onViewDetails,
    this.onShare,
  }) : super(key: key);

  @override
  State<PostOptionsMenu> createState() => _PostOptionsMenuState();
}

class _PostOptionsMenuState extends State<PostOptionsMenu> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 0,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              _buildOptionsList(),
              _buildCancelButton(),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Column(
        children: [
          Container(
            width: 20.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'options.title'.tr,
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (widget.postOwnerName != null) ...[
            SizedBox(height: 0.5.h),
            Text(
              'options.post_by'.tr + '${widget.postOwnerName}',
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionsList() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: Get.height * 0.6,
      ),
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(horizontal: 3.w),
        children: [
          // Section des options principales
          if (widget.isCurrentUser) _buildOwnerOptions(),
          if (!widget.isCurrentUser) _buildUserOptions(),
          _buildInteractionOptions(),
          if (!widget.isCurrentUser) _buildUserManagementOptions(),
        ],
      ),
    );
  }

  Widget _buildOwnerOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('options.manage'.tr),
        _buildOptionTile(
          icon: Icons.edit_outlined,
          label: 'options.edit'.tr,
          color: Colors.blue,
          onTap: widget.onEdit,
        ),
        _buildOptionTile(
          icon: Icons.delete_outline,
          label: 'options.delete'.tr,
          color: Colors.red,
          onTap: widget.onDelete,
          showConfirmation: true,
          confirmationMessage: 'options.delete_confirm'.tr,
        ),
        _buildOptionTile(
          icon: Icons.push_pin_outlined,
          label: 'options.pin'.tr,
          color: Colors.green,
          onTap: widget.onPinPost,
        ),
        _buildOptionTile(
          icon: Icons.lock_outline,
          label: 'options.privacy'.tr,
          color: Colors.purple,
          onTap: _showPrivacyOptions,
        ),
        _buildOptionTile(
          icon: Icons.star_outline,
          label: 'options.favorites'.tr,
          color: Colors.amber,
          onTap: widget.onAddToFavorites,
        ),
        _buildDivider(),
      ],
    );
  }

  Widget _buildUserOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('options.interactions'.tr),
        _buildOptionTile(
          icon: Icons.flag_outlined,
          label: 'options.report'.tr,
          color: Colors.orange,
          onTap: () => _showReportOptions(),
        ),
        _buildOptionTile(
          icon: Icons.visibility_off_outlined,
          label: 'options.hide'.tr,
          color: Theme.of(context).colorScheme.outline!,
          onTap: widget.onHide,
          showConfirmation: true,
          confirmationMessage: 'options.hide_confirm'.tr,
        ),
        _buildOptionTile(
          icon: Icons.not_interested_outlined,
          label: 'options.hide_similar'.tr,
          color: Theme.of(context).colorScheme.onSurfaceVariant!,
          onTap: () => _showSnackBar('options.preferences_updated'.tr),
        ),
        _buildDivider(),
      ],
    );
  }

  Widget _buildInteractionOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('options.share_save'.tr),
        _buildOptionTile(
          icon: Icons.share_outlined,
          label: 'options.share_title'.tr,
          color: Colors.teal,
          onTap: () => _showShareOptions(),
        ),
        _buildOptionTile(
          icon: Icons.send_outlined,
          label: 'options.send_message'.tr,
          color: Colors.blue,
          onTap: widget.onSendInMessage,
        ),
        _buildOptionTile(
          icon: Icons.work_history_rounded,
          label: 'options.share_story'.tr,
          color: Colors.purple,
          onTap: widget.onShareToStory,
        ),
        _buildOptionTile(
          icon: Icons.bookmark_border_outlined,
          label: 'options.save_collection'.tr,
          color: Colors.pink,
          onTap: widget.onSaveToCollection,
        ),
        _buildOptionTile(
          icon: Icons.link_outlined,
          label: 'options.copy_link'.tr,
          color: Colors.blueGrey,
          onTap: () {
            widget.onCopyLink?.call();
            _showSnackBar('options.link_copied'.tr);
          },
        ),
        _buildDivider(),
      ],
    );
  }

  Widget _buildUserManagementOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('options.user_options'.tr),
        _buildOptionTile(
          icon: Icons.volume_off_outlined,
          label: 'options.hide_user'.tr + '${widget.postOwnerName}',
          color: Theme.of(context).colorScheme.outline!,
          onTap: widget.onMuteUser,
          showConfirmation: true,
          confirmationMessage: 'options.hide_user_confirm'.tr,
        ),
        _buildOptionTile(
          icon: Icons.block_outlined,
          label: 'options.block'.tr + '${widget.postOwnerName}',
          color: Colors.red[700]!,
          onTap: widget.onBlockUser,
          showConfirmation: true,
          confirmationMessage: 'options.block_confirm'.tr,
        ),
        _buildOptionTile(
          icon: Icons.info_outline,
          label: 'options.details'.tr,
          color: Theme.of(context).colorScheme.onSurfaceVariant!,
          onTap: widget.onViewDetails,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
    bool showConfirmation = false,
    String confirmationMessage = '',
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18.sp),
      ),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14.sp,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onTap: () {
        if (showConfirmation && onTap != null) {
          _showConfirmationDialog(label, confirmationMessage, onTap);
        } else {
          onTap?.call();
        }
      },
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 2.h,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }

  Widget _buildCancelButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[200],
          foregroundColor: Colors.grey[800],
          minimumSize: Size(double.infinity, 6.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: Text(
          'app.close'.tr,
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Method to display share options
  void _showShareOptions() {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildShareOptionsSheet(),
    );
  }

  Widget _buildShareOptionsSheet() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 1.h),
            width: 20.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(3.w),
            child:              Text(
              'options.share_title'.tr,
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildShareOption(
            icon: Icons.storm_outlined,
          label: 'options.share_story'.tr,
          color: Colors.purple,
          onTap: widget.onShareToStory,
          ),
          _buildShareOption(
            icon: Icons.send_outlined,
          label: 'options.send_message'.tr,
          color: Colors.blue,
          onTap: widget.onSendInMessage,
          ),
          _buildShareOption(
            icon: Icons.group_outlined,
            label: 'options.share_group'.tr,
            color: Colors.green,
            onTap: widget.onShare,
          ),
          _buildShareOption(
            icon: Icons.facebook_outlined,
            label: 'options.share_facebook'.tr,
            color: Colors.blue[800]!,
            onTap: widget.onShare,
          ),
          _buildShareOption(
            icon: Icons.chat_outlined,
            label: 'options.share_whatsapp'.tr,
            color: Colors.green[700]!,
            onTap: widget.onShare,
          ),
          _buildShareOption(
            icon: Icons.link_outlined,
            label: 'options.copy_link'.tr,
            color: Colors.blueGrey,
            onTap: widget.onCopyLink,
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18.sp),
      ),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap?.call();
      },
    );
  }

  // Method to display report options
  void _showReportOptions() {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildReportOptionsSheet(),
    );
  }

  Widget _buildReportOptionsSheet() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 1.h),
            width: 20.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(3.w),
            child:              Text(
              'options.report'.tr,
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildReportOption('options.report_inappropriate'.tr, Icons.warning_amber_outlined),
          _buildReportOption('options.report_harassment'.tr, Icons.gpp_bad_outlined),
          _buildReportOption('options.report_spam'.tr, Icons.report_outlined),
          _buildReportOption('options.report_hate'.tr, Icons.block_outlined),
          _buildReportOption('options.report_violence'.tr, Icons.no_accounts_outlined),
          _buildReportOption('options.report_nudity'.tr, Icons.visibility_off_outlined),
          _buildReportOption('options.report_copyright'.tr, Icons.copyright_outlined),
          _buildReportOption('options.report_other'.tr, Icons.more_horiz_outlined),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildReportOption(String reason, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.outline, size: 18.sp),
      title: Text(
        reason,
        style: GoogleFonts.poppins(fontSize: 14.sp),
      ),
      onTap: () {
        Navigator.pop(context);
        widget.onReport?.call();
        _showSnackBar('options.report_sent'.tr);
      },
    );
  }

  // Method to display privacy options
  void _showPrivacyOptions() {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPrivacyOptionsSheet(),
    );
  }

  Widget _buildPrivacyOptionsSheet() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 1.h),
            width: 20.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(3.w),
            child:              Text(
              'options.privacy_title'.tr,
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildPrivacyOption(
            icon: Icons.public,
            label: 'options.privacy_public'.tr,
            subtitle: 'options.privacy_public_desc'.tr,
            value: 'public',
          ),
          _buildPrivacyOption(
            icon: Icons.people_outline,
            label: 'options.privacy_friends'.tr,
            subtitle: 'options.privacy_friends_desc'.tr,
            value: 'friends',
          ),
          _buildPrivacyOption(
            icon: Icons.lock_outline,
            label: 'options.privacy_private'.tr,
            subtitle: 'options.privacy_private_desc'.tr,
            value: 'private',
          ),
          _buildPrivacyOption(
            icon: Icons.group_outlined,
            label: 'options.privacy_friends_except'.tr,
            subtitle: 'options.privacy_friends_except_desc'.tr,
            value: 'friends_except',
          ),
          _buildPrivacyOption(
            icon: Icons.person_outlined,
            label: 'options.privacy_custom'.tr,
            subtitle: 'options.privacy_custom_desc'.tr,
            value: 'custom',
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildPrivacyOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required String value,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.blue, size: 18.sp),
      ),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 12.sp,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        _showSnackBar('options.privacy_updated'.tr);
      },
    );
  }

  // Method to display a confirmation dialog
  void _showConfirmationDialog(String action, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          action,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16.sp,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'app.cancel'.tr,
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14.sp,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'app.confirm'.tr,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Method to show a SnackBar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(3.w),
      ),
    );
  }
}

// Extension for easy usage
extension PostOptionsMenuExtension on BuildContext {
  void showPostOptionsMenu({
    required String? postId,
    required String? postOwnerId,
    required String? postOwnerName,
    required bool isCurrentUser,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    VoidCallback? onReport,
    VoidCallback? onHide,
    VoidCallback? onCopyLink,
    VoidCallback? onPinPost,
    VoidCallback? onMuteUser,
    VoidCallback? onBlockUser,
    VoidCallback? onSaveToCollection,
    VoidCallback? onShareToStory,
    VoidCallback? onSendInMessage,
    VoidCallback? onAddToFavorites,
    VoidCallback? onViewDetails,
    VoidCallback? onShare,
  }) {
    showModalBottomSheet(
      context: this,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PostOptionsMenu(
        postId: postId,
        postOwnerId: postOwnerId,
        postOwnerName: postOwnerName,
        isCurrentUser: isCurrentUser,
        onEdit: onEdit,
        onDelete: onDelete,
        onReport: onReport,
        onHide: onHide,
        onCopyLink: onCopyLink,
        onPinPost: onPinPost,
        onMuteUser: onMuteUser,
        onBlockUser: onBlockUser,
        onSaveToCollection: onSaveToCollection,
        onShareToStory: onShareToStory,
        onSendInMessage: onSendInMessage,
        onAddToFavorites: onAddToFavorites,
        onViewDetails: onViewDetails,
        onShare: onShare,
      ),
    );
  }
}
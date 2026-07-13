import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../sevice/controlleur/live_controller.dart';
import 'meeting/pre_join_screen.dart';

class GoLiveScreen extends StatefulWidget {
  const GoLiveScreen({super.key});

  @override
  State<GoLiveScreen> createState() => _GoLiveScreenState();
}

class _GoLiveScreenState extends State<GoLiveScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final controller = LiveController.to;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _startLive() async {
    if (_titleController.text.trim().isEmpty) {
      Get.snackbar('live.title_required'.tr, 'live.enter_title'.tr);
      return;
    }

    final result = await controller.startLive(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
    );

    if (result != null && mounted) {
      Get.off(() => PreJoinScreen(
        liveId: result['liveId']!,
        roomId: result['roomId']!,
        isHost: true,
        liveTitle: _titleController.text.trim(),
      ));
    } else {
      Get.snackbar('app.error'.tr, 'live.start_error'.tr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.primary;
    final bg = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final subtle = theme.colorScheme.onSurfaceVariant;
    final error = theme.colorScheme.error;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text('live.go_live'.tr, style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: gold),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(5.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône live
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: error.withValues(alpha: 0.3), width: 2),
                ),
                child: Icon(Icons.videocam_rounded, color: error, size: 36),
              ),
            ),
            SizedBox(height: 3.h),
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: error.withValues(alpha: 0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: error),
                    SizedBox(width: 2.w),
                    Text(
                      'live.visible_to_all'.tr,
                      style: TextStyle(color: error, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 3.h),

            // Titre
            Text('live.title_field'.tr, style: TextStyle(color: onSurface, fontSize: 14, fontWeight: FontWeight.w500)),
            SizedBox(height: 1.h),
            TextField(
              controller: _titleController,
              maxLength: 60,
              decoration: InputDecoration(
                hintText: 'live.title_example'.tr,
                hintStyle: TextStyle(color: subtle, fontSize: 14),
                filled: true,
                fillColor: subtle.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: subtle.withValues(alpha: 0.2)),
                ),
                contentPadding: EdgeInsets.all(4.w),
              ),
              style: TextStyle(color: onSurface, fontSize: 14),
            ),
            SizedBox(height: 2.h),

            // Description
            Text('live.description_field'.tr, style: TextStyle(color: onSurface, fontSize: 14, fontWeight: FontWeight.w500)),
            SizedBox(height: 1.h),
            TextField(
              controller: _descController,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'live.description_hint'.tr,
                hintStyle: TextStyle(color: subtle, fontSize: 14),
                filled: true,
                fillColor: subtle.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: subtle.withValues(alpha: 0.2)),
                ),
                contentPadding: EdgeInsets.all(4.w),
              ),
              style: TextStyle(color: onSurface, fontSize: 14),
            ),
            SizedBox(height: 4.h),

            // Bouton Go Live
            SizedBox(
              width: double.infinity,
              child: Obx(() => ElevatedButton.icon(
                onPressed: controller.isLoading.value ? null : _startLive,
                icon: controller.isLoading.value
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.videocam_rounded, size: 20),
                label: Text(
                  controller.isLoading.value ? 'live.preparing'.tr : 'live.start'.tr,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: error,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: error.withValues(alpha: 0.5),
                  padding: EdgeInsets.symmetric(vertical: 1.8.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: error.withValues(alpha: 0.4),
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }
}

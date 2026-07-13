import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../model/datamodel/user_model.dart';
import 'meeting_screen.dart';

/// Pre-live setup screen — choose camera, mic, and preview before joining.
///
/// Navigates to [MeetingScreen] with the user's chosen settings when they tap
/// "Rejoindre".
class PreJoinScreen extends StatefulWidget {
  final String liveId;
  final String roomId;
  final bool isHost;
  final String? liveTitle;

  const PreJoinScreen({
    super.key,
    required this.liveId,
    required this.roomId,
    required this.isHost,
    this.liveTitle,
  });

  @override
  State<PreJoinScreen> createState() => _PreJoinScreenState();
}

class _PreJoinScreenState extends State<PreJoinScreen> {
  bool _micOn = true;
  bool _camOn = true;
  int _selectedCameraIndex = 0;

  // VideoSDK v1.1.x does not support local camera preview outside a Room,
  // so we show the avatar placeholder until the user joins.
  // The actual camera stream will activate inside MeetingScreen after join.

  @override
  void initState() {
    super.initState();
    if (!widget.isHost) {
      _micOn = false;
      _camOn = false;
    }
  }

  void _toggleMic() => setState(() => _micOn = !_micOn);

  void _toggleCam() {
    setState(() => _camOn = !_camOn);
  }

  void _switchCamera() {
    setState(() {
      _selectedCameraIndex = _selectedCameraIndex == 0 ? 1 : 0;
    });
  }

  void _joinMeeting() {
    Get.off(() => MeetingScreen(
          liveId: widget.liveId,
          roomId: widget.roomId,
          isHost: widget.isHost,
          initialMicEnabled: _micOn,
          initialCamEnabled: _camOn,
          initialCameraIndex: _selectedCameraIndex,
        ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.primary;
    final error = theme.colorScheme.error;
    final subtle = theme.colorScheme.onSurfaceVariant;

    final user = AppUser.info;
    final avatarUrl = user?.photoUrl ?? '';
    final displayName = user?.displayName ?? 'Anonymous';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: gold, size: 20),
                    onPressed: () => Get.back(),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.3.h),
                    decoration: BoxDecoration(
                      color: error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 1.5.w),
                        Text(
                          widget.liveTitle ?? 'Live',
                          style: TextStyle(
                              color: error,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(width: 8.w),
                ],
              ),
            ),

            // ── Camera preview area ──
            Expanded(
              child: Center(
                child: _buildPlaceholderPreview(
                        gold, subtle, displayName, initial, avatarUrl),
              ),
            ),

            // ── Device info + toggles ──
            _buildControls(gold, subtle),

            // ── Join button ──
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              child: ElevatedButton.icon(
                onPressed: _joinMeeting,
                icon: const Icon(Icons.videocam_rounded, size: 20),
                label: Text(
                  widget.isHost ? 'live.start'.tr : 'live.join'.tr,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: error,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 1.6.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: error.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Placeholder with avatar + name while camera is off or before joining.
  Widget _buildPlaceholderPreview(Color gold, Color subtle, String name,
      String initial, String avatarUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 85.w,
        height: 50.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.grey.shade900,
              Colors.grey.shade800,
              Colors.grey.shade900,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl.isEmpty
                        ? Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 1.h),
                  if (_camOn)
                    Text(
                      'live.camera_preview_off'.tr,
                      style: TextStyle(color: subtle, fontSize: 13),
                    ),
                ],
              ),
            ),
            if (!_camOn)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.videocam_off,
                      color: Colors.redAccent, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Control row: mic toggle, cam toggle, switch camera.
  Widget _buildControls(Color gold, Color subtle) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _toggleChip(
            icon: _micOn ? Icons.mic : Icons.mic_off,
            label: _micOn ? 'live.mic_on'.tr : 'live.mic_off'.tr,
            active: _micOn,
            activeColor: gold,
            inactiveColor: subtle,
            onTap: _toggleMic,
          ),
          _toggleChip(
            icon: _camOn ? Icons.videocam : Icons.videocam_off,
            label: _camOn ? 'live.cam_on'.tr : 'live.cam_off'.tr,
            active: _camOn,
            activeColor: gold,
            inactiveColor: subtle,
            onTap: _toggleCam,
          ),
          if (_camOn)
            _toggleChip(
              icon: Icons.flip_camera_android,
              label: 'live.switch_cam'.tr,
              active: true,
              activeColor: Colors.white70,
              inactiveColor: subtle,
              onTap: _switchCamera,
            ),
        ],
      ),
    );
  }

  Widget _toggleChip({
    required IconData icon,
    required String label,
    required bool active,
    required Color activeColor,
    required Color inactiveColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.6.h),
        decoration: BoxDecoration(
          color: active
              ? activeColor.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? activeColor.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: active ? activeColor : inactiveColor),
            SizedBox(width: 1.5.w),
            Text(
              label,
              style: TextStyle(
                color: active ? activeColor : inactiveColor,
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

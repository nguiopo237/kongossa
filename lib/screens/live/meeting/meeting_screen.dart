import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:videosdk/videosdk.dart';

import '../../../model/datamodel/user_model.dart';
import '../../../sevice/controlleur/live_controller.dart';
import '../../../sevice/videosdk/videosdk_service.dart';
import 'participant_tile.dart';

/// In-app meeting room powered by VideoSDK.
///
/// Usage:
///   Get.to(() => MeetingScreen(liveId: 'abc', roomId: 'xyz', isHost: true));
class MeetingScreen extends StatefulWidget {
  final String liveId;
  final String roomId;
  final bool isHost;
  final bool initialMicEnabled;
  final bool initialCamEnabled;
  final int initialCameraIndex;

  const MeetingScreen({
    super.key,
    required this.liveId,
    required this.roomId,
    required this.isHost,
    this.initialMicEnabled = true,
    this.initialCamEnabled = true,
    this.initialCameraIndex = 0,
  });

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  final _liveController = LiveController.to;
  final _sdk = VideoSdkService.to;

  Room? _room;
  final Map<String, Participant> _participants = {};
  bool _micOn = true;
  bool _camOn = true;
  bool _isChatOpen = false;
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();
  int _currentCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _micOn = widget.initialMicEnabled;
    _camOn = widget.initialCamEnabled;
    _currentCameraIndex = widget.initialCameraIndex;
    _initMeeting();
  }

  Future<void> _initMeeting() async {
    final user = AppUser.info;
    final displayName = user?.displayName ?? 'Anonymous';

    final room = _sdk.initRoom(
      roomId: widget.roomId,
      displayName: displayName,
      micEnabled: _micOn,
      camEnabled: _camOn,
    );

    _setupRoomListeners(room);
    await room.join();

    setState(() {
      _room = room;
    });

    if (!widget.isHost) {
      _liveController.joinLive(widget.liveId);
    }
  }

  void _setupRoomListeners(Room room) {
    room.on(Events.roomJoined, () {
      debugPrint('✅ VideoSDK room joined: ${widget.roomId}');
      _participants[room.localParticipant.id] = room.localParticipant;
      if (mounted) setState(() {});
    });

    room.on(Events.participantJoined, (Participant participant) {
      _participants[participant.id] = participant;
      if (mounted) setState(() {});
    });

    room.on(Events.participantLeft, (String participantId) {
      _participants.remove(participantId);
      if (mounted) setState(() {});
    });

    room.on(Events.roomLeft, (String? code) {
      debugPrint('👋 VideoSDK room left: $code');
      if (mounted) Get.back();
    });
  }

  @override
  void dispose() {
    _room?.leave();
    _room = null;
    _liveController.leaveLive(widget.liveId);
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Controls ─────────────────────────────────────────────────────────────

  void _toggleMic() {
    if (_micOn) {
      _room?.muteMic();
    } else {
      _room?.unmuteMic();
    }
    setState(() => _micOn = !_micOn);
  }

  void _toggleCam() {
    if (_camOn) {
      _room?.disableCam();
    } else {
      _room?.enableCam();
    }
    setState(() => _camOn = !_camOn);
  }

  void _switchCamera() {
    if (_room == null) return;
    final cameras = _room!.getCameras();
    if (cameras.length > 1) {
      final nextIdx = _currentCameraIndex == 0 ? 1 : 0;
      if (nextIdx < cameras.length) {
        _room!.changeCam(cameras[nextIdx].deviceId);
        _currentCameraIndex = nextIdx;
      }
    }
  }

  Future<void> _leaveCall() async {
    if (widget.isHost) {
      await _liveController.endLive(widget.liveId);
    }
    _room?.leave();
    Get.back();
  }

  // ── Chat ──────────────────────────────────────────────────────────────────

  void _sendChatMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    _liveController.sendMessage(widget.liveId, text);
    _chatController.clear();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── Video grid ──
            Expanded(child: _buildVideoGrid()),

            // ── End call bar ──
            _buildCallControls(gold),

            // ── Chat panel (slide-up) ──
            if (_isChatOpen) _buildChatPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoGrid() {
    final participants = _participants.values.toList();
    if (participants.isEmpty) {
      return Center(
        child: Text(
          'live.connecting'.tr,
          style: const TextStyle(color: Colors.white54, fontSize: 15),
        ),
      );
    }

    final count = participants.length;
    final crossAxisCount = count <= 1 ? 1 : (count <= 4 ? 2 : 3);

    return Padding(
      padding: EdgeInsets.all(1.5.w),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 1.5.w,
          crossAxisSpacing: 1.5.w,
          childAspectRatio: count <= 2 ? 0.75 : 0.6,
        ),
        itemCount: count,
        itemBuilder: (context, index) {
          final p = participants[index];
          return ParticipantTile(
            participant: p,
            isLocal: p.id == _room?.localParticipant.id,
          );
        },
      ),
    );
  }

  Widget _buildCallControls(Color gold) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        border: Border(top: BorderSide(color: gold.withValues(alpha: 0.12))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Toggle mic
          _controlBtn(
            icon: _micOn ? Icons.mic : Icons.mic_off,
            color: _micOn ? Colors.white : Colors.redAccent,
            onTap: _toggleMic,
          ),
          // Toggle camera
          _controlBtn(
            icon: _camOn ? Icons.videocam : Icons.videocam_off,
            color: _camOn ? Colors.white : Colors.redAccent,
            onTap: _toggleCam,
          ),
          // Switch camera
          _controlBtn(
            icon: Icons.flip_camera_android,
            color: Colors.white,
            onTap: _switchCamera,
          ),
          // Chat toggle
          _controlBtn(
            icon: Icons.chat_bubble_outline,
            color: _isChatOpen ? gold : Colors.white,
            onTap: () => setState(() => _isChatOpen = !_isChatOpen),
          ),
          // Leave / End
          GestureDetector(
            onTap: _leaveCall,
            child: Container(
              padding: EdgeInsets.all(3.w),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.call_end,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(2.5.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildChatPanel() {
    final subtle = Theme.of(context).colorScheme.onSurfaceVariant;
    final gold = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 40.h,
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.8.h),
            color: Colors.grey.shade900,
            child: Row(
              children: [
                Text(
                  'live.chat'.tr,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _isChatOpen = false),
                  child: const Icon(Icons.close, color: Colors.white54, size: 18),
                ),
              ],
            ),
          ),
          // Messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _liveController.messagesStream(widget.liveId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!.docs;
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'live.no_messages'.tr,
                      style: TextStyle(color: subtle),
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!_scrollController.hasClients) return;
                  final nearBottom =
                      _scrollController.position.extentAfter < 100;
                  if (nearBottom) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(2.w),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final isMe = data['userId'] == AppUser.info?.googleId;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 0.8.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundImage: data['userAvatar'] != null
                                ? NetworkImage(data['userAvatar'])
                                : null,
                            child: data['userAvatar'] == null
                                ? Icon(Icons.person, size: 12, color: gold)
                                : null,
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['userName'] ?? '',
                                  style: TextStyle(
                                    color: isMe ? gold : Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  data['message'] ?? '',
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Input
          Container(
            padding: EdgeInsets.all(2.w),
            color: Colors.grey.shade900,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: InputDecoration(
                      hintText: 'live.chat_hint'.tr,
                      hintStyle: TextStyle(color: subtle, fontSize: 13),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 0.8.h,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendChatMessage(),
                  ),
                ),
                SizedBox(width: 2.w),
                GestureDetector(
                  onTap: _sendChatMessage,
                  child: Container(
                    padding: EdgeInsets.all(2.5.w),
                    decoration: BoxDecoration(
                      color: gold,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.black, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:videosdk/videosdk.dart';

/// Displays a single participant's video stream (or a fallback avatar).
class ParticipantTile extends StatefulWidget {
  final Participant participant;
  final bool isLocal;

  const ParticipantTile({
    super.key,
    required this.participant,
    this.isLocal = false,
  });

  @override
  State<ParticipantTile> createState() => _ParticipantTileState();
}

class _ParticipantTileState extends State<ParticipantTile> {
  Stream? _videoStream;

  @override
  void initState() {
    super.initState();

    // Check for existing video stream
    widget.participant.streams.forEach((key, stream) {
      if (stream.kind == 'video') _videoStream = stream;
    });

    // Listen for stream enable/disable
    widget.participant.on(Events.streamEnabled, (Stream stream) {
      if (stream.kind == 'video') setState(() => _videoStream = stream);
    });

    widget.participant.on(Events.streamDisabled, (Stream stream) {
      if (stream.kind == 'video') setState(() => _videoStream = null);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.participant.displayName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Video stream ──
          if (_videoStream != null)
            RTCVideoView(
              _videoStream!.renderer as RTCVideoRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),

          // ── Fallback avatar ──
          if (_videoStream == null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

          // ── Name badge ──
          if (_videoStream != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: Colors.black.withValues(alpha: 0.5),
                child: Text(
                  widget.isLocal ? '$name (${'meeting.you'.tr})' : name,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

          // ── Muted mic indicator ──
          if (!_hasAudioStream(widget.participant))
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic_off, size: 14, color: Colors.redAccent),
              ),
            ),
        ],
      ),
    );
  }
}

/// Checks whether a participant has an active audio stream.
bool _hasAudioStream(Participant p) {
  bool found = false;
  p.streams.forEach((key, stream) {
    if (stream.kind == 'audio') found = true;
  });
  return found;
}

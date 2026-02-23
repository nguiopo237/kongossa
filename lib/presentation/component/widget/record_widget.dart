import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../sevice/record/record_audi.dart';

class AudioRecordButton extends StatefulWidget {
  final Function(String audioPath) onSendAudio;
  final VoidCallback? onCancel;
  final bool see;

  const AudioRecordButton({
    Key? key,
    required this.onSendAudio,
    required this.see,
    this.onCancel,
  }) : super(key: key);

  @override
  State<AudioRecordButton> createState() => _AudioRecordButtonState();
}

class _AudioRecordButtonState extends State<AudioRecordButton> with TickerProviderStateMixin, WidgetsBindingObserver {
  final AudioRecordingService _audioService = AudioRecordingService();
  bool _isRecording = false;
  bool _isLocked = false;
  bool _isShowingControls = false;
  double _recordProgress = 0.0;
  int _recordDuration = 0;
  Timer? _progressTimer;
  Timer? _durationTimer;
  late AnimationController _pulseAnimation;

  static const int maxRecordDuration = 60;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanupRecording();
    _pulseAnimation.dispose();
    _audioService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Si l'app passe en arrière-plan pendant l'enregistrement
    if (state == AppLifecycleState.paused && _isRecording) {
      _cancelRecording();
    }
  }

  void _cleanupRecording() {
    _progressTimer?.cancel();
    _progressTimer = null;
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  void _startProgressTimer() {
    _cleanupRecording();

    if (!mounted) return;

    setState(() {
      _recordProgress = 0.0;
      _recordDuration = 0;
    });

    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_recordProgress >= 1.0) {
        timer.cancel();
        _stopAndSend();
      } else {
        setState(() {
          _recordProgress += 0.1 / (maxRecordDuration / 10);
        });
      }
    });

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordDuration++;
        });
      }
    });
  }

  Future<void> _stopAndSend() async {
    _cleanupRecording();

    if (!mounted) return;

    String? path;
    try {
      path = await _audioService.stopRecording();
    } catch (e) {
      print('Erreur arrêt enregistrement: $e');
    }

    if (mounted) {
      setState(() {
        _isRecording = false;
        _isLocked = false;
        _isShowingControls = false;
        _recordProgress = 0.0;
        _recordDuration = 0;
      });
    }

    if (path != null && mounted) {
      widget.onSendAudio(path);
    }
  }

  Future<void> _cancelRecording() async {
    _cleanupRecording();

    if (!mounted) return;

    try {
      await _audioService.cancelRecording();
    } catch (e) {
      print('Erreur annulation enregistrement: $e');
    }

    if (mounted) {
      setState(() {
        _isRecording = false;
        _isLocked = false;
        _isShowingControls = false;
        _recordProgress = 0.0;
        _recordDuration = 0;
      });
    }

    if (mounted) {
      widget.onCancel?.call();
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _startRecording() async {
    if (_isRecording) return;

    try {
      HapticFeedback.heavyImpact();
      final started = await _audioService.startRecording();

      if (started && mounted) {
        setState(() {
          _isRecording = true;
          _isShowingControls = true;
        });
        _startProgressTimer();
      }
    } catch (e) {
      print('Erreur démarrage enregistrement: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: widget.see==true,
      child: SizedBox(
        height: 80,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Panneau de contrôle avec animation explicite
            _buildControlPanel(),

            // Bouton d'enregistrement principal
            _buildRecordButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    if (!_isRecording) return const SizedBox.shrink();

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: 70,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(35),
        ),
        child: _isLocked ? _buildLockedControls() : _buildUnlockedControls(),
      ),
    );
  }

  Widget _buildUnlockedControls() {
    return Row(
      children: [
        Expanded(
          child: Center(
            child: Text(
              '← Glisser pour annuler',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ),
        ),
        Container(
          width: 50,
          child: IconButton(
            icon: Icon(
              Icons.lock_outline,
              color: Colors.grey[400],
            ),
            onPressed: _isRecording ? () {
              setState(() {
                _isLocked = true;
              });
            } : null,
          ),
        ),
      ],
    );
  }

  Widget _buildLockedControls() {
    return Row(
      children: [
        Expanded(
          child: TextButton.icon(
            onPressed: _cancelRecording,
            icon: const Icon(Icons.close, color: Colors.red),
            label: const Text(
              'Annuler',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDuration(_recordDuration),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TextButton.icon(
            onPressed: _stopAndSend,
            icon: const Icon(Icons.send, color: Colors.green),
            label: const Text(
              'Envoyer',
              style: TextStyle(color: Colors.green),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordButton() {
    return GestureDetector(
      onLongPressDown: (_) =>  _startRecording(),
      onLongPressEnd: (_) {
        if (!_isLocked && mounted && _isRecording) {
          HapticFeedback.lightImpact();
          _stopAndSend();
        }
      },
      onLongPressCancel: () {
        if (!_isLocked && mounted && _isRecording) {
          HapticFeedback.lightImpact();
          _cancelRecording();
        }
      },
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isRecording
                    ? [Colors.red, Colors.redAccent]
                    : [Colors.pink, Colors.purple],
              ),
              shape: BoxShape.circle,
              boxShadow: _isRecording ? [
                BoxShadow(
                  color: Colors.red.withOpacity(0.5),
                  blurRadius: 10 + (_pulseAnimation.value * 10),
                  spreadRadius: _pulseAnimation.value * 2,
                ),
              ] : null,
            ),
            child: Transform.scale(
              scale: _isRecording ? 1.0 + (_pulseAnimation.value * 0.2) : 1.0,
              child: const Icon(
                Icons.mic,
                color: Colors.white,
                size: 30,
              ),
            ),
          );
        },
      ),
    );
  }
}
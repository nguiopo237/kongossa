// lib/presentation/component/widget/audio_message.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:voice_message_package/voice_message_package.dart';
import '../../../sevice/record/audio_manager.dart';

class AudioMessage extends StatefulWidget {
  final String audioUrl;
  final bool isMe;
  final String? messageId;
  final VoidCallback? onPlayed;
  final Duration maxDuration;

  const AudioMessage({
    Key? key,
    required this.audioUrl,
    required this.isMe,
    this.messageId,
    this.onPlayed,
    this.maxDuration = const Duration(seconds: 60),
  }) : super(key: key);

  @override
  State<AudioMessage> createState() => _AudioMessageState();
}

class _AudioMessageState extends State<AudioMessage> with AutomaticKeepAliveClientMixin {
  VoiceController? _voiceController;
  bool _isDisposed = false;
  bool _hasBeenPlayed = false;
  bool _isInitialized = false;
  bool _isDownloading = false;
  bool _useNetworkFallback = false;
  int _retryCount = 0;

  String get _audioId => widget.messageId ?? widget.audioUrl.hashCode.toString();

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    if (_isDisposed) return;

    // 🔥 On ne bloque plus tout le widget, on gère juste le bouton
    setState(() => _isDownloading = true);

    try {
      String audioSource = widget.audioUrl;
      bool isFile = false;

      if (!_useNetworkFallback) {
        try {
          final localPath = await AudioManager().getLocalAudioPath(widget.audioUrl);
          final file = File(localPath);

          if (await file.exists()) {
            audioSource = localPath;
            isFile = true;
            print("✅ Utilisation du fichier local: $localPath");
          }
        } catch (e) {
          print("⚠️ Échec chargement local, utilisation réseau: $e");
          _useNetworkFallback = true;
        }
      }

      if (_isDisposed) return;

      _voiceController = VoiceController(

        audioSrc: audioSource,
        maxDuration: widget.maxDuration,
        isFile: isFile,
        onComplete: _onComplete,
        onPause: _onPause,
        onPlaying: _onPlaying,
        onError: _onError,
      );

      await Future.delayed(const Duration(milliseconds: 100));

      AudioManager().registerController(_audioId, _voiceController!);

      if (!_isDisposed) {
        setState(() {
          _isInitialized = true;
          _isDownloading = false; // 🔥 On libère le bouton
        });
      }

    } catch (e) {
      print("❌ Erreur création VoiceController: $e");
      _handleInitError();
    }
  }

  void _handleInitError() {
    if (_isDisposed) return;

    if (_retryCount < 2 && !_useNetworkFallback) {
      _retryCount++;
      _useNetworkFallback = true;
      Future.delayed(const Duration(seconds: 1), _initController);
    } else {
      setState(() => _isDownloading = false);
    }
  }

  void _onComplete() {
    if (_isDisposed) return;
    print('✅ Audio terminé');
    if (!_hasBeenPlayed && widget.onPlayed != null) {
      _hasBeenPlayed = true;
      widget.onPlayed!();
    }
  }

  void _onPause() {
    if (_isDisposed) return;
  }

  void _onPlaying() {
    if (_isDisposed) return;
    AudioManager().playAudio(_audioId);
  }

  void _onError(Object error) {
    if (_isDisposed) return;
    print('❌ Erreur audio: $error');

    if (error.toString().contains('FileNotFoundException') && !_useNetworkFallback) {
      _useNetworkFallback = true;
      _disposeController();
      _initController();
    } else {
      // 🔥 En cas d'erreur, on libère aussi le bouton
      setState(() => _isDownloading = false);
    }
  }

  void _disposeController() {
    try {
      AudioManager().unregisterController(_audioId);
      if (_voiceController != null) {
        _voiceController!.dispose();
      }
    } catch (e) {
      print("❌ Erreur disposal: $e");
    } finally {
      _voiceController = null;
      _isInitialized = false;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _disposeController();
    super.dispose();
  }

  // 🔥 Nouveau widget pour le bouton avec état de chargement
  Widget _buildPlayButton() {
    if (_isDownloading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    // Retourne null pour utiliser l'icône par défaut du package
    return Icon(Icons.play_arrow,color: Colors.white,);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // 🔥 On affiche TOUJOURS le VoiceMessageView, même en chargement
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
        minHeight: 40,
      ),
      child: VoiceMessageView(
        controller: _voiceController ?? _createDummyController(),
        innerPadding: 8,
        cornerRadius: 16,
        backgroundColor: widget.isMe
            ? Colors.pink.withOpacity(0.3)
            : Colors.grey.shade800,
        pauseIcon: Icon(Icons.stop,color: Colors.white,),
        // 🔥 On injecte notre bouton personnalisé
        playIcon: _buildPlayButton(),
        // 🔥 Optionnel : désactiver le tap pendant le chargement
        // onPlay: _isDownloading ? null : null, // Le controller gère déjà le play
      ),
    );
  }

  // 🔥 Controller factice pour éviter les erreurs quand _voiceController est null
  VoiceController _createDummyController() {
    return VoiceController(
      audioSrc: '',
      maxDuration: widget.maxDuration,
      isFile: true, onComplete: () {  }, onPause: () {  }, onPlaying: () {  },
    );
  }

  // ... (les autres méthodes restent inchangées)
  Widget _buildDownloadingIndicator() {
    return Container(
      width: 100,
      height: 40,
      decoration: BoxDecoration(
        color: widget.isMe
            ? Colors.pink.withOpacity(0.3)
            : Colors.grey.shade800,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorIndicator() {
    return Container(
      width: 100,
      height: 40,
      decoration: BoxDecoration(
        color: widget.isMe
            ? Colors.pink.withOpacity(0.3)
            : Colors.grey.shade800,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Icon(Icons.error_outline, color: Colors.white, size: 20),
      ),
    );
  }
}
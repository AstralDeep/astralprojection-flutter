import 'package:just_audio/just_audio.dart';
import 'package:logger/logger.dart';

/// Playback state for the TTS voice output.
enum VoiceOutputState { idle, playing, error }

/// TTS audio playback service that plays audio URLs received from the
/// backend using the just_audio package (T026).
class VoiceOutputService {
  final _logger = Logger();
  final AudioPlayer _player = AudioPlayer();

  VoiceOutputState _state = VoiceOutputState.idle;
  VoiceOutputState get state => _state;

  VoiceOutputService() {
    // Track playback state changes from the player.
    _player.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        _state = VoiceOutputState.idle;
        _logger.d('VoiceOutputService: playback completed');
      }
    }, onError: (Object error) {
      _state = VoiceOutputState.error;
      _logger.e('VoiceOutputService: player stream error', error: error);
    });
  }

  /// Play the TTS audio at the given [url].
  ///
  /// The URL is typically an absolute backend URL pointing to a generated
  /// audio file (e.g. `http://host:port/api/voice/tts/<id>.wav`).
  Future<void> playAudio(String url) async {
    try {
      _logger.d('VoiceOutputService: loading $url');
      await _player.setUrl(url);
      _state = VoiceOutputState.playing;
      await _player.play();
    } catch (e) {
      _state = VoiceOutputState.error;
      _logger.e('VoiceOutputService: playback failed', error: e);
    }
  }

  /// Stop any currently playing audio and reset to idle.
  Future<void> stopAudio() async {
    try {
      await _player.stop();
      _state = VoiceOutputState.idle;
      _logger.d('VoiceOutputService: stopped');
    } catch (e) {
      _logger.e('VoiceOutputService: stop failed', error: e);
    }
  }

  /// Release all resources held by the audio player.
  Future<void> dispose() async {
    await _player.dispose();
    _logger.d('VoiceOutputService: disposed');
  }
}

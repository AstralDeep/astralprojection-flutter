import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:logger/logger.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config.dart';

/// STT service that streams microphone audio over a WebSocket and emits
/// transcript updates received from the backend (T025).
class VoiceInputService {
  final _logger = Logger();

  WebSocketChannel? _channel;
  StreamSubscription? _wsSubscription;
  final AudioRecorder _recorder = AudioRecorder();

  StreamSubscription? _audioSubscription;

  /// Controller that broadcasts transcript text fragments.
  final _transcriptController = StreamController<String>.broadcast();

  /// Stream of transcript updates from the backend.
  Stream<String> get transcripts => _transcriptController.stream;

  bool _isStreaming = false;
  bool get isStreaming => _isStreaming;

  /// Begin capturing microphone audio and streaming to the backend.
  ///
  /// Opens a WebSocket to `/api/voice/stream` and pipes PCM16 24 kHz audio
  /// frames. The backend responds with JSON transcript messages.
  Future<void> startStreaming() async {
    if (_isStreaming) {
      _logger.w('VoiceInputService: already streaming');
      return;
    }

    // Check microphone permission / availability.
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      _logger.e('VoiceInputService: microphone permission denied');
      return;
    }

    try {
      // Open WebSocket connection to backend voice endpoint.
      final wsUri = Uri.parse(
        'ws://${AppConfig.backendHost}:${AppConfig.backendPort}/api/voice/stream',
      );
      _channel = WebSocketChannel.connect(wsUri);
      _logger.d('VoiceInputService: WebSocket connecting to $wsUri');

      // Listen for transcript responses from the backend.
      _wsSubscription = _channel!.stream.listen(
        _onWsMessage,
        onError: (error) {
          _logger.e('VoiceInputService: WebSocket error', error: error);
          stopStreaming();
        },
        onDone: () {
          _logger.d('VoiceInputService: WebSocket closed');
          _isStreaming = false;
        },
      );

      // Start recording PCM16 at 24 kHz mono and stream chunks.
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 24000,
          numChannels: 1,
        ),
      );

      _audioSubscription = stream.listen(
        (Uint8List data) {
          if (_channel != null) {
            _channel!.sink.add(data);
          }
        },
        onError: (error) {
          _logger.e('VoiceInputService: audio stream error', error: error);
        },
      );

      _isStreaming = true;
      _logger.d('VoiceInputService: streaming started');
    } catch (e) {
      _logger.e('VoiceInputService: failed to start streaming', error: e);
      await _cleanup();
    }
  }

  /// Stop microphone capture and close the WebSocket.
  Future<void> stopStreaming() async {
    if (!_isStreaming) return;
    _logger.d('VoiceInputService: stopping');
    await _cleanup();
  }

  /// Handle an incoming WebSocket message (expected JSON with transcript).
  void _onWsMessage(dynamic raw) {
    try {
      final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
      if (decoded['type'] == 'transcript') {
        final text = decoded['text'] as String? ?? '';
        _transcriptController.add(text);
        _logger.d('VoiceInputService: transcript received: $text');
      }
    } catch (e) {
      _logger.e('VoiceInputService: error parsing message', error: e);
    }
  }

  Future<void> _cleanup() async {
    _isStreaming = false;

    await _audioSubscription?.cancel();
    _audioSubscription = null;

    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (_) {}

    await _wsSubscription?.cancel();
    _wsSubscription = null;

    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  /// Release all resources.
  Future<void> dispose() async {
    await _cleanup();
    await _transcriptController.close();
    _recorder.dispose();
  }
}

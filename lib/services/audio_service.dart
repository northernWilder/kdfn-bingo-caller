import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _bgPlayer = AudioPlayer();
  bool _muted = false;

  bool get muted => _muted;

  Future<void> init() async {
    await _player.setReleaseMode(ReleaseMode.stop);
  }

  void toggleMute() => _muted = !_muted;

  Future<void> _play(String asset) async {
    if (_muted) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/$asset'));
    } catch (_) {}
  }

  Future<void> playBallRoll() => _play('ball_roll.mp3');
  Future<void> playBallDrop() => _play('ball_drop.mp3');
  Future<void> playDrawReveal() => _play('draw_reveal.mp3');
  Future<void> playBingo() => _play('bingo.mp3');
  Future<void> playNoBingo() => _play('no_bingo.mp3');
  Future<void> playRoundComplete() => _play('round_complete.mp3');

  // Full draw sequence: roll (tumbling) → drop → reveal
  // ball_roll.mp3 is ~5s of ping-pong balls tumbling; we let it play for 2.5s
  // before cutting to the drop sound for a natural feel.
  Future<void> playDrawSequence() async {
    if (_muted) return;
    await playBallRoll();
    await Future.delayed(const Duration(milliseconds: 2500));
    await playBallDrop();
    await Future.delayed(const Duration(milliseconds: 600));
    await playDrawReveal();
  }

  void dispose() {
    _player.dispose();
    _bgPlayer.dispose();
  }
}

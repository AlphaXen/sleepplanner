import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/sound_option_model.dart';

class MusicProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();

  SoundOption? _currentSound;
  bool _isPlaying = false;
  double _volume = 0.7;
  int _duration = 30; // in minutes

  SoundOption? get currentSound => _currentSound;
  bool get isPlaying => _isPlaying;
  double get volume => _volume;
  int get duration => _duration;

  MusicProvider() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });
  }

  Future<void> playSound(SoundOption sound) async {
    if (_currentSound?.id == sound.id && _isPlaying) {
      // If same sound is playing, pause it
      await pauseSound();
      return;
    }

    _currentSound = sound;

    try {
      // Stop any currently playing sound
      await _audioPlayer.stop();

      // Play from URL if available, otherwise from asset
      if (sound.url != null) {
        await _audioPlayer.play(UrlSource(sound.url!));
      } else if (sound.assetPath != null) {
        await _audioPlayer.play(AssetSource(sound.assetPath!));
      }

      // Set volume and loop mode
      await _audioPlayer.setVolume(_volume);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);

      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing sound: $e');
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> pauseSound() async {
    await _audioPlayer.pause();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> stopSound() async {
    await _audioPlayer.stop();
    _isPlaying = false;
    _currentSound = null;
    notifyListeners();
  }

  void setVolume(double value) {
    _volume = value;
    _audioPlayer.setVolume(_volume);
    notifyListeners();
  }

  void setDuration(int minutes) {
    _duration = minutes;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

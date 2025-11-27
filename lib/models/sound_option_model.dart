import 'package:flutter/material.dart';

class SoundOption {
  final String id;
  final String name;
  final String icon;
  final List<Color> gradientColors;
  final String? assetPath; // For local audio files
  final String? url; // For streaming audio

  const SoundOption({
    required this.id,
    required this.name,
    required this.icon,
    required this.gradientColors,
    this.assetPath,
    this.url,
  });
}

// Predefined sound options with online audio sources
class SoundOptions {
  static const List<SoundOption> all = [
    SoundOption(
      id: 'rain',
      name: 'Rain',
      icon: '🌧️',
      gradientColors: [Color(0xFF667eea), Color(0xFF764ba2)],
      url:
          'https://cdn.pixabay.com/download/audio/2022/05/27/audio_1808fbf07a.mp3', // Rain sound
    ),
    SoundOption(
      id: 'ocean',
      name: 'Ocean',
      icon: '🌊',
      gradientColors: [Color(0xFF11998e), Color(0xFF38ef7d)],
      url:
          'https://cdn.pixabay.com/download/audio/2022/06/07/audio_c2f5d7dc57.mp3', // Ocean waves
    ),
    SoundOption(
      id: 'forest',
      name: 'Forest',
      icon: '🌲',
      gradientColors: [Color(0xFF56ab2f), Color(0xFFa8e063)],
      url:
          'https://cdn.pixabay.com/download/audio/2022/03/10/audio_4a56282c36.mp3', // Forest birds
    ),
    SoundOption(
      id: 'white_noise',
      name: 'White Noise',
      icon: '📻',
      gradientColors: [Color(0xFF7F7FD5), Color(0xFF91EAE4)],
      url:
          'https://cdn.pixabay.com/download/audio/2022/03/15/audio_c610217418.mp3', // White noise
    ),
    SoundOption(
      id: 'meditation',
      name: 'Meditation',
      icon: '🧘',
      gradientColors: [Color(0xFFf093fb), Color(0xFFf5576c)],
      url:
          'https://cdn.pixabay.com/download/audio/2022/08/02/audio_884fe88c21.mp3', // Meditation music
    ),
    SoundOption(
      id: 'crickets',
      name: 'Crickets',
      icon: '🦗',
      gradientColors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
      url:
          'https://cdn.pixabay.com/download/audio/2022/05/13/audio_c2653f4d22.mp3', // Night crickets
    ),
  ];

  static SoundOption getById(String id) {
    return all.firstWhere(
      (sound) => sound.id == id,
      orElse: () => all[0],
    );
  }
}

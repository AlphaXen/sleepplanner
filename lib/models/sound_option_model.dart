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

// Predefined sound options with local asset paths
class SoundOptions {
  static const List<SoundOption> all = [
    SoundOption(
      id: 'rain',
      name: 'Rain',
      icon: '🌧️',
      gradientColors: [Color(0xFF667eea), Color(0xFF764ba2)],
      assetPath: 'sounds/rain.mp3',
    ),
    SoundOption(
      id: 'ocean',
      name: 'Ocean',
      icon: '🌊',
      gradientColors: [Color(0xFF11998e), Color(0xFF38ef7d)],
      assetPath: 'sounds/ocean.mp3',
    ),
    SoundOption(
      id: 'forest',
      name: 'Forest',
      icon: '🌲',
      gradientColors: [Color(0xFF56ab2f), Color(0xFFa8e063)],
      assetPath: 'sounds/forest.mp3',
    ),
    SoundOption(
      id: 'white_noise',
      name: 'White Noise',
      icon: '📻',
      gradientColors: [Color(0xFF7F7FD5), Color(0xFF91EAE4)],
      assetPath: 'sounds/whitenoise.mp3',
    ),
    SoundOption(
      id: 'meditation',
      name: 'Meditation',
      icon: '🧘',
      gradientColors: [Color(0xFFf093fb), Color(0xFFf5576c)],
      assetPath: 'sounds/meditation.mp3',
    ),
    SoundOption(
      id: 'crickets',
      name: 'Crickets',
      icon: '🦗',
      gradientColors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
      assetPath: 'sounds/crickets.mp3',
    ),
  ];

  static SoundOption getById(String id) {
    return all.firstWhere(
      (sound) => sound.id == id,
      orElse: () => all[0],
    );
  }
}

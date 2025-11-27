import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../models/sound_option_model.dart';

class SleepMusicScreen extends StatelessWidget {
  const SleepMusicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Music'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<MusicProvider>(
        builder: (context, musicProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Now Playing Card
                if (musicProvider.currentSound != null)
                  _NowPlayingCard(musicProvider: musicProvider),

                const SizedBox(height: 24),

                // Sound Options Grid
                const Text(
                  '🎵 Select Sound',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: SoundOptions.all.length,
                  itemBuilder: (context, index) {
                    final sound = SoundOptions.all[index];
                    final isSelected =
                        musicProvider.currentSound?.id == sound.id;

                    return _SoundCard(
                      sound: sound,
                      isSelected: isSelected,
                      isPlaying: isSelected && musicProvider.isPlaying,
                      onTap: () => musicProvider.playSound(sound),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Volume Control
                _buildVolumeControl(context, musicProvider),

                const SizedBox(height: 24),

                // Duration Control
                _buildDurationControl(context, musicProvider),

                const SizedBox(height: 32),

                // Control Buttons
                _buildControlButtons(context, musicProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVolumeControl(BuildContext context, MusicProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.volume_up),
                const SizedBox(width: 8),
                const Text(
                  'Volume',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(provider.volume * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            Slider(
              value: provider.volume,
              onChanged: (value) => provider.setVolume(value),
              min: 0.0,
              max: 1.0,
              divisions: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationControl(BuildContext context, MusicProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timer),
                const SizedBox(width: 8),
                const Text(
                  'Duration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${provider.duration} min',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            Slider(
              value: provider.duration.toDouble(),
              onChanged: (value) => provider.setDuration(value.toInt()),
              min: 5,
              max: 480,
              divisions: 95,
              label: '${provider.duration} min',
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => provider.setDuration(15),
                  child: const Text('15 min'),
                ),
                TextButton(
                  onPressed: () => provider.setDuration(30),
                  child: const Text('30 min'),
                ),
                TextButton(
                  onPressed: () => provider.setDuration(60),
                  child: const Text('1 hour'),
                ),
                TextButton(
                  onPressed: () => provider.setDuration(120),
                  child: const Text('2 hours'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons(BuildContext context, MusicProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: provider.currentSound != null
                ? () {
                    if (provider.isPlaying) {
                      provider.pauseSound();
                    } else {
                      provider.playSound(provider.currentSound!);
                    }
                  }
                : null,
            icon: Icon(
              provider.isPlaying ? Icons.pause : Icons.play_arrow,
              size: 32,
            ),
            label: Text(
              provider.isPlaying ? 'Pause' : 'Play',
              style: const TextStyle(fontSize: 18),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: provider.currentSound != null
                ? () => provider.stopSound()
                : null,
            icon: const Icon(Icons.stop, size: 32),
            label: const Text(
              'Stop',
              style: TextStyle(fontSize: 18),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class _NowPlayingCard extends StatelessWidget {
  final MusicProvider musicProvider;

  const _NowPlayingCard({required this.musicProvider});

  @override
  Widget build(BuildContext context) {
    final sound = musicProvider.currentSound!;

    return Card(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: sound.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  sound.icon,
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Now Playing',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        sound.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    musicProvider.isPlaying ? Icons.volume_up : Icons.pause,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SoundCard extends StatelessWidget {
  final SoundOption sound;
  final bool isSelected;
  final bool isPlaying;
  final VoidCallback onTap;

  const _SoundCard({
    required this.sound,
    required this.isSelected,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: isSelected ? 8 : 2,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: sound.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border:
                isSelected ? Border.all(color: Colors.white, width: 3) : null,
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      sound.icon,
                      style: const TextStyle(fontSize: 48),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      sound.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isPlaying)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      color: sound.gradientColors[0],
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

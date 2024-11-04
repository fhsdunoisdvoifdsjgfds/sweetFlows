import 'package:audioplayers/audioplayers.dart';
import 'package:color_flood/gameScreen.dart';
import 'package:color_flood/settingsScreen/settings.dart';
import 'package:color_flood/settingsScreen/settingsScreen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    await _audioPlayer.setSource(AssetSource('music/background_music.mp3'));
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);

    final prefs = await SharedPreferences.getInstance();
    final musicVolume = prefs.getDouble('musicVolume') ?? 1.0;
    final isMusicPlaying = prefs.getBool('isMusicPlaying') ?? true;

    if (isMusicPlaying) {
      await _audioPlayer.resume();
      await _audioPlayer.setVolume(musicVolume);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bgMain.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),
              // Logo
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 300,
                  fit: BoxFit.contain,
                ),
              ),
              const Spacer(),
              // Game buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Play button
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const ColorFloodGame()));
                      },
                      child: Image.asset(
                        'assets/images/play_btn.png',
                        width: 180,
                        height: 180,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Info and Settings buttons row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Info button
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => const TutorialScreen()));
                          },
                          child: Image.asset(
                            'assets/images/info_btn.png',
                            width: 80,
                            height: 80,
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Settings button
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) =>
                                    SettingsScreen(audioPlayer: _audioPlayer)));
                          },
                          child: Image.asset(
                            'assets/images/settings_btn.png',
                            width: 80,
                            height: 80,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

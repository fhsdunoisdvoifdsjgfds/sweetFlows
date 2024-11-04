import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';

import 'settingsScreen.dart';

class SettingsScreen extends StatefulWidget {
  final AudioPlayer audioPlayer;
  const SettingsScreen({super.key, required this.audioPlayer});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _musicVolume = 1.0;
  double _soundVolume = 1.0;
  bool _isMusicPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _musicVolume = prefs.getDouble('musicVolume') ?? 1.0;
      _soundVolume = prefs.getDouble('soundVolume') ?? 1.0;
      _isMusicPlaying = prefs.getBool('isMusicPlaying') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('musicVolume', _musicVolume);
    await prefs.setDouble('soundVolume', _soundVolume);
    await prefs.setBool('isMusicPlaying', _isMusicPlaying);
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Widget _buildVolumeSlider({
    required double value,
    required ValueChanged<double> onChanged,
    required bool isMusic,
  }) {
    return Container(
      width: 180,
      height: 35,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.orange
            .withOpacity(0.3), // Возвращаем прозрачный оранжевый фон
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Progress bar
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value,
                child: Container(
                  decoration: const BoxDecoration(
                    color:
                        Colors.orange, // Непрозрачный оранжевый для индикатора
                  ),
                ),
              ),
            ),
            // Invisible slider for interaction
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 35,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 0,
                ),
                overlayShape: SliderComponentShape.noOverlay,
                trackShape: const RectangularSliderTrackShape(),
              ),
              child: Slider(
                value: value,
                onChanged: onChanged,
                activeColor: Colors.transparent,
                inactiveColor: Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Image.asset(
                        'assets/images/back.png',
                        width: 40,
                        height: 40,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const TutorialScreen()));
                      },
                      child: Image.asset(
                        'assets/images/info_btn.png',
                        width: 40,
                        height: 40,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Image.asset(
                'assets/images/settings_title.png',
                width: 200,
                height: 60,
              ),
              const Spacer(),
              Container(
                height: MediaQuery.of(context).size.height * .6,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image:
                        AssetImage('assets/images/settings_bg_container.png'),
                    fit: BoxFit.fill,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  // mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 50,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/music_icon.png',
                          width: 30,
                          height: 30,
                        ),
                        const SizedBox(width: 10),
                        _buildVolumeSlider(
                          value: _musicVolume,
                          onChanged: (value) {
                            setState(() {
                              _musicVolume = value;
                              widget.audioPlayer.setVolume(value);
                            });
                            _saveSettings();
                          },
                          isMusic: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/sound_icon.png',
                          width: 30,
                          height: 30,
                        ),
                        const SizedBox(width: 10),
                        _buildVolumeSlider(
                          value: _soundVolume,
                          onChanged: (value) {
                            setState(() {
                              _soundVolume = value;
                            });
                            _saveSettings();
                          },
                          isMusic: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    GestureDetector(
                      onTap: () => _launchURL(
                          'https://racketboost.xyz/sweetflows-terms'),
                      child: Image.asset(
                        'assets/images/terms_btn.png',
                        width: 200,
                        height: 50,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => _launchURL(
                          'https://racketboost.xyz/sweetflows-policy'),
                      child: Image.asset(
                        'assets/images/privacy_btn.png',
                        width: 200,
                        height: 50,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

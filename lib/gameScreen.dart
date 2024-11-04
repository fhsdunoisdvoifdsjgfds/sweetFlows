import 'dart:collection';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:color_flood/settingsScreen/settings.dart';
import 'package:color_flood/settingsScreen/settingsScreen.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ColorFloodGame extends StatefulWidget {
  const ColorFloodGame({super.key});

  @override
  State<ColorFloodGame> createState() => _ColorFloodGameState();
}

class _ColorFloodGameState extends State<ColorFloodGame> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _soundPlayer = AudioPlayer();
  double _soundVolume = 1.0;
  static const int gridSize = 12;
  static const int maxMoves = 25;
  late ConfettiController _confettiController;
  bool _showResult = false;
  String? _resultAsset;
  late List<List<int>> grid;
  int moves = 0;
  int bestScore = 0;
  int coins = 0;

  final List<String> colorAssets = [
    'assets/images/red.png',
    'assets/images/green.png',
    'assets/images/blue.png',
    'assets/images/pink.png',
    'assets/images/orange.png',
    'assets/images/yellow.png',
  ];

  @override
  void initState() {
    super.initState();
    initializeGrid();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _loadSoundSettings();
  }

  void initializeGrid() {
    final random = Random();
    grid = List.generate(gridSize, (i) => List.generate(gridSize, (j) => 0));

    bool hasMoreThanTwoSameNeighbors(int x, int y, int color) {
      int sameColorCount = 0;
      final directions = [
        [-1, 0],
        [1, 0],
        [0, -1],
        [0, 1],
        [-1, -1],
        [-1, 1],
        [1, -1],
        [1, 1]
      ];

      for (final dir in directions) {
        final newX = x + dir[0];
        final newY = y + dir[1];

        if (newX >= 0 && newX < gridSize && newY >= 0 && newY < gridSize) {
          if (grid[newX][newY] == color) {
            sameColorCount++;
            if (sameColorCount > 2) return true;
          }
        }
      }
      return false;
    }

    List<int> getValidColors(int x, int y) {
      final availableColors = List<int>.generate(colorAssets.length, (i) => i);
      availableColors.shuffle(random);
      return availableColors
          .where((color) => !hasMoreThanTwoSameNeighbors(x, y, color))
          .toList();
    }

    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        final validColors = getValidColors(i, j);
        grid[i][j] = validColors.isEmpty
            ? random.nextInt(colorAssets.length)
            : validColors[random.nextInt(validColors.length)];
      }
    }

    final startColor = grid[0][0];
    if (grid[0][1] == startColor && grid[1][0] == startColor) {
      grid[0][1] = (startColor + 1) % colorAssets.length;
    }

    bool isTargetReachable(int targetMoves) {
      List<List<int>> tempGrid =
          List<List<int>>.generate(gridSize, (i) => List<int>.from(grid[i]));
      int moves = 0;
      bool changed;

      do {
        changed = false;
        final currentColor = tempGrid[0][0];

        for (int color = 0; color < colorAssets.length; color++) {
          if (color == currentColor) continue;

          List<List<int>> testGrid = List<List<int>>.generate(
              gridSize, (i) => List<int>.from(tempGrid[i]));

          floodFillTest(testGrid, color);

          int sameColorCount = countSameColor(testGrid, color);
          if (sameColorCount > countSameColor(tempGrid, tempGrid[0][0])) {
            tempGrid = testGrid;
            moves++;
            changed = true;
            break;
          }
        }
      } while (changed && moves < targetMoves);

      return isGridComplete(tempGrid) && moves <= targetMoves;
    }

    if (!isTargetReachable(maxMoves)) {
      initializeGrid();
    }
  }

  void floodFillTest(List<List<int>> testGrid, int newColor) {
    final oldColor = testGrid[0][0];
    final queue = Queue<Point>();
    queue.add(Point(0, 0));

    while (queue.isNotEmpty) {
      final p = queue.removeFirst();
      if (p.x < 0 || p.x >= gridSize || p.y < 0 || p.y >= gridSize) continue;
      if (testGrid[p.x][p.y] != oldColor) continue;

      testGrid[p.x][p.y] = newColor;

      queue.add(Point(p.x + 1, p.y));
      queue.add(Point(p.x - 1, p.y));
      queue.add(Point(p.x, p.y + 1));
      queue.add(Point(p.x, p.y - 1));
    }
  }

  int countSameColor(List<List<int>> testGrid, int color) {
    int count = 0;
    for (var row in testGrid) {
      for (var cell in row) {
        if (cell == color) count++;
      }
    }
    return count;
  }

  Future<void> _loadSoundSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundVolume = prefs.getDouble('soundVolume') ?? 1.0;
    });
  }

  Future<void> _playSound(String soundName) async {
    if (_soundVolume > 0) {
      await _soundPlayer.stop();
      await _soundPlayer.setVolume(_soundVolume);
      await _soundPlayer.play(AssetSource('music/$soundName'));
    }
  }

  bool isGridComplete(List<List<int>> testGrid) {
    final firstColor = testGrid[0][0];
    for (var row in testGrid) {
      for (var cell in row) {
        if (cell != firstColor) return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _soundPlayer.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void flood(int newColorIndex) async {
    if (moves >= maxMoves) {
      showGameResult(false);
      Future.delayed(const Duration(seconds: 3), () {
        setState(() {
          moves = 0;
          initializeGrid();
        });
      });
      return;
    }

    final oldColorIndex = grid[0][0];
    if (oldColorIndex == newColorIndex) return;

    await _playSound('tap.mp3');

    setState(() {
      moves++;
      floodFill(0, 0, oldColorIndex, newColorIndex);
    });

    if (checkWin()) {
      if (moves < bestScore || bestScore == 0) {
        bestScore = moves;
      }
      showGameResult(true);
      Future.delayed(const Duration(seconds: 3), () {
        setState(() {
          moves = 0;
          initializeGrid();
        });
      });
    }
  }

  void showGameResult(bool isWin) async {
    setState(() {
      _showResult = true;
      _resultAsset =
          isWin ? 'assets/images/you_win.png' : 'assets/images/you_lost.png';
    });

    await _playSound(isWin ? 'win.mp3' : 'lose.mp3');

    if (isWin) {
      _confettiController.play();
      setState(() {
        coins += 100;
      });
    }
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showResult = false;
          _resultAsset = null;
        });
      }
    });
  }

  void floodFill(int x, int y, int oldColor, int newColor) {
    Queue<Point> queue = Queue();
    queue.add(Point(x, y));

    while (queue.isNotEmpty) {
      Point p = queue.removeFirst();
      if (p.x < 0 || p.x >= gridSize || p.y < 0 || p.y >= gridSize) continue;
      if (grid[p.x][p.y] != oldColor) continue;

      grid[p.x][p.y] = newColor;

      queue.add(Point(p.x + 1, p.y));
      queue.add(Point(p.x - 1, p.y));
      queue.add(Point(p.x, p.y + 1));
      queue.add(Point(p.x, p.y - 1));
    }
  }

  bool checkWin() {
    final firstColor = grid[0][0];
    for (var row in grid) {
      for (var cell in row) {
        if (cell != firstColor) return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
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
                        Row(
                          children: [
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) =>
                                        const TutorialScreen()));
                              },
                              child: Image.asset(
                                'assets/images/info_btn.png',
                                width: 40,
                                height: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: MediaQuery.of(context).size.height * .55,
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage('assets/images/back_field.png'),
                        fit: BoxFit.fill,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 40,
                              width: 100,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage('assets/images/coins.png'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 40,
                                  top: 5,
                                ),
                                child: Center(
                                  child: Text(
                                    coins.toString(),
                                    style: GoogleFonts.titanOne(
                                      color:
                                          const Color.fromARGB(255, 89, 56, 38),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            Column(
                              children: [
                                Text(
                                  'Best',
                                  style: GoogleFonts.titanOne(
                                    color:
                                        const Color.fromARGB(255, 144, 90, 61),
                                    fontSize: 23,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '$moves/$maxMoves',
                                  style: GoogleFonts.titanOne(
                                    color:
                                        const Color.fromARGB(255, 144, 90, 61),
                                    fontSize: 21,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  moves = 0;
                                  initializeGrid();
                                });
                              },
                              child: Image.asset(
                                'assets/images/restart.png',
                                width: 40,
                                height: 40,
                              ),
                            ),
                            const SizedBox(width: 30),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: gridSize,
                                crossAxisSpacing: 0,
                                mainAxisSpacing: 0,
                              ),
                              itemCount: gridSize * gridSize,
                              itemBuilder: (context, index) {
                                final x = index ~/ gridSize;
                                final y = index % gridSize;
                                return Image.asset(
                                  colorAssets[grid[x][y]],
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        colorAssets.length,
                        (index) => GestureDetector(
                          onTap: () => flood(index),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(
                                    'assets/images/btn_color_back.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Image.asset(
                                colorAssets[index],
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 1,
              emissionFrequency: 0.03,
              numberOfParticles: 50,
              gravity: 0.1,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.red,
              ],
            ),
          ),
          if (_showResult)
            GestureDetector(
              onTap: () {
                if (_confettiController.state ==
                    ConfettiControllerState.stopped) {
                  setState(() {
                    _showResult = false;
                    _resultAsset = null;
                    moves = 0;
                    initializeGrid();
                  });
                }
              },
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Image.asset(
                    _resultAsset!,
                    width: MediaQuery.of(context).size.width * 0.7,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class Point {
  final int x;
  final int y;
  Point(this.x, this.y);
}

import 'package:flutter/material.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
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
          child: Stack(
            children: [
              PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildTutorialPage(
                    'assets/images/tutorial_page_1.png',
                  ),
                  _buildTutorialPage(
                    'assets/images/tutorial_page_2.png',
                  ),
                ],
              ),
              Positioned(
                top: 16,
                left: 16,
                child: GestureDetector(
                  onTap: () {
                    if (_currentPage > 0) {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Image.asset(
                    'assets/images/back.png',
                    width: 40,
                    height: 40,
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    if (_currentPage < 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Image.asset(
                    'assets/images/next_btn.png',
                    width: 40,
                    height: 40,
                  ),
                ),
              ),
              // Индикатор страниц
              Positioned(
                top: 120,
                left: 0,
                right: 0,
                child: Center(
                  child: Image.asset(
                    'assets/images/tutorial_title.png',
                    width: 200,
                    height: 60,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTutorialPage(String assetPath) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Image.asset(
              assetPath,
              fit: BoxFit.contain,
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

import 'dart:ui'; 
import 'package:flutter/material.dart';

class ImageFullScreenViewer extends StatefulWidget {
  final List<Map<String, String>> imageList;
  final int initialIndex;

  const ImageFullScreenViewer({
    Key? key,
    required this.imageList,
    required this.initialIndex,
  }) : super(key: key);

  @override
  _ImageFullScreenViewerState createState() => _ImageFullScreenViewerState();
}

class _ImageFullScreenViewerState extends State<ImageFullScreenViewer> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            Colors.transparent, 
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar:
          true, 
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  widget.imageList[_currentIndex]['imageUrl']!,
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 10.0,
                sigmaY: 10.0,
              ), 
              child: Container(
                color: Colors.black.withOpacity(
                  0.3,
                ), // Semi-transparent overlay
              ),
            ),
          ),
          // Foreground content
          Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity! < 0)
                      _goToNextImage();
                    else if (details.primaryVelocity! > 0)
                      _goToPreviousImage();
                  },
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                    },
                    itemCount: widget.imageList.length,
                    itemBuilder: (context, index) {
                      return _buildFullScreenImage(
                        widget.imageList[index]['imageUrl']!,
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      widget.imageList[_currentIndex]['title']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.imageList[_currentIndex]['description']!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              _buildNavigationButtons(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenImage(String imageUrl) {
    return Center(
      child: Image.network(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder:
            (context, error, stackTrace) => const Text(
              'Failed to load image',
              style: TextStyle(color: Colors.white),
            ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _goToPreviousImage,
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          IconButton(
            onPressed: _goToNextImage,
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _goToNextImage() {
    if (_currentIndex < widget.imageList.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousImage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }
}
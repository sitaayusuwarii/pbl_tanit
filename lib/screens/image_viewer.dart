import 'package:flutter/material.dart';

class ImageViewerPage extends StatefulWidget {
  final List<Map<String, dynamic>> posts;
  final int initialIndex;

  const ImageViewerPage({
    super.key,
    required this.posts,
    required this.initialIndex,
  });

  @override
  State<ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context), // klik keluar
      child: Scaffold(
        backgroundColor: Colors.black,
        body: PageView.builder(
          controller: _pageController,
          itemCount: widget.posts.length,
          itemBuilder: (context, index) {
            final post = widget.posts[index];
            return InteractiveViewer(
              child: Center(
                child: post['image_url'] != null
                    ? Image.network(
                        post['image_url'],
                        fit: BoxFit.contain,
                      )
                    : const Icon(Icons.broken_image,
                        color: Colors.white, size: 100),
              ),
            );
          },
        ),
      ),
    );
  }
}

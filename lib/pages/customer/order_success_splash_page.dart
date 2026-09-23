import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class OrderSuccessSplashPage extends StatefulWidget {
  const OrderSuccessSplashPage({super.key});

  @override
  State<OrderSuccessSplashPage> createState() => _OrderSuccessSplashPageState();
}

class _OrderSuccessSplashPageState extends State<OrderSuccessSplashPage> {
  late VideoPlayerController _controller;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _controller =
        VideoPlayerController.asset('lib/assests/videos/order_success.mp4')
          ..initialize().then((_) {
            if (!mounted) return;

            setState(() {});

            _controller.play();
          })
          ..addListener(_videoListener);
  }

  void _videoListener() {
    if (_hasNavigated || !_controller.value.isInitialized) return;

    if (_controller.value.position >= _controller.value.duration) {
      _hasNavigated = true;
      _goHome();
    }
  }

  void _goHome() {
    if (!mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _controller.value.isInitialized
          ? Stack(
              fit: StackFit.expand,
              children: [
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 48,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Text(
                          'ร้านกำลังเตรียมอาหารของคุณ...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: const LinearProgressIndicator(
                          color: Color(0xFFE6391A),
                          backgroundColor: Colors.white24,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 4,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'ร้านกำลังเตรียมอาหารของคุณ...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

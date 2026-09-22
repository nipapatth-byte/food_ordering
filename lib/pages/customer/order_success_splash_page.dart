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
      backgroundColor: Colors.white,
      body: Center(
        child: _controller.value.isInitialized
            ? SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}

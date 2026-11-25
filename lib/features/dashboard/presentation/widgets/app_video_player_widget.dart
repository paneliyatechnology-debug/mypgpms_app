import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/colors/app_colors.dart';

class AppVideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;

  const AppVideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.autoPlay = true,
  });

  @override
  State<AppVideoPlayerWidget> createState() => _AppVideoPlayerWidgetState();
}

class _AppVideoPlayerWidgetState extends State<AppVideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
      _isInitialized = false;
    });

    try {
      final oldController = _controller;
      _controller = null;
      await oldController?.dispose();

      final controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      _controller = controller;

      await controller.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });

        if (widget.autoPlay) {
          controller.play();
        }

        controller.addListener(() {
          if (mounted) setState(() {});
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3.0,
            ),
            const SizedBox(height: 14.0),
            Text(
              'Loading video...',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white70,
                fontSize: 13.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      final isChannelError = _errorMessage.contains('channel-error') ||
          _errorMessage.contains('PlatformException') ||
          _errorMessage.contains('dev.flutter');

      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Container(
            padding: const EdgeInsets.all(22.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(18.0),
              border: Border.all(color: Colors.white24, width: 1.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.play_circle_outline_rounded,
                  color: Colors.white,
                  size: 50.0,
                ),
                const SizedBox(height: 12.0),
                Text(
                  'In-App Video Player',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  isChannelError
                      ? 'To enable in-app playback for newly installed video player, please fully restart the app (press Stop ⏹ and Run ▶ in Android Studio).'
                      : 'Unable to stream video. Please check your internet connection and try again.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontSize: 12.0,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18.0),
                InkWell(
                  onTap: _initializePlayer,
                  borderRadius: BorderRadius.circular(999.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 11.0),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.refresh_rounded, color: Colors.white, size: 18.0),
                        const SizedBox(width: 8.0),
                        Text(
                          'Retry Playback',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 13.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final controller = _controller;
    if (!_isInitialized || controller == null) {
      return const SizedBox.shrink();
    }

    final isPlaying = controller.value.isPlaying;
    final position = controller.value.position;
    final duration = controller.value.duration;
    final isFinished = position >= duration && duration > Duration.zero;

    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio > 0 ? controller.value.aspectRatio : 16 / 9,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // In-app video stream
              VideoPlayer(controller),

              // Controls Overlay
              if (_showControls || !isPlaying || isFinished)
                Container(
                  color: Colors.black38,
                  child: Stack(
                    children: [
                      // Center Play / Pause / Replay button
                      Center(
                        child: IconButton(
                          iconSize: 58.0,
                          icon: Icon(
                            isFinished
                                ? Icons.replay_circle_filled_rounded
                                : (isPlaying
                                    ? Icons.pause_circle_filled_rounded
                                    : Icons.play_circle_filled_rounded),
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              if (isFinished) {
                                controller.seekTo(Duration.zero);
                                controller.play();
                              } else if (isPlaying) {
                                controller.pause();
                              } else {
                                controller.play();
                              }
                            });
                          },
                        ),
                      ),

                      // Bottom Progress bar & Duration
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black87, Colors.transparent],
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              VideoProgressIndicator(
                                controller,
                                allowScrubbing: true,
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                colors: const VideoProgressColors(
                                  playedColor: AppColors.primary,
                                  bufferedColor: Colors.white30,
                                  backgroundColor: Colors.white12,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(position),
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(duration),
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white70,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

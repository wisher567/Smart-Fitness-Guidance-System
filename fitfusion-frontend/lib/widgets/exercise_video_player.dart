import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class ExerciseVideoPlayer extends StatefulWidget {
  final String youtubeVideoId;
  final String? duration;

  const ExerciseVideoPlayer({
    super.key,
    required this.youtubeVideoId,
    this.duration,
  });

  @override
  State<ExerciseVideoPlayer> createState() => _ExerciseVideoPlayerState();
}

class _ExerciseVideoPlayerState extends State<ExerciseVideoPlayer> {
  YoutubePlayerController? _controller;
  bool _showPlayer = false;

  static const _accent = Color(0xFFE8845C);

  void _loadPlayer() {
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.youtubeVideoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
      ),
    );
    setState(() => _showPlayer = true);
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: _showPlayer && _controller != null
          ? _buildPlayer()
          : _buildThumbnail(),
    );
  }

  Widget _buildPlayer() {
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: YoutubePlayerScaffold(
        controller: _controller!,
        aspectRatio: 16 / 9,
        builder: (context, player) => player,
      ),
    );
  }

  Widget _buildThumbnail() {
    final thumbnailUrl =
        'https://img.youtube.com/vi/${widget.youtubeVideoId}/hqdefault.jpg';
    return GestureDetector(
      onTap: _loadPlayer,
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFF5F5F5),
                child: const Icon(Icons.fitness_center, size: 48, color: Color(0xFFE0E0E0)),
              ),
            ),
            // Dark overlay for contrast
            Container(color: Colors.black.withAlpha(90)),
            // Play button
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _accent.withAlpha(230),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withAlpha(100),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
              ),
            ),
            // Duration badge
            if (widget.duration != null)
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(180),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.duration!,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            // YouTube badge
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'YouTube',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            // Tap hint
            Positioned(
              bottom: 10,
              left: 12,
              child: Text(
                'Tap to play',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

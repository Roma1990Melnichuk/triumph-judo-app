import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VideoPlayerDialog extends StatefulWidget {
  const VideoPlayerDialog({super.key, required this.videoUrl, this.title = ''});

  final String videoUrl;
  final String title;

  static Future<void> show(
      BuildContext context, String videoUrl, {String title = ''}) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => VideoPlayerDialog(videoUrl: videoUrl, title: title),
    );
  }

  @override
  State<VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<VideoPlayerDialog> {
  late final WebViewController _controller;
  bool _loading = true;

  static String? _extractYouTubeId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (uri.host.contains('youtu.be')) return uri.pathSegments.firstOrNull;
    if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'] ??
          (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'embed'
              ? uri.pathSegments[1]
              : null);
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final ytId = _extractYouTubeId(widget.videoUrl);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
        },
      ));

    if (ytId != null) {
      // Load YouTube embed URL directly — avoids iframe X-Frame-Options restrictions
      // that block when loading from loadHtmlString (about:blank origin)
      _controller.loadRequest(
        Uri.parse(
            'https://www.youtube.com/embed/$ytId?autoplay=1&playsinline=1&rel=0&fs=1'),
      );
    } else {
      // Direct video file — use HTML5 video element
      _controller.loadHtmlString('''
<!DOCTYPE html>
<html>
<body style="margin:0;padding:0;background:#000;height:100vh;display:flex;align-items:center;justify-content:center">
  <video width="100%" height="100%" controls autoplay playsinline
         style="max-height:100vh;object-fit:contain">
    <source src="${widget.videoUrl}">
  </video>
</body>
</html>''');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Use 90% of screen height so player is large enough to watch comfortably
    final dialogH = size.height * 0.88;
    final videoH = dialogH - 56; // minus header bar

    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(),
      child: SizedBox(
        width: size.width,
        height: dialogH,
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // ── Video ────────────────────────────────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  SizedBox(
                    height: videoH,
                    child: WebViewWidget(controller: _controller),
                  ),
                  if (_loading)
                    const Center(
                      child: CircularProgressIndicator(color: Colors.white54),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'app_back_button.dart';

class VideoPlayerDialog extends StatefulWidget {
  const VideoPlayerDialog({super.key, required this.videoUrl, this.title = ''});

  final String videoUrl;
  final String title;

  /// Відкриває повноекранний плеєр поверх поточного маршруту.
  static Future<void> show(
      BuildContext context, String videoUrl, {String title = ''}) {
    return Navigator.of(context).push<void>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) =>
          VideoPlayerDialog(videoUrl: videoUrl, title: title),
    ));
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
    // Сховати навігаційний рядок для справжнього fullscreen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

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
      _controller.loadRequest(Uri.parse(
          'https://www.youtube.com/embed/$ytId?autoplay=1&playsinline=1&rel=0&fs=1'));
    } else {
      // Прямий файл (Cloudinary тощо) — baseUrl = origin відео,
      // щоб уникнути блокування cross-origin з about:blank
      final uri = Uri.tryParse(widget.videoUrl);
      final baseUrl =
          (uri != null) ? '${uri.scheme}://${uri.host}' : null;

      final html = '''<!DOCTYPE html>
<html>
<head><meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="margin:0;padding:0;background:#000;height:100vh;
             display:flex;align-items:center;justify-content:center">
  <video width="100%" height="100%" controls playsinline
         style="max-height:100vh;object-fit:contain">
    <source src="${widget.videoUrl}">
  </video>
</body>
</html>''';

      if (baseUrl != null) {
        _controller.loadHtmlString(html, baseUrl: baseUrl);
      } else {
        _controller.loadHtmlString(html);
      }
    }
  }

  @override
  void dispose() {
    // Повернути звичайний UI при виході з плеєра
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────────
            SafeArea(
              bottom: false,
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                    AppBackButton(onPressed: () => Navigator.pop(context)),
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
                  ],
                ),
              ),
            ),
            // ── Video (решта екрану) ──────────────────────────────────────────
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  WebViewWidget(controller: _controller),
                  if (_loading)
                    const Center(
                      child:
                          CircularProgressIndicator(color: Colors.white54),
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

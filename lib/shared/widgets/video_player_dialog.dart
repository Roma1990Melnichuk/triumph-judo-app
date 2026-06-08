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
      builder: (_) => VideoPlayerDialog(videoUrl: videoUrl, title: title),
    );
  }

  @override
  State<VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<VideoPlayerDialog> {
  late final WebViewController _controller;

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

  String _buildHtml() {
    final ytId = _extractYouTubeId(widget.videoUrl);
    if (ytId != null) {
      return '''<!DOCTYPE html><html><body style="margin:0;padding:0;background:#000;height:100vh">
<iframe width="100%" height="100%"
  src="https://www.youtube.com/embed/$ytId?autoplay=1&playsinline=1&rel=0"
  frameborder="0" allow="autoplay; fullscreen" allowfullscreen></iframe>
</body></html>''';
    }
    return '''<!DOCTYPE html><html><body style="margin:0;padding:0;background:#000;height:100vh;display:flex;align-items:center">
<video width="100%" controls autoplay playsinline>
  <source src="${widget.videoUrl}">
</video>
</body></html>''';
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(_buildHtml());
  }

  @override
  Widget build(BuildContext context) {
    final videoH = (MediaQuery.of(context).size.width - 32) * 9 / 16;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
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
            SizedBox(
              height: videoH,
              child: WebViewWidget(controller: _controller),
            ),
          ],
        ),
      ),
    );
  }
}

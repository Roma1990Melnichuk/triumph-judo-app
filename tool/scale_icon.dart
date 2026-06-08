import 'dart:io';
import 'package:image/image.dart';

/// Crops transparent padding from the logo and scales it up
/// so the actual logo fills more of the adaptive icon safe zone.
void main() {
  final src = File('assets/images/triumph_logo_android.png');
  if (!src.existsSync()) {
    print('ERROR: ${src.path} not found');
    exit(1);
  }

  final img = decodeImage(src.readAsBytesSync())!;
  print('Original size: ${img.width}×${img.height}');

  final w = img.width;
  final h = img.height;

  // Zoom in by cropping outer 12% from each side
  const cropPct = 0.12;
  final cropX = (w * cropPct).toInt();
  final cropY = (h * cropPct).toInt();

  final cropped = copyCrop(img, x: cropX, y: cropY,
      width: w - cropX * 2, height: h - cropY * 2);

  final scaled = copyResize(cropped, width: w, height: h,
      interpolation: Interpolation.cubic);

  // Fill canvas with adaptive background color (#CC1B1B) to eliminate
  // transparent corners that render as a white border on some launchers
  final canvas = Image(width: w, height: h, numChannels: 4);
  for (var y2 = 0; y2 < h; y2++) {
    for (var x2 = 0; x2 < w; x2++) {
      canvas.setPixelRgba(x2, y2, 0xCC, 0x1B, 0x1B, 0xFF); // #CC1B1B
    }
  }
  compositeImage(canvas, scaled, dstX: 0, dstY: 0,
      blend: BlendMode.alpha);

  final out = File('assets/images/triumph_logo_android.png');
  out.writeAsBytesSync(encodePng(canvas));
  print('Saved: ${out.path} — solid red background, no transparent corners');
}

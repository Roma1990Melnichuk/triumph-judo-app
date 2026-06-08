// Generates triumph_logo_android.png: red background + logo composited.
// Usage: dart run tool/make_android_icon.dart
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final src = File('assets/images/triumph_logo.png').readAsBytesSync();
  final logo = img.decodePng(src);
  if (logo == null) {
    print('ERROR: could not decode triumph_logo.png');
    exit(1);
  }

  const size = 1024;

  // Red background: #CC1B1B
  final bg = img.Image(width: size, height: size, numChannels: 4);
  img.fill(bg, color: img.ColorRgba8(0xCC, 0x1B, 0x1B, 0xFF));

  // Scale logo to fill the canvas
  final scaled = img.copyResize(logo, width: size, height: size,
      interpolation: img.Interpolation.cubic);

  // Composite (logo alpha blended onto red bg)
  img.compositeImage(bg, scaled);

  final out = File('assets/images/triumph_logo_android.png');
  out.writeAsBytesSync(img.encodePng(bg));
  print('Saved ${out.path}');
}

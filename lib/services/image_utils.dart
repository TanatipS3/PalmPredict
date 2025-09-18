import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Resize to maxSide px (keeping aspect) and JPEG quality.
Future<File> downscaleForUpload(File input,
    {int maxSide = 1280, int quality = 85}) async {
  final bytes = await input.readAsBytes();
  final src = img.decodeImage(bytes);
  if (src == null) return input; // fallback if decode fails

  int w = src.width, h = src.height;
  if (w <= maxSide && h <= maxSide) return input;

  // keep aspect ratio
  if (w >= h) {
    final nw = maxSide;
    final nh = (h * maxSide / w).round();
    final resized = img.copyResize(src, width: nw, height: nh);
    return _writeTempJpg(resized, quality);
  } else {
    final nh = maxSide;
    final nw = (w * maxSide / h).round();
    final resized = img.copyResize(src, width: nw, height: nh);
    return _writeTempJpg(resized, quality);
  }
}

Future<File> _writeTempJpg(img.Image image, int quality) async {
  final outBytes = img.encodeJpg(image, quality: quality);
  final dir = await getTemporaryDirectory();
  final f = File('${dir.path}/upl_${DateTime.now().millisecondsSinceEpoch}.jpg');
  await f.writeAsBytes(outBytes, flush: true);
  return f;
}

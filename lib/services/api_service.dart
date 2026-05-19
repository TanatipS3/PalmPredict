import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class PalmResult {
  final String imageToken;
  final String lifeLinePrediction;
  final String headLinePrediction;
  final String heartLinePrediction;

  const PalmResult({
    required this.imageToken,
    required this.lifeLinePrediction,
    required this.headLinePrediction,
    required this.heartLinePrediction,
  });

  bool get noLines =>
      (lifeLinePrediction.isEmpty || lifeLinePrediction == 'ไม่พบข้อมูล') &&
      (headLinePrediction.isEmpty || headLinePrediction == 'ไม่พบข้อมูล') &&
      (heartLinePrediction.isEmpty || heartLinePrediction == 'ไม่พบข้อมูล');
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});
  @override
  String toString() =>
      'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

class ApiService {
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    // Default for local development
    if (kIsWeb) return 'http://127.0.0.1:5000';
    if (Platform.isAndroid) return 'http://10.0.2.2:5000';
    return 'http://127.0.0.1:5000'; // iOS Simulator, Desktop, etc.
  }

  static const _detect = '/detect-hand';
  static const _segment = '/segment-lines';
  static const _getMask = '/get-mask-image';

  static const Duration _timeout = Duration(seconds: 45);

  // ---------- step 1: detect hand (multipart) ----------
  static Future<bool> detectHand(File imageFile) async {
    final uri = Uri.parse('$baseUrl$_detect');

    final req = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath(
        'image', // <-- field name Flask expects
        imageFile.path,
        contentType: MediaType('image', _guessExt(imageFile.path)),
      ));

    final streamed = await req.send().timeout(_timeout);
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode != 200) {
      throw ApiException('detect-hand failed: ${resp.body}',
          statusCode: resp.statusCode);
    }
    final m = jsonDecode(resp.body) as Map<String, dynamic>;
    return (m['palm_detected'] == true);
  }

  // ---------- step 2: segment lines (raw bytes) ----------
  static Future<PalmResult> processPalm(File imageFile) async {
    final uri = Uri.parse('$baseUrl$_segment');

    final bytes = await imageFile.readAsBytes();
    final resp = await http
        .post(uri,
            headers: {'Content-Type': 'image/jpeg'}, body: bytes)
        .timeout(_timeout);

    if (resp.statusCode != 200) {
      throw ApiException('Server error: ${resp.statusCode} ${resp.body}',
          statusCode: resp.statusCode);
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final life = (data['life_line'] ?? '').toString();
    final head = (data['head_line'] ?? '').toString();
    final heart = (data['heart_line'] ?? '').toString();
    final token = (data['image_token'] ?? '').toString();

    return PalmResult(
      imageToken: token,
      lifeLinePrediction: life,
      headLinePrediction: head,
      heartLinePrediction: heart,
    );
  }

  static Future<Uint8List?> fetchMaskImage(String token) async {
    if (token.isEmpty) return null;
    final uri = Uri.parse('$baseUrl$_getMask?token=$token');
    final resp = await http.get(uri).timeout(const Duration(seconds: 45));
    if (resp.statusCode == 200) return resp.bodyBytes;
    return null;
  }

  static String _guessExt(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.png')) return 'png';
    if (p.endsWith('.jpeg') || p.endsWith('.jpg')) return 'jpeg';
    return 'jpeg';
  }
}

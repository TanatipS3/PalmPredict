import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// ---------- Models ----------
class PalmResult {
  final String imageToken;            // may be empty if backend didn't return it
  final String lifeLinePrediction;
  final String headLinePrediction;
  final String heartLinePrediction;

  const PalmResult({
    required this.imageToken,
    required this.lifeLinePrediction,
    required this.headLinePrediction,
    required this.heartLinePrediction,
  });

  Map<String, dynamic> toJson() => {
        'lifeLinePrediction': lifeLinePrediction,
        'headLinePrediction': headLinePrediction,
        'heartLinePrediction': heartLinePrediction,
        'imageToken': imageToken,
      };
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});
  @override
  String toString() =>
      'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// ---------- Service ----------
class ApiService {
  /// Set at build time:
  /// flutter run --dart-define=API_BASE_URL=https://<api-id>.execute-api.<region>.amazonaws.com
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000', // local fallback if needed
  );

  static const Duration defaultTimeout = Duration(seconds: 60);

  // ---- paths you asked to keep ----
  static const _healthPath = '/health';
  static const _detectPath = '/detect-hand';
  static const _segmentPath = '/segment-lines';
  static const _maskPath = '/get-mask-image';
  static const _profilePath = '/upload-user-profile';

  /// Quick ping
  static Future<bool> health() async {
    final resp = await http
        .get(Uri.parse('$baseUrl$_healthPath'))
        .timeout(const Duration(seconds: 10));
    return resp.statusCode == 200;
  }

  /// 1) Detect palm (multipart/form-data, field name 'image')
  static Future<bool> detectPalm(File imageFile) async {
    try {
      final uri = Uri.parse('$baseUrl$_detectPath');
      final req = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      final streamed = await req.send().timeout(defaultTimeout);
      final resp = await http.Response.fromStream(streamed);
      if (resp.statusCode != 200) return false;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return data['palm_detected'] == true;
    } on TimeoutException {
      throw const ApiException('Detect timeout');
    } on SocketException {
      throw const ApiException('Network unavailable');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Detect failed: $e');
    }
  }

  /// 2) Send raw bytes to /segment-lines (Content-Type: application/octet-stream)
  static Future<PalmResult> processPalm(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final resp = await http
          .post(
            Uri.parse('$baseUrl$_segmentPath'),
            headers: {'Content-Type': 'application/octet-stream'},
            body: bytes,
          )
          .timeout(defaultTimeout);

      if (resp.statusCode != 200) {
        throw ApiException('Server error: ${resp.statusCode} ${resp.body}',
            statusCode: resp.statusCode);
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      // backend returns keys: life_line, head_line, heart_line, image_token
      return PalmResult(
        imageToken: (data['image_token'] ?? '').toString(),
        lifeLinePrediction: (data['life_line'] ?? 'ไม่พบข้อมูล').toString(),
        headLinePrediction: (data['head_line'] ?? 'ไม่พบข้อมูล').toString(),
        heartLinePrediction: (data['heart_line'] ?? 'ไม่พบข้อมูล').toString(),
      );
    } on TimeoutException {
      throw const ApiException('Server took too long (timeout)');
    } on SocketException {
      throw const ApiException('Network unavailable');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error: $e');
    }
  }

  /// 3) Get the masked/overlay image by token (bytes for Image.memory)
  static Future<Uint8List?> fetchMaskImage(String token) async {
  final uri = Uri.parse("$baseUrl/get-mask-image?token=$token");
  final resp = await http.get(uri).timeout(defaultTimeout);
  if (resp.statusCode == 200) return resp.bodyBytes;
  throw ApiException('fetchMaskImage failed: ${resp.statusCode}');
}


  /// 4) Upload/Update user profile in Supabase (JSON)
  static Future<bool> uploadUserProfile({
    required String name,
    required String passcode,
    File? imageFile,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$_profilePath');

      String? b64;
      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        b64 = base64Encode(bytes);
      }

      final body = jsonEncode({
        'name': name,
        'passcode': passcode,
        if (b64 != null) 'image_base64': b64,
        'last_updated': DateTime.now().toUtc().toIso8601String(),
      });

      final resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(defaultTimeout);

      if (resp.statusCode == 200) return true;
      throw ApiException('Upload failed: ${resp.statusCode} ${resp.body}',
          statusCode: resp.statusCode);
    } on TimeoutException {
      throw const ApiException('Upload timeout');
    } on SocketException {
      throw const ApiException('Network unavailable');
    }
  }
}

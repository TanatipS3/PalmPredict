import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

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

class ApiService {
  static const String baseUrl = "http://192.168.1.29:5000";
  static const Duration defaultTimeout = Duration(seconds: 2400);
  static const String _palmDetectionEndpoint = "/detect-hand";
  static const String _segmentLinesEndpoint = "/segment-lines";
  static const String _getMaskImageEndpoint = "/get-mask-image";
  static const String _uploadUserProfileEndpoint = "/upload-user-profile";

  /// Detect if palm is present in the image
  static Future<bool> detectPalm(File imageFile) async {
    try {
      final uri = Uri.parse("$baseUrl$_palmDetectionEndpoint");
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 600));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["palm_detected"] == true;
      }
      return false;
    } catch (e) {
      print("❌ Error in detectPalm: $e");
      return false;
    }
  }

  /// Send palm image to server and get predictions + token
  static Future<PalmResult?> processPalm(File imageFile) async {
    try {
      final uri = Uri.parse("$baseUrl$_segmentLinesEndpoint");
      final bytes = await imageFile.readAsBytes();

      final request = http.Request('POST', uri)
        ..headers['Content-Type'] = 'application/octet-stream'
        ..bodyBytes = bytes;

      final streamedResponse = await request.send().timeout(defaultTimeout);
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200) {
        final data = jsonDecode(responseBody);

        if (data.containsKey('life_line') &&
            data.containsKey('head_line') &&
            data.containsKey('heart_line') &&
            data.containsKey('image_token')) {
          return PalmResult(
            imageToken: data['image_token'],
            lifeLinePrediction: data["life_line"] ?? "ไม่พบข้อมูล",
            headLinePrediction: data["head_line"] ?? "ไม่พบข้อมูล",
            heartLinePrediction: data["heart_line"] ?? "ไม่พบข้อมูล",
          );
        } else {
          throw ApiException("Missing required fields: $data");
        }
      } else {
        throw ApiException("Server error", statusCode: streamedResponse.statusCode);
      }
    } catch (e) {
      print("❌ Error in processPalm: $e");
      return null;
    }
  }

  /// Fetch the debug mask image from token
  static Future<Uint8List?> fetchMaskImage(String token) async {
    try {
      final uri = Uri.parse("$baseUrl$_getMaskImageEndpoint?token=$token");
      final response = await http.get(uri).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('image_base64')) {
          return base64Decode(data["image_base64"]);
        }
      } else {
        print("❌ fetchMaskImage failed: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error in fetchMaskImage: $e");
    }
    return null;
  }

  /// Upload or update user profile to Supabase
  static Future<bool> uploadUserProfile({
  required String name,
  required String passcode,
  File? imageFile,
}) async {
  try {
    final uri = Uri.parse("$baseUrl/upload-user-profile");
    final Map<String, dynamic> body = {
      'username': name,
      'passcode': passcode,
      'last_updated': DateTime.now().toIso8601String(),
    };

    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      body['profile_image'] = base64Encode(bytes);
    }

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json', // ✅ make sure this is set!
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print("❌ Upload failed: ${response.statusCode} - ${response.body}");
      return false;
    }
  } catch (e) {
    print("❌ Error in uploadUserProfile: $e");
    return false;
  }
}

}

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

const _cloudName = 'dwrw28192';
const _uploadPreset = 'k8xxcwr2';

/// Uploads image [bytes] to Cloudinary and returns the secure CDN URL.
/// [publicId] should be a stable identifier so re-uploads overwrite the same resource.
Future<String> uploadImageToCloudinary(Uint8List bytes, String publicId) async {
  return _upload(
    resourceType: 'image',
    publicId: publicId,
    file: http.MultipartFile.fromBytes('file', bytes, filename: '$publicId.jpg'),
  );
}

/// Uploads a video file at [filePath] to Cloudinary and returns the secure CDN URL.
Future<String> uploadVideoToCloudinary(String filePath, String publicId) async {
  return _upload(
    resourceType: 'video',
    publicId: publicId,
    file: await http.MultipartFile.fromPath('file', filePath),
  );
}

Future<String> _upload({
  required String resourceType,
  required String publicId,
  required http.MultipartFile file,
}) async {
  final uri = Uri.parse(
    'https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload',
  );
  final request = http.MultipartRequest('POST', uri)
    ..fields['upload_preset'] = _uploadPreset
    ..fields['public_id'] = publicId
    ..files.add(file);

  final streamed = await request.send();
  final body = await streamed.stream.bytesToString();
  if (streamed.statusCode != 200) {
    throw Exception('Upload failed (${streamed.statusCode}): $body');
  }
  final json = jsonDecode(body) as Map<String, dynamic>;
  return json['secure_url'] as String;
}

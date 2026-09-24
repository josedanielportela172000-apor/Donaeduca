import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as path;

class CloudinaryService {
  // Es más eficiente leer las variables de entorno una vez.
  // Se pueden inicializar en el constructor o como estáticas.
  static final String? _cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
  static final String? _uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'];

  /// Sube una imagen a Cloudinary y devuelve la URL segura.
  /// Lanza una [Exception] si las variables de entorno no están configuradas
  /// o si ocurre un error durante la subida.
  Future<String?> uploadImage(File imageFile) async {
    // Verificación para asegurar que las variables de entorno se cargaron.
    if (_cloudName == null || _uploadPreset == null) {
      debugPrint('Error: Las variables de entorno de Cloudinary no están configuradas.');
      // Es mejor lanzar una excepción para que la UI pueda manejarla.
      throw Exception('El servicio de subida de imágenes no está configurado.');
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset!
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          filename: path.basename(imageFile.path),
        ),
      );

    try {
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(responseData);
        return data['secure_url'];
      } else {
        throw Exception('Error al subir la imagen: ${response.reasonPhrase} - $responseData');
      }
    } catch (e) {
      debugPrint('Error al subir imagen: $e');
      // Relanzar la excepción para que la capa superior la maneje.
      rethrow;
    }
  }
}

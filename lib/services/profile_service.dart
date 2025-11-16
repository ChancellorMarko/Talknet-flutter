import 'dart:io';
import 'package:image_picker/image_picker.dart';

/// Service que serve a página profile
class ProfileService {
  /// Instância do ImagePicker
  final ImagePicker _imagePicker = ImagePicker();

  /// Possibilita selecionar uma imagem da galeria
  Future<File?> pickImageFromGallery() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }

      return null;
    } catch (e) {
      throw Exception('Erro ao selecionar imagem: $e');
    }
  }

  /// Tira uma foto com a câmera
  Future<File?> takePhotoWithCamera() async {
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        return File(photo.path);
      }

      return null;
    } catch (e) {
      throw Exception('Erro ao tirar foto: $e');
    }
  }
}

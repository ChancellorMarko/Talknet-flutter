import 'dart:io';

import 'package:image_picker/image_picker.dart';

class ProfileService {
  /// Instância do ImagePicker
  final ImagePicker imagePicker = ImagePicker();

  /// Possibilita selecionar uma imagem da galeria
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      return image != null ? File(image.path) : null;
    } catch (e) {
      throw Exception('Erro ao selecionar imagem: $e');
    }
  }

  /// Tira uma foto com a câmera
  Future<File?> takePhotoWithCamera() async {
    try {
      final XFile? photo = await imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      return photo != null ? File(photo.path) : null;
    } catch (e) {
      throw Exception('Erro ao tirar foto: $e');
    }
  }
}

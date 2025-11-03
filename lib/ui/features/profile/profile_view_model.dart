import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_talknet_app/repositories/implementations/profile_repository_implementation.dart';
import 'package:flutter_talknet_app/services/profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ViewModel para a tela de perfil
class ProfileViewModel extends ChangeNotifier {
  /// Constructor da classe [ProfileViewModel]
  ProfileViewModel(this.profileRepository);

  /// Constructor da classe [ProfileViewModel]
  final ProfileRepositoryImplementation profileRepository;

  /// Controladores de nome do usuário
  final TextEditingController nameController = TextEditingController();
  /// Controladores de bio do usuário
  final TextEditingController bioController = TextEditingController();
  /// Controladores de idade do usuário
  final TextEditingController ageController = TextEditingController();

  String? _avatarUrl;
  File? _selectedImage;
  bool _isLoading = true;
  bool _isSaving = false;

  /// Getter de avatarUrl
  String? get avatarUrl => _avatarUrl;
  /// Getter de selectedImage
  File? get selectedImage => _selectedImage;
  /// Getter de isLoading
  bool get isLoading => _isLoading;
  /// Getter de isSaving
  bool get isSaving => _isSaving;

  // Setters privados
  void _setAvatarUrl(String? value) {
    _avatarUrl = value;
    notifyListeners();
  }

  void _setSelectedImage(File? value) {
    _selectedImage = value;
    notifyListeners();
  }

  void _setIsLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setIsSaving(bool value) {
    _isSaving = value;
    notifyListeners();
  }

  /// Carrega os dados do perfil do usuário
  Future<void> loadProfile() async {
    try {
      _setIsLoading(true);

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      final profile = await profileRepository.getProfileData(userId);

      if (profile != null) {
        nameController.text = (profile['full_name'] as String?) ?? '';
        bioController.text = (profile['bio'] as String?) ?? '';
        ageController.text = profile['age']?.toString() ?? '';
        _setAvatarUrl(profile['avatar_url'] as String?);
      }
      _setIsLoading(false);
    } catch (e) {
      _setIsLoading(false);
      rethrow;
    }
  }

  /// Seleciona uma imagem da galeria
  Future<void> pickImage() async {
    try {
      final image = await ProfileService().pickImageFromGallery();
      if (image != null) {
        _setSelectedImage(image);
      }
    } on Exception catch (e) {
      debugPrint('Erro ao selecionar imagem: $e');
    }
  }

  /// Tira uma foto com a câmera
  Future<void> takePhoto() async {
    try {
      final photo = await ProfileService().takePhotoWithCamera();
      if (photo != null) {
        _setSelectedImage(photo);
      }
    } on Exception catch (e) {
      debugPrint('Erro ao tirar foto: $e');
    }
  }

  /// Remove a imagem selecionada
  void removeImage() {
    _setSelectedImage(null);
    _setAvatarUrl(null);
  }

  /// Valida os dados do formulário
  String? validateForm() {
    if (nameController.text.trim().isEmpty) {
      return 'Por favor, digite seu nome completo';
    }

    if (ageController.text.isNotEmpty) {
      final age = int.tryParse(ageController.text);
      if (age == null || age < 13 || age > 120) {
        return 'Por favor, digite uma idade válida (13-120)';
      }
    }

    if (bioController.text.length > 200) {
      return 'A bio deve ter no máximo 200 caracteres';
    }

    return null;
  }

  /// Salva o perfil do usuário
  Future<void> saveProfile() async {
    try {
      // Validar formulário
      final validationError = validateForm();
      if (validationError != null) {
        throw Exception(validationError);
      }

      _setIsSaving(true);

      // Upload da imagem se houver uma nova
      var finalAvatarUrl = _avatarUrl;
      if (_selectedImage != null) {
        finalAvatarUrl = await profileRepository.uploadProfilePicture(
          _selectedImage!,
          _avatarUrl,
        );
        _setAvatarUrl(finalAvatarUrl);
      }

      // Preparar dados do perfil
      final profileData = {
        'full_name': nameController.text.trim(),
        'bio': bioController.text.trim(),
        'age': ageController.text.isNotEmpty
            ? int.parse(ageController.text)
            : null,
        'avatar_url': finalAvatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Salvar no banco de dados
      await profileRepository.saveProfile(profileData);

      _setIsSaving(false);
    } catch (e) {
      _setIsSaving(false);
      rethrow;
    }
  }
}

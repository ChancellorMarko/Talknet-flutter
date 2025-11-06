import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_talknet_app/repositories/interfaces/profile_repository.dart';
import 'package:flutter_talknet_app/services/profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

///
class ProfileViewModel extends ChangeNotifier {
  ///
  ProfileViewModel(this.profileRepository) {
    _profileService = ProfileService();
  }

  final ProfileRepository profileRepository;
  late final ProfileService _profileService;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController ageController = TextEditingController();

  String? _avatarUrl;
  File? _selectedImage;
  bool _isLoading = true;
  bool _isSaving = false;

  // Getters
  String? get avatarUrl => _avatarUrl;
  File? get selectedImage => _selectedImage;
  bool get isLoading => _isLoading;
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
      debugPrint('Erro ao carregar perfil: $e');
      rethrow;
    }
  }

  /// Seleciona uma imagem da galeria
  Future<void> pickImage() async {
    try {
      final image = await _profileService.pickImageFromGallery();
      if (image != null) {
        _setSelectedImage(image);
      }
    } catch (e) {
      debugPrint('Erro ao selecionar imagem: $e');
      rethrow;
    }
  }

  /// Tira uma foto com a câmera
  Future<void> takePhoto() async {
    try {
      final photo = await _profileService.takePhotoWithCamera();
      if (photo != null) {
        _setSelectedImage(photo);
      }
    } catch (e) {
      debugPrint('Erro ao tirar foto: $e');
      rethrow;
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
        debugPrint('Fazendo upload da nova imagem...');
        finalAvatarUrl = await profileRepository.uploadProfilePicture(
          _selectedImage!,
          _avatarUrl,
        );
        _setAvatarUrl(finalAvatarUrl);
        debugPrint('Upload concluído: $finalAvatarUrl');
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

      debugPrint('Salvando perfil: $profileData');

      // Salvar no banco de dados
      await profileRepository.saveProfile(profileData);

      debugPrint('Perfil salvo com sucesso!');

      _setIsSaving(false);
    } catch (e) {
      _setIsSaving(false);
      debugPrint('Erro ao salvar perfil: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    ageController.dispose();
    super.dispose();
  }
}

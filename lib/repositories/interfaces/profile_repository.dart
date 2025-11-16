import 'dart:io';

/// Interface para repositório do Profile
abstract class ProfileRepository {
  /// Busca perfil do usuário atual
  Future<Map<String, dynamic>?> getProfileData(String userId);

  /// Salva os dados do perfil do usuário
  Future<void> saveProfile(Map<String, dynamic> profileData);

  /// Faz upload da foto de perfil
  Future<String> uploadProfilePicture(File imageFile, String? oldAvatarUrl);

  /// Deleta a foto de perfil
  Future<void> deleteProfilePicture(String avatarUrl);
}

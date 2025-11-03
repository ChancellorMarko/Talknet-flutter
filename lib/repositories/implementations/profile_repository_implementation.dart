import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_talknet_app/repositories/interfaces/profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Implementação do repositório de perfil
class ProfileRepositoryImplementation implements ProfileRepository {
  /// Constructor da classe [ProfileRepositoryImplementation]
  ProfileRepositoryImplementation({required this.supabase});

  /// Instância do SupabaseClient
  final SupabaseClient supabase;

  @override
  Future<Map<String, dynamic>?> getProfileData(String userId) async {
    final response = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    return response;
  }

  /// Salva ou atualiza o perfil do usuário
  @override
  Future<void> saveProfile(Map<String, dynamic> profileData) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuário não autenticado');

    // Verificar se o perfil já existe
    final existingProfile = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (existingProfile != null) {
      // Atualizar perfil existente
      await supabase
          .from('profiles')
          .update(profileData)
          .eq('id', userId);
    } else {
      // Criar novo perfil
      await supabase.from('profiles').insert({
        'id': userId,
        ...profileData,
      });
    }
  }

  /// Faz upload de uma imagem para o storage
  @override
  Future<String> uploadProfilePicture(File image, String? oldAvatarUrl) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuário não autenticado');

    // Remover foto antiga se existir
    if (oldAvatarUrl != null && oldAvatarUrl.isNotEmpty) {
      try {
        final oldPath = oldAvatarUrl.split('/').last;
        await supabase.storage.from('avatars').remove(['$userId/$oldPath']);
      } on Exception catch (e) {
        debugPrint('Erro ao remover imagem antiga: $e');
      }
    }

    // Gerar nome único para o arquivo
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'avatar_$timestamp.jpg';
    final filePath = '$userId/$fileName';

    // Ler os bytes do arquivo
    final bytes = await image.readAsBytes();

    // Upload do arquivo
    await supabase.storage.from('avatars').uploadBinary(
      filePath,
      bytes,
      fileOptions: const FileOptions(
        upsert: true,
        contentType: 'image/jpeg',
      ),
    );

    // Obter URL pública
    final imageUrl = supabase.storage.from('avatars').getPublicUrl(filePath);

    return imageUrl;
  }

  /// Remove a imagem do storage
  @override
  Future<void> deleteProfilePicture(String avatarUrl) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuário não autenticado');

    final oldPath = avatarUrl.split('/').last;
    await supabase.storage.from('avatars').remove(['$userId/$oldPath']);
  }
}

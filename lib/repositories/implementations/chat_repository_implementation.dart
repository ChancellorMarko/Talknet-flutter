import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../interfaces/chat_repository.dart';

/// Implementação do repositório de Chat
class ChatRepositoryImplementation implements ChatRepository {
  /// Instância do cliente Supabase
  final SupabaseClient supabase;

  /// Construtor
  ChatRepositoryImplementation({required this.supabase});

  @override
  Future<String> getOrCreateConversation(
    String currentUserId,
    String otherUserId,
  ) async {
    try {
      final result = await supabase.rpc(
        'get_or_create_conversation',
        params: {
          'user_a_id': currentUserId,
          'user_b_id': otherUserId,
        },
      );
      return result as String;
    } catch (e) {
      print('Erro em getOrCreateConversation: $e');
      throw Exception('Não foi possível iniciar a conversa. Erro: $e');
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> getMessagesStream(String conversationId) {
    // Corrigido para buscar reações (das nossas tentativas anteriores)
    return supabase
        .from('messages?select=*,message_reactions(*)') 
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((listOfMaps) {
          return listOfMaps;
        });
  }

  @override
  Future<void> sendMessage(Map<String, dynamic> messageData) {
    try {
      return supabase.from('messages').insert(messageData);
    } catch (e) {
      print('Erro ao enviar mensagem: $e');
      throw Exception('Não foi possível enviar a mensagem.');
    }
  }

  @override
  Future<String> uploadMedia(File mediaFile, String conversationId) async {
    try {
      final fileExtension = mediaFile.path.split('.').last.toLowerCase();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath =
          '$conversationId/media_${timestamp}.$fileExtension';

      await supabase.storage.from('chat_media').upload(
            filePath,
            mediaFile,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      final publicUrl = supabase.storage
          .from('chat_media')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('Erro no upload de mídia: $e');
      throw Exception('Falha ao enviar o arquivo.');
    }
  }

  //
  // --- ADICIONE ESTES DOIS NOVOS MÉTODOS ---
  //

  @override
  Future<void> editMessage(String messageId, String newContent) {
    try {
      // Faz o UPDATE na tabela 'messages'
      return supabase
          .from('messages')
          .update({
            'content': newContent, 
            'is_edited': true // (Se você criou a coluna)
          })
          .eq('id', messageId); // Onde o ID da mensagem for este
    } catch (e) {
      print('Erro ao editar mensagem: $e');
      throw Exception('Não foi possível editar a mensagem.');
    }
  }

  @override
  Future<void> deleteMessage(String messageId) {
    try {
      // Faz o DELETE na tabela 'messages'
      return supabase
          .from('messages')
          .delete()
          .eq('id', messageId); // Onde o ID da mensagem for este
    } catch (e) {
      print('Erro ao apagar mensagem: $e');
      throw Exception('Não foi possível apagar a mensagem.');
    }
  }
}
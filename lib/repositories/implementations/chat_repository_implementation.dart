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
      // Vamos chamar uma função do banco de dados (RPC)
      // que faz todo o trabalho pesado no servidor.
      // Esta é a melhor prática de performance e segurança.
      final result = await supabase.rpc(
        'get_or_create_conversation',
        params: {
          'user_a_id': currentUserId,
          'user_b_id': otherUserId,
        },
      );

      // O resultado da RPC será o ID da conversa
      return result as String;
    } catch (e) {
      print('Erro em getOrCreateConversation: $e');
      throw Exception('Não foi possível iniciar a conversa. Erro: $e');
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> getMessagesStream(String conversationId) {
    // Aqui usamos a mágica do Supabase Realtime.
    // 1. .from('messages') - Escuta a tabela de mensagens
    // 2. .stream(primaryKey: ['id']) - Define a chave primária
    // 3. .eq('conversation_id', conversationId) - Filtra SÓ para esta conversa
    // 4. .order('created_at', ascending: true) - Ordena da mais antiga para a nova
    //
    // O Supabase cuida de atualizar o app automaticamente quando
    // uma nova mensagem chegar nessa conversation_id.
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((listOfMaps) {
          // O stream retorna List<Map<String, dynamic>>, que é o que queremos
          return listOfMaps;
        });
  }

  @override
  Future<void> sendMessage(Map<String, dynamic> messageData) {
    // A 'messageData' deve ser um Map pronto, contendo:
    // {
    //   'conversation_id': '...',
    //   'sender_id': '...',
    //   'content': '...' (ou null se for mídia)
    //   'media_url': '...' (ou null se for texto)
    //   'media_type': '...' (ou null se for texto)
    // }
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
      // 1. Criar um caminho único para o arquivo
      final fileExtension = mediaFile.path.split('.').last.toLowerCase();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath =
          '$conversationId/media_${timestamp}.$fileExtension';

      // 2. Fazer upload do arquivo
      await supabase.storage.from('chat_media').upload(
            filePath,
            mediaFile,
            fileOptions: FileOptions(
              cacheControl: '3600', // 1 hora de cache
              upsert: false, // Não sobrescrever se já existir
            ),
          );

      // 3. Obter a URL pública
      final publicUrl = supabase.storage
          .from('chat_media')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('Erro no upload de mídia: $e');
      throw Exception('Falha ao enviar o arquivo.');
    }
  }
}
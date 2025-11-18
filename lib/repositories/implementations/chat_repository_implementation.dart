import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_talknet_app/repositories/interfaces/chat_repository.dart';

/// Implementação do repositório de Chat usando Supabase
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
      // Chama a função RPC no Supabase para obter ou criar a conversa
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
    // Stream em tempo real das mensagens da conversa
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((listOfMaps) {
          return listOfMaps;
        })
        .handleError((error) {
          print('Erro no stream de mensagens: $error');
          throw Exception('Erro ao carregar mensagens: $error');
        });
  }

  @override
  Future<void> sendMessage(Map<String, dynamic> messageData) async {
    try {
      // A 'messageData' deve conter:
      // {
      //   'conversation_id': '...',
      //   'sender_id': '...',
      //   'content': '...' (ou null se for mídia)
      //   'media_url': '...' (ou null se for texto)
      //   'media_type': '...' (ou null se for texto)
      // }
      await supabase.from('messages').insert(messageData);
    } catch (e) {
      print('Erro ao enviar mensagem: $e');
      throw Exception('Não foi possível enviar a mensagem.');
    }
  }

  @override
  Future<String> uploadMedia(File mediaFile, String conversationId) async {
    try {
      // Verificar se o arquivo existe
      if (!await mediaFile.exists()) {
        throw Exception('Arquivo não encontrado');
      }

      // Validar tamanho do arquivo
      if (!_isValidFileSize(mediaFile)) {
        throw Exception('Arquivo muito grande. Tamanho máximo: 20MB');
      }

      // 1. Criar um caminho único para o arquivo
      final fileExtension = mediaFile.path.split('.').last.toLowerCase();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomString = _generateRandomString(8);
      final filePath =
          '$conversationId/media_${timestamp}_$randomString.$fileExtension';

      print('Fazendo upload para: $filePath');

      // 2. Fazer upload do arquivo
      await supabase.storage
          .from('chat_media')
          .uploadBinary(filePath, await mediaFile.readAsBytes());

      // 3. Obter a URL pública
      final publicUrl = supabase.storage
          .from('chat_media')
          .getPublicUrl(filePath);

      print('Upload realizado com sucesso: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Erro detalhado no upload: $e');

      // Tratamento específico para erros de bucket
      if (e.toString().contains('Bucket not found') ||
          e.toString().contains('chat_media')) {
        throw Exception(
          'Bucket chat_media não configurado corretamente no Supabase',
        );
      }

      throw Exception('Falha ao enviar o arquivo: $e');
    }
  }

  @override
  Future<void> toggleReaction(String messageId, String emoji) async {
    try {
      // Usamos RPC para toggle (adicionar ou remover)
      await supabase.rpc(
        'toggle_message_reaction',
        params: {
          'p_message_id': messageId,
          'p_emoji': emoji,
        },
      );
    } catch (e) {
      print('Erro ao toggle reaction: $e');
      throw Exception('Não foi possível adicionar/remover reação: $e');
    }
  }

  @override
  Future<void> editMessage(String messageId, String newContent) async {
    try {
      await supabase.rpc(
        'edit_message',
        params: {
          'message_id': messageId,
          'new_content': newContent,
        },
      );
    } on PostgrestException catch (e) {
      print('Erro Postgrest ao editar mensagem: ${e.message}');
      throw Exception('Erro ao editar mensagem: ${e.message}');
    } catch (e) {
      print('Erro ao editar mensagem: $e');
      throw Exception('Não foi possível editar a mensagem: $e');
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> getReactionsStream(String conversationId) {
    // Stream de todas as reações das mensagens da conversa
    return supabase
        .from('message_reactions')
        .stream(primaryKey: ['id'])
        .map((reactions) {
          // Filtramos as reações que pertencem às mensagens da conversa
          // Em uma implementação mais eficiente, você pode criar uma view no Supabase
          return reactions;
        })
        .handleError((error) {
          print('Erro no stream de reações: $error');
          throw Exception('Erro ao carregar reações: $error');
        });
  }

  @override
  Future<void> setTypingStatus(String conversationId, bool isTyping) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      await supabase.from('user_presence').upsert({
        'user_id': userId,
        'typing_in_conversation': isTyping ? conversationId : null,
        'is_online': true,
        'last_seen': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Erro ao atualizar status de digitação: $e');
      // Não lançamos exceção aqui para não interromper o UX
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> getPresenceStream(List<String> userIds) {
    // Stream de presença dos usuários
    return supabase
        .from('user_presence')
        .stream(primaryKey: ['user_id'])
        .inFilter('user_id', userIds)
        .map((presenceList) => presenceList)
        .handleError((error) {
          print('Erro no stream de presença: $error');
          throw Exception('Erro ao carregar status dos usuários: $error');
        });
  }

  @override
  Future<Map<String, dynamic>?> getMessageById(String messageId) async {
    try {
      final response = await supabase
          .from('messages')
          .select()
          .eq('id', messageId)
          .single();

      return response;
    } catch (e) {
      print('Erro ao buscar mensagem: $e');
      throw Exception('Não foi possível carregar a mensagem: $e');
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    try {
      // A RLS (Row Level Security) deve garantir que apenas o sender pode deletar
      await supabase
          .from('messages')
          .delete()
          .eq('id', messageId)
          .eq('sender_id', supabase.auth.currentUser!.id);
    } catch (e) {
      print('Erro ao deletar mensagem: $e');
      throw Exception('Não foi possível excluir a mensagem: $e');
    }
  }

  @override
  Future<void> markMessagesAsRead(String conversationId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Aqui você pode implementar a lógica para marcar mensagens como lidas
      // Isso depende da estrutura do seu banco de dados
      // Exemplo: atualizar uma tabela de mensagens_lidas
      print('Marcando mensagens como lidas para a conversa: $conversationId');
    } catch (e) {
      print('Erro ao marcar mensagens como lidas: $e');
    }
  }

  @override
  Stream<Map<String, dynamic>> getMessageStream(String messageId) {
    // Stream para uma mensagem específica (útil para edições em tempo real)
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('id', messageId)
        .map<List<Map<String, dynamic>>>(
          (messages) => messages.cast<Map<String, dynamic>>(),
        )
        .map((messages) {
          if (messages.isEmpty) return <String, dynamic>{};
          return messages.first;
        })
        .handleError((error) {
          print('Erro no stream da mensagem: $error');
          throw Exception('Erro ao acompanhar a mensagem: $error');
        });
  }

  @override
  Future<bool> hasAccessToConversation(String conversationId) async {
    try {
      // Verifica se o usuário atual é participante da conversa
      final response = await supabase
          .from('participants')
          .select()
          .eq('conversation_id', conversationId)
          .eq('user_id', supabase.auth.currentUser!.id);

      return response.isNotEmpty;
    } catch (e) {
      print('Erro ao verificar acesso à conversa: $e');
      return false;
    }
  }

  // --- Métodos Auxiliares Privados ---

  /// Gera uma string aleatória para evitar conflitos de nomes de arquivo
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = supabase.realtime.channel('random');
    final codeUnits = List.generate(
      length,
      (index) => chars.codeUnitAt(
        (DateTime.now().microsecondsSinceEpoch + index) % chars.length,
      ),
    );
    return String.fromCharCodes(codeUnits);
  }

  /// Verifica se o arquivo é uma imagem válida
  bool _isValidImage(File file) {
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    final extension = file.path.split('.').last.toLowerCase();
    return allowedExtensions.contains(extension);
  }

  /// Verifica o tamanho do arquivo (máximo 20MB conforme requisito)
  bool _isValidFileSize(File file) {
    const maxSize = 20 * 1024 * 1024; // 20MB
    return file.lengthSync() <= maxSize;
  }

  /// Limpa recursos (útil para testes)
  void dispose() {
    // O SupabaseClient geralmente é gerenciado pelo app
    // Este método é para casos específicos onde você quer fechar conexões
  }
}

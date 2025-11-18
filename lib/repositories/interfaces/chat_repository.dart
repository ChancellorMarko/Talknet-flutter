import 'dart:io';

/// Interface para o repositório de chat
abstract class ChatRepository {
  /// Busca ou cria uma conversa 1-a-1 entre dois usuários.
  /// Retorna o ID da conversa.
  Future<String> getOrCreateConversation(String currentUserId, String otherUserId);

  /// Retorna um Stream com a lista de mensagens de uma conversa específica.
  /// O Stream será atualizado em tempo real pelo Supabase.
  Stream<List<Map<String, dynamic>>> getMessagesStream(String conversationId);

  /// Envia uma nova mensagem para a base de dados.
  Future<void> sendMessage(Map<String, dynamic> messageData);

  /// Faz o upload de uma imagem ou arquivo para o Storage do Supabase.
  /// Retorna a URL pública do arquivo.
  Future<String> uploadMedia(File mediaFile, String conversationId);

  //
  // --- ADICIONE ESTAS DUAS LINHAS ---
  //
  /// Atualiza o conteúdo de uma mensagem existente.
  Future<void> editMessage(String messageId, String newContent);

  /// Apaga uma mensagem da base de dados.
  Future<void> deleteMessage(String messageId);
}
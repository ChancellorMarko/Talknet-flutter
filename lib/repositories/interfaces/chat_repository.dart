import 'dart:io';

/// Interface para o repositório de chat
abstract class ChatRepository {
  /// Busca ou cria uma conversa 1-a-1 entre dois usuários.
  /// Retorna o ID da conversa.
  Future<String> getOrCreateConversation(
    String currentUserId,
    String otherUserId,
  );

  /// Retorna um Stream com a lista de mensagens de uma conversa específica.
  /// O Stream será atualizado em tempo real pelo Supabase.
  Stream<List<Map<String, dynamic>>> getMessagesStream(String conversationId);

  /// Envia uma nova mensagem para a base de dados.
  Future<void> sendMessage(Map<String, dynamic> messageData);

  /// Faz o upload de uma imagem ou arquivo para o Storage do Supabase.
  /// Retorna a URL pública do arquivo.
  Future<String> uploadMedia(File mediaFile, String conversationId);

  /// Adiciona ou remove uma reação em uma mensagem.
  /// Se a reação já existir, ela é removida. Caso contrário, é adicionada.
  Future<void> toggleReaction(String messageId, String emoji);

  /// Edita uma mensagem existente.
  /// Apenas mensagens do próprio usuário podem ser editadas, e apenas
  /// dentro de 15 minutos após o envio.
  Future<void> editMessage(String messageId, String newContent);

  /// Obtém o stream de reações para uma conversa específica.
  /// Retorna todas as reações das mensagens da conversa em tempo real.
  Stream<List<Map<String, dynamic>>> getReactionsStream(String conversationId);

  /// Atualiza o status de digitação do usuário.
  /// [isTyping] = true indica que o usuário está digitando na conversa.
  /// [isTyping] = false indica que o usuário parou de digitar.
  Future<void> setTypingStatus(String conversationId, bool isTyping);

  /// Obtém o stream de presença dos usuários.
  /// Retorna informações de online/offline e status de digitação.
  Stream<List<Map<String, dynamic>>> getPresenceStream(List<String> userIds);

  /// Obtém informações detalhadas de uma mensagem específica.
  Future<Map<String, dynamic>?> getMessageById(String messageId);

  /// Exclui uma mensagem (apenas do próprio usuário).
  Future<void> deleteMessage(String messageId);

  /// Marca mensagens como lidas em uma conversa.
  Future<void> markMessagesAsRead(String conversationId);

  /// Obtém o stream de atualizações de uma mensagem específica.
  Stream<Map<String, dynamic>> getMessageStream(String messageId);

  /// Verifica se o usuário tem permissão para acessar a conversa.
  Future<bool> hasAccessToConversation(String conversationId);
}
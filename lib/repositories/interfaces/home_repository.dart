/// Interface para repositório do Home
abstract class HomeRepository {
  /// Busca lista de usuários (exceto o usuário atual)
  Future<List<Map<String, dynamic>>> getUsers(String currentUserId);

  /// Busca dados do usuário atual
  Future<Map<String, dynamic>?> getCurrentUserData(String userId);
}

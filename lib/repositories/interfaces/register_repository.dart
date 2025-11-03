/// Repositório de registro de usuário
abstract class RegisterRepository {
  /// Envia os dados de registro do usuário para o serviço correspondente
  Future<void> sendRegister(String fullName, String email, String password);
}

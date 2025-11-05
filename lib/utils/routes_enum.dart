/// Enumeração das rotas do aplicativo
enum RoutesEnum {
  /// Rota de login
  login('/login'),

  /// Rota de registro de novo usuário
  register('/register'),

  /// Rota principal do projeto
  home('/home'),

  /// Rota de chat
  chat('/chat'),

  /// Tela de edição de perfil
  profile('/profile'),

  /// Tela para resetar a senha do usuário
  resetPassword('/passwordReset');

  /// Constructor do Enum [RoutesEnum]
  const RoutesEnum(this.route);

  /// Caminho da rota
  final String route;
}

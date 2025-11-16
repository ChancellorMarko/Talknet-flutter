enum RoutesEnum {
  /// Rota de login
  login('/login'),

  /// Rota de registro de novo usuário
  register('/register'),

  /// Rota de recuperação de senha
  forgotPassword('/forgot-password'),

  /// Rota principal do projeto
  home('/home');

  /// Constructor do Enum [RoutesEnum]
  const RoutesEnum(this.route);

  /// Caminho da rota
  final String route;
}

import 'package:supabase_flutter/supabase_flutter.dart';

class HomeService {
  /// Verifica se há um usuário autenticado
  bool isUserAuthenticated() {
    return Supabase.instance.client.auth.currentUser != null;
  }

  /// Retorna o ID do usuário atual
  String? getCurrentUserId() {
    return Supabase.instance.client.auth.currentUser?.id;
  }

  /// Retorna o nome do usuário atual dos metadados
  String getCurrentUserName() {
    final user = Supabase.instance.client.auth.currentUser;
    return (user?.userMetadata?['full_name'] as String?) ?? 'Usuário';
  }

  /// Faz logout do usuário
  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
  }
}
import 'package:supabase_flutter/supabase_flutter.dart';

/// Serviço encarregado de realizar registro dos usuários
class RegisterService {
  Future<void> sendRegister(
    String fullName,
    String email,
    String password,
  ) async {
    final supabase = Supabase.instance.client;
    await supabase.auth.signUp(
      data: {'full_name': fullName},
      password: password,
      email: email,
    );
  }
}

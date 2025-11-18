import 'package:flutter/material.dart';
import 'package:flutter_talknet_app/ui/widgets/custom_button.dart';
import 'package:flutter_talknet_app/ui/widgets/custom_input.dart';
import 'package:flutter_talknet_app/ui/widgets/custom_text_button.dart';
import 'package:flutter_talknet_app/utils/routes_enum.dart';
import 'package:flutter_talknet_app/utils/style/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tela para inserir nova senha e confirmação de senha
class NewPasswordScreen extends StatefulWidget {
  /// Email pode ser passado opcionalmente
  final String? email;

  const NewPasswordScreen({this.email, super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleUpdatePassword() async {
    final password = passwordController.text.trim();
    final confirm = confirmController.text.trim();

    if (password.isEmpty || confirm.isEmpty) {
      _showError('Preencha ambos os campos de senha');
      return;
    }

    if (password.length < 8) {
      _showError('A senha deve ter pelo menos 8 caracteres');
      return;
    }

    if (password != confirm) {
      _showError('As senhas não coincidem');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );

      debugPrint(
        'Senha atualizada com sucesso para: ${widget.email ?? "usuário atual"}',
      );

      if (mounted) {
        _showSuccess(
          'Senha alterada com sucesso! Faça login com a nova senha.',
        );
        // Navegar para login após delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        });
      }
    } on AuthException catch (e) {
      debugPrint('Erro de autenticação ao alterar senha: ${e.message}');
      String msg;
      final low = e.message.toLowerCase();
      if (low.contains('invalid') ||
          low.contains('session') ||
          low.contains('expired')) {
        msg = 'Sessão inválida ou expirada. Refaça o fluxo de recuperação.';
      } else {
        msg = 'Erro ao alterar senha: ${e.message}';
      }
      _showError(msg);
    } catch (e) {
      debugPrint('Erro inesperado ao alterar senha: $e');
      _showError('Erro de conexão. Verifique sua internet e tente novamente.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: constraints.maxWidth > 768
                        ? 768
                        : constraints.maxWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Image(
                            image: AssetImage('assets/logos/talknet_logo.png'),
                            height: 220,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Redefinir senha',
                          style: TextStyle(fontSize: 20),
                        ),
                        const SizedBox(height: 12),
                        if (widget.email != null)
                          Text(
                            'Atualizando senha para: ${widget.email}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          )
                        else
                          const Text(
                            'Digite sua nova senha abaixo',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        const SizedBox(height: 24),
                        CustomInput(
                          hint: 'Digite a nova senha',
                          label: 'Nova Senha',
                          controller: passwordController,
                          obscureText: _obscurePassword,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        CustomInput(
                          hint: 'Confirme a nova senha',
                          label: 'Confirmar Senha',
                          controller: confirmController,
                          obscureText: _obscureConfirm,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator())
                        else
                          CustomButton(
                            buttonText: 'Atualizar Senha',
                            backgroundColor: AppColors.primaryRed,
                            buttonAction: _handleUpdatePassword,
                          ),
                        const SizedBox(height: 18),
                        CustomTextButton(
                          buttonText: 'Voltar para Login',
                          buttonAction: _isLoading
                              ? null
                              : () {
                                  Navigator.of(context).pushReplacementNamed(RoutesEnum.login.route);
                                },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

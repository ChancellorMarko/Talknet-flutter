import 'package:flutter/material.dart';
import 'package:flutter_talknet_app/ui/widgets/custom_button.dart';
import 'package:flutter_talknet_app/ui/widgets/custom_input.dart';
import 'package:flutter_talknet_app/ui/widgets/custom_text_button.dart';
import 'package:flutter_talknet_app/utils/routes_enum.dart';
import 'package:flutter_talknet_app/utils/style/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tela de login
class LoginScreen extends StatefulWidget {
  /// Construtor da classe [LoginScreen]
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

bool _hasActiveSession() {
  final supabase = Supabase.instance.client;
  final session = supabase.auth.currentSession;
  return session != null;
}

class _LoginScreenState extends State<LoginScreen> {
  /// Controlador do campo de email
  final TextEditingController emailController = TextEditingController();

  /// Controlador do campo de senha
  final TextEditingController passwordController = TextEditingController();

  /// Indica se está processando o login
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Verificar sessão ativa
    if (_hasActiveSession()) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Navigator.of(context).pushReplacementNamed(
          RoutesEnum.home.route,
        );
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// Realiza o login do usuário
  Future<void> _handleLogin() async {
    // Validação básica
    if (emailController.text.trim().isEmpty) {
      _showError('Por favor, digite seu email');
      return;
    }

    if (passwordController.text.isEmpty) {
      _showError('Por favor, digite sua senha');
      return;
    }

    // Validação de email básica
    if (!emailController.text.contains('@')) {
      _showError('Por favor, digite um email válido');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      // Verificar se o login foi bem-sucedido
      if (response.user != null) {
        debugPrint('Login bem-sucedido: ${response.user!.email}');

        if (mounted) {
          await Navigator.of(context).pushReplacementNamed(
            RoutesEnum.home.route,
          );
        }
      } else {
        _showError('Erro ao fazer login. Tente novamente.');
      }
    } on AuthException catch (e) {
      // Erros específicos do Supabase
      debugPrint('Erro de autenticação: ${e.message}');

      String errorMessage;
      switch (e.message.toLowerCase()) {
        case 'invalid login credentials':
        case 'invalid credentials':
          errorMessage = 'Email ou senha incorretos';
        case 'email not confirmed':
          errorMessage = 'Email não confirmado. Verifique sua caixa de entrada';
        default:
          errorMessage = 'Erro ao fazer login: ${e.message}';
      }

      _showError(errorMessage);
    } on Exception catch (e) {
      // Outros erros (rede, etc)
      debugPrint('Erro inesperado: $e');
      _showError('Erro de conexão. Verifique sua internet e tente novamente.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Exibe mensagem de erro
  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                      children: [
                        const Image(
                          image: AssetImage('assets/logos/talknet_logo.png'),
                          height: 280,
                        ),
                        const SizedBox(height: 18),
                        const SizedBox(
                          width: double.infinity,
                          child: Text('Login', style: TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(height: 18),
                        CustomInput(
                          hint: 'Digite seu email',
                          label: 'Email',
                          controller: emailController,
                        ),
                        const SizedBox(height: 18),
                        CustomInput(
                          showPasswordToggle: true,
                          obscureText: true,
                          hint: 'Digite sua senha',
                          label: 'Senha',
                          controller: passwordController,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: CustomTextButton(
                            buttonText: 'Esqueci minha senha',
                            buttonAction: _isLoading ? null : () async {
                              await Navigator.pushNamed(
                                context,
                                RoutesEnum.resetPassword.route,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (_isLoading)
                          const CircularProgressIndicator()
                        else
                          CustomButton(
                            buttonText: 'Entrar',
                            backgroundColor: AppColors.primaryBlue,
                            buttonAction: _handleLogin,
                          ),
                        const SizedBox(height: 18),
                        CustomTextButton(
                          buttonText: 'Não tem uma conta? Cadastre-se',
                          buttonAction: _isLoading
                              ? null
                              : () async {
                                  await Navigator.pushNamed(
                                    context,
                                    RoutesEnum.register.route,
                                  );
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

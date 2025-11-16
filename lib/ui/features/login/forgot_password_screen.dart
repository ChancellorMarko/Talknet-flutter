import 'package:flutter/material.dart';
import 'package:flutter_talknet_app/ui/widgets/custom_button.dart';
import 'package:flutter_talknet_app/ui/widgets/custom_input.dart';
import 'package:flutter_talknet_app/ui/widgets/custom_text_button.dart';
import 'package:flutter_talknet_app/utils/style/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tela de recuperação de senha
class ForgotPasswordScreen extends StatefulWidget {
  /// Construtor da classe [ForgotPasswordScreen]
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  /// Controlador do campo de email
  final TextEditingController emailController = TextEditingController();

  /// Controlador do campo de código
  final TextEditingController codeController = TextEditingController();

  /// Indica se está processando a requisição
  bool _isLoading = false;

  /// Indica se o código foi enviado com sucesso
  bool _codeSent = false;

  @override
  void dispose() {
    emailController.dispose();
    codeController.dispose();
    super.dispose();
  }

  /// Realiza o envio do código de recuperação de senha
  Future<void> _handleSendCode() async {
    // Validação básica
    if (emailController.text.trim().isEmpty) {
      _showError('Por favor, digite seu email');
      return;
    }

    // Validação de email básica
    if (!emailController.text.contains('@')) {
      _showError('Por favor, digite um email válido');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        emailController.text.trim(),
      );

      debugPrint('Código de recuperação enviado para: ${emailController.text.trim()}');

      if (mounted) {
        setState(() => _codeSent = true);
        _showSuccess('Código de recuperação enviado para seu email!');
      }
    } on AuthException catch (e) {
      // Erros específicos do Supabase
      debugPrint('Erro de autenticação: ${e.message}');

      String errorMessage;
      switch (e.message.toLowerCase()) {
        case 'user not found':
          errorMessage = 'Email não encontrado em nossa base de dados';
          break;
        case 'email not confirmed':
          errorMessage = 'Por favor, confirme seu email primeiro';
          break;
        case 'over email send rate limit':
          errorMessage = 'Muitas solicitações. Tente novamente em alguns minutos';
          break;
        default:
          errorMessage = 'Erro ao processar recuperação: ${e.message}';
      }

      _showError(errorMessage);
    } catch (e) {
      // Outros erros (rede, etc)
      debugPrint('Erro inesperado: $e');
      _showError('Erro de conexão. Verifique sua internet e tente novamente.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Realiza a verificação do código
  Future<void> _handleVerifyCode() async {
    // Validação básica
    if (codeController.text.trim().isEmpty) {
      _showError('Por favor, digite o código');
      return;
    }

    if (codeController.text.trim().length < 6) {
      _showError('O código deve ter pelo menos 6 caracteres');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Verificar o código com Supabase
      await Supabase.instance.client.auth.verifyOTP(
        email: emailController.text.trim(),
        token: codeController.text.trim(),
        type: OtpType.recovery,
      );

      debugPrint('Código verificado com sucesso');

      if (mounted) {
        _showSuccess('Código verificado! Agora você pode redefinir sua senha.');
        // Aqui você pode navegar para tela de redefinição de senha
        // Por enquanto, vamos voltar ao login
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } on AuthException catch (e) {
      debugPrint('Erro de autenticação: ${e.message}');
      _showError('Código inválido. Tente novamente.');
    } catch (e) {
      debugPrint('Erro inesperado: $e');
      _showError('Erro ao verificar código. Tente novamente.');
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
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Exibe mensagem de sucesso
  void _showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
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
                          child: Text(
                            'Recuperar Senha',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (!_codeSent)
                          const SizedBox(
                            width: double.infinity,
                            child: Text(
                              'Digite seu email para receber um código de recuperação de senha',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        else
                          const SizedBox(
                            width: double.infinity,
                            child: Text(
                              'Um código de recuperação foi enviado para seu email. Digite-o abaixo para redefinir sua senha.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        if (!_codeSent) ...[
                          CustomInput(
                            hint: 'Digite seu email',
                            label: 'Email',
                            controller: emailController,
                          ),
                          const SizedBox(height: 24),
                          _isLoading
                              ? const CircularProgressIndicator()
                              : CustomButton(
                                  buttonText: 'Enviar Código',
                                  backgroundColor: AppColors.primaryBlue,
                                  buttonAction: _handleSendCode,
                                ),
                        ] else ...[
                          CustomInput(
                            hint: 'Digite o código recebido',
                            label: 'Código de Recuperação',
                            controller: codeController,
                          ),
                          const SizedBox(height: 24),
                          _isLoading
                              ? const CircularProgressIndicator()
                              : CustomButton(
                                  buttonText: 'Verificar Código',
                                  backgroundColor: AppColors.primaryBlue,
                                  buttonAction: _handleVerifyCode,
                                ),
                        ],
                        const SizedBox(height: 18),
                        CustomTextButton(
                          buttonText: 'Voltar para Login',
                          buttonAction: _isLoading
                              ? null
                              : () {
                                  Navigator.pop(context);
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

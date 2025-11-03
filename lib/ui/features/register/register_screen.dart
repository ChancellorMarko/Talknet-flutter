import 'package:flutter/material.dart';
import 'package:flutter_talknet_app/ui/features/register/register_view_model.dart';
import 'package:flutter_talknet_app/ui/features/validators/email_validator.dart';
import 'package:flutter_talknet_app/ui/features/validators/full_name_validator.dart';
import 'package:flutter_talknet_app/ui/features/validators/password_validator.dart';
import 'package:flutter_talknet_app/ui/widgets/custom_button.dart';
import 'package:flutter_talknet_app/ui/widgets/custom_input.dart';
import 'package:flutter_talknet_app/ui/widgets/custom_text_button.dart';
import 'package:flutter_talknet_app/utils/style/colors.dart';

/// Tela de registro de novos usuários
class RegisterScreen extends StatefulWidget {
  /// Construtor da classe [RegisterScreen]
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final RegisterViewModel viewModel = RegisterViewModel();

  @override
  void initState() {
    viewModel.initToast(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: constraints.maxWidth > 768
                        ? 768
                        : constraints.maxWidth,
                    child: FormWidget(viewModel: viewModel),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Widget do formulário de registro
class FormWidget extends StatefulWidget {
  /// Construtor da classe [FormWidget]
  const FormWidget({required this.viewModel, super.key});

  /// ViewModel associado ao formulário
  final RegisterViewModel viewModel;

  @override
  State<FormWidget> createState() => _FormWidgetState();
}

class _FormWidgetState extends State<FormWidget> {
  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.viewModel.formKey,
      child: Column(
        spacing: 8,
        children: [
          const Image(
            image: AssetImage('assets/logos/talknet_logo.png'),
            height: 280,
          ),
          const SizedBox(
            width: double.infinity,
            child: Text('Registro', style: TextStyle(fontSize: 20)),
          ),
          CustomInput(
            hint: 'Digite seu email',
            label: 'Email',
            controller: widget.viewModel.emailController,
            validator: emailValidator,
          ),
          CustomInput(
            hint: 'Digite seu nome completo',
            label: 'Nome',
            controller: widget.viewModel.fullNameController,
            validator: fullNameValidator,
          ),
          CustomInput(
            showPasswordToggle: true,
            hint: 'Digite sua senha',
            label: 'Senha',
            controller: widget.viewModel.passwordController,
            validator: passwordValidator,
          ),
          CustomInput(
            showPasswordToggle: true,
            hint: 'Confirme sua senha',
            label: 'Confirmação da senha',
            controller: widget.viewModel.passwordConfirmationController,
            validator: (value) =>
                widget.viewModel.passwordConfirmationValidator(value),
          ),
          CustomButton(
            icon: widget.viewModel.isLoading ? Icons.hourglass_empty : null,
            buttonText: 'Registrar',
            backgroundColor: AppColors.primaryBlue,
            buttonAction: () async =>
                widget.viewModel.registerButtonAction(context),
          ),
          CustomTextButton(
            icon: Icons.login,
            buttonText: 'Já tem uma conta? Faça login',
            buttonAction: () => widget.viewModel.navigateToLogin(
              Navigator.of(context),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Campo de entrada customizado reutilizável
class CustomInput extends StatelessWidget {
  /// Construtor da classe [CustomInput]
  const CustomInput({
    required this.label,
    required this.hint,
    required this.controller,
    super.key,
    this.validator,
    this.obscureText = false,
    this.showPasswordToggle = false,
  });

  /// Rótulo do campo
  final String label;

  /// Texto de dica exibido no campo
  final String hint;

  /// Controlador do campo de entrada
  final TextEditingController controller;

  /// Função de validação do campo
  final String? Function(String?)? validator;

  /// Indica se o texto deve ser ocultado (para senhas)
  final bool obscureText;

  /// Controla se o botão de mostrar/esconder senha deve ser exibido
  final bool showPasswordToggle;

  @override
  Widget build(BuildContext context) {
    // Notificação que mostra se o texto deve ser obscurecido ou não
    final obscureNotifier = ValueNotifier<bool>(obscureText);

    return ValueListenableBuilder<bool>(
      valueListenable: obscureNotifier,
      builder: (context, isObscure, child) {
        return ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, child) {
            return SizedBox(
              height: 68,
              child: TextFormField(
                obscureText: isObscure,
                validator: validator,
                controller: controller,
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: value.text.isEmpty ? Colors.grey : Colors.redAccent,
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Colors.redAccent,
                      width: 2.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.purpleAccent, width: 2.5),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.purpleAccent, width: 2.5),
                  ),
                  labelText: label,
                  hintText: hint,
                  fillColor: Colors.white,
                  filled: true,
                  suffixIcon: showPasswordToggle
                      ? IconButton(
                          onPressed: () {
                            obscureNotifier.value = !isObscure;
                          },
                          icon: Icon(
                            isObscure ? Icons.visibility : Icons.visibility_off,
                          ),
                        )
                      : null,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

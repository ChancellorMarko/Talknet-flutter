import 'package:flutter/material.dart';
import 'package:flutter_talknet_app/utils/style/colors.dart';

/// Botão customizado reutilizável
class CustomButton extends StatelessWidget {
  /// Construtor da classe [CustomButton]
  const CustomButton({
    required this.backgroundColor,
    required this.buttonText,
    required this.buttonAction,
    super.key,
    this.icon,
  });

  /// Cor de fundo do botão
  final Color backgroundColor;

  /// Texto exibido no botão
  final String buttonText;

  /// Ação executada ao pressionar o botão
  final VoidCallback buttonAction;

  /// Ícone exibido no botão
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: AppColors.backgroundLight),
        label: Text(
          buttonText,
          style: const TextStyle(
            color: AppColors.textWhite,
            fontSize: 20,
          ),
        ),
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(backgroundColor),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        onPressed: buttonAction,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_talknet_app/utils/style/colors.dart';

/// Toast customizado reutilizável
class CustomToast extends StatelessWidget {
  /// Construtor da classe [CustomToast]
  const CustomToast({
    required this.errorText,
    required this.backgroundColor,
    required this.icon,
    super.key,
  });

  /// Texto de erro exibido no toast
  final String errorText;

  /// Cor de fundo do toast
  final Color backgroundColor;

  /// Ícone exibido no toast
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: backgroundColor,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textWhite),
          const SizedBox(width: 12),
          Text(errorText, style: const TextStyle(color: AppColors.textWhite)),
        ],
      ),
    );
  }
}

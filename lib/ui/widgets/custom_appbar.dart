import 'package:flutter/material.dart';
import 'package:flutter_talknet_app/utils/routes_enum.dart';
import 'package:flutter_talknet_app/utils/style/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({
    required this.title,
    this.height = kToolbarHeight,
    super.key,
  });

  final String title;
  final double height;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  _CustomAppBarState createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  bool _isLoggingOut = false;

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await Supabase.instance.client.auth.signOut();

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          RoutesEnum.login.route,
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Erro ao fazer logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erro ao fazer logout'),
            action: SnackBarAction(
              label: 'Tentar novamente',
              onPressed: _handleLogout,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(widget.title),
      backgroundColor: AppColors.primaryBlue,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.person),
          tooltip: 'Meu Perfil',
          onPressed: () async {
            await Navigator.pushNamed(
              context,
              RoutesEnum.profile.route,
            );
          },
        ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: _handleLogout,
          ),
      ],
    );
  }
}

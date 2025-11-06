import 'package:flutter/material.dart';
import 'package:flutter_talknet_app/repositories/implementations/home_repository_implementation.dart';
import 'package:flutter_talknet_app/ui/features/home/home_view_model.dart';
import 'package:flutter_talknet_app/ui/widgets/custom_appbar.dart';
import 'package:flutter_talknet_app/utils/routes_enum.dart';
import 'package:flutter_talknet_app/utils/style/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tela inicial com lista de usuários
class HomeScreen extends StatefulWidget {
  /// Construtor da classe [HomeScreen]
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();

    // Inicializar o ViewModel com o repository
    final repository = HomeRepositoryImplementation(
      supabase: Supabase.instance.client,
    );
    _viewModel = HomeViewModel(repository);

    // Adicionar listener para atualizar a UI
    _viewModel.addListener(_onViewModelChanged);

    // Verificar sessão e carregar dados
    _initializeScreen();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initializeScreen() async {
    // Verificar autenticação
    if (!_viewModel.checkAuthentication()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(RoutesEnum.login.route);
        }
      });
      return;
    }

    // Carregar dados
    try {
      await _viewModel.loadInitialData();
    } catch (e) {
      if (mounted) {
        _showError('Erro ao carregar dados: ${e}');
      }
    }
  }

  Future<void> _handleRefresh() async {
    try {
      await _viewModel.reloadUsers();
    } catch (e) {
      if (mounted) {
        _showError('Erro ao atualizar: ${e}');
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Home'),
      body: Column(
        children: [
          // Header com informações do usuário logado
          _buildHeader(),

          // Lista de usuários
          Expanded(
            child: _buildUsersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bem-vindo(a),',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _viewModel.currentUserName,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Conecte-se com pessoas',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    if (_viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_viewModel.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              _viewModel.error!,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _handleRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_viewModel.users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhum usuário encontrado',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _handleRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Atualizar'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _viewModel.users.length,
        itemBuilder: (context, index) {
          final user = _viewModel.users[index];
          return UserCard(
            user: user,
            onTap: () => _navigateToChat(user),
          );
        },
      ),
    );
  }

  void _navigateToChat(Map<String, dynamic> user) {
    Navigator.pushNamed(
      context,
      RoutesEnum.chat.route,
      arguments: {
        'userId': user['id'],
        'userName': user['full_name'],
        'userAvatar': user['avatar_url'],
      },
    );
  }
}

/// Card de usuário
class UserCard extends StatelessWidget {
  /// Construtor da classe [UserCard]
  const UserCard({
    required this.user,
    required this.onTap,
    super.key,
  });

  /// Dados do usuário
  final Map<String, dynamic> user;

  /// Ação ao clicar no card
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = user['full_name'] ?? 'Usuário';
    final bio = user['bio'] ?? 'Sem descrição';
    final age = user['age'];
    final avatarUrl = user['avatar_url'];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primaryBlue,
                backgroundImage: avatarUrl != null && (avatarUrl.isNotEmpty as bool)
                    ? NetworkImage(avatarUrl as String)
                    : null,
                child: avatarUrl == null || (avatarUrl as String).isEmpty
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textWhite,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),

              // Informações do usuário
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (age != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$age anos',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bio,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Ícone de navegação
              const Icon(
                Icons.chevron_right,
                color: AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

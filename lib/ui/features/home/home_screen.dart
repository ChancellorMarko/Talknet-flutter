import 'package:flutter/material.dart';
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
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  void _checkSession() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(RoutesEnum.login.route);
      });
    }
  }

  Future<void> _handleLogout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        await Navigator.of(context).pushReplacementNamed(
          RoutesEnum.login.route,
        );
      }
    } catch (e) {
      debugPrint('Erro ao fazer logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao fazer logout')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TalkNet'),
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Meu Perfil',
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context,
                RoutesEnum.profile.route,
              );
              // Se o perfil foi atualizado, recarregar a lista
              if (result == true && mounted) {
                // Você pode adicionar lógica para recarregar a lista aqui
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header com informações do usuário logado
          Container(
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
                  currentUser?.userMetadata?['full_name'] ?? 'Usuário',
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
          ),

          // Lista de usuários
          const Expanded(
            child: UsersListComponent(),
          ),
        ],
      ),
    );
  }
}

/// Componente que exibe a lista de usuários
class UsersListComponent extends StatefulWidget {
  /// Construtor da classe [UsersListComponent]
  const UsersListComponent({super.key});

  @override
  State<UsersListComponent> createState() => _UsersListComponentState();
}

class _UsersListComponentState extends State<UsersListComponent> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final currentUserId = Supabase.instance.client.auth.currentUser?.id;

      if (currentUserId == null) {
        setState(() {
          _error = 'Usuário não autenticado';
          _isLoading = false;
        });
        return;
      }

      // Buscar usuários (exceto o usuário atual)
      // Assumindo que você tem uma tabela 'profiles' no Supabase
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id, full_name, bio, age, avatar_url')
          .neq('id', currentUserId)
          .order('full_name');

      setState(() {
        _users = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar usuários: $e');
      setState(() {
        _error = 'Erro ao carregar usuários';
        _isLoading = false;
      });
    }
  }

  void _navigateToChat(Map<String, dynamic> user) {
    // Navegar para a tela de chat passando os dados do usuário
    Navigator.pushNamed(
      context,
      RoutesEnum.chat.route, // Você precisará adicionar esta rota
      arguments: {
        'userId': user['id'],
        'userName': user['full_name'],
        'userAvatar': user['avatar_url'],
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
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
              _error!,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
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
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('Atualizar'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return UserCard(
            user: user,
            onTap: () => _navigateToChat(user),
          );
        },
      ),
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
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
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

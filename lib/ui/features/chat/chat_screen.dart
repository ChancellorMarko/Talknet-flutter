import 'package:flutter/material.dart';
import 'package:flutter_talknet_app/ui/widgets/custom_input.dart';
import 'package:flutter_talknet_app/utils/routes_enum.dart';
import 'package:flutter_talknet_app/utils/style/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tela inicial após o login bem-sucedido
class HomeScreen extends StatefulWidget {
  /// Construtor da classe [HomeScreen]
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Verificar sessão ao iniciar
    _checkSession();
  }

  void _checkSession() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Navigator.of(
          context,
        ).pushReplacementNamed(RoutesEnum.login.route);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'),
        backgroundColor: AppColors.backgroundLight,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await Supabase.instance.client.auth.signOut();
                if (mounted) {
                  await Navigator.of(context).pushReplacementNamed(
                    RoutesEnum.login.route,
                  );
                }
              } on Exception catch (e) {
                debugPrint('Erro ao fazer logout: $e');
              }
            },
          ),
        ],
      ),
      body: ColoredBox(
        color: const Color.fromARGB(255, 187, 221, 237),
        child: Column(
          children: [
            const ChatComponent(),
            InputComponent(controller: _textController),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

/// Componente de chat
class ChatComponent extends StatefulWidget {
  /// Construtor da classe [ChatComponent]
  const ChatComponent({super.key});

  @override
  State<ChatComponent> createState() => _ChatComponentState();
}

class _ChatComponentState extends State<ChatComponent> {
  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;

    // Proteção contra sessão expirada
    if (currentUser == null) {
      return const Expanded(
        child: Center(child: Text('Sessão expirada')),
      );
    }

    return StreamBuilder(
      stream: Supabase.instance.client
          .from('chatRoom')
          .stream(primaryKey: ['id']),
      builder: (context, asyncSnapshot) {
        if (asyncSnapshot.connectionState == ConnectionState.waiting) {
          return const Expanded(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (asyncSnapshot.hasError) {
          return Expanded(
            child: Center(child: Text('Erro: ${asyncSnapshot.error}')),
          );
        }

        if (!asyncSnapshot.hasData || asyncSnapshot.data!.isEmpty) {
          return const Expanded(
            child: Center(child: Text('Nenhuma mensagem disponível')),
          );
        }

        final messages = asyncSnapshot.data!;

        return Expanded(
          child: ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(8),
                child: Align(
                  alignment: messages[index]['from_id'] == currentUser.id
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Text(messages[index]['content'] as String),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Componente de entrada
class InputComponent extends StatefulWidget {
  /// Construtor da classe [InputComponent]
  const InputComponent({required this.controller, super.key});

  /// Controlador de texto
  final TextEditingController controller;

  @override
  State<InputComponent> createState() => _InputComponentState();
}

class _InputComponentState extends State<InputComponent> {
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          Expanded(
            child: CustomInput(
              label: '',
              hint: 'Digite sua mensagem',
              controller: widget.controller,
            ),
          ),
          IconButton(
            icon: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            onPressed: _isSending
                ? null
                : () async {
                    final content = widget.controller.text;
                    final currentUser =
                        Supabase.instance.client.auth.currentUser;

                    if (currentUser == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sessão expirada')),
                      );
                      return;
                    }

                    if (content.isEmpty) return;

                    setState(() => _isSending = true);

                    try {
                      await Supabase.instance.client.from('chatRoom').insert({
                        'content': content,
                        'from_id': currentUser.id,
                        'from_name': currentUser.userMetadata?['full_name'],
                      });
                      widget.controller.clear();
                    } on Exception catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro ao enviar: $e')),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() => _isSending = false);
                      }
                    }
                  },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_talknet_app/repositories/implementations/chat_repository_implementation.dart';
import 'package:flutter_talknet_app/ui/features/chat/chat_view_model.dart';
import 'package:flutter_talknet_app/utils/style/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatViewModel _viewModel;
  late final Map<String, dynamic> _routeArgs;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 1. Pegar os argumentos passados da HomeScreen
      _routeArgs =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

      final otherUserId = _routeArgs['userId'] as String;
      final currentUserId = Supabase.instance.client.auth.currentUser!.id;

      // 2. Inicializar o ViewModel
      _viewModel = ChatViewModel(
        chatRepository: ChatRepositoryImplementation(
          supabase: Supabase.instance.client,
        ),
        currentUserId: currentUserId,
        otherUserId: otherUserId,
      );

      // 3. Adicionar o listener para redesenhar a tela
      _viewModel.addListener(_onViewModelUpdate);

      // 4. Carregar a conversa
      _viewModel.loadConversation();
    });
  }

  void _onViewModelUpdate() {
    if (mounted) {
      setState(() {
        _scrollToBottom();
      });
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelUpdate);
    _viewModel.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted || !ModalRoute.of(context)!.isCurrent) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_routeArgs['userName'] as String? ?? 'Chat'),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessagesList(),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  // Constrói a lista de mensagens
  Widget _buildMessagesList() {
    if (_viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.error != null) {
      return Center(
        child: Text('Erro: ${_viewModel.error}'),
      );
    }

    if (_viewModel.messages.isEmpty) {
      return const Center(
        child: Text('Nenhuma mensagem ainda. Diga olá!'),
      );
    }

    // Lista de mensagens
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8.0),
      itemCount: _viewModel.messages.length,
      itemBuilder: (context, index) {
        final message = _viewModel.messages[index];
        final isMe = message['sender_id'] == _viewModel.currentUserId;

        //
        // --- MUDANÇA AQUI: PASSANDO O VIEWMODEL ---
        //
        return _MessageBubble(
          message: message,
          isMe: isMe,
          viewModel: _viewModel, // Passa o viewModel
        );
      },
    );
  }

  // Constrói a área de input de texto e botões
  Widget _buildInputArea() {
    // ... (seu código existente, sem mudança)
    return Container(
      padding: const EdgeInsets.all(8.0),
      // ... (resto do seu _buildInputArea)
    );
  }
}

//
// --- WIDGET _MessageBubble COMPLETAMENTE ATUALIZADO ---
//

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final ChatViewModel viewModel; // <-- Recebe o ViewModel

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.viewModel,
  });

  // Método para mostrar o menu de Apagar/Editar
  void _showMessageMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: AppColors.primaryBlue),
                title: const Text('Editar Mensagem'),
                onTap: () {
                  Navigator.pop(ctx); // Fecha o menu
                  _showEditDialog(context); // Abre o dialog de edição
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text('Apagar Mensagem'),
                onTap: () {
                  final messageId = message['id'] as String;
                  viewModel.deleteMessage(messageId);
                  Navigator.pop(ctx); // Fecha o menu
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Método para mostrar o Dialog de Edição
  void _showEditDialog(BuildContext context) {
    // Controlador SÓ para este dialog
    final textController =
        TextEditingController(text: message['content'] as String? ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Editar Mensagem'),
          content: TextField(
            controller: textController,
            autofocus: true,
            maxLines: null, // Permite quebra de linha
            decoration: const InputDecoration(
              hintText: 'Digite sua mensagem...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx); // Cancela
              },
              child: const Text('CANCELAR'),
            ),
            TextButton(
              onPressed: () {
                // Salva a edição
                final messageId = message['id'] as String;
                final newContent = textController.text;
                viewModel.editMessage(messageId, newContent);
                Navigator.pop(ctx); // Fecha o dialog
              },
              child: const Text('SALVAR'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaUrl = message['media_url'] as String?;
    final content = message['content'] as String?;
    final mediaType = message['media_type'] as String?;
    final isEdited = message['is_edited'] as bool? ?? false; // (Se você criou a coluna)

    // Envolvemos o balão com o GestureDetector
    return GestureDetector(
      onLongPress: () {
        // Só mostra o menu se a mensagem for MINHA
        if (isMe) {
          _showMessageMenu(context);
        }
      },
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe ? AppColors.primaryBlue : Colors.grey[300],
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft:
                  isMe ? const Radius.circular(16) : const Radius.circular(0),
              bottomRight:
                  isMe ? const Radius.circular(0) : const Radius.circular(16),
            ),
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Conteúdo (Texto ou Imagem)
              if (mediaType == 'image' && mediaUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    mediaUrl,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.error, color: Colors.red);
                    },
                  ),
                )
              else if (content != null)
                Text(
                  content,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                  ),
                )
              else
                const Text(
                  '[Mensagem indisponível]',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              
              // Se a mensagem foi editada, mostre um indicador
              if (isEdited)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    '(editado)',
                    style: TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: isMe ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
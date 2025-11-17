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

  // Scroll controller para a lista de mensagens
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // O initState roda ANTES do build, mas DEPOIS que os argumentos da rota estão disponíveis.
    // Usamos o addPostFrameCallback para garantir que o context está pronto.
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

  // Método chamado sempre que o viewModel.notifyListeners() é ativado
  void _onViewModelUpdate() {
    if (mounted) {
      setState(() {
        // Rola para o fim da lista quando novas mensagens chegam
        _scrollToBottom();
      });
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelUpdate);
    _viewModel.dispose(); // Essencial para cancelar o stream
    _scrollController.dispose();
    super.dispose();
  }

  // Rola para o final da lista de mensagens
  void _scrollToBottom() {
    // Usamos um timer curto para garantir que o ListView foi construído
    // ANTES de tentarmos rolar.
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
    // Enquanto o viewModel não foi inicializado (primeiro frame)
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
          // 1. Lista de Mensagens
          Expanded(
            child: _buildMessagesList(),
          ),
          // 2. Área de Input
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

        return _MessageBubble(
          message: message,
          isMe: isMe,
        );
      },
    );
  }

  // Constrói a área de input de texto e botões
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3), // Sombra no topo
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Botão de Câmera
            IconButton(
              icon: const Icon(Icons.camera_alt, color: AppColors.primaryBlue),
              onPressed: _viewModel.takeAndSendPhoto,
            ),
            // Botão de Galeria
            IconButton(
              icon: const Icon(Icons.photo, color: AppColors.primaryBlue),
              onPressed: _viewModel.pickAndSendImage,
            ),
            // Campo de Texto
            Expanded(
              child: TextField(
                controller: _viewModel.textController,
                decoration: InputDecoration(
                  hintText: 'Digite sua mensagem...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onSubmitted: (_) => _viewModel.sendMessage(),
              ),
            ),
            // Botão de Enviar
            IconButton(
              icon: const Icon(Icons.send, color: AppColors.primaryBlue),
              onPressed: _viewModel.sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

// --- Widget separado para a Bolha de Mensagem ---
// (Isso ajuda a organizar o código)

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;

  const _MessageBubble({
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final mediaUrl = message['media_url'] as String?;
    final content = message['content'] as String?;
    final mediaType = message['media_type'] as String?;

    return Align(
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
            // Conteúdo da Mensagem (Texto ou Imagem)
            if (mediaType == 'image' && mediaUrl != null)
              // É uma imagem
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
              // É um texto
              Text(
                content,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                ),
              )
            else
              // Tipo desconhecido ou falha
              const Text(
                '[Mensagem indisponível]',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),

            // TODO: Adicionar a data/hora da mensagem
            // (Você pode adicionar um 'Text' pequeno aqui com o 'created_at')
          ],
        ),
      ),
    );
  }
}
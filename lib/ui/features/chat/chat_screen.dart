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
  ChatViewModel? _viewModel;
  Map<String, dynamic>? _routeArgs;
  bool _isInitialized = false;
  String? _errorMessage;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Não inicializamos aqui, vamos usar didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Só inicializa uma vez
    if (!_isInitialized && _errorMessage == null) {
      _initializeChat();
    }
  }

  Future<void> _initializeChat() async {
    try {
      // 1. Pegar os argumentos - AGORA no didChangeDependencies
      final args = ModalRoute.of(context)!.settings.arguments;

      if (args == null || args is! Map<String, dynamic>) {
        throw Exception('Argumentos da rota inválidos ou não fornecidos');
      }

      _routeArgs = args;

      final otherUserId = _routeArgs!['userId']?.toString();
      final currentUser = Supabase.instance.client.auth.currentUser;

      if (otherUserId == null) {
        throw Exception('ID do usuário não fornecido');
      }

      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      final currentUserId = currentUser.id;

      print('Inicializando chat: $currentUserId -> $otherUserId');

      // 2. Inicializar o ViewModel
      _viewModel = ChatViewModel(
        chatRepository: ChatRepositoryImplementation(
          supabase: Supabase.instance.client,
        ),
        currentUserId: currentUserId,
        otherUserId: otherUserId,
      );

      // 3. Adicionar listener
      _viewModel!.addListener(_onViewModelUpdate);

      // 4. Carregar a conversa
      await _viewModel!.loadConversation().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout ao carregar conversa');
        },
      );

      // 5. Marcar como inicializado
      _isInitialized = true;

      if (mounted) {
        setState(() {});
      }

      print('Chat inicializado com sucesso');
    } catch (e) {
      print('Erro ao inicializar chat: $e');
      _errorMessage = 'Erro ao carregar conversa: $e';

      if (mounted) {
        setState(() {});
      }
    }
  }

  void _onViewModelUpdate() {
    if (mounted && _isInitialized) {
      setState(() {
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients && mounted) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _retryInitialization() {
    _errorMessage = null;
    _isInitialized = false;
    setState(() {});
    _initializeChat();
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_onViewModelUpdate);
    _viewModel?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Se houve erro na inicialização
    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _retryInitialization,
                child: const Text('Tentar Novamente'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
      );
    }

    // Enquanto não foi inicializado, mostra loading
    if (!_isInitialized || _viewModel == null || _routeArgs == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Carregando...'),
          backgroundColor: AppColors.primaryBlue,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Iniciando conversa...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_routeArgs!['userName']?.toString() ?? 'Chat'),
            _buildStatusIndicator(),
          ],
        ),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: Column(
        children: [
          if (_viewModel!.isOtherUserTyping) _buildTypingIndicator(),
          Expanded(child: _buildMessagesList()),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    final isOnline = _viewModel!.otherUserPresence['is_online'] == true;
    final lastSeen = _viewModel!.otherUserPresence['last_seen'];

    return Text(
      isOnline ? 'Online' : _formatLastSeen(lastSeen),
      style: const TextStyle(
        fontSize: 12,
        color: Colors.white70,
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final userName = _routeArgs!['userName']?.toString() ?? 'Usuário';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Row(
        children: [
          Text(
            '$userName está digitando...',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(width: 8),
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
    );
  }

  String _formatLastSeen(dynamic lastSeen) {
    if (lastSeen == null) return 'Offline';

    try {
      final dateTime = DateTime.parse(lastSeen.toString());
      final difference = DateTime.now().difference(dateTime);

      if (difference.inMinutes < 1) return 'Visto agora há pouco';
      if (difference.inMinutes < 60)
        return 'Visto há ${difference.inMinutes} min';
      if (difference.inHours < 24) return 'Visto há ${difference.inHours} h';
      return 'Visto há ${difference.inDays} dias';
    } catch (e) {
      return 'Offline';
    }
  }

  Widget _buildMessagesList() {
    if (_viewModel!.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando mensagens...'),
          ],
        ),
      );
    }

    if (_viewModel!.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Erro: ${_viewModel!.error}',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _viewModel!.loadConversation(),
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_viewModel!.messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhuma mensagem ainda.\nDiga olá!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8.0),
      itemCount: _viewModel!.messages.length,
      itemBuilder: (context, index) {
        final message = _viewModel!.messages[index];
        final messageId = message['id']?.toString() ?? '';
        final senderId = message['sender_id']?.toString() ?? '';
        final content = message['content']?.toString() ?? '';
        final isMe = senderId == _viewModel!.currentUserId;

        if (messageId.isEmpty) return const SizedBox();

        return _MessageBubble(
          message: message,
          isMe: isMe,
          reactions: _viewModel!.messageReactions[messageId] ?? [],
          onReaction: (emoji) => _viewModel!.toggleReaction(messageId, emoji),
          onEdit: isMe
              ? () {
                  _viewModel!.startEditingMessage(messageId, content);
                }
              : null,
        );
      },
    );
  }

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
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (_viewModel!.editingMessageId != null) _buildEditingIndicator(),
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.camera_alt,
                    color: AppColors.primaryBlue,
                  ),
                  onPressed: _viewModel!.takeAndSendPhoto,
                ),
                IconButton(
                  icon: const Icon(Icons.photo, color: AppColors.primaryBlue),
                  onPressed: _viewModel!.pickAndSendImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _viewModel!.textController,
                    decoration: InputDecoration(
                      hintText: _viewModel!.editingMessageId != null
                          ? 'Editando mensagem...'
                          : 'Digite sua mensagem...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                    onChanged: (text) {
                      _viewModel!.updateTypingStatus(text.isNotEmpty);
                    },
                    onSubmitted: (_) => _viewModel!.sendMessage(),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _viewModel!.editingMessageId != null
                        ? Icons.check
                        : Icons.send,
                    color: AppColors.primaryBlue,
                  ),
                  onPressed: _viewModel!.sendMessage,
                ),
                if (_viewModel!.editingMessageId != null)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: _viewModel!.cancelEditing,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit, size: 16, color: AppColors.primaryBlue),
          const SizedBox(width: 8),
          const Text(
            'Editando mensagem',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _viewModel!.cancelEditing,
            child: const Text(
              'Cancelar',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Widget separado para a Bolha de Mensagem ---
class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final List<Map<String, dynamic>> reactions;
  final Function(String) onReaction;
  final VoidCallback? onEdit;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.reactions,
    required this.onReaction,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final mediaUrl = message['media_url'] as String?;
    final content = message['content'] as String?;
    final mediaType = message['media_type'] as String?;
    final isEdited = message['edited_at'] != null;

    return Column(
      crossAxisAlignment: isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        // Reações acima da mensagem
        if (reactions.isNotEmpty) _buildReactionsBar(),

        GestureDetector(
          onLongPress: onEdit != null ? () => _showMessageMenu(context) : null,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primaryBlue : Colors.grey[300],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isMe
                    ? const Radius.circular(16)
                    : const Radius.circular(0),
                bottomRight: isMe
                    ? const Radius.circular(0)
                    : const Radius.circular(16),
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

                // Indicador de editado e hora
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isEdited)
                      Text(
                        ' (editado)',
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe ? Colors.white70 : Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(message['created_at']),
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Botões de reação rápida (apenas para mensagens do outro usuário)
        if (!isMe) _buildQuickReactions(),
      ],
    );
  }

  Widget _buildReactionsBar() {
    // Agrupa reações por emoji
    final reactionCounts = <String, int>{};
    for (var reaction in reactions) {
      final emoji = reaction['emoji'] as String;
      reactionCounts[emoji] = (reactionCounts[emoji] ?? 0) + 1;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 4,
        children: reactionCounts.entries.map((entry) {
          return Chip(
            label: Text('${entry.key} ${entry.value}'),
            backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            labelStyle: const TextStyle(fontSize: 10),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickReactions() {
    return Container(
      margin: const EdgeInsets.only(left: 12, right: 12, bottom: 4),
      child: Wrap(
        spacing: 4,
        children: ['👍', '❤️', '😂', '😮'].map((emoji) {
          return GestureDetector(
            onTap: () => onReaction(emoji),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(emoji),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showMessageMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar mensagem'),
                onTap: () {
                  Navigator.pop(context);
                  onEdit!();
                },
              ),
            ListTile(
              leading: const Icon(Icons.emoji_emotions),
              title: const Text('Adicionar reação'),
              onTap: () {
                Navigator.pop(context);
                _showReactionPicker(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReactionPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escolha uma reação'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['👍', '❤️', '😂', '😮', '😢', '🙏', '👏', '🔥', '🎉', '🤔']
              .map(
                (emoji) => GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onReaction(emoji);
                  },
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  String _formatTime(dynamic timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp.toString());
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}

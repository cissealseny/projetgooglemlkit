import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/di/injection.dart';
import '../bloc/generative_bloc.dart';

/// Generative AI Chat Page with Real API Integration
class GenerativeChatPage extends StatefulWidget {
  const GenerativeChatPage({super.key});

  @override
  State<GenerativeChatPage> createState() => _GenerativeChatPageState();
}

class _GenerativeChatPageState extends State<GenerativeChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  String _selectedModel = 'ollama:mistral:7b';
  bool _showSidebar = true;
  int? _currentConversationId;

  final List<_ModelOption> _models = [
    _ModelOption(
      id: 'ollama:llama3.2:1b',
      name: 'Llama 3.2 (1B)',
      description: 'Rapide et léger',
      icon: Icons.bolt_rounded,
    ),
    _ModelOption(
      id: 'ollama:llama3.2:3b',
      name: 'Llama 3.2 (3B)',
      description: 'Équilibré',
      icon: Icons.auto_awesome_rounded,
    ),
    _ModelOption(
      id: 'ollama:codellama',
      name: 'Code Llama',
      description: 'Génération de code',
      icon: Icons.code_rounded,
    ),
    _ModelOption(
      id: 'ollama:mistral:7b',
      name: 'Mistral 7B',
      description: 'Performance avancée',
      icon: Icons.psychology_rounded,
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<GenerativeBloc>()..add(LoadConversations()),
      child: BlocConsumer<GenerativeBloc, GenerativeState>(
        listener: (context, state) {
          if (state.status == GenerativeStatus.failure && state.error != null) {
            _showErrorSnackbar(context, state.error!);
          }
          if (state.currentConversation != null) {
            _currentConversationId = state.currentConversation!['id'];
          }
          if (state.status == GenerativeStatus.success &&
              state.messages.isNotEmpty) {
            _scrollToBottom();
          }
        },
        builder: (context, state) {
          return _buildResponsiveLayout(context, state);
        },
      ),
    );
  }

  Widget _buildResponsiveLayout(BuildContext context, GenerativeState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive breakpoints
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    if (isMobile) {
      return _buildMobileLayout(context, state, isDark);
    } else if (isTablet) {
      return _buildTabletLayout(context, state, isDark);
    } else {
      return _buildDesktopLayout(context, state, isDark);
    }
  }

  // Mobile Layout - Full screen chat with bottom sheet for settings
  Widget _buildMobileLayout(
      BuildContext context, GenerativeState state, bool isDark) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.generativeGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Assistant IA', overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => _showMobileSettings(context, isDark),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _createNewConversation(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildModelChip(context, isDark),
          Expanded(child: _buildMessageList(context, state, isDark)),
          _buildInputArea(context, state, isDark, compact: true),
        ],
      ),
    );
  }

  // Tablet Layout - Chat with collapsible sidebar
  Widget _buildTabletLayout(
      BuildContext context, GenerativeState state, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _buildChatHeader(context, state, isDark, showToggle: true),
              Expanded(child: _buildMessageList(context, state, isDark)),
              _buildInputArea(context, state, isDark),
            ],
          ),
        ),
        if (_showSidebar)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 280,
            child: _buildSidebar(context, state, isDark),
          ),
      ],
    );
  }

  // Desktop Layout - Full sidebar always visible
  Widget _buildDesktopLayout(
      BuildContext context, GenerativeState state, bool isDark) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildChatHeader(context, state, isDark),
              Expanded(child: _buildMessageList(context, state, isDark)),
              _buildInputArea(context, state, isDark),
            ],
          ),
        ),
        Container(
          width: 1,
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        SizedBox(
          width: 320,
          child: _buildSidebar(context, state, isDark),
        ),
      ],
    );
  }

  Widget _buildModelChip(BuildContext context, bool isDark) {
    final model = _models.firstWhere((m) => m.id == _selectedModel,
        orElse: () => _models.first);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      child: Row(
        children: [
          Icon(model.icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            model.name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const Spacer(),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text('En ligne', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildChatHeader(
      BuildContext context, GenerativeState state, bool isDark,
      {bool showToggle = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.generativeGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assistant IA Génératif',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'En ligne • ${_models.firstWhere((m) => m.id == _selectedModel, orElse: () => _models.first).name}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (showToggle)
            IconButton(
              icon: Icon(
                  _showSidebar ? Icons.menu_open_rounded : Icons.menu_rounded),
              onPressed: () => setState(() => _showSidebar = !_showSidebar),
            ),
          IconButton(
            icon: const Icon(Icons.add_comment_rounded),
            onPressed: () => _createNewConversation(context),
            tooltip: 'Nouvelle conversation',
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(
      BuildContext context, GenerativeState state, bool isDark) {
    final messages = state.messages;
    final isSending = state.status == GenerativeStatus.sending;

    if (messages.isEmpty && _currentConversationId == null) {
      return _buildEmptyState(context, isDark);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length + (isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (isSending && index == messages.length) {
          return _buildTypingIndicator(context, isDark);
        }
        final message = messages[index];
        return _buildMessageBubble(
          context,
          content: message['content'] ?? '',
          isUser: message['role'] == 'user',
          timestamp: message['timestamp'] != null
              ? DateTime.tryParse(message['timestamp']) ?? DateTime.now()
              : DateTime.now(),
          isDark: isDark,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.generativeGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              'Commencez une conversation',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Posez une question ou décrivez ce que vous voulez accomplir',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip(context, '💡 Génère des idées', isDark),
                _buildSuggestionChip(context, '📝 Aide-moi à écrire', isDark),
                _buildSuggestionChip(context, '💻 Écris du code', isDark),
                _buildSuggestionChip(context, '🔍 Explique-moi', isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(BuildContext context, String text, bool isDark) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        _messageController.text = text.split(' ').skip(1).join(' ');
        _inputFocusNode.requestFocus();
      },
      backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
    );
  }

  Widget _buildMessageBubble(
    BuildContext context, {
    required String content,
    required bool isUser,
    required DateTime timestamp,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.generativeGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _copyToClipboard(content),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isUser
                      ? AppColors.primary
                      : (isDark ? AppColors.cardDark : AppColors.cardLight),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isUser ? 16 : 4),
                    topRight: Radius.circular(isUser ? 4 : 16),
                    bottomLeft: const Radius.circular(16),
                    bottomRight: const Radius.circular(16),
                  ),
                  border: isUser
                      ? null
                      : Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      content,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isUser ? Colors.white : null,
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(timestamp),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isUser
                                        ? Colors.white.withValues(alpha: 0.7)
                                        : Theme.of(context).colorScheme.outline,
                                    fontSize: 10,
                                  ),
                        ),
                        if (!isUser) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _copyToClipboard(content),
                            child: Icon(
                              Icons.copy_rounded,
                              size: 14,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 10),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.person_rounded,
                  color: AppColors.primary, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppColors.generativeGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(
      BuildContext context, GenerativeState state, bool isDark,
      {bool compact = false}) {
    final isSending = state.status == GenerativeStatus.sending;

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        border: Border(
          top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _inputFocusNode,
                maxLines: 5,
                minLines: 1,
                enabled: !isSending,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(context),
                decoration: InputDecoration(
                  hintText: isSending
                      ? 'Génération en cours...'
                      : 'Tapez votre message...',
                  filled: true,
                  fillColor: isDark
                      ? AppColors.backgroundDark
                      : AppColors.backgroundLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: compact ? 10 : 14,
                  ),
                  prefixIcon: compact
                      ? null
                      : Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: isSending ? null : AppColors.generativeGradient,
                color: isSending ? Theme.of(context).colorScheme.outline : null,
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                onPressed: isSending ? null : () => _sendMessage(context),
                icon: isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(
      BuildContext context, GenerativeState state, bool isDark) {
    return Container(
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Configuration',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight),

          // Model Selection
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modèle IA',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ..._models
                    .map((model) => _buildModelOption(context, model, isDark)),
              ],
            ),
          ),

          Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight),

          // Conversation History
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Historique',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      onPressed: () => context
                          .read<GenerativeBloc>()
                          .add(LoadConversations()),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (state.conversations.isEmpty)
                  Text(
                    'Aucune conversation',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else
                  ...state.conversations.take(5).map(
                      (conv) => _buildConversationItem(context, conv, isDark)),
              ],
            ),
          ),

          const Spacer(),

          // Info Box
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Text('Info',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'L\'IA utilise Ollama en local. Assurez-vous que le serveur Ollama est démarré.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelOption(
      BuildContext context, _ModelOption model, bool isDark) {
    final isSelected = _selectedModel == model.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedModel = model.id),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : (isDark
                    ? AppColors.backgroundDark
                    : AppColors.backgroundLight),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
          ),
          child: Row(
            children: [
              Icon(model.icon,
                  size: 18,
                  color: isSelected
                      ? AppColors.primary
                      : Theme.of(context).colorScheme.outline),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.name,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      model.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle_rounded,
                    color: AppColors.primary, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConversationItem(
      BuildContext context, dynamic conv, bool isDark) {
    return InkWell(
      onTap: () => context
          .read<GenerativeBloc>()
          .add(SelectConversation(conversationId: conv['id'])),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: _currentConversationId == conv['id']
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.chat_rounded,
                size: 14, color: Theme.of(context).colorScheme.outline),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                conv['title'] ?? 'Conversation',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMobileSettings(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Configuration',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text('Modèle IA',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ..._models
                  .map((model) => _buildModelOption(context, model, isDark)),
            ],
          ),
        ),
      ),
    );
  }

  void _createNewConversation(BuildContext context) {
    context.read<GenerativeBloc>().add(CreateConversation());
    setState(() => _currentConversationId = null);
  }

  void _sendMessage(BuildContext context) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Create conversation if needed
    if (_currentConversationId == null) {
      context.read<GenerativeBloc>().add(CreateConversation(
          title: text.substring(0, text.length.clamp(0, 50))));
    }

    // Wait a bit for conversation creation, then send
    Future.delayed(
        Duration(milliseconds: _currentConversationId == null ? 500 : 0), () {
      final bloc = context.read<GenerativeBloc>();
      final convId =
          bloc.state.currentConversation?['id'] ?? _currentConversationId;

      if (convId != null) {
        bloc.add(SendMessage(
          conversationId: convId,
          message: text,
          model: _selectedModel,
        ));
        _messageController.clear();
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Copié dans le presse-papiers'),
          duration: Duration(seconds: 1)),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      )..repeat(reverse: true);
    });

    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controllers[index],
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.primary
                    .withValues(alpha: 0.3 + (_controllers[index].value * 0.7)),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

class _ModelOption {
  final String id;
  final String name;
  final String description;
  final IconData icon;

  _ModelOption({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}

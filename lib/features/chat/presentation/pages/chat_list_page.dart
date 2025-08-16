import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_text_styles.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../../../core/router/app_router.dart';

class ChatListPage extends ConsumerStatefulWidget {
  const ChatListPage({super.key});

  @override
  ConsumerState<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends ConsumerState<ChatListPage> {
  final TextEditingController _searchController = TextEditingController();

  // Mock data for demonstration
  final List<ChatItem> _conversations = [
    ChatItem(
      id: '1',
      name: 'Maria Santos',
      lastMessage: 'Is the textbook still available?',
      timestamp: '2m ago',
      isOnline: true,
      unreadCount: 2,
      productName: 'Engineering Mathematics',
    ),
    ChatItem(
      id: '2',
      name: 'John Doe',
      lastMessage: 'Thanks! Let\'s meet at the library',
      timestamp: '15m ago',
      isOnline: false,
      unreadCount: 0,
      productName: 'Physics Lab Manual',
    ),
    ChatItem(
      id: '3',
      name: 'Anna Cruz',
      lastMessage: 'What\'s the condition of the laptop?',
      timestamp: '1h ago',
      isOnline: true,
      unreadCount: 1,
      productName: 'Gaming Laptop',
    ),
    ChatItem(
      id: '4',
      name: 'Mike Johnson',
      lastMessage: 'Perfect! I\'ll take it',
      timestamp: '2h ago',
      isOnline: false,
      unreadCount: 0,
      productName: 'Calculus Textbook',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search functionality
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: AppColors.primaryBlue,
            padding: const EdgeInsets.all(AppSizes.paddingM),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingM,
                    vertical: AppSizes.paddingS,
                  ),
                ),
              ),
            ),
          ),

          // Chat list
          Expanded(
            child: _conversations.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final chat = _conversations[index];
                      return _buildChatItem(chat);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.gray),
          const SizedBox(height: AppSizes.spaceM),
          Text(
            'No conversations yet',
            style: AppTextStyles.h3.copyWith(color: AppColors.gray),
          ),
          const SizedBox(height: AppSizes.spaceS),
          Text(
            'Start chatting with sellers and buyers',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textGray),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.spaceL),
          ElevatedButton.icon(
            onPressed: () => context.go(AppRoutes.home),
            icon: const Icon(Icons.explore),
            label: const Text('Browse Products'),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(ChatItem chat) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingS,
        vertical: 2,
      ),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingM,
          vertical: AppSizes.paddingS,
        ),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primaryBlue,
              child: Text(
                chat.name.substring(0, 1).toUpperCase(),
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (chat.isOnline)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                chat.name,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
            Text(
              chat.timestamp,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textGray,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (chat.productName != null) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  chat.productName!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              chat.lastMessage,
              style: AppTextStyles.bodyMedium.copyWith(
                color: chat.unreadCount > 0
                    ? AppColors.primaryBlue
                    : AppColors.textGray,
                fontWeight: chat.unreadCount > 0
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: chat.unreadCount > 0
            ? Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    chat.unreadCount.toString(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            : null,
        onTap: () {
          context.push('${AppRoutes.chatDetail}/${chat.id}');
        },
      ),
    );
  }
}

class ChatItem {
  final String id;
  final String name;
  final String lastMessage;
  final String timestamp;
  final bool isOnline;
  final int unreadCount;
  final String? productName;

  ChatItem({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.timestamp,
    required this.isOnline,
    required this.unreadCount,
    this.productName,
  });
}

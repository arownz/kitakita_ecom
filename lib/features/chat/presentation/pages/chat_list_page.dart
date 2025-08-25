import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_text_styles.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../shared/layouts/main_layout.dart';
import '../../../../shared/widgets/email_verification_banner.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../providers/chat_providers.dart';
import '../../domain/models/chat_models.dart';

class ChatListPage extends ConsumerStatefulWidget {
  const ChatListPage({super.key});

  @override
  ConsumerState<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends ConsumerState<ChatListPage> {
  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final authState = ref.watch(authProvider);

    // Check if email is verified using database status
    final isEmailVerified = authState.isEmailVerified;

    if (!isEmailVerified) {
      return MainLayout(
        currentIndex: 2,
        title: 'Messages',
        child: Column(
          children: [
            const EmailVerificationBanner(),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 64,
                      color: AppColors.textGray.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: AppSizes.spaceM),
                    Text(
                      'Verify your email to start messaging',
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.textGray,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spaceS),
                    Text(
                      'Please verify your email address to send and receive messages from other students.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textGray,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Load conversations from Supabase
    final conversationsAsync = ref.watch(conversationsProvider);

    if (isDesktop) {
      return _buildDesktopLayout(context, conversationsAsync);
    } else {
      return _buildMobileLayout(context, conversationsAsync);
    }
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    AsyncValue<List<ChatConversation>> conversationsAsync,
  ) {
    return MainLayout(
      currentIndex: 2,
      title: 'Messages',
      child: Container(
        decoration: const BoxDecoration(color: Color(0xFFF8F9FA)),
        child: Row(
          children: [
            // Chat List Panel (Left)
            Container(
              width: 360,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Color(0xFFE9ECEF))),
              ),
              child: _buildChatList(
                context,
                conversationsAsync,
                isDesktop: true,
              ),
            ),
            // Chat View Panel (Center) - Show placeholder when no chat selected
            Expanded(flex: 2, child: _buildChatPlaceholder(context)),
            // Chat Info Panel (Right) - Hidden when no chat selected
            Container(
              width: 320,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(left: BorderSide(color: Color(0xFFE9ECEF))),
              ),
              child: _buildInfoPlaceholder(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    AsyncValue<List<ChatConversation>> conversationsAsync,
  ) {
    return MainLayout(
      currentIndex: 2,
      title: 'Messages',
      child: _buildChatList(context, conversationsAsync, isDesktop: false),
    );
  }

  Widget _buildChatList(
    BuildContext context,
    AsyncValue<List<ChatConversation>> conversationsAsync, {
    required bool isDesktop,
  }) {
    return Column(
      children: [
        // Search bar
        if (isDesktop) _buildSearchBar(context),

        // Chat list
        Expanded(
          child: conversationsAsync.when(
            data: (conversations) => conversations.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: EdgeInsets.symmetric(
                      vertical: isDesktop ? 0 : AppSizes.paddingS,
                    ),
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      return _buildChatItem(
                        context,
                        conversation,
                        isDesktop: isDesktop,
                      );
                    },
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading conversations',
                    style: AppTextStyles.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: AppTextStyles.bodySmall.copyWith(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(conversationsProvider);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF))),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textGray,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textGray,
            size: 20,
          ),
          filled: true,
          fillColor: const Color(0xFFF8F9FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingM,
            vertical: AppSizes.paddingS,
          ),
        ),
      ),
    );
  }

  Widget _buildChatItem(
    BuildContext context,
    ChatConversation conversation, {
    required bool isDesktop,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isDesktop ? 0 : AppSizes.paddingS,
        vertical: isDesktop ? 0 : 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isDesktop ? 0 : 12),
        border: isDesktop
            ? const Border(bottom: BorderSide(color: Color(0xFFE9ECEF)))
            : Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: InkWell(
        onTap: () => context.push('${AppRoutes.chatDetail}/${conversation.id}'),
        borderRadius: BorderRadius.circular(isDesktop ? 0 : 12),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          child: Row(
            children: [
              // Avatar with online indicator
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        conversation.otherUserName[0].toUpperCase(),
                        style: AppTextStyles.h3.copyWith(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (conversation.isOnline)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: AppSizes.spaceM),

              // Chat info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.otherUserName,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E1E1E),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatTimestamp(conversation.lastMessageAt),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textGray,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      conversation.productName,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessage ?? 'No messages yet',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: conversation.unreadCount > 0
                                  ? const Color(0xFF1E1E1E)
                                  : AppColors.textGray,
                              fontWeight: conversation.unreadCount > 0
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conversation.unreadCount > 0) ...[
                          const SizedBox(width: AppSizes.spaceS),
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
                              conversation.unreadCount.toString(),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppColors.textGray.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSizes.spaceM),
          Text(
            'No conversations yet',
            style: AppTextStyles.h3.copyWith(color: AppColors.textGray),
          ),
          const SizedBox(height: AppSizes.spaceS),
          Text(
            'Start chatting with sellers to see your conversations here',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textGray),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.spaceL),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.home),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Browse Products'),
          ),
        ],
      ),
    );
  }

  Widget _buildChatPlaceholder(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: AppColors.textGray.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSizes.spaceL),
            Text(
              'Select a conversation',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textGray,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: AppSizes.spaceS),
            Text(
              'Choose a conversation from the list to start messaging',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textGray,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPlaceholder(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 60,
              color: AppColors.textGray.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSizes.spaceM),
            Text(
              'Chat Info',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textGray,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: AppSizes.spaceS),
            Text(
              'Select a conversation to view details',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textGray,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}

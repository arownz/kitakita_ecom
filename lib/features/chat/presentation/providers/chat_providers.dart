import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../domain/models/chat_models.dart';

final _logger = Logger();

// Chat state model
class ChatState {
  final List<ChatConversation> conversations;
  final bool isLoading;
  final String? error;

  const ChatState({
    this.conversations = const [],
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatConversation>? conversations,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Chat state notifier
class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier() : super(const ChatState());

  Future<void> loadConversations(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get conversations where the user is either buyer or seller
      final response = await SupabaseService.from('conversations')
          .select('''
            id,
            product_id,
            buyer_id,
            seller_id,
            last_message,
            last_message_at,
            created_at,
            products!inner(
              id,
              title,
              price,
              product_images(image_url)
            ),
            buyer:user_profiles!conversations_buyer_id_fkey(
              id,
              first_name,
              last_name,
              profile_image_url
            ),
            seller:user_profiles!conversations_seller_id_fkey(
              id,
              first_name,
              last_name,
              profile_image_url
            )
          ''')
          .or('buyer_id.eq.$userId,seller_id.eq.$userId')
          .order('last_message_at', ascending: false);

      final conversations = await Future.wait(
        (response as List).map((data) async {
          final isBuyer = data['buyer_id'] == userId;
          final otherUser = isBuyer ? data['seller'] : data['buyer'];
          final product = data['products'];

          return ChatConversation(
            id: data['id'],
            productId: data['product_id'],
            buyerId: data['buyer_id'],
            sellerId: data['seller_id'],
            otherUserId: isBuyer ? data['seller_id'] : data['buyer_id'],
            otherUserName:
                '${otherUser['first_name']} ${otherUser['last_name']}',
            otherUserAvatar: otherUser['profile_image_url'],
            productName: product['title'],
            productPrice: product['price'],
            productImage: product['product_images']?.isNotEmpty == true
                ? product['product_images'][0]['image_url']
                : null,
            lastMessage: data['last_message'] ?? '',
            lastMessageAt: DateTime.parse(data['last_message_at']),
            unreadCount: await _getUnreadCount(data['id'], userId),
            isOnline: await _checkUserOnlineStatus(
              isBuyer ? data['seller_id'] : data['buyer_id'],
            ),
          );
        }),
      );

      state = state.copyWith(conversations: conversations, isLoading: false);
    } catch (e) {
      _logger.e('Failed to load conversations: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load conversations: $e',
      );
    }
  }

  Future<ChatConversation?> createOrGetConversation({
    required String buyerId,
    required String sellerId,
    required String productId,
  }) async {
    try {
      // Check if conversation already exists
      final existing = await SupabaseService.from('conversations')
          .select('*')
          .eq('buyer_id', buyerId)
          .eq('seller_id', sellerId)
          .eq('product_id', productId)
          .maybeSingle();

      if (existing != null) {
        // Return existing conversation
        await loadConversations(buyerId);
        return state.conversations.firstWhere((c) => c.id == existing['id']);
      }

      // Create new conversation
      final response = await SupabaseService.from('conversations')
          .insert({
            'buyer_id': buyerId,
            'seller_id': sellerId,
            'product_id': productId,
            'last_message': '',
            'last_message_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      // Reload conversations
      await loadConversations(buyerId);
      return state.conversations.firstWhere((c) => c.id == response['id']);
    } catch (e) {
      _logger.e('Failed to create conversation: $e');
      state = state.copyWith(error: 'Failed to create conversation: $e');
      return null;
    }
  }

  // Helper method to get unread message count for a conversation
  Future<int> _getUnreadCount(String conversationId, String userId) async {
    try {
      final response = await SupabaseService.from('messages')
          .select('id')
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      _logger.w('Failed to get unread count: $e');
      return 0;
    }
  }

  // Helper method to check if user is online (simplified implementation)
  Future<bool> _checkUserOnlineStatus(String userId) async {
    try {
      final response = await SupabaseService.from(
        'user_profiles',
      ).select('last_seen_at').eq('user_id', userId).single();

      if (response['last_seen_at'] != null) {
        final lastSeen = DateTime.parse(response['last_seen_at']);
        final now = DateTime.now();
        // Consider user online if last seen within 5 minutes
        return now.difference(lastSeen).inMinutes < 5;
      }
      return false;
    } catch (e) {
      _logger.w('Failed to check online status: $e');
      return false;
    }
  }

  // Method to mark messages as read
  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    try {
      await SupabaseService.from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId);
    } catch (e) {
      _logger.e('Failed to mark messages as read: $e');
    }
  }
}

// Messages state model
class MessagesState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  const MessagesState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  MessagesState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return MessagesState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Messages state notifier
class MessagesNotifier extends StateNotifier<MessagesState> {
  MessagesNotifier() : super(const MessagesState());

  Future<void> loadMessages(String conversationId, String currentUserId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await SupabaseService.from('messages')
          .select('''
            id,
            conversation_id,
            sender_id,
            content,
            created_at,
            sender:user_profiles!messages_sender_id_fkey(
              first_name,
              last_name,
              profile_image_url
            )
          ''')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      final messages = (response as List).map((data) {
        return ChatMessage(
          id: data['id'],
          conversationId: data['conversation_id'],
          senderId: data['sender_id'],
          content: data['content'],
          createdAt: DateTime.parse(data['created_at']),
          isFromCurrentUser: data['sender_id'] == currentUserId,
          senderName:
              '${data['sender']['first_name']} ${data['sender']['last_name']}',
          senderAvatar: data['sender']['profile_image_url'],
        );
      }).toList();

      state = state.copyWith(messages: messages, isLoading: false);

      // Mark messages as read
      await _markMessagesAsRead(conversationId, currentUserId);
    } catch (e) {
      _logger.e('Failed to load messages: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load messages: $e',
      );
    }
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
  }) async {
    try {
      // Insert message
      await SupabaseService.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': senderId,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update conversation's last message
      await SupabaseService.from('conversations')
          .update({
            'last_message': content,
            'last_message_at': DateTime.now().toIso8601String(),
          })
          .eq('id', conversationId);

      // Reload messages
      await loadMessages(conversationId, senderId);
    } catch (e) {
      _logger.e('Failed to send message: $e');
      state = state.copyWith(error: 'Failed to send message: $e');
    }
  }

  // Helper method to mark messages as read
  Future<void> _markMessagesAsRead(String conversationId, String userId) async {
    try {
      await SupabaseService.from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId);
    } catch (e) {
      _logger.e('Failed to mark messages as read: $e');
    }
  }

  // Update user's last seen status
  Future<void> updateLastSeen(String userId) async {
    try {
      await SupabaseService.from('user_profiles')
          .update({'last_seen_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId);
    } catch (e) {
      _logger.w('Failed to update last seen: $e');
    }
  }
}

// Providers
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});

final messagesProvider = StateNotifierProvider<MessagesNotifier, MessagesState>(
  (ref) {
    return MessagesNotifier();
  },
);

// Auto-load conversations when user changes
final conversationsProvider = FutureProvider<List<ChatConversation>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final chatNotifier = ref.read(chatProvider.notifier);
  await chatNotifier.loadConversations(user.id);
  return ref.read(chatProvider).conversations;
});

class ChatConversation {
  final String id;
  final String productId;
  final String buyerId;
  final String sellerId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String productName;
  final double productPrice;
  final String? productImage;
  final String? lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final bool isOnline;

  const ChatConversation({
    required this.id,
    required this.productId,
    required this.buyerId,
    required this.sellerId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    required this.productName,
    required this.productPrice,
    this.productImage,
    this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
    this.isOnline = false,
  });

  ChatConversation copyWith({
    String? id,
    String? productId,
    String? buyerId,
    String? sellerId,
    String? otherUserId,
    String? otherUserName,
    String? otherUserAvatar,
    String? productName,
    double? productPrice,
    String? productImage,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    bool? isOnline,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserAvatar: otherUserAvatar ?? this.otherUserAvatar,
      productName: productName ?? this.productName,
      productPrice: productPrice ?? this.productPrice,
      productImage: productImage ?? this.productImage,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final bool isFromCurrentUser;
  final String senderName;
  final String? senderAvatar;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.isFromCurrentUser,
    required this.senderName,
    this.senderAvatar,
  });

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    DateTime? createdAt,
    bool? isFromCurrentUser,
    String? senderName,
    String? senderAvatar,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isFromCurrentUser: isFromCurrentUser ?? this.isFromCurrentUser,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
    );
  }
}

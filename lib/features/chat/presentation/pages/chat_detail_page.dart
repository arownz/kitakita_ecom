import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_text_styles.dart';

class ChatDetailPage extends ConsumerWidget {
  final String chatId;

  const ChatDetailPage({super.key, required this.chatId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.chat_bubble,
              size: 64,
              color: AppColors.primaryBlue,
            ),
            const SizedBox(height: 16),
            const Text('Chat Detail Page', style: AppTextStyles.h2),
            const SizedBox(height: 8),
            Text('Chat ID: $chatId', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            const Text(
              'Coming Soon - Chat Interface',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

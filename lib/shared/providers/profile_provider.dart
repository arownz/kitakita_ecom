import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../services/supabase_service.dart';
import 'auth_provider.dart';

final _logger = Logger();

// Profile data model
class ProfileData {
  final String? studentId;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? email;
  final bool isVerified;

  const ProfileData({
    this.studentId,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.profileImageUrl,
    this.email,
    this.isVerified = false,
  });

  ProfileData copyWith({
    String? studentId,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profileImageUrl,
    String? email,
    bool? isVerified,
  }) {
    return ProfileData(
      studentId: studentId ?? this.studentId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      email: email ?? this.email,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

// Profile provider that fetches data from database
final profileDataProvider = FutureProvider.autoDispose<ProfileData?>((
  ref,
) async {
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser == null) {
    return null;
  }

  try {
    _logger.i('Fetching profile data for user: ${currentUser.id}');

    final response = await SupabaseService.from('user_profiles')
        .select(
          'student_id, first_name, last_name, phone_number, profile_image_url, email, is_verified',
        )
        .eq('user_id', currentUser.id)
        .single();

    final profileData = ProfileData(
      studentId: response['student_id'] as String?,
      firstName: response['first_name'] as String?,
      lastName: response['last_name'] as String?,
      phoneNumber: response['phone_number'] as String?,
      profileImageUrl: response['profile_image_url'] as String?,
      email: response['email'] as String?,
      isVerified: response['is_verified'] as bool? ?? false,
    );

    _logger.i(
      'Profile data fetched successfully: ${profileData.profileImageUrl != null ? "Has image" : "No image"}',
    );
    return profileData;
  } catch (e) {
    _logger.w('Error fetching profile data: $e');
    return null;
  }
});

// Convenience provider for profile image URL
final profileImageUrlProvider = Provider<String?>((ref) {
  final profileDataAsync = ref.watch(profileDataProvider);
  return profileDataAsync.when(
    data: (profileData) => profileData?.profileImageUrl,
    loading: () => null,
    error: (error, stackTrace) => null,
  );
});

// Convenience provider for user's display name
final userDisplayNameProvider = Provider<String>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  final profileDataAsync = ref.watch(profileDataProvider);

  return profileDataAsync.when(
    data: (profileData) {
      if (profileData?.firstName != null &&
          profileData!.firstName!.isNotEmpty) {
        final lastName = profileData.lastName?.isNotEmpty == true
            ? ' ${profileData.lastName}'
            : '';
        return '${profileData.firstName}$lastName';
      }
      return currentUser?.email?.split('@').first ?? 'User';
    },
    loading: () => currentUser?.email?.split('@').first ?? 'User',
    error: (error, stackTrace) =>
        currentUser?.email?.split('@').first ?? 'User',
  );
});

// Convenience provider for user initials
final userInitialsProvider = Provider<String>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  final profileDataAsync = ref.watch(profileDataProvider);

  return profileDataAsync.when(
    data: (profileData) {
      if (profileData?.firstName != null &&
          profileData!.firstName!.isNotEmpty) {
        final firstInitial = profileData.firstName![0].toUpperCase();
        final lastInitial = profileData.lastName?.isNotEmpty == true
            ? profileData.lastName![0].toUpperCase()
            : '';
        return '$firstInitial$lastInitial';
      }
      return currentUser?.email?.substring(0, 1).toUpperCase() ?? 'U';
    },
    loading: () => currentUser?.email?.substring(0, 1).toUpperCase() ?? 'U',
    error: (error, stackTrace) =>
        currentUser?.email?.substring(0, 1).toUpperCase() ?? 'U',
  );
});

# KitaKita E-Commerce AI Coding Guidelines

## Project Overview

KitaKita is a Flutter-based campus marketplace application with Supabase backend, designed for university students to buy and sell items. The app supports role-based access (students/admin), real-time chat, product management, and comprehensive authentication.

## Architecture Principles

### Project Structure

```
lib/
├── main.dart                    # App entry point with Supabase initialization
├── core/
│   ├── app.dart                # Main app configuration
│   └── router/
│       └── app_router.dart     # GoRouter configuration with role-based routing
├── features/                   # Feature-based architecture
│   ├── auth/                   # Authentication (login/register/landing)
│   ├── marketplace/            # Product browsing/search/management
│   ├── chat/                   # Messaging system
│   ├── profile/                # User profiles and settings
│   ├── notifications/          # Notification management
│   └── admin/                  # Admin dashboard
├── shared/                     # Shared resources
│   ├── constants/              # App colors, sizes, text styles
│   ├── providers/              # Riverpod state management
│   ├── services/               # External service integrations
│   ├── utils/                  # Helper functions and utilities
│   ├── widgets/                # Reusable UI components
│   └── layouts/                # Layout templates (MainLayout)
```

### State Management (Riverpod)

- **Primary Pattern**: `StateNotifierProvider` for complex state
- **Simple State**: `Provider` for computed values and dependency injection
- **Authentication**: Central `authProvider` with reactive providers for role checking
- **Data Fetching**: `FutureProvider` for async operations
- **Repository Pattern**: Inject repositories via providers for testability

**Example Provider Patterns:**

```dart
// State Notifier for complex state
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// Computed providers for reactive UI
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).user != null;
});

// Repository injection
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});
```

### Navigation (GoRouter)

- **Role-Based Routing**: Automatic redirection based on user role (student/admin)
- **Auth Guards**: Protected routes require authentication
- **Error Handling**: Graceful fallbacks for invalid routes
- **Route Structure**: RESTful paths with parameters (`/product/:id`, `/chat/:id`)

**Critical Router Patterns:**

```dart
// Role-based redirection in router.dart
if (userRole == UserRole.admin) {
  return AppRoutes.adminDashboard;
} else {
  return AppRoutes.home;
}

// Email verification guards
void _handleVerifiedNavigation(BuildContext context, String route) {
  final isVerified = ref.read(authProvider).isEmailVerified;
  if (!isVerified) {
    // Show verification prompt
    return;
  }
  context.go(route);
}
```

## Backend Integration (Supabase)

### Authentication Patterns

- **Bypass Email Verification**: Custom solution for development/demo
- **Role Management**: Database-driven user roles with reactive UI updates
- **Session Persistence**: Automatic token refresh and validation
- **Error Handling**: Graceful degradation for auth failures

**Key Service Patterns:**

```dart
// SupabaseService wrapper for consistent API access
static SupabaseClient get client => Supabase.instance.client;
static User? get currentUser => client.auth.currentUser;

// Database operations with error handling
final response = await SupabaseService.from('user_profiles')
    .select('role')
    .eq('user_id', userId)
    .single();
```

### Database Schema Awareness

- **Tables**: user_profiles, products, categories, conversations, messages, notifications
- **Storage**: Profile images, product images with organized bucket structure
- **RLS**: Row Level Security policies for data access control
- **Functions**: Database functions for complex operations

## UI/UX Standards

### Design System

- **Colors**: Defined in `AppColors` - primary blue (#37428F), yellow accent (#FFDA4F)
- **Typography**: Consistent text styles via `AppTextStyles`
- **Spacing**: Standardized spacing via `AppSizes`
- **Responsive**: Desktop sidebar + mobile bottom navigation via `ResponsiveUtils`

### Component Patterns

- **Layouts**: Use `MainLayout` for consistent navigation and responsive behavior
- **State Loading**: Show loading states during async operations
- **Error Handling**: Display user-friendly error messages
- **Verification Guards**: Block features requiring email verification

**Example UI Patterns:**

```dart
// Consistent container styling for cards
Container(
  decoration: BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(AppSizes.radiusM),
    boxShadow: [AppShadows.card],
  ),
)

// Responsive padding
Padding(
  padding: ResponsiveUtils.getScreenPadding(context),
  child: widget,
)
```

### Image Handling

- **Logo Standards**: 120x120px containers with 30px border radius
- **Product Images**: Support multiple images with primary image selection
- **Profile Images**: Circular avatars with fallback to initials
- **Asset Management**: Organized in assets/images/ and assets/icons/

## Development Workflows

### Feature Development

1. **Model First**: Define data models in `domain/models/`
2. **Repository Layer**: Create repository for data access
3. **Provider Setup**: Configure Riverpod providers for state management
4. **UI Implementation**: Build responsive UI with error handling
5. **Navigation Integration**: Add routes and navigation logic

### Testing Approach

- **Unit Tests**: Test business logic and data transformations
- **Provider Tests**: Test state management behavior
- **Integration Tests**: Test feature workflows
- **Widget Tests**: Test UI components and interactions

### Code Quality

- **Linting**: Follow `flutter_lints` rules
- **Documentation**: Document complex business logic
- **Error Handling**: Implement comprehensive error boundaries
- **Performance**: Optimize list rendering and image loading

## Security & Permissions

### Authentication Security

- **API Keys**: Use flutter_dotenv for secure key management
- **Session Management**: Automatic token refresh and validation
- **Role Verification**: Server-side role validation for sensitive operations
- **Input Validation**: Validate all user inputs before database operations

### Data Protection

- **RLS Policies**: Implement Row Level Security for data access
- **File Uploads**: Validate file types and sizes for image uploads
- **Privacy**: Respect user privacy in chat and profile data
- **Sanitization**: Sanitize user inputs to prevent injection attacks

## Common Patterns & Solutions

### State Management Patterns

```dart
// Loading states with error handling
class ProductsState {
  final List<Product> products;
  final bool isLoading;
  final String? error;

  const ProductsState({
    this.products = const [],
    this.isLoading = false,
    this.error,
  });
}

// Pagination pattern
Future<void> loadProducts({bool refresh = false}) async {
  if (refresh) {
    state = state.copyWith(products: [], isLoading: true);
  }
  // Load data...
}
```

### Error Handling Patterns

```dart
// Service layer error handling
try {
  final result = await repository.getData();
  return result;
} catch (e) {
  _logger.e('Operation failed: $e');
  throw ServiceException('User-friendly message');
}

// UI error display
if (state.error != null) {
  return ErrorWidget(
    message: state.error!,
    onRetry: () => ref.read(provider.notifier).retry(),
  );
}
```

### Image Upload Patterns

```dart
// Image picker with validation
final ImagePicker _picker = ImagePicker();
final XFile? image = await _picker.pickImage(
  source: ImageSource.gallery,
  imageQuality: 80,
  maxWidth: 1024,
  maxHeight: 1024,
);

// Supabase storage upload
final file = File(image.path);
final filename = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
await SupabaseService.storage
    .from('profile-images')
    .upload(filename, file);
```

## Environment Configuration

### Development Setup

- **API Keys**: Store in `.env` file (excluded from git)
- **Supabase URL**: https://irfkajxfonujbjxzveka.supabase.co
- **Environment Loading**: Use flutter_dotenv in main.dart
- **Debug Logging**: Enable detailed logging for development

### Production Considerations

- **Error Reporting**: Implement crash reporting
- **Performance Monitoring**: Track app performance metrics
- **Security Audits**: Regular security reviews
- **Backup Strategies**: Database backup and recovery plans

## Debugging & Troubleshooting

### Common Issues

1. **"Invalid API key"**: Check .env file and pubspec.yaml assets
2. **Auth state not updating**: Verify provider watching patterns
3. **Navigation loops**: Check router redirect logic
4. **Image loading failures**: Verify storage bucket permissions
5. **Email verification**: Use database status, not Supabase auth status

### Debugging Tools

- **Logger**: Use logger package for structured logging
- **Riverpod DevTools**: Monitor state changes
- **Supabase Dashboard**: Monitor database and auth
- **Flutter Inspector**: Debug UI layout issues

## AI Assistant Guidelines

### Code Generation

- Always use the established architecture patterns
- Include proper error handling and loading states
- Follow the existing naming conventions
- Add appropriate documentation and comments
- Consider responsive design requirements

### Feature Requests

- Start with data model definition
- Plan the repository and provider layers
- Consider authentication and authorization requirements
- Design responsive UI components
- Plan navigation and routing integration

### Bug Fixes

- Analyze the full feature workflow
- Check related providers and state management
- Verify authentication and permission logic
- Test responsive behavior
- Consider edge cases and error scenarios

### Refactoring

- Maintain existing API contracts
- Preserve state management patterns
- Keep responsive design intact
- Update related documentation
- Test all affected workflows

## Performance Guidelines

### Optimization Strategies

- **Lazy Loading**: Load data only when needed
- **Image Caching**: Use cached_network_image for product images
- **List Performance**: Use ListView.builder for large lists
- **State Minimization**: Keep only necessary data in state
- **Memory Management**: Dispose controllers and subscriptions

### Monitoring

- **Build Times**: Monitor compilation performance
- **Runtime Performance**: Profile widget rebuilds
- **Memory Usage**: Track memory leaks
- **Network Calls**: Optimize API call frequency
- **Image Loading**: Monitor image cache performance

This comprehensive guide ensures consistent, maintainable, and scalable development practices for the KitaKita e-commerce platform.

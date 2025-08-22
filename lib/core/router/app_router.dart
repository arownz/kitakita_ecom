import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/auth_provider.dart';
import '../../features/auth/presentation/pages/landing_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/marketplace/presentation/pages/home_page.dart';
import '../../features/marketplace/presentation/pages/product_detail_page.dart';
import '../../features/marketplace/presentation/pages/add_product_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/chat/presentation/pages/chat_list_page.dart';
import '../../features/chat/presentation/pages/chat_detail_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/my_products_page.dart';
import '../../features/profile/presentation/pages/favorites_page.dart';
import '../../features/profile/presentation/pages/settings_page.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';

// Route names
class AppRoutes {
  static const String landing = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String productDetail = '/product/:id';
  static const String addProduct = '/add-product';

  static const String notifications = '/notifications';
  static const String chatList = '/chat';
  static const String chatDetail = '/chat/:id';
  static const String profile = '/profile';
  static const String adminDashboard = '/admin';
  static const String myProducts = '/my-products';
  static const String favorites = '/favorites';
  static const String settings = '/settings';
}

class AppRouter {
  static GoRouter router(Ref ref) {
    return GoRouter(
      initialLocation: AppRoutes.landing,
      redirect: (context, state) {
        final isLoggedIn = ref.read(isLoggedInProvider);
        final userRole = ref.read(userRoleProvider);
        final isLoggingIn =
            state.matchedLocation == AppRoutes.login ||
            state.matchedLocation == AppRoutes.register ||
            state.matchedLocation == AppRoutes.landing;

        // If not logged in and trying to access protected routes
        if (!isLoggedIn && !isLoggingIn) {
          return AppRoutes.landing;
        }

        // If logged in and on auth pages, redirect to appropriate home
        if (isLoggedIn && isLoggingIn) {
          if (userRole == UserRole.admin) {
            return AppRoutes.adminDashboard;
          } else {
            return AppRoutes.home;
          }
        }

        // Admin trying to access student routes
        if (isLoggedIn && userRole == UserRole.admin) {
          final protectedStudentRoutes = [
            AppRoutes.home,
            AppRoutes.addProduct,
            AppRoutes.chatList,
          ];

          if (protectedStudentRoutes.any(
            (route) => state.matchedLocation.startsWith(route.split(':')[0]),
          )) {
            return AppRoutes.adminDashboard;
          }
        }

        // Student trying to access admin routes
        if (isLoggedIn && userRole == UserRole.student) {
          if (state.matchedLocation.startsWith('/admin')) {
            return AppRoutes.home;
          }
        }

        return null; // No redirect needed
      },
      routes: [
        // Auth Routes
        GoRoute(
          path: AppRoutes.landing,
          name: 'landing',
          builder: (context, state) => const LandingPage(),
        ),
        GoRoute(
          path: AppRoutes.login,
          name: 'login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: AppRoutes.register,
          name: 'register',
          builder: (context, state) => const RegisterPage(),
        ),

        // Student Routes
        GoRoute(
          path: AppRoutes.home,
          name: 'home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: AppRoutes.productDetail,
          name: 'productDetail',
          builder: (context, state) {
            final productId = state.pathParameters['id']!;
            return ProductDetailPage(productId: productId);
          },
        ),
        GoRoute(
          path: AppRoutes.addProduct,
          name: 'addProduct',
          builder: (context, state) => const AddProductPage(),
        ),
        GoRoute(
          path: AppRoutes.notifications,
          name: 'notifications',
          builder: (context, state) => const NotificationsPage(),
        ),
        GoRoute(
          path: AppRoutes.chatList,
          name: 'chatList',
          builder: (context, state) => const ChatListPage(),
        ),
        GoRoute(
          path: AppRoutes.chatDetail,
          name: 'chatDetail',
          builder: (context, state) {
            final chatId = state.pathParameters['id']!;
            return ChatDetailPage(chatId: chatId);
          },
        ),
        GoRoute(
          path: AppRoutes.profile,
          name: 'profile',
          builder: (context, state) => const ProfilePage(),
        ),
        GoRoute(
          path: AppRoutes.myProducts,
          name: 'myProducts',
          builder: (context, state) => const MyProductsPage(),
        ),
        GoRoute(
          path: AppRoutes.favorites,
          name: 'favorites',
          builder: (context, state) => const FavoritesPage(),
        ),
        GoRoute(
          path: AppRoutes.settings,
          name: 'settings',
          builder: (context, state) => const SettingsPage(),
        ),

        // Admin Routes
        GoRoute(
          path: AppRoutes.adminDashboard,
          name: 'adminDashboard',
          builder: (context, state) => const AdminDashboardPage(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Page not found: ${state.uri}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.landing),
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Provider for the router - reactive to auth state changes
final routerProvider = Provider<GoRouter>((ref) {
  // Watch auth state to make router reactive
  ref.watch(authProvider);

  return AppRouter.router(ref);
});

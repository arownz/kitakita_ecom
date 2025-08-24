import 'package:flutter/foundation.dart';
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
      debugLogDiagnostics: false,
      redirectLimit: 3,
      redirect: (context, state) {
        final authState = ref.read(authProvider);
        final isLoggedIn = authState.user != null;
        final userRole = authState.userRole;
        final hasError = authState.error != null;
        final isLoading = authState.isLoading;
        final currentLocation = state.matchedLocation;

        if (kDebugMode) {
          print(
            '🔍 Router redirect: isLoggedIn=$isLoggedIn, role=$userRole, location=$currentLocation, hasError=$hasError, isLoading=$isLoading',
          );
        }

        // Don't redirect if auth is loading
        if (isLoading) {
          if (kDebugMode) {
            print('⏳ Auth is loading, no redirect');
          }
          return null;
        }

        // CRITICAL: If there's an auth error, NEVER redirect anywhere
        if (hasError) {
          if (kDebugMode) {
            print(
              '🚨 AUTH ERROR DETECTED - NO REDIRECT ALLOWED - Error: ${authState.error}',
            );
          }
          // Force stay on current page - this prevents GoRouter from going to /
          return currentLocation;
        }

        // CRITICAL: If on login page, NEVER redirect to landing (regardless of error state)
        if (currentLocation == AppRoutes.login) {
          if (kDebugMode) {
            print('🚨 ON LOGIN PAGE - NO REDIRECT TO LANDING ALLOWED');
          }
          return null; // Stay on login page
        }

        // CRITICAL: If on register page, NEVER redirect to landing (regardless of error state)
        if (currentLocation == AppRoutes.register) {
          if (kDebugMode) {
            print('🚨 ON REGISTER PAGE - NO REDIRECT TO LANDING ALLOWED');
          }
          return null; // Stay on register page
        }

        // If logged in and on any auth page, redirect to appropriate home
        if (isLoggedIn) {
          if (currentLocation == AppRoutes.login ||
              currentLocation == AppRoutes.register ||
              currentLocation == AppRoutes.landing) {
            if (userRole == UserRole.admin) {
              if (kDebugMode) {
                print('👑 Admin logged in, redirecting to admin dashboard');
              }
              return AppRoutes.adminDashboard;
            } else {
              if (kDebugMode) {
                print('👨‍🎓 Student logged in, redirecting to home');
              }
              return AppRoutes.home;
            }
          }
        }

        // If not logged in and trying to access protected routes
        if (!isLoggedIn) {
          final protectedRoutes = [
            AppRoutes.home,
            AppRoutes.addProduct,
            AppRoutes.notifications,
            AppRoutes.chatList,
            AppRoutes.chatDetail,
            AppRoutes.profile,
            AppRoutes.myProducts,
            AppRoutes.favorites,
            AppRoutes.settings,
            AppRoutes.adminDashboard,
          ];

          if (protectedRoutes.any(
            (route) => currentLocation.startsWith(route.split(':')[0]),
          )) {
            if (kDebugMode) {
              print('🔒 Not logged in, redirecting to landing');
            }
            return AppRoutes.landing;
          }
        }

        // CRITICAL: If on any auth page and not logged in, NEVER redirect
        if (!isLoggedIn &&
            (currentLocation == AppRoutes.login ||
                currentLocation == AppRoutes.register ||
                currentLocation == AppRoutes.landing)) {
          if (kDebugMode) {
            print('🚨 ON AUTH PAGE AND NOT LOGGED IN - NO REDIRECT ALLOWED');
          }
          return null; // Stay on current auth page
        }

        // Admin trying to access student routes
        if (isLoggedIn && userRole == UserRole.admin) {
          final protectedStudentRoutes = [
            AppRoutes.home,
            AppRoutes.addProduct,
            AppRoutes.chatList,
            AppRoutes.profile,
            AppRoutes.myProducts,
            AppRoutes.favorites,
            AppRoutes.settings,
          ];

          if (protectedStudentRoutes.any(
            (route) => currentLocation.startsWith(route.split(':')[0]),
          )) {
            if (kDebugMode) {
              print(
                '👑 Admin trying to access student route, redirecting to admin dashboard',
              );
            }
            return AppRoutes.adminDashboard;
          }
        }

        // Student trying to access admin routes
        if (isLoggedIn && userRole == UserRole.student) {
          if (currentLocation.startsWith('/admin')) {
            if (kDebugMode) {
              print(
                '👨‍🎓 Student trying to access admin route, redirecting to home',
              );
            }
            return AppRoutes.home;
          }
        }

        if (kDebugMode) {
          print('✅ No redirect needed');
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
          builder: (context, state) => const ChatDetailPage(chatId: 'default'),
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
  // Watch auth state changes
  final authState = ref.watch(authProvider);

  if (kDebugMode) {
    print(
      '🔄 Router provider rebuilding: user=${authState.user?.email}, role=${authState.userRole}, hasError=${authState.error != null}',
    );
  }

  return AppRouter.router(ref);
});

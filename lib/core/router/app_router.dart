import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/viewmodels/auth_providers.dart';
import '../../features/auth/presentation/viewmodels/auth_state.dart';
import '../../features/auth/presentation/views/complete_profile_view.dart';
import '../../features/auth/presentation/views/forgot_password_view.dart';
import '../../features/auth/presentation/views/login_view.dart';
import '../../features/auth/presentation/views/register_view.dart';
import '../../features/auth/presentation/views/reset_password_view.dart';
import '../../features/auth/presentation/views/verify_otp_view.dart';
import '../../features/dashboard/presentation/views/permissions_view.dart';
import '../../features/home/data/models/home_dummy_data.dart';
import '../../features/home/presentation/views/category_list_view.dart';
import '../../features/home/presentation/views/category_products_view.dart';
import '../../features/home/presentation/views/home_view.dart';
import '../../features/home/presentation/views/product_detail_view.dart';
import '../../features/home/presentation/views/product_virtual_try_on_view.dart';
import '../../features/home/presentation/views/virtual_try_on_list_view.dart';
import '../../features/home/presentation/views/virtual_try_on_detail_view.dart';
import '../../features/location/presentation/viewmodels/location_providers.dart';
import '../../features/location/presentation/views/location_selection_view.dart';
import '../../features/onboarding/presentation/views/onboarding_view.dart';
import '../../features/onboarding/presentation/views/welcome_view.dart';
import '../../features/cart/presentation/views/cart_view.dart';
import '../../features/checkout/data/models/checkout_result_model.dart';
import '../../features/checkout/presentation/viewmodels/order_list_state.dart';
import '../../features/checkout/presentation/views/checkout_view.dart';
import '../../features/checkout/presentation/views/leave_review_view.dart';
import '../../features/checkout/presentation/views/order_detail_view.dart';
import '../../features/checkout/presentation/views/order_list_view.dart';
import '../../features/checkout/presentation/views/payment_success_view.dart';
import '../../features/checkout/presentation/views/shipping_address_selection_view.dart';
import '../../features/checkout/presentation/views/shipping_type_selection_view.dart';
import '../../features/checkout/presentation/views/track_order_view.dart';
import '../../features/checkout/presentation/views/upload_payment_proof_view.dart';
import '../../features/notification/presentation/views/notification_view.dart';
import '../../features/profile/presentation/views/help_center_view.dart';
import '../../features/profile/presentation/views/notification_settings_view.dart';
import '../../features/profile/presentation/views/password_manager_view.dart';
import '../../features/profile/presentation/views/privacy_policy_view.dart';
import '../../features/profile/presentation/views/profile_view.dart';
import '../../features/profile/presentation/views/settings_view.dart';
import '../../features/profile/presentation/views/your_profile_view.dart';
import '../../features/search/data/models/product_filter_model.dart';
import '../../features/search/presentation/views/filter_view.dart';
import '../../features/search/presentation/views/search_view.dart';
import '../../features/splash/presentation/views/splash_view.dart';
import '../../features/store/data/models/store_setting_model.dart';
import '../../features/store/presentation/views/store_detail_view.dart';
import '../../features/wishlist/presentation/views/wishlist_view.dart';
import '../storage/storage_providers.dart';

final routerKey = GlobalKey<NavigatorState>();

/// Provider GoRouter terintegrasi dengan Riverpod Auth State Guard
final routerProvider = Provider<GoRouter>((ref) {
  // Gunakan ref.read agar GoRouter tidak diinisialisasi ulang setiap ada perubahan auth state
  final authNotifier = ValueNotifier<AuthState>(ref.read(authViewModelProvider));

  ref.listen<AuthState>(authViewModelProvider, (previous, next) {
    authNotifier.value = next;
  });

  ref.onDispose(() {
    authNotifier.dispose();
  });

  return GoRouter(
    navigatorKey: routerKey,
    initialLocation: '/splash',
    refreshListenable: authNotifier,
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashView(),
      ),
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeView(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingView(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterView(),
      ),
      GoRoute(
        path: '/complete-profile',
        name: 'complete-profile',
        builder: (context, state) => const CompleteProfileView(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => ForgotPasswordView(
          initialEmail: state.extra as String?,
        ),
      ),
      GoRoute(
        path: '/verify-otp',
        name: 'verify-otp',
        builder: (context, state) {
          String email = '';
          String type = 'password_reset';

          if (state.extra is Map) {
            final map = state.extra as Map;
            email = map['email']?.toString() ?? '';
            type = map['type']?.toString() ?? 'password_reset';
          } else if (state.extra is String) {
            email = state.extra as String;
          } else {
            email = state.uri.queryParameters['email'] ?? '';
            type = state.uri.queryParameters['type'] ?? 'password_reset';
          }
          return VerifyOtpView(email: email, type: type);
        },
      ),
      GoRoute(
        path: '/reset-password',
        name: 'reset-password',
        builder: (context, state) {
          final extraMap = state.extra is Map ? (state.extra as Map) : null;
          final email = extraMap?['email']?.toString() ??
              state.uri.queryParameters['email'] ??
              '';
          final resetToken = extraMap?['reset_token']?.toString() ??
              extraMap?['resetToken']?.toString() ??
              state.uri.queryParameters['token'] ??
              state.uri.queryParameters['reset_token'] ??
              '';
          return ResetPasswordView(
            email: email,
            resetToken: resetToken,
          );
        },
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const HomeView(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeView(),
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) {
          final query = state.uri.queryParameters['q'] ??
              (state.extra is String ? state.extra as String : null);
          return SearchView(initialQuery: query);
        },
      ),
      GoRoute(
        path: '/filter',
        name: 'filter',
        builder: (context, state) => FilterView(
          initialFilter: state.extra as ProductFilter?,
        ),
      ),
      GoRoute(
        path: '/categories',
        name: 'categories',
        builder: (context, state) => const CategoryListView(),
      ),
      GoRoute(
        path: '/category-products',
        name: 'category-products',
        builder: (context, state) {
          final category = state.extra is ProductCategoryItem
              ? state.extra as ProductCategoryItem
              : ProductCategoryItem(
                  id: state.uri.queryParameters['id'] ?? 'all',
                  name: state.uri.queryParameters['name'] ?? 'Kategori Batik',
                  slug: state.uri.queryParameters['slug'] ?? '',
                  description: state.uri.queryParameters['description'] ?? '',
                );
          return CategoryProductsView(category: category);
        },
      ),
      GoRoute(
        path: '/product/:productId',
        name: 'product-detail',
        builder: (context, state) {
          final productId = state.pathParameters['productId'] ?? '';
          final initialProduct = state.extra is ProductItem
              ? state.extra as ProductItem
              : null;
          return ProductDetailView(
            productId: productId,
            initialProduct: initialProduct,
          );
        },
      ),
      GoRoute(
        path: '/product/:productId/try-on',
        name: 'product-try-on',
        builder: (context, state) {
          final productId = state.pathParameters['productId'] ?? '';
          final product = state.extra is ProductItem
              ? state.extra as ProductItem
              : ProductItem(
                  id: productId,
                  name: 'Produk Batik',
                  category: 'Batik',
                  discountedPrice: 0,
                  originalPrice: 0,
                  discountPercentage: 0,
                  rating: 5.0,
                  reviewCount: 0,
                  soldCount: 0,
                  placeholderColor: const Color(0xFF704F38),
                );
          return ProductVirtualTryOnView(product: product);
        },
      ),
      GoRoute(
        path: '/store/:storeId',
        name: 'store-detail',
        builder: (context, state) {
          final storeId =
              int.tryParse(state.pathParameters['storeId'] ?? '1') ?? 1;
          final initialStore = state.extra is StoreSettingModel
              ? state.extra as StoreSettingModel
              : null;
          return StoreDetailView(
            storeId: storeId,
            initialStore: initialStore,
          );
        },
      ),
      GoRoute(
        path: '/permissions',
        name: 'permissions',
        builder: (context, state) => const PermissionsView(),
      ),
      GoRoute(
        path: '/location',
        name: 'location',
        builder: (context, state) => const LocationSelectionView(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileView(),
      ),
      GoRoute(
        path: '/account',
        name: 'account',
        builder: (context, state) => const ProfileView(),
      ),
      GoRoute(
        path: '/your-profile',
        name: 'your-profile',
        builder: (context, state) => const YourProfileView(),
      ),
      GoRoute(
        path: '/wishlist',
        name: 'wishlist',
        builder: (context, state) => const WishlistView(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsView(),
      ),
      GoRoute(
        path: '/settings/notifications',
        name: 'notification-settings',
        builder: (context, state) => const NotificationSettingsView(),
      ),
      GoRoute(
        path: '/settings/password',
        name: 'password-manager',
        builder: (context, state) => const PasswordManagerView(),
      ),
      GoRoute(
        path: '/help-center',
        name: 'help-center',
        builder: (context, state) => const HelpCenterView(),
      ),
      GoRoute(
        path: '/privacy-policy',
        name: 'privacy-policy',
        builder: (context, state) => const PrivacyPolicyView(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationView(),
      ),
      GoRoute(
        path: '/cart',
        name: 'cart',
        builder: (context, state) => const CartView(),
      ),
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        builder: (context, state) => const CheckoutView(),
        routes: [
          GoRoute(
            path: 'shipping-address',
            name: 'shipping-address',
            builder: (context, state) => const ShippingAddressSelectionView(),
          ),
          GoRoute(
            path: 'shipping-type',
            name: 'shipping-type',
            builder: (context, state) => const ShippingTypeSelectionView(),
          ),
          GoRoute(
            path: 'success',
            name: 'payment-success',
            builder: (context, state) {
              final order = state.extra is CheckoutResultModel
                  ? (state.extra as CheckoutResultModel)
                  : null;
              final orderNumber = state.uri.queryParameters['order_number'];
              return PaymentSuccessView(
                order: order,
                orderNumber: orderNumber,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/orders',
        name: 'orders',
        builder: (context, state) {
          final initialTab = state.extra is OrderTabStatus
              ? state.extra as OrderTabStatus
              : null;
          return OrderListView(initialTab: initialTab);
        },
      ),
      GoRoute(
        path: '/orders/:orderNumber',
        name: 'order-detail',
        builder: (context, state) {
          final orderNumber = state.pathParameters['orderNumber'] ?? '';
          final order = state.extra is CheckoutResultModel
              ? (state.extra as CheckoutResultModel)
              : null;
          return OrderDetailView(
            orderNumber: orderNumber,
            initialOrder: order,
          );
        },
      ),
      GoRoute(
        path: '/orders/:orderNumber/track',
        name: 'track-order',
        builder: (context, state) {
          final orderNumber = state.pathParameters['orderNumber'] ?? '';
          final order = state.extra is CheckoutResultModel
              ? (state.extra as CheckoutResultModel)
              : null;
          return TrackOrderView(
            orderNumber: orderNumber,
            initialOrder: order,
          );
        },
      ),
      GoRoute(
        path: '/orders/:orderNumber/payment-proof',
        name: 'upload-payment-proof',
        builder: (context, state) {
          final orderNumber = state.pathParameters['orderNumber'] ?? '';
          final order = state.extra is CheckoutResultModel
              ? (state.extra as CheckoutResultModel)
              : null;
          return UploadPaymentProofView(
            orderNumber: orderNumber,
            order: order,
          );
        },
      ),
      GoRoute(
        path: '/orders/:orderNumber/review',
        name: 'leave-review',
        builder: (context, state) {
          final orderNumber = state.pathParameters['orderNumber'] ?? '';
          CheckoutResultModel? order;
          CheckoutOrderItemModel? targetItem;
          int? targetProductId = int.tryParse(
            state.uri.queryParameters['productId'] ?? '',
          );

          if (state.extra is CheckoutResultModel) {
            order = state.extra as CheckoutResultModel;
          } else if (state.extra is Map) {
            final map = state.extra as Map;
            if (map['order'] is CheckoutResultModel) {
              order = map['order'] as CheckoutResultModel;
            }
            if (map['item'] is CheckoutOrderItemModel) {
              targetItem = map['item'] as CheckoutOrderItemModel;
            }
            if (map['productId'] is int) {
              targetProductId = map['productId'] as int;
            }
          }

          return LeaveReviewView(
            orderNumber: orderNumber,
            initialOrder: order,
            targetItem: targetItem,
            targetProductId: targetProductId,
          );
        },
      ),
      GoRoute(
        path: '/virtual-try-ons',
        name: 'virtual-try-ons',
        builder: (context, state) => const VirtualTryOnListView(),
      ),
      GoRoute(
        path: '/virtual-try-ons/:id',
        name: 'virtual-try-on-detail',
        builder: (context, state) {
          final idStr = state.pathParameters['id'] ?? '';
          final tryOnId = int.tryParse(idStr) ?? 0;
          final initialTask = state.extra is VirtualTryOnTaskItem
              ? state.extra as VirtualTryOnTaskItem
              : null;
          return VirtualTryOnDetailView(
            tryOnId: tryOnId,
            initialTask: initialTask,
          );
        },
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authViewModelProvider);
      final storage = ref.read(localStorageServiceProvider);
      final isAuthenticated = authState.isAuthenticated;
      final hasCompletedOnboarding = storage.hasCompletedOnboarding();
      final isProfileComplete = authState.user?.isProfileComplete ?? true;

      final isSplash = state.matchedLocation == '/splash';
      final isWelcomeOrOnboarding = state.matchedLocation == '/welcome' ||
          state.matchedLocation == '/onboarding';
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/verify-otp' ||
          state.matchedLocation == '/reset-password';
      final isCompleteProfileRoute = state.matchedLocation == '/complete-profile';
      final isLocationRoute = state.matchedLocation == '/location';
      final isVerifyOtpRoute = state.matchedLocation == '/verify-otp';

      // Biarkan splash screen selesai menampilkan animasi logo sebelum bernavigasi
      if (isSplash) {
        return null;
      }

      // Rute pemilihan lokasi dan verifikasi OTP dapat diakses tanpa dipaksa redirect
      if (isLocationRoute || isVerifyOtpRoute) {
        return null;
      }

      // Jika belum login dan mencoba ke complete profile
      if (!isAuthenticated && isCompleteProfileRoute) {
        return '/login';
      }

      // Jika belum login dan sedang berada di halaman login/register, TETAP DI HALAMAN INI!
      if (!isAuthenticated && isAuthRoute) {
        return null;
      }

      // Jika belum login tapi sudah pernah onboarding, jangan tampilkan welcome/onboarding lagi
      if (!isAuthenticated && hasCompletedOnboarding && isWelcomeOrOnboarding) {
        return '/login';
      }

      // Jika belum selesai onboarding dan belum login (serta bukan di halaman login/register)
      if (!isAuthenticated && !hasCompletedOnboarding && !isWelcomeOrOnboarding && !isAuthRoute) {
        return '/welcome';
      }

      // Jika belum login dan mencoba mengakses rute internal
      if (!isAuthenticated && !isAuthRoute && !isWelcomeOrOnboarding) {
        return hasCompletedOnboarding ? '/login' : '/welcome';
      }

      // Jika sudah login:
      if (isAuthenticated) {
        // Jika profil belum lengkap:
        if (!isProfileComplete) {
          if (!isCompleteProfileRoute) {
            return '/complete-profile';
          }
          return null;
        }

        // Cek apakah user sudah memiliki lokasi tersimpan di cache
        final hasLocation =
            ref.read(locationRepositoryProvider).getCachedLocation() != null;

        // Jika profil sudah lengkap:
        if (isCompleteProfileRoute) {
          if (hasLocation) {
            ref.read(locationViewModelProvider.notifier).loadLocation();
            return '/dashboard';
          }
          return '/location';
        }

        // Jika berada di auth routes (/login, /register, dll):
        if (isAuthRoute || isWelcomeOrOnboarding) {
          if (hasLocation) {
            ref.read(locationViewModelProvider.notifier).loadLocation();
            return '/dashboard';
          }
          return '/location';
        }
      }

      return null;
    },
  );
});

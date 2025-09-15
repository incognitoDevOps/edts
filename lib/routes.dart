import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moderntr/main_layout.dart';
import 'package:moderntr/pages/ad_details.dart';
import 'package:moderntr/pages/boost_product.dart';
import 'package:moderntr/pages/category_listings.dart';
import 'package:moderntr/pages/chat_details.dart';
import 'package:moderntr/pages/chats.dart';
import 'package:moderntr/pages/create_product.dart';
import 'package:moderntr/pages/create_store.dart';
import 'package:moderntr/pages/edit-product.dart';
import 'package:moderntr/pages/faqs.dart';
import 'package:moderntr/pages/forgot_password.dart';
import 'package:moderntr/pages/homepage.dart';
import 'package:moderntr/pages/login.dart';
import 'package:moderntr/pages/my_account.dart';
import 'package:moderntr/pages/my_ads.dart';
import 'package:moderntr/pages/my_listings.dart';
import 'package:moderntr/pages/my_profile.dart';
import 'package:moderntr/pages/my_reviews.dart';
import 'package:moderntr/pages/pay_ad.dart';
import 'package:moderntr/pages/reset_password.dart';
import 'package:moderntr/pages/search.dart';
import 'package:moderntr/pages/signup.dart';
import 'package:moderntr/pages/product_details.dart';
import 'package:moderntr/pages/splash_screen.dart';
import 'package:moderntr/pages/store_settings.dart';
import 'package:moderntr/pages/verify_email.dart';
import 'package:moderntr/pages/wishlist.dart';
import 'package:moderntr/pages/payment_messages.dart';

GoRouter appRouter(String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            const LoginPage(), // Changed from LoginForm to LoginPage
      ),
      GoRoute(
        path: '/sign-up',
        builder: (context, state) =>
            const SignUpPage(), // Changed from RegisterForm to SignUpPage
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          final queryParams = state.uri.queryParameters;
          return VerifyEmailPage(
            uid: queryParams['uid'],
            token: queryParams['token'],
          );
        },
      ),

      // Add these routes to your existing routes
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final queryParams = state.uri.queryParameters;
          return ResetPasswordPage(
            uid: queryParams['uid']!,
            token: queryParams['token']!,
          );
        },
      ),
 
      // ShellRoute for pages with bottom navigation
      ShellRoute(
        builder: (context, state, child) {
          return MainLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/category-listing',
            builder: (context, state) => const CategoryListings(),
          ),
          GoRoute(
            path: '/product-details',
            builder: (context, state) {
              final product = state.extra as Map<String, dynamic>;
              return ProductDetailsPage(product: product);
            },
          ),
          GoRoute(
            path: '/wishlist',
            builder: (context, state) => const WishlistPage(),
          ),
          GoRoute(
            path: '/create-product',
            builder: (context, state) => const CreateProductPage(),
          ),
          GoRoute(
            path: '/edit-product',
            builder: (context, state) => EditProductPage(
              product: state.extra as Map<String, dynamic>,
            ),
          ),
          GoRoute(
            path: '/create-store',
            builder: (context, state) => const CreateStorePage(),
          ),
          GoRoute(
            path: "/promote",
            builder: (context, state) {
              final args = state.extra as Map<String, dynamic>;
              return PromoteProductWidget(
                productId: args["productId"],
                productName: args["productName"],
              );
            },
          ),
          GoRoute(
            path: "/pay-ad",
            builder: (context, state) {
              final args = state.extra as Map<String, dynamic>;
              return PayAd(
                adId: args["ad_id"],
              );
            },
          ),
          GoRoute(
            path: '/payment-success',
            builder: (context, state) => const PaymentSuccessPage(),
          ),
          GoRoute(
            path: '/payment-failed',
            builder: (context, state) => const PaymentFailedPage(),
          ),
          GoRoute(
            path: '/account',
            builder: (context, state) => const MyAccountPage(),
          ),
          GoRoute(
            path: '/my-profile',
            builder: (context, state) => const MyProfilePage(),
          ),
          GoRoute(
            path: '/my-listings',
            builder: (context, state) => const MyListingsPage(),
          ),
          GoRoute(
            path: '/store-settings',
            builder: (context, state) => const StoreSettingsPage(),
          ),
          GoRoute(
            path: '/my-ads',
            builder: (context, state) => const MyAdsPage(),
          ),
          GoRoute(
            path: '/ad-details',
            builder: (context, state) {
              final ad = state.extra as Map<String, dynamic>?;
              if (ad == null) {
                return const Scaffold(
                  body: Center(child: Text("Error: No Ad Data Found")),
                );
              }
              return AdDetailsPage(adId: ad["ad_id"].toString());
            },
          ),
          GoRoute(
            path: '/reviews',
            builder: (context, state) => const MyReviewsPage(),
          ),
          GoRoute(
            path: '/chats',
            builder: (context, state) => const MyChatsPage(),
          ),
          GoRoute(
            path: '/chat-details',
            builder: (context, state) => const ChatDetailsPage(),
          ),
          GoRoute(
            path: '/search-results',
            builder: (context, state) {
              final searchQuery = state.uri.queryParameters['q'] ?? '';
              return SearchResultsPage(searchQuery: searchQuery);
            },
          ),
          GoRoute(
            path: '/faqs',
            builder: (context, state) => const FAQsPage(),
          ),
        ],
      ),
    ],
  );
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/onboarding_provider.dart';
import '../../presentation/providers/user_profile_provider.dart';
import '../../presentation/providers/subscription_provider.dart';

import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/signup_screen.dart';
import '../../presentation/screens/auth/otp_verification_screen.dart';
import '../../presentation/screens/auth/change_password_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/pos/pos_screen.dart';
import '../../presentation/screens/products/products_screen.dart';
import '../../presentation/screens/products/add_product_screen.dart';
import '../../presentation/screens/products/edit_product_screen.dart';
import '../../presentation/screens/products/barcode_scanner_screen.dart';
import '../../data/models/product.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/team/team_screen.dart';
import '../../presentation/screens/team/ranking_screen.dart';
import '../../presentation/screens/customers/customers_screen.dart';
import '../../presentation/screens/financial/balance_hub_screen.dart';
import '../../presentation/screens/financial/balance_light_screen.dart';
import '../../presentation/screens/financial/balance_medium_screen.dart';
import '../../presentation/screens/financial/balance_full_screen.dart';
import '../../presentation/screens/debts/debts_hub_screen.dart';
import '../../presentation/screens/paywall/paywall_screen.dart';
import '../../presentation/widgets/owner_shell.dart';
import '../../presentation/widgets/employee_shell.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (previous, next) {
      final prevUser = previous?.value?.session?.user.id;
      final nextUser = next.value?.session?.user.id;
      
      if (prevUser != nextUser) {
        // Ao deslogar ou trocar de conta, invalida perfil e subscription
        _ref.invalidate(userProfileProvider);
        _ref.invalidate(subscriptionProvider);
      }
      notifyListeners();
    });
    _ref.listen(onboardingCompleteProvider, (_, _) => notifyListeners());
    _ref.listen(userProfileProvider, (_, _) => notifyListeners());
    _ref.listen(subscriptionProvider, (_, _) => notifyListeners());
  }
}

final _routerNotifierProvider = Provider((ref) {
  return RouterNotifier(ref);
});

// Chaves de navegação para cada branch
final _homeNavKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _productsNavKey = GlobalKey<NavigatorState>(debugLabel: 'products');
final _teamNavKey = GlobalKey<NavigatorState>(debugLabel: 'team');
final _profileNavKey = GlobalKey<NavigatorState>(debugLabel: 'profile');
final _posNavKey = GlobalKey<NavigatorState>(debugLabel: 'pos');
final _customersNavKey = GlobalKey<NavigatorState>(debugLabel: 'customers');
final _empProfileNavKey = GlobalKey<NavigatorState>(debugLabel: 'emp_profile');
final _balanceNavKey = GlobalKey<NavigatorState>(debugLabel: 'balance');

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_routerNotifierProvider);

  return GoRouter(
    refreshListenable: notifier,
    initialLocation: '/',
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final onboardingComplete = ref.read(onboardingCompleteProvider);
      final profileAsync = ref.read(userProfileProvider);

      if (authState.isLoading) return null;

      final session = authState.value?.session;
      final isAuth = session != null;

      final isGoingToAuth = state.matchedLocation == '/auth/login' ||
          state.matchedLocation == '/auth/signup' ||
          state.matchedLocation == '/auth/otp';
      final isGoingToOnboarding = state.matchedLocation == '/onboarding';
      final isGoingToChangePassword = state.matchedLocation == '/auth/change-password';
      final isSplash = state.matchedLocation == '/';

      if (!onboardingComplete && !isGoingToOnboarding) {
        return '/onboarding';
      }

      if (onboardingComplete && !isAuth && !isGoingToAuth) {
        return '/auth/login';
      }

      if (isAuth && (isGoingToAuth || isGoingToOnboarding || isSplash)) {
        // Se o perfil ainda estiver carregando, fica ou vai para o splash
        if (profileAsync.isLoading) {
          return '/';
        }

        // Verifica se precisa trocar senha
        final profile = profileAsync.value;
        if (profile?.mustChangePassword == true && !isGoingToChangePassword) {
          return '/auth/change-password';
        }

        // Direciona por role
        if (profile?.isEmployee == true) {
          return '/pos';
        }
        return '/home';
      }

      // Se logado e precisa trocar senha
      if (isAuth) {
        final profile = profileAsync.value;
        if (profile?.mustChangePassword == true && !isGoingToChangePassword) {
          return '/auth/change-password';
        }

        // Guard de subscription: bloqueia acesso se trial/assinatura expirou
        final isGoingToPaywall = state.matchedLocation == '/paywall';
        if (!isGoingToPaywall && profile != null) {
          final subAsync = ref.read(subscriptionProvider);
          final sub = subAsync.value;
          if (sub != null && sub.isExpired) {
            return '/paywall';
          }
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/auth/otp',
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return OtpVerificationScreen(phone: phone);
        },
      ),
      GoRoute(
        path: '/auth/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),

      // ── Paywall ──
      GoRoute(
        path: '/paywall',
        builder: (context, state) => const PaywallScreen(),
      ),

      // ── Owner Shell (ADMIN_EMPRESA) ──
      // 4 abas: Início, Produtos, Equipe, Perfil
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return OwnerShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _homeNavKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _productsNavKey,
            routes: [
              GoRoute(
                path: '/products',
                builder: (context, state) => const ProductsScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (context, state) {
                      final barcode = state.extra as String?;
                      return AddProductScreen(initialBarcode: barcode);
                    },
                  ),
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) {
                      final product = state.extra as Product;
                      return EditProductScreen(product: product);
                    },
                  ),
                  GoRoute(
                    path: 'scanner',
                    builder: (context, state) => const BarcodeScannerScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _teamNavKey,
            routes: [
              GoRoute(
                path: '/team',
                builder: (context, state) => const TeamScreen(),
                routes: [
                  GoRoute(
                    path: 'ranking',
                    builder: (context, state) => const RankingScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _balanceNavKey,
            routes: [
              GoRoute(
                path: '/balance',
                builder: (context, state) => const BalanceHubScreen(),
                routes: [
                  GoRoute(
                    path: 'light',
                    builder: (context, state) => const BalanceLightScreen(),
                  ),
                  GoRoute(
                    path: 'medium',
                    builder: (context, state) => const BalanceMediumScreen(),
                  ),
                  GoRoute(
                    path: 'full',
                    builder: (context, state) => const BalanceFullScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _profileNavKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // ── Employee Shell (FUNCIONARIO) ──
      // 3 abas: Vender, Clientes, Perfil
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return EmployeeShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _posNavKey,
            routes: [
              GoRoute(
                path: '/pos',
                builder: (context, state) => const PosScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _customersNavKey,
            routes: [
              GoRoute(
                path: '/customers',
                builder: (context, state) => const CustomersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _empProfileNavKey,
            routes: [
              GoRoute(
                path: '/emp-profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // ── Rotas Standalone ──
      GoRoute(
        path: '/debts',
        builder: (context, state) => const DebtsHubScreen(),
      ),
      GoRoute(
        path: '/owner-pos',
        builder: (context, state) => const PosScreen(),
      ),
    ],
  );
});

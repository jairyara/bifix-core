import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/home/presentation/dashboard_screen.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/maintenance/presentation/maintenance_screen.dart';
import '../../features/onboarding/presentation/daily_profile_setup_screen.dart';
import '../../features/onboarding/presentation/mode_selection_screen.dart';
import '../../features/preferences/application/preferences_controller.dart';
import '../../features/profile/presentation/bike_form_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/rides/presentation/rides_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/tracking/presentation/tracking_screen.dart';

/// App routes as constants to avoid stringly-typed navigation.
abstract class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const home = '/';
  static const rides = '/rides';
  static const maintenance = '/maintenance';
  static const profile = '/profile';
  static const addBike = '/profile/bike/new';
  static const editBike = '/profile/bike/edit';
  static const onboarding = '/onboarding';
  static const onboardingEstimation = '/onboarding/estimacion';
  static const tracking = '/tracking';
  static const settings = '/profile/settings';
}

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  // Rebuild routing decisions whenever the auth session changes.
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;
      final atSplash = loc == Routes.splash;
      final atAuth = loc == Routes.login || loc == Routes.register;
      final atOnboarding =
          loc == Routes.onboarding || loc == Routes.onboardingEstimation;

      // Still restoring the persisted session: stay on splash.
      if (auth.isLoading && !auth.hasValue) {
        return atSplash ? null : Routes.splash;
      }

      final loggedIn = auth.valueOrNull != null;
      if (!loggedIn) return atAuth ? null : Routes.login;

      // Logged in: wait for preferences to resolve before deciding onboarding.
      final prefs = ref.read(preferencesControllerProvider);
      if (prefs.isLoading && !prefs.hasValue) {
        return atSplash ? null : Routes.splash;
      }

      // First-run users must choose a riding mode before entering the app.
      final needsOnboarding = prefs.valueOrNull?.needsOnboarding ?? false;
      if (needsOnboarding && !atOnboarding) return Routes.onboarding;

      // Onboarded user sitting on an entry screen → go to the app.
      if (!needsOnboarding && (atAuth || atSplash)) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.onboarding,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const ModeSelectionScreen(),
      ),
      GoRoute(
        path: Routes.onboardingEstimation,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const DailyProfileSetupScreen(),
      ),
      GoRoute(
        path: Routes.tracking,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const TrackingScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: Routes.addBike,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const BikeFormScreen(),
      ),
      GoRoute(
        path: Routes.editBike,
        parentNavigatorKey: _rootKey,
        builder: (context, state) =>
            BikeFormScreen(bikeId: state.uri.queryParameters['id']),
      ),
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: Routes.home,
            pageBuilder: (_, _) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: Routes.rides,
            pageBuilder: (_, _) => const NoTransitionPage(
              child: RidesScreen(),
            ),
          ),
          GoRoute(
            path: Routes.maintenance,
            pageBuilder: (_, _) => const NoTransitionPage(
              child: MaintenanceScreen(),
            ),
          ),
          GoRoute(
            path: Routes.profile,
            pageBuilder: (_, _) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});

/// Bridges Riverpod's session providers to a [Listenable] GoRouter can refresh
/// on. Listens to both auth and preferences so the onboarding gate reacts.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    _subs = [
      ref.listen(authControllerProvider, (_, _) => notifyListeners()),
      ref.listen(preferencesControllerProvider, (_, _) => notifyListeners()),
    ];
  }

  late final List<ProviderSubscription> _subs;

  @override
  void dispose() {
    for (final s in _subs) {
      s.close();
    }
    super.dispose();
  }
}

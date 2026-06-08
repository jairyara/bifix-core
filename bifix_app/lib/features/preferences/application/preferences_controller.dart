import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../auth/application/auth_controller.dart';
import '../domain/riding_mode.dart';

/// Loads and mutates the current user's [UserPreferences]. Rebuilds whenever the
/// auth session changes so preferences follow login/logout.
class PreferencesController extends AsyncNotifier<UserPreferences> {
  @override
  Future<UserPreferences> build() async {
    final user = ref.watch(authControllerProvider).valueOrNull;
    if (user == null) return UserPreferences.empty;
    return ref.watch(preferencesRepositoryProvider).get();
  }

  Future<void> setMode(RidingMode mode) async {
    final repo = ref.read(preferencesRepositoryProvider);
    final current = state.valueOrNull ?? UserPreferences.empty;
    final saved = await repo.save(current.copyWith(ridingMode: mode));
    state = AsyncValue.data(saved);
  }

  Future<void> setDailyProfile(DailyEstimateProfile profile) async {
    final repo = ref.read(preferencesRepositoryProvider);
    final current = state.valueOrNull ?? UserPreferences.empty;
    final saved = await repo.save(current.copyWith(dailyProfile: profile));
    state = AsyncValue.data(saved);
  }

  /// Used by onboarding when the user picks estimation: set mode + profile atomically.
  Future<void> completeEstimationOnboarding(
      DailyEstimateProfile profile) async {
    final repo = ref.read(preferencesRepositoryProvider);
    final saved = await repo.save(UserPreferences(
      ridingMode: RidingMode.estimation,
      dailyProfile: profile,
    ));
    state = AsyncValue.data(saved);
  }
}

final preferencesControllerProvider =
    AsyncNotifierProvider<PreferencesController, UserPreferences>(
        PreferencesController.new);

/// Current riding mode, or null while loading / not chosen.
final ridingModeProvider = Provider<RidingMode?>((ref) {
  return ref.watch(preferencesControllerProvider).valueOrNull?.ridingMode;
});

/// True when the user is logged in but has not chosen a riding mode yet.
final needsOnboardingProvider = Provider<bool>((ref) {
  final loggedIn = ref.watch(authControllerProvider).valueOrNull != null;
  if (!loggedIn) return false;
  final prefs = ref.watch(preferencesControllerProvider);
  // Only force onboarding once preferences have resolved.
  final value = prefs.valueOrNull;
  if (value == null) return false;
  return value.needsOnboarding;
});

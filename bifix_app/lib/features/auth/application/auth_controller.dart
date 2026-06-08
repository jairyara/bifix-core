import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/user.dart';

/// Holds the authenticated [User] (or null when signed out).
///
/// `build` restores any persisted session on startup, so the router can decide
/// between the auth flow and the app shell.
class AuthController extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    final repo = ref.watch(authRepositoryProvider);
    return repo.currentUser();
  }

  bool get isAuthenticated => state.valueOrNull != null;

  /// Throws [AppFailure] on bad credentials; the screen catches and shows it.
  /// We avoid flipping global state to loading so the router doesn't bounce.
  Future<void> login({required String email, required String password}) async {
    final repo = ref.read(authRepositoryProvider);
    final session = await repo.login(email: email, password: password);
    state = AsyncValue.data(session.user);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    final session = await repo.register(
      name: name,
      email: email,
      password: password,
      phone: phone,
    );
    state = AsyncValue.data(session.user);
  }

  Future<void> updateProfile(User user) async {
    final repo = ref.read(authRepositoryProvider);
    final updated = await repo.updateProfile(user);
    state = AsyncValue.data(updated);
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AsyncValue.data(null);
  }

  Future<void> requestPasswordReset(String email) {
    return ref.read(authRepositoryProvider).requestPasswordReset(email);
  }

  Future<void> deleteAccount() async {
    await ref.read(authRepositoryProvider).deleteAccount();
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, User?>(AuthController.new);

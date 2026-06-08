import '../../../core/error/failures.dart';
import '../../../core/mock/mock_store.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/user.dart';

/// Contract the rest of the app codes against. Swappable mock/HTTP impls.
abstract class AuthRepository {
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  });

  Future<AuthSession> login({
    required String email,
    required String password,
  });

  /// Returns the current user if a valid session exists, else null.
  Future<User?> currentUser();

  Future<User> updateProfile(User user);

  Future<void> logout();

  /// Requests a password reset for [email]. Always resolves without revealing
  /// whether the email exists (anti-enumeration).
  Future<void> requestPasswordReset(String email);

  /// Permanently deletes the current user's account and clears the session.
  Future<void> deleteAccount();
}

/// Talks to the real external API. Endpoints below are the agreed contract the
/// parallel backend should implement.
class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository(this._client, this._tokenStorage);

  final ApiClient _client;
  final TokenStorage _tokenStorage;

  @override
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final json = await _client.post('/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
      'phone': ?phone,
    });
    final session = AuthSession.fromJson(json);
    await _tokenStorage.write(session.token);
    return session;
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final json = await _client.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    final session = AuthSession.fromJson(json);
    await _tokenStorage.write(session.token);
    return session;
  }

  @override
  Future<User?> currentUser() async {
    final token = await _tokenStorage.read();
    if (token == null || token.isEmpty) return null;
    try {
      final json = await _client.get('/auth/me');
      return User.fromJson(json);
    } on AppFailure catch (e) {
      if (e.isUnauthorized) {
        await _tokenStorage.clear();
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<User> updateProfile(User user) async {
    final json = await _client.put('/auth/me', body: user.toJson());
    return User.fromJson(json);
  }

  @override
  Future<void> logout() => _tokenStorage.clear();

  @override
  Future<void> requestPasswordReset(String email) async {
    // Endpoint pending backend; shape follows the agreed contract.
    await _client.post('/auth/forgot-password', body: {'email': email});
  }

  @override
  Future<void> deleteAccount() async {
    await _client.delete('/auth/me');
    await _tokenStorage.clear();
  }
}

/// In-memory implementation backed by [MockStore].
class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._tokenStorage);

  final TokenStorage _tokenStorage;
  final MockStore _store = MockStore.instance;

  // A trivial token format: "mock:<userId>".
  Future<AuthSession> _sessionFor(User user) async {
    final token = 'mock:${user.id}';
    await _tokenStorage.write(token);
    return AuthSession(token: token, user: user);
  }

  @override
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (_store.emailExists(email)) {
      throw const AppFailure('Ya existe una cuenta con ese correo.');
    }
    final user = _store.createAccount(
      name: name,
      email: email,
      password: password,
      phone: phone,
    );
    return _sessionFor(user);
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final user = _store.authenticate(email, password);
    if (user == null) {
      throw const AppFailure('Correo o contraseña incorrectos.');
    }
    return _sessionFor(user);
  }

  @override
  Future<User?> currentUser() async {
    final token = await _tokenStorage.read();
    if (token == null || !token.startsWith('mock:')) return null;
    final userId = token.substring('mock:'.length);
    return _store.userById(userId);
  }

  @override
  Future<User> updateProfile(User user) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _store.updateUser(user.id, user);
  }

  @override
  Future<void> logout() => _tokenStorage.clear();

  @override
  Future<void> requestPasswordReset(String email) async {
    // Simulate the email send; never reveal whether the account exists.
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> deleteAccount() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final token = await _tokenStorage.read();
    if (token != null && token.startsWith('mock:')) {
      _store.deleteAccount(token.substring('mock:'.length));
    }
    await _tokenStorage.clear();
  }
}

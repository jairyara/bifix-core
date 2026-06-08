import '../../../core/mock/mock_store.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/riding_mode.dart';

/// Reads and writes the current user's [UserPreferences] (riding mode + daily
/// estimate profile). The user is inferred from the auth token.
abstract class PreferencesRepository {
  Future<UserPreferences> get();
  Future<UserPreferences> save(UserPreferences prefs);
}

class HttpPreferencesRepository implements PreferencesRepository {
  HttpPreferencesRepository(this._client);
  final ApiClient _client;

  @override
  Future<UserPreferences> get() async {
    final json = await _client.get('/me/preferences');
    return UserPreferences.fromJson(json);
  }

  @override
  Future<UserPreferences> save(UserPreferences prefs) async {
    final json = await _client.put('/me/preferences', body: prefs.toJson());
    return UserPreferences.fromJson(json);
  }
}

class MockPreferencesRepository implements PreferencesRepository {
  MockPreferencesRepository(this._tokenStorage);

  final TokenStorage _tokenStorage;
  final MockStore _store = MockStore.instance;

  // Tokens are formatted "mock:<userId>" by MockAuthRepository.
  Future<String?> _userId() async {
    final token = await _tokenStorage.read();
    if (token == null || !token.startsWith('mock:')) return null;
    return token.substring('mock:'.length);
  }

  @override
  Future<UserPreferences> get() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final id = await _userId();
    if (id == null) return UserPreferences.empty;
    return _store.preferencesFor(id);
  }

  @override
  Future<UserPreferences> save(UserPreferences prefs) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final id = await _userId();
    if (id == null) return prefs;
    return _store.savePreferences(id, prefs);
  }
}

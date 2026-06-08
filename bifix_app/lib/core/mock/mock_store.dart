import '../../features/auth/domain/user.dart';
import '../../features/maintenance/domain/maintenance.dart';
import '../../features/preferences/domain/riding_mode.dart';
import '../../features/profile/domain/bike.dart';
import '../../features/rides/domain/ride.dart';

/// In-memory backend used while the real API is being built in parallel.
///
/// A single shared instance keeps users, bikes, rides and maintenance records
/// consistent across the mock repositories. Seeded with demo data so the app
/// has something to show on first run.
class MockStore {
  MockStore._() {
    _seed();
  }

  static final MockStore instance = MockStore._();

  int _idSeq = 100;
  String nextId(String prefix) => '$prefix-${_idSeq++}';

  final List<_Account> _accounts = [];
  final List<Bike> bikes = [];
  final List<Ride> rides = [];
  final List<MaintenanceRecord> records = [];
  final List<MaintenanceTask> tasks = List.of(defaultMaintenanceTasks);

  /// Preferences keyed by userId. Missing entry ⇒ user must complete onboarding.
  final Map<String, UserPreferences> _preferences = {};

  void _seed() {
    final user = User(
      id: 'user-1',
      name: 'Ciclista Demo',
      email: 'demo@vikla.app',
      phone: '+57 300 000 0000',
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
    );
    _accounts.add(_Account(user: user, password: 'demo1234'));

    // Demo user starts in privacy/estimation mode with a recurring profile so
    // the dashboard shows odometer accrual out of the box.
    _preferences[user.id] = UserPreferences(
      ridingMode: RidingMode.estimation,
      dailyProfile: DailyEstimateProfile(
        dailyKm: 12,
        activeWeekdays: const {1, 2, 3, 4, 5},
        since: DateTime.now().subtract(const Duration(days: 30)),
      ),
    );

    final bike = Bike(
      id: 'bike-1',
      name: 'Mi e-bike',
      brand: 'Specialized',
      model: 'Turbo Vado',
      year: 2024,
      batteryWh: 710,
      baselineKm: 320,
      purchaseDate: DateTime.now().subtract(const Duration(days: 110)),
    );
    bikes.add(bike);

    final now = DateTime.now();
    rides.addAll([
      Ride(
        id: 'ride-1',
        bikeId: bike.id,
        title: 'Casa → Oficina',
        date: now.subtract(const Duration(days: 1)),
        distanceKm: 12.4,
        durationMinutes: 35,
      ),
      Ride(
        id: 'ride-2',
        bikeId: bike.id,
        title: 'Paseo dominical',
        date: now.subtract(const Duration(days: 3)),
        distanceKm: 28.0,
        durationMinutes: 90,
      ),
      Ride(
        id: 'ride-3',
        bikeId: bike.id,
        title: 'Vuelta al parque',
        date: now.subtract(const Duration(days: 6)),
        distanceKm: 8.2,
        durationMinutes: 25,
      ),
    ]);

    records.add(
      MaintenanceRecord(
        id: 'rec-1',
        bikeId: bike.id,
        taskId: 'brakes',
        date: now.subtract(const Duration(days: 40)),
        odometerKm: 300,
        notes: 'Cambio de pastillas delanteras.',
      ),
    );
  }

  /// Total odometer for a bike: baseline + sum of estimated rides.
  double odometerFor(String bikeId) {
    final bike = bikes.firstWhere((b) => b.id == bikeId);
    final ridden = rides
        .where((r) => r.bikeId == bikeId)
        .fold<double>(0, (sum, r) => sum + r.distanceKm);
    return bike.baselineKm + ridden;
  }

  _Account? _accountByEmail(String email) {
    final lower = email.toLowerCase().trim();
    for (final a in _accounts) {
      if (a.user.email.toLowerCase() == lower) return a;
    }
    return null;
  }

  // --- Auth operations (kept here so _Account stays encapsulated) ---

  /// Returns the user for valid credentials, or null otherwise.
  User? authenticate(String email, String password) {
    final account = _accountByEmail(email);
    if (account == null || account.password != password) return null;
    return account.user;
  }

  bool emailExists(String email) => _accountByEmail(email) != null;

  User? userById(String userId) {
    for (final a in _accounts) {
      if (a.user.id == userId) return a.user;
    }
    return null;
  }

  /// Creates and stores a new account, returning its user.
  User createAccount({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) {
    final user = User(
      id: nextId('user'),
      name: name.trim(),
      email: email.trim(),
      phone: phone,
      createdAt: DateTime.now(),
    );
    _accounts.add(_Account(user: user, password: password));
    return user;
  }

  /// Replaces the stored user for [userId] and returns the updated copy.
  User updateUser(String userId, User updated) {
    for (final a in _accounts) {
      if (a.user.id == userId) {
        a.user = updated;
        return updated;
      }
    }
    return updated;
  }

  // --- Preferences ---

  UserPreferences preferencesFor(String userId) =>
      _preferences[userId] ?? UserPreferences.empty;

  UserPreferences savePreferences(String userId, UserPreferences prefs) {
    _preferences[userId] = prefs;
    return prefs;
  }
}

class _Account {
  _Account({required this.user, required this.password});
  User user;
  String password;
}

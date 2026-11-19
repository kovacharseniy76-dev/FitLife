import '../models/models.dart';
import 'backend.dart';

/// Сервіс автентифікації (клас AuthService з діаграми класів).
/// Реалізує сценарій «Увійти в систему» з діаграм кооперації та послідовності.
class AuthService {
  AuthService(this._backend);

  final FitLifeBackend _backend;

  String? currentUserId;

  Future<Account> signUp(String email, String password, {String name = ''}) async {
    final uid = await _backend.createCredentials(email.trim(), password);
    final user = User(id: uid, email: email.trim(), name: name.trim());
    user.register();
    await _backend.saveAccount(user);
    currentUserId = uid;
    return user;
  }

  /// 1: signIn → 1.1 verifyCredentials → 1.2 loadAccount → 1.3 isActive →
  /// [isActive] 1.4 getDisplayName, інакше — «акаунт заблоковано».
  Future<Account> signIn(String email, String password) async {
    final uid = await _backend.verifyCredentials(email.trim(), password);
    final account = await _backend.loadAccount(uid);
    if (account == null) {
      await _backend.signOut();
      throw AuthException('Профіль користувача не знайдено');
    }
    if (!account.isActive()) {
      await _backend.signOut();
      throw AuthException('Акаунт заблоковано. Зверніться до адміністратора.');
    }
    currentUserId = uid;
    SystemLog.instance.add('Вхід: ${account.getDisplayName()} (${account.roleName})');
    return account;
  }

  Future<void> signOut() async {
    await _backend.signOut();
    currentUserId = null;
  }

  Future<void> sendPasswordReset(String email) => _backend.sendPasswordReset(email.trim());
}

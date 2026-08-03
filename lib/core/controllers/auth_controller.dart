import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isCheckingAuth = true;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  UserModel? _currentUser;
  String? _token;
  String? _errorMessage;
  String? _successMessage;

  bool get isCheckingAuth => _isCheckingAuth;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  bool get isInactiveUserError => 
      _errorMessage != null && _errorMessage!.toLowerCase().contains('usuario inactivo');

  AuthController() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    _isCheckingAuth = true;
    notifyListeners();

    // En inicio, por seguridad no hay sesión activa por defecto hasta que el usuario se loguee
    _isAuthenticated = false;
    _currentUser = null;
    _isCheckingAuth = false;
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(username, password);
      _currentUser = result.user;
      _token = result.token;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isAuthenticated = false;
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Ocurrió un error insospechado durante el inicio de sesión.';
      _isAuthenticated = false;
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final user = await _authService.register(username, email, password);
      _successMessage = '¡Registro exitoso! Ya puedes iniciar sesión con tu cuenta.';
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error insospechado durante el registro.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> forgotPassword(String username, String email) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final msg = await _authService.forgotPassword(username, email);
      _successMessage = msg;
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error insospechado al procesar la solicitud.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    _token = null;
    _isAuthenticated = false;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}

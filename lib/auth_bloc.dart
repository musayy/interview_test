import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:local_auth/local_auth.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LocalAuthentication _localAuth = LocalAuthentication();

  AuthBloc() : super(AuthInitial()) {
    on<CheckBiometricSupport>(_onCheckBiometricSupport);
    on<AuthenticateWithBiometrics>(_onAuthenticateWithBiometrics);
    on<ValidatePassword>(_onValidatePassword);
  }

  Future<void> _onCheckBiometricSupport(
      CheckBiometricSupport event, Emitter<AuthState> emit) async {
    bool canCheckBiometrics;
    List<BiometricType> availableBiometrics = [];
    try {
      canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (canCheckBiometrics) {
        availableBiometrics = await _localAuth.getAvailableBiometrics();
      }
    } catch (e) {
      canCheckBiometrics = false;
    }
    if (canCheckBiometrics && availableBiometrics.isNotEmpty) {
      emit(AuthInitial());
    } else {
      emit(BiometricNotAvailable());
    }
  }

  Future<void> _onAuthenticateWithBiometrics(
      AuthenticateWithBiometrics event, Emitter<AuthState> emit) async {
    bool isAuthenticated = false;
    try {
      isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to proceed',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      emit(AuthFailure('Error during authentication: $e'));
    }

    if (isAuthenticated) {
      emit(AuthSuccess('Biometric Authentication Successful'));
    } else {
      emit(AuthFailure('Biometric Authentication Failed'));
    }
  }

  Future<void> _onValidatePassword(
      ValidatePassword event, Emitter<AuthState> emit) async {
    final String apiUrl =
        'http://brownonions-002-site1.ftempurl.com/api/ChefRegister/ValidateChefPassword';
    final Map<String, String> queryParams = {
      'ChefId': '3',
      'CurrentPassword': '123',
      'APIKey': 'mobileapi19042024',
    };
    final Uri url = Uri.parse(apiUrl).replace(queryParameters: queryParams);

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        emit(AuthSuccess('Password validation successful: ${data.toString()}'));
      } else {
        emit(AuthFailure(
            'Failed to validate password: ${response.reasonPhrase}'));
      }
    } catch (e) {
      emit(AuthFailure('Error during password validation: $e'));
    }
  }
}

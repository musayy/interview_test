import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Authentication App',
      home: AuthScreen(),
    );
  }
}

abstract class AuthEvent {}

class CheckBiometricSupport extends AuthEvent {}

class AuthenticateWithBiometrics extends AuthEvent {}

class ValidatePassword extends AuthEvent {}

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String message;
  AuthSuccess(this.message);
}

class AuthFailure extends AuthState {
  final String error;
  AuthFailure(this.error);
}

class BiometricNotAvailable extends AuthState {}

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
    emit(AuthLoading());
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
      return;
    }

    if (isAuthenticated) {
      emit(AuthSuccess('Biometric Authentication Successful'));
      add(ValidatePassword());
    } else {
      emit(AuthFailure('Biometric Authentication Failed'));
    }
  }

  Future<void> _onValidatePassword(
      ValidatePassword event, Emitter<AuthState> emit) async {
    const String apiUrl =
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

class AuthScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc()..add(CheckBiometricSupport()),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Authentication App'),
        ),
        body: Center(
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthSuccess) {
                Fluttertoast.showToast(msg: state.message);
              } else if (state is AuthFailure) {
                Fluttertoast.showToast(msg: state.error);
              } else if (state is BiometricNotAvailable) {
                Fluttertoast.showToast(
                    msg: "Biometric authentication is not available");
              }
            },
            builder: (context, state) {
              if (state is AuthLoading) {
                return CircularProgressIndicator();
              }
              return ElevatedButton(
                onPressed: () {
                  context.read<AuthBloc>().add(AuthenticateWithBiometrics());
                },
                child: Text('Authenticate'),
              );
            },
          ),
        ),
      ),
    );
  }
}

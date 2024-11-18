abstract class AuthEvent {}

class CheckBiometricSupport extends AuthEvent {}

class AuthenticateWithBiometrics extends AuthEvent {}

class ValidatePassword extends AuthEvent {}

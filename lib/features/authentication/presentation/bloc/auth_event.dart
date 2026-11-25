import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginSubmitted extends AuthEvent {
  final String emailOrPhone;
  final String password;
  final bool rememberMe;

  const LoginSubmitted({
    required this.emailOrPhone,
    required this.password,
    required this.rememberMe,
  });

  @override
  List<Object?> get props => [emailOrPhone, password, rememberMe];
}

class PhoneVerificationSubmitted extends AuthEvent {
  final String phoneNumber;

  const PhoneVerificationSubmitted({required this.phoneNumber});

  @override
  List<Object?> get props => [phoneNumber];
}

class OtpSubmitted extends AuthEvent {
  final String phoneNumber;
  final String otp;

  const OtpSubmitted({
    required this.phoneNumber,
    required this.otp,
  });

  @override
  List<Object?> get props => [phoneNumber, otp];
}

class OtpResendRequested extends AuthEvent {
  final String phoneNumber;

  const OtpResendRequested({required this.phoneNumber});

  @override
  List<Object?> get props => [phoneNumber];
}

class ForgotPasswordSubmitted extends AuthEvent {
  final String emailOrPhone;

  const ForgotPasswordSubmitted({required this.emailOrPhone});

  @override
  List<Object?> get props => [emailOrPhone];
}

class CheckAuthStatusEvent extends AuthEvent {}

class AuthResetState extends AuthEvent {}

